"""
-------------------------------------------------------------------------------
Author: 		Krzysztof Koch
File: 			mandelbrot.py
Brief: 			Mandelbrot set visualisation functional model
Date created:	20.11.2016
Last mod:		20.11.2016

Notes:			A brave attempt to model high-level functionality of the hardware
				accelerator
-------------------------------------------------------------------------------
"""

# Include relevant libraries
import numpy as np
import sys
import re
import matplotlib.pyplot as plt


counter = 0

#------------------------------------------------------------------------------
# Constants and global variables
# -----------------------------------------------------------------------------
# Screen size
SCREEN_WIDTH = 640				
SCREEN_HEIGHT = 480

# Parameters for internal data representation
Q_LEN = 46							# Register size holding real/imaginary parts of complex numbers
FRAC_LEN = 40 						# Number of bits for fractional part
INT_LEN = Q_LEN - FRAC_LEN 			# Number of bits for integer part
INPUT_LEN = 16 						# Input parameter size (in bits)
PRE_MUL_SHIFT = FRAC_LEN / 2 		# Pre-multiplication shift needed
MASK = int("1" * Q_LEN, 2) 			# Bitmask for truncating multiplication output 



#------------------------------------------------------------------------------
# Convert Q4.28 fixed point number to float
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

	# Otherwise simple division will do. This is for debugging so doesn't reflect
	# actual hardware
	else:
		accumulator = number / float((2 ** FRAC_LEN))

	return accumulator



#------------------------------------------------------------------------------
# Signed fixed-point number preprocessing
# -----------------------------------------------------------------------------
def process_complex_numbers(number):

	# Shift the input right and sign extend it
	temp = bin(number);
	temp = temp[2:]
	temp = "0" * (Q_LEN - len(temp)) + temp

	if temp[0] == '1':
		return int(("1" * PRE_MUL_SHIFT) + temp[0:Q_LEN-PRE_MUL_SHIFT], 2)
	else:
		return int(("0" * PRE_MUL_SHIFT) + temp[0:Q_LEN-PRE_MUL_SHIFT], 2)



#------------------------------------------------------------------------------
# Mandelbrot - functional model of the mandelbrot set hardware accelerator
# -----------------------------------------------------------------------------
def mandelbrot(max_iterations, c_r, c_i, argand_step):

	# Convert the input arguments to internal complex number signed fixed-point
	# format 
	z_i = c_i = int(bin(c_i) + "0" * (Q_LEN-INPUT_LEN), 2)
	init_c_r = z_r = c_r = int(bin(c_r) + "0" * (Q_LEN-INPUT_LEN), 2)
	argand_step = int(bin(argand_step) + "0" * (FRAC_LEN-INPUT_LEN), 2)

	# Test case header
	modelOutput.write("\n\n--------------------------------------------------------\n")
	modelOutput.write("Maximum iterations:\t\t{}\n".format(max_iterations))
	modelOutput.write("Starting 'C' Real:\t\t{:6f}\n".format(q_to_float(c_r)))
	modelOutput.write("Starting 'C' Imaginary:\t{:6f}\n".format(q_to_float(c_i)))
	modelOutput.write("Step size: \t\t\t\t{:6f}\n".format(q_to_float(argand_step)))
	modelOutput.write("--------------------------------------------------------\n")
	modelOutput.write("de_data\t\tde_addr\tde_nbyte\n")

	# Initialise internal registers
	bound = 4 << FRAC_LEN 				# Calculate the bound as a fixed-point fractional number
	x_pos = 0 							# Coordinates of the pixel currently being computed
	y_pos = 0
	iteration = 1 						# Mandelbrot iteration counter. Set to 1 to save one cycle 
										# as we start with z_r = c_r and z_i = c_i instead of 0s
	screen = np.zeros((SCREEN_HEIGHT, SCREEN_WIDTH)) # Initialise the frame store


	# Iterate through all the pixels on screem
	while(True):

		iteration = 1

		# Mandelbrot iteration loop
		while (iteration < max_iterations):



			# Preprocess 'z' so that and then calculate z_imaginary and z_real squared. Truncate
			# bits that won't fit
			mul_op1 = process_complex_numbers(z_r)
			mul_op2 = process_complex_numbers(z_i)
			z_real_sq = (mul_op1 * mul_op1) & MASK
			z_imag_sq = (mul_op2 * mul_op2) & MASK
		
			# Compute next value of 'z'
			next_z_real = (z_real_sq - z_imag_sq + c_r) & MASK
			next_z_imag = (((mul_op1 * mul_op2) << 1) + c_i) & MASK

			print hex(z_r) + "\t" + hex(next_z_real) + "\t" + hex(z_i) + "\t" + hex(next_z_imag)

			# Compute the value of function and check if its still within bounds.
			func_val = (z_real_sq + z_imag_sq) & MASK
			if func_val > bound:
				break


			# Update the iteration counter and 'z'
			iteration = iteration + 1
			z_r = next_z_real
			z_i = next_z_imag


		# Write to frame buffer and dump the address and byte number and value to be written to
		# to it
		screen[y_pos][x_pos] = iteration & 0xFF
		de_data = iteration & 0xFF
		address = (y_pos << 9) + (y_pos << 7) + x_pos
		de_addr = address >> 2

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

		modelOutput.write("{0:02x}{0:02x}{0:02x}{0:02x}\t{1:05x}\t{2}\n".format(de_data, de_addr, de_nbyte))


		# Compute the next pixel number coordinate and respective point Argand plane
		if (x_pos + 1 >= SCREEN_WIDTH):
			if (y_pos + 1 >= SCREEN_HEIGHT):
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

# Test for valid number of command line arguments
if len(sys.argv) is not 4:
	print "Invalid number of command line arguments! (should be 3)"
	sys.exit()

# Load the input parameters
testVectors = open(sys.argv[1], "r")
modelOutput = open(sys.argv[2], "w")
#verilogOutput = open(sys.argv[3], "r")

# Read the file with input vectors line by line
lines = testVectors.readlines()
counter = 0
for line in lines:
	numbers = line.split(' ')
	r0 = int(numbers[0]) 					# Max iterations before Mandelbrot set membership determined
	r1 = int(numbers[1], 16)				# Current real part of 'c'
	r2 = int(numbers[2], 16)				# Current imaginary part of 'c'
	r3 = int(numbers[3], 16)				# Step size in Argand plane
	screen = mandelbrot(r0, r1, r2, r3)		# Launch the execution of command in module	
	plt.figure(counter) 					# Show the resulting plot on virtual screen
	plt.imshow(screen)
	counter += 1


plt.show()
