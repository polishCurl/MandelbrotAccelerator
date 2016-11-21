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
START_REAL = -2.0
START_IMAGINARY = -1.0
ARGAND_STEP = 0.005

# Bound value
BOUND_VALUE = 2.0

# Coordinates of the pixel currently being computed
xPixel = 0.0
yPixel = 0.0

# Iteration counter and maximum number of iterations allowed
iteration = 0
MAX_ITERATION = 30

# Real and imaginary part of the complex number whose mandelbrot set membership
# is being tested: c
cReal = START_REAL
cImaginary = START_IMAGINARY

# Complex number iterator: z
zReal = 0.0
zImaginary = 0.0



"""
-------------------------------------------------------------------------------
Main program loop
-------------------------------------------------------------------------------
"""
for yPixel in range(0, SCREEN_HEIGHT):
	for xPixel in range(0, SCREEN_WIDTH):


		
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
		screen[yPixel][xPixel] = iteration & 255;

		cReal += ARGAND_STEP

	cReal = START_REAL
	cImaginary += ARGAND_STEP


"""
-------------------------------------------------------------------------------
Rendering
-------------------------------------------------------------------------------
"""
plt.imshow(screen)
plt.show()



