"""
-------------------------------------------------------------------------------
Author: 		Krzysztof Koch
File: 			mandelbrot.py
Brief: 			Mandelbrot set visualisation fast model
Date created:	20.11.2016
Last mod:		26.11.2016

Notes:		
-------------------------------------------------------------------------------
"""

# Include relevant libraries
import numpy as np
import sys
import re
import matplotlib.pyplot as plt



#------------------------------------------------------------------------------
# Constants and global variables
# -----------------------------------------------------------------------------
# Parameters for internal data representation
Q_LEN = 50							# Size of registers holding internal complex numbers
FRAC_LEN = 44 						# Number of bits for fractional and integer in the complex
INT_LEN = Q_LEN - FRAC_LEN 			# number signed fixed-point representation. (sign bit included in INT)
INPUT_LEN = 16 						# Input parameter size (in bits). 
INPUT_INT_LEN = 4 					# Number of bits for integer and fractional part of r1, r2 
INPUT_FRAC_LEN = INPUT_LEN - INPUT_INT_LEN
PRE_MUL_SHIFT = FRAC_LEN / 2 		# Pre-multiplication shift.
MASK = int("1" * Q_LEN, 2) 			# Bitmask for truncating multiplication output 



#------------------------------------------------------------------------------
# Convert Q6.44 fixed point number to float
# -----------------------------------------------------------------------------
def q_to_float(number):

	# Convert the number to binary string and test the msb (get rid of first two
	# characters because they are "0b") Also bear in mind that leading zeros are not
	# printed so length of the resulting string has to be tested too.
	temp = bin(number)
	temp = temp[2:]

	# The number is negative (2s complement) so interpret it bit by bit.
	if len(temp) == Q_LEN and temp[0] == '1':
		accumulator = 0.0
		for i in range(Q_LEN):
			if temp[i] == '1':
				if (i == 0):
					accumulator -= 2 ** (INT_LEN - 1)
				else:
					accumulator += 2 ** (INT_LEN - 1 - i)

	# Otherwise simple division will do. 
	else:
		accumulator = number / float((2 ** FRAC_LEN))

	return accumulator



#------------------------------------------------------------------------------
# Sign-shift the multiplication operands so that the output can be stored 
# in registers of same size
# -----------------------------------------------------------------------------
def pre_mul_shift(number):

	temp = bin(number);
	temp = temp[2:]
	temp = "0" * (Q_LEN - len(temp)) + temp
	return int((temp[0] * PRE_MUL_SHIFT) + temp[0:Q_LEN-PRE_MUL_SHIFT], 2)


#------------------------------------------------------------------------------
# Convert the starting point coordinates from Q4.12 to Q6.44
# -----------------------------------------------------------------------------
def convert_start_coordinates(number):

	temp = bin(number);
	temp = temp[2:]
	temp = "0" * (INPUT_LEN - len(temp)) + temp
	return int(temp[0] * (INT_LEN - INPUT_INT_LEN) + temp + "0" * (FRAC_LEN-INPUT_FRAC_LEN), 2)



