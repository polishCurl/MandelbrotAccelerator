/******************************************************************************
* Author:       Krzysztof Koch
* Brief:        Mandelbrot set combinatorial logic
* Date created: 18/11/2016
* Last edit:    23/11/2016
* 
* Note:
******************************************************************************/

`define Q_LEN           46 					// Size of registers holding complex numbers 
`define FRAC_LEN 		40 					// Number of bits for the fractional part
`define INT_LEN         `Q_LEN-`FRAC_LEN   	// Number of bits for the integer part
`define PRE_MUL_SHIFT	`FRAC_LEN/2 		// Shift before fixed-point multiplication
`define MANDEL_INFINITY 4 					// Mandebrot definiton of 'infinity'



/*----------------------------------------------------------------------------
* Module declaration
*---------------------------------------------------------------------------*/ 
module mandelbrot_logic (input  wire [`Q_LEN-1:0] z_real, 
					     input  wire [`Q_LEN-1:0] z_imag,
					     input  wire [`Q_LEN-1:0] c_real, 
					     input  wire [`Q_LEN-1:0] c_imag,
					     output reg  [`Q_LEN-1:0] next_z_real, 
					     output reg  [`Q_LEN-1:0] next_z_imag,
					     output reg 			  finished);



/*----------------------------------------------------------------------------
* Internal signals and buses used              
*---------------------------------------------------------------------------*/ 
reg [`Q_LEN -1:0] bound; 		// Mandelbrot 'infinity'
reg [`Q_LEN -1:0] mul_op1;		// Multiplication operands: complex number 
reg [`Q_LEN -1:0] mul_op2; 		// values "shifted" right for fixed-point multiplication
reg [`Q_LEN -1:0] z_real_sq; 	// Squared values of real and imaginary part 
reg [`Q_LEN -1:0] z_imag_sq;  	// of complex number 'z'
reg [`Q_LEN -1:0] func_val; 	// Output from the funcion z^2 + c 




/*----------------------------------------------------------------------------
* Determine if, for current value of 'z' and 'c' the resulting value of function 
* 'z^2' + c is bounded. Also the next value of 'z' is computed         
*---------------------------------------------------------------------------*/ 
always @ (*)
begin
	// Calculate the bound as a fixed-point fractional number
	bound = `MANDEL_INFINITY << `FRAC_LEN;	

	// Shift both imaginary and real parts of 'z' complex number by filling
	// the msb's with the sign bit
	if (z_real[`Q_LEN-1])
		mul_op1 = {{`PRE_MUL_SHIFT{1'b1}}, z_real[`Q_LEN -1:`PRE_MUL_SHIFT]};
	else 
		mul_op1 = {{`PRE_MUL_SHIFT{1'b0}}, z_real[`Q_LEN -1:`PRE_MUL_SHIFT]};

	if (z_imag[`Q_LEN-1])
		mul_op2 = {{`PRE_MUL_SHIFT{1'b1}}, z_imag[`Q_LEN -1:`PRE_MUL_SHIFT]};
	else 
		mul_op2 = {{`PRE_MUL_SHIFT{1'b0}}, z_imag[`Q_LEN -1:`PRE_MUL_SHIFT]};

	// Calculate the squared value of real an imaginary part of 'z'
	z_real_sq = mul_op1 * mul_op1;	
	z_imag_sq = mul_op2 * mul_op2;

    // Calculate the next value of 'z'
	next_z_real = z_real_sq - z_imag_sq + c_real;
	next_z_imag = ((mul_op1 * mul_op2) << 1) + c_imag;
	func_val = z_real_sq + z_imag_sq;

	// Determine whether the function value has gone out of bounds
	finished = (func_val > bound) ? 1 : 0;
end

endmodule
