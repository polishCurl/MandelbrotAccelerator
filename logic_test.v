/******************************************************************************
* Author:       Krzysztof Koch
* Brief:        Test fixture for mandelbrot_logic
* Date created: 18/11/2016
* Last edit:    18/11/2016
* 
* Note:
******************************************************************************/


/*----------------------------------------------------------------------------
* Definitions    
*---------------------------------------------------------------------------*/ 
`define WORD_LEN 		    32 		// Size of registers holding complex numbers
`define TIME_DELAY          5       // Delay between sucessive tests
`define TEST_VECTORS_NO     14      // Number of test vectors
`define MAX_ITER            20      // Maximum number of iterations before mandelbrot       
                                    // set membership is determined


/*----------------------------------------------------------------------------
* Global variables    
*---------------------------------------------------------------------------*/ 
integer iteration;              // number of iterations for mandelbrot set
integer real_index;             // index into test vector of 'c' real values
integer imag_index;             // index into test vector of 'c' imaginary values

// Test cases
reg	 [`WORD_LEN-1:0] c_real_in  [0:`TEST_VECTORS_NO];     
reg	 [`WORD_LEN-1:0] c_imag_in  [0:`TEST_VECTORS_NO];    





/*----------------------------------------------------------------------------
* Test bench  
*---------------------------------------------------------------------------*/ 
initial
begin
    
    // Initialise test cases, all falues are Q(4.28)
    c_real_in[0] = 0;                   // 0.0
    c_real_in[1] = 32'h00000A70;        // 0.00001
    c_real_in[2] = 32'h01999999;        // 0.1
    c_real_in[3] = 32'h04CCCCCC;        // 0.3          
    c_real_in[4] = 32'h08000000;        // 0.5
    c_real_in[5] = 32'h09999999;        // 0.6
    c_real_in[6] = 32'h01C7A390;        // 0.11124
    c_real_in[7] = 32'h0DF765F0;        // 0.872
    c_real_in[8] = 32'h10000000;        // 1.0
    c_real_in[9] = 32'hFFFFFFFF;        // -0.0000001
    c_real_in[10] = 32'hFDF765F0;       // -0.128
    c_real_in[11] = 32'hFB333330;       // -0.3
    c_real_in[12] = 32'hF0000000;       // -1.0
    c_real_in[13] = 32'hE1C7A390;       // -1.88876

    c_imag_in[0] = 0;                   // 0.0i
    c_imag_in[1] = 32'h00000A70;        // 0.00001i
    c_imag_in[2] = 32'h01999999;        // 0.1i
    c_imag_in[3] = 32'h04CCCCCC;        // 0.3i       
    c_imag_in[4] = 32'h08000000;        // 0.5i
    c_imag_in[5] = 32'h09999999;        // 0.6i
    c_imag_in[6] = 32'h01C7A390;        // 0.11124i
    c_imag_in[7] = 32'h0DF765F0;        // 0.872i
    c_imag_in[8] = 32'h10000000;        // 1.0i
    c_imag_in[9] = 32'hFFFFFFFF;        // -0.0000001i
    c_imag_in[10] = 32'hFDF765F0;       // -0.128i
    c_imag_in[11] = 32'hFB333330;       // -0.3i
    c_imag_in[12] = 32'hF0000000;       // -1.0i
    c_imag_in[13] = 32'hE1C7A390;       // -1.88876i


    // Go through each value of z (both imaginary and real part). Reset Z complex number
    // on each test case as well as the iteration counter
    for (real_index = 0; real_index < `TEST_VECTORS_NO; real_index = real_index + 1)
    begin
        c_real = c_real_in[real_index];
        for (imag_index = 0; imag_index < `TEST_VECTORS_NO; imag_index = imag_index + 1)
		begin
            c_imag = c_imag_in[imag_index];
            z_real = 0;
            z_imag = 0;
            iteration = 0;
            #`TIME_DELAY

            // Count the number of iterations needed to determine mandelbrot set membership
            // There is a cap in order to avoid looping infinitely
            while (iteration < `MAX_ITER && ~finished)
            begin
                #`TIME_DELAY
                iteration = iteration + 1;
                z_real = next_z_real;
                z_imag = next_z_imag;
            end
        end
    end
    #`TIME_DELAY
    $stop;
end
 