#------------------------------------------------------------------------------
# Mandelbrot - functional model of the mandelbrot set hardware accelerator 
# (drawing_mandelbrot.v)
# -----------------------------------------------------------------------------
def mandelbrot(max_iterations, c_r, c_i, argand_step_h, argand_step_l, screen_width, screen_height):

	# Test case header
	modelOutput.write("--------------------------------------------------------\n")
	modelOutput.write("Maximum iterations:\t\t{:4d}\n".format(max_iterations))
	modelOutput.write("Starting 'C' Real:\t\t{:04x}\n".format(c_r))
	modelOutput.write("Starting 'C' Imaginary:\t{:04x}\n".format(c_i))
	modelOutput.write("Step size: \t\t\t\t{}{}\n".format(argand_step_h, argand_step_l))
	modelOutput.write("Screen width: \t\t\t{:4d}\n".format(screen_width))
	modelOutput.write("Screen height: \t\t\t{:4d}\n".format(screen_height))
	modelOutput.write("--------------------------------------------------------\n")
	modelOutput.write("de_data\t\tde_addr\tde_nbyte\n")

	# Convert the input arguments to internal complex number signed fixed-point
	# format 
	init_c_r = z_r = c_r = convert_start_coordinates(c_r)
	z_i = c_i = convert_start_coordinates(c_i)
	argand_step = int(argand_step_h + argand_step_l, 16)
	argand_step = argand_step << (FRAC_LEN - 2 * INPUT_LEN)

	# Initialise internal registers
	bound = 4 << FRAC_LEN 				# Calculate the bound as a fixed-point fractional number
	x_pos = 0 							# Coordinates of the pixel currently being computed
	y_pos = 0
	iteration = 1 						# Mandelbrot iteration counter. Set to 1 to save one cycle 
										# as we start with z_r = c_r and z_i = c_i instead of 0s

	# Initialise the frame store
	screen = np.zeros((screen_height, screen_width), dtype='uint8')


	# Iterate through all the pixels on screen with specified parameter
	while(True):

		iteration = 1

		# Mandelbrot iteration loop
		while (iteration < max_iterations):

			# Sign-shift current 'z' so that the output of multiplication can fit in registers
			# of same size as input operands
			mul_op1 = pre_mul_shift(z_r)
			mul_op2 = pre_mul_shift(z_i)
			z_real_sq = (mul_op1 * mul_op1) & MASK
			z_imag_sq = (mul_op2 * mul_op2) & MASK
		
			# Compute next value of 'z'
			next_z_real = (z_real_sq - z_imag_sq + c_r) & MASK
			next_z_imag = (((mul_op1 * mul_op2) << 1) + c_i) & MASK

			# Compute the value of function and check if its still within bounds.
			func_val = (z_real_sq + z_imag_sq) & MASK
			if func_val > bound:
				break

			# Update the iteration counter and 'z'
			iteration = iteration + 1
			z_r = next_z_real
			z_i = next_z_imag


		# Write to frame buffer and dump the address and byte number and value to be written to
		# to it. I want the inside of the fractal to be black
		if iteration == max_iterations:
			screen[y_pos][x_pos] = 0
		else:
			screen[y_pos][x_pos] = iteration & 0xFF

		# Compute the pixel addres and byte number
		de_data = screen[y_pos][x_pos]
		address = (y_pos << 9) + (y_pos << 7) + x_pos
		de_addr = address >> 2

		# Byte select by low strobe
		temp = address & 0b11
		if (temp == 0):
			de_nbyte = "e"
		elif (temp == 1):
			de_nbyte = "d"
		elif (temp == 2):
			de_nbyte = "b"
		elif (temp == 3):
			de_nbyte = "7"
		else:
			de_nbyte = "f"

		# Print for functional testing against the verilog output
		modelOutput.write("{0:02x}{0:02x}{0:02x}{0:02x}\t{1:05x}\t{2}\n".format(de_data, de_addr, de_nbyte))

		# Compute the next pixel number coordinate and respective point in Argand plane
		if (x_pos + 1 >= screen_width):
			if (y_pos + 1 >= screen_height):
				return screen
			else:
				x_pos = 0
				y_pos = y_pos + 1
				z_r = c_r = init_c_r
				z_i = c_i = (c_i + argand_step) & MASK
		else:
			x_pos = x_pos + 1
			z_r = c_r = (c_r + argand_step) & MASK
			z_i = c_i



#------------------------------------------------------------------------------
# Main method
# -----------------------------------------------------------------------------
# File with test vectors
testVectors = open("testVectors.txt", "r")

# File with pixel values, addresses and byte numbers dumped. 
modelOutput = open("modelOutput.txt", "w")

# Plotting figure counter
counter = 0

# Read the file with input vectors line by line
lines = testVectors.readlines()
for line in lines:
	numbers = line.split(' ')
	r0 = int(numbers[0]) 					# Max iterations before Mandelbrot set membership determined
	r1 = int(numbers[1], 16)				# Current real part of 'c'
	r2 = int(numbers[2], 16)				# Current imaginary part of 'c'
	r3 = numbers[3]							# Step size in Argand plane (32bit)
	r4 = numbers[4]				
	r5 = int(numbers[5])					# Screen width
	r6 = int(numbers[6]) 					# Screen height

	# Launch the execution of command in module	and show the resulting plot on virtual screen
	screen = mandelbrot(r0, r1, r2, r3, r4, r5, r6)	 
	plt.figure(counter) 	
	plt.imshow(screen)
	counter += 1
	
# Display all the figures generated
plt.show()
