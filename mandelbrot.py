"""
-------------------------------------------------------------------------------
Author: 		Krzysztof Koch
File: 			mandelbrot.py
Brief: 			Mandelbrot set visualisation functional model
Date created:	20.11.2016
Last mod:		20.11.2016

Notes:
-------------------------------------------------------------------------------
"""

# Include relevant libraries
import numpy as np
import sys
import matplotlib.pyplot as plt



#------------------------------------------------------------------------------
# Convert Q4.28 fixed point number to float
# -----------------------------------------------------------------------------
def q_to_float(number):
	temp = bin(number)
	temp = temp[2:]
	if len(temp) == Q_LEN and temp[0] == '1':
		accumulator = 0.0
		for i in range(Q_LEN):
			if temp[i] == '1':
				if (i == 0):
					accumulator -= 2 ** (INT_LEN - 1)
				else:
					accumulator += 2 ** (INT_LEN - 1 - i)
	else:
		accumulator = number / float((2 ** FRAC_LEN))

	return accumulator



#------------------------------------------------------------------------------
# Preprocess complex numbers before they can be used in multiplication
# -----------------------------------------------------------------------------
def process_complex_numbers(number):

	# Shift the input and sign extend it
	temp = bin(number);
	temp = temp[2:]
	temp = "0" * (Q_LEN - len(temp)) + temp
	if (temp[0] == '1' and len(temp) == Q_LEN):
		return int(("1" * PRE_MUL_SHIFT) + temp[0:Q_LEN-PRE_MUL_SHIFT], 2)
	else:
		return int(("0" * PRE_MUL_SHIFT) + temp[0:Q_LEN-PRE_MUL_SHIFT], 2)



#------------------------------------------------------------------------------
# Mask off bits that are overflown according to the internal complex number 
# representation
# -----------------------------------------------------------------------------
def mask_off(number):
	return number & int("1" * Q_LEN, 2)




#------------------------------------------------------------------------------
# Constants and global variables
# -----------------------------------------------------------------------------
# Screen size
SCREEN_WIDTH = 640				
SCREEN_HEIGHT = 480

# Number formats
Q_LEN = 43
FRAC_LEN = 40
INT_LEN = 3
INPUT_LEN = 16
PRE_MUL_SHIFT = 20


# Calculate the bound as a fixed-point fractional number
bound = 4 << FRAC_LEN

# Coordinates of the pixel currently being computed
x_pos = 0
y_pos = 0

# Real and Imaginary parts of 'z' and 'c' complex numbers in recursive
# function z^2 + c
z_r = z_i = 0
c_r = c_i = 0

# Real and imaginary parts of 'z' squared
z_real_sq = 0
z_imag_sq = 0

# Preprocessed 'z' for multiplication
mul_op1 = 0
mul_op2 = 0

iteration = 0



#------------------------------------------------------------------------------
# Mandelbrot
# -----------------------------------------------------------------------------
# Load the input parameters
max_iterations = int(sys.argv[1])					# Max iterations before Mandelbrot set membership determined
z_r = c_r = init_c_r = int(sys.argv[2] + "0" * ((FRAC_LEN-INPUT_LEN+4)/4), 16)		# Current real part of 'c'
z_i = c_i = int(sys.argv[3] + "0" * ((FRAC_LEN-INPUT_LEN+4)/4), 16)			# Current imaginary part of 'c'
argand_step = int(sys.argv[4] + "0" * ((FRAC_LEN-INPUT_LEN)/4), 16)		# Step size in Argand plane



# Initialise the frame store
screen = np.zeros((SCREEN_HEIGHT, SCREEN_WIDTH))


# Iterate through all the pixels on screem
while(True):

	iteration = 1


	# Mandelbrot iteration loop
	while (True):

		# Proprocess 'z' so that, z_r and z_i can be used in multiplication
		mul_op1 = process_complex_numbers(z_r)
		mul_op2 = process_complex_numbers(z_i)

		z_real_sq = mask_off(mul_op1 * mul_op1)
		z_imag_sq = mask_off(mul_op2 * mul_op2)

		print hex(z_r),
		print hex(mul_op1)

		"""
		print q_to_float(z_r),
		print q_to_float(z_real_sq),
		print q_to_float(z_i),
		print q_to_float(z_imag_sq)
		"""

		# Compute next value of 'z'
		z_r = mask_off(z_real_sq - z_imag_sq + c_r)
		z_i = mask_off(mul_op1 * mul_op2)
		z_i = mask_off((z_i << 1) + c_i)

		# Compute the value of function and check if its still within bounds.
		func_val = z_real_sq + z_imag_sq

		
		


		if (func_val > bound or iteration >= max_iterations):
			screen[y_pos][x_pos] = iteration & 255
			break


		iteration = iteration + 1


	if (x_pos + 1 >= SCREEN_WIDTH):
		if (y_pos + 1 >= SCREEN_HEIGHT):
			plt.imshow(screen)
			plt.show()
			sys.exit(0)
		else:
			x_pos = 0
			y_pos = y_pos + 1
			c_r = z_r = init_c_r
			z_i = mask_off((c_i + argand_step))
			c_i = z_i
	else:
		x_pos = x_pos + 1
		z_r = mask_off((c_r + argand_step))
		c_r = z_r


