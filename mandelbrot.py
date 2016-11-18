"""
-------------------------------------------------------------------------------
Author: 		Krzysztof Koch
File: 			mandelbrot.py
Brief: 			Mandelbrot set visualisation fast model
Date created:	24.10.2016
Last mod:		24.10.2016

Notes:
-------------------------------------------------------------------------------
"""

# Include relevant libraries
import numpy as np
import matplotlib.pyplot as plt


"""
-------------------------------------------------------------------------------
Setup
-------------------------------------------------------------------------------
"""
# Screen resolution
SCREEN_WIDTH = 640
SCREEN_HEIGHT = 480
screen = np.zeros((SCREEN_HEIGHT, SCREEN_WIDTH))

# Size of the complex plane in Real and Imaginary dimension and offsets
REAL_PLANE_SIZE = 3.0
IMAGINARY_PLANE_SIZE = 2.0
REAL_PLANE_OFFSET = -2.0
IMAGINARY_PLANE_OFFSET = -1.0

# Bound value
BOUND_VALUE = 2.0

# Coordinates of the pixel currently being computed
xPixel = 0.0
yPixel = 0.0

# Iteration counter and maximum number of iterations allowed
iteration = 0
MAX_ITERATION = 50

# Real and imaginary part of the complex number whose mandelbrot set membership
# is being tested: c
cReal = 0.0
cImaginary = 0.0

# Complex number iterator: z
zReal = 0.0
zImaginary = 0.0



"""
-------------------------------------------------------------------------------
Main program loop
-------------------------------------------------------------------------------
"""
for xPixel in range(0, SCREEN_WIDTH):
	for yPixel in range(0, SCREEN_HEIGHT):

		# Compute the complex number for which we test mandelbrot set membership
		cReal = xPixel * REAL_PLANE_SIZE / SCREEN_WIDTH + REAL_PLANE_OFFSET
		cImaginary = yPixel * IMAGINARY_PLANE_SIZE  / SCREEN_HEIGHT + IMAGINARY_PLANE_OFFSET

		# Reset important variables
		iteration = 0
		zReal = 0.0
		zImaginary = 0.0

		# Iterate until the complex number Z is outside the circle of radius BOUND_VALUE
		# The equation for the circle is: x^2 + y^2 <= r^2. Or we reached the maximum
		# number of iterations
		while ((zReal * zReal + zImaginary * zImaginary <= BOUND_VALUE * BOUND_VALUE) and (iteration < MAX_ITERATION)):

			# Calculate the next value of the complex number z
			# z^2 + c 
			nextZReal = zReal * zReal - zImaginary * zImaginary + cReal
			nextZImaginary = 2 * zReal * zImaginary + cImaginary
			zReal = nextZReal
			zImaginary = nextZImaginary
			iteration = iteration + 1


		# Test if we have reached the limit of iterations, which implies that the function
		# is bounded for given cReal and cImaginary
		if iteration == MAX_ITERATION:
			screen[yPixel][xPixel] = 0
		else:
			screen[yPixel][xPixel] = int(iteration * 256 / MAX_ITERATION)


"""
-------------------------------------------------------------------------------
Rendering
-------------------------------------------------------------------------------
"""
plt.imshow(screen)
plt.show()



