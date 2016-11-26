/****************************************************************************************
* Author:       Krzysztof Koch
* Brief:        Mandelbrot set combinatorial logic
* Date created: 18/11/2016
* Last edit:    25/11/2016
* 
* Note:
*   Logic to determine whether the complex function z_(n+1) = (z_n)^2 + C diverges for 
*   given'z' and 'c' and to compute the next 'z' in this recurrence equation
****************************************************************************************/



/*--------------------------------------------------------------------------------------
* Constant parameters
*-------------------------------------------------------------------------------------*/ 
`define Q_LEN           50                  // Number of bits for representing complex numbers
                                            // using signed fixed point numbers
`define FRAC_LEN        44                  // Bits in the fractional part
`define INT_LEN         `Q_LEN-`FRAC_LEN    // Bits in the integer part (including sign bit)
`define PRE_MUL_SHIFT   `FRAC_LEN/2         // Shift before fixed-point multiplication
`define MANDEL_INFINITY 4                   // Mandebrot definiton of 'infinity'



/*--------------------------------------------------------------------------------------
* Module declaration
*-------------------------------------------------------------------------------------*/ 
module mandelbrot_logic (input  wire [`Q_LEN-1:0] z_real,       // Real part of 'z_n'
                         input  wire [`Q_LEN-1:0] z_imag,       // Imaginary part of 'z_n'
                         input  wire [`Q_LEN-1:0] c_real,       // Real part of 'C'
                         input  wire [`Q_LEN-1:0] c_imag,       // Imaginary part of 'C'
                         output reg  [`Q_LEN-1:0] next_z_real,  // Real part of 'z_(n+1)'
                         output reg  [`Q_LEN-1:0] next_z_imag,  // Imaginary part of 'z_(n+1)'
                         output reg               finished);    // 'Function diverges' flag



/*--------------------------------------------------------------------------------------
* Internal signals and buses used. All buses carry numbers in the Q(INT_LEN.FRAC_LEN) format             
*-------------------------------------------------------------------------------------*/ 
reg [`Q_LEN -1:0] bound;        // Mandelbrot 'infinity'
reg [`Q_LEN -1:0] mul_op1;      // Multiplication operands: complex number 
reg [`Q_LEN -1:0] mul_op2;      // values "shifted" right for fixed-point multiplication
reg [`Q_LEN -1:0] z_real_sq;    // Squared values of real and imaginary part of complex
reg [`Q_LEN -1:0] z_imag_sq;    // number 'z'
reg [`Q_LEN -1:0] func_val;     // z^2 - used to check if function goes to infinity



/*--------------------------------------------------------------------------------------
* Determine if, for current value of 'z' and 'c' the resulting value of function 
* 'z^2' + c is bounded. Also the next value of 'z' is computed         
*-------------------------------------------------------------------------------------*/ 
always @ (*)
begin
    // Calculate the bound as a fixed-point fractional number
    bound = `MANDEL_INFINITY << `FRAC_LEN;  

    // Signed shift of both real and imaginary parts of 'z'. Necessary to fit multiplication
    // output inside registers of same size as inputs
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
    
    // Determine whether the recurrence function diverges ('z' lies outside circle of
    // of radius 2)
    func_val = z_real_sq + z_imag_sq;
    finished = (func_val > bound) ? 1 : 0;
end

endmodule