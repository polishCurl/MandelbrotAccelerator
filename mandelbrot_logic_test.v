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
`define Q_LEN 		        46 		// Size of registers holding complex numbers
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
reg	 [`Q_LEN-1:0] c_real_in  [0:`TEST_VECTORS_NO];     
reg	 [`Q_LEN-1:0] c_imag_in  [0:`TEST_VECTORS_NO];    





/*----------------------------------------------------------------------------
* Test bench  
*---------------------------------------------------------------------------*/ 
initial
begin
    
    // Initialise test cases, all falues are Q(6.40)
    c_real_in[0] = 0;                           // 0.0
    c_real_in[1] = `Q_LEN'h000000A70000;        // 0.00001
    c_real_in[2] = `Q_LEN'h001999999999;        // 0.1
    c_real_in[3] = `Q_LEN'h004CCCCCCCCC;        // 0.3          
    c_real_in[4] = `Q_LEN'h008000000000;        // 0.5
    c_real_in[5] = `Q_LEN'h009999999999;        // 0.6
    c_real_in[6] = `Q_LEN'h001C7A390000;        // 0.11124
    c_real_in[7] = `Q_LEN'h00DF765F0000;        // 0.872
    c_real_in[8] = `Q_LEN'h010000000000;        // 1.0
    c_real_in[9] = `Q_LEN'h3FFFFFFFFFFF;        // -0.0000001
    c_real_in[10] = `Q_LEN'h3FDF765F0000;       // -0.128
    c_real_in[11] = `Q_LEN'h3FB333333333;       // -0.3
    c_real_in[12] = `Q_LEN'h3F0000000000;       // -1.0
    c_real_in[13] = `Q_LEN'h3E1C7A390000;       // -1.88876

    c_imag_in[0] = 0;                           // 0.0i
    c_imag_in[1] = `Q_LEN'h000000A70000;        // 0.00001i
    c_imag_in[2] = `Q_LEN'h001999999999;        // 0.1i
    c_imag_in[3] = `Q_LEN'h004CCCCCCCCC;        // 0.3i       
    c_imag_in[4] = `Q_LEN'h008000000000;        // 0.5i
    c_imag_in[5] = `Q_LEN'h009999999999;        // 0.6i
    c_imag_in[6] = `Q_LEN'h001C7A390000;        // 0.11124i
    c_imag_in[7] = `Q_LEN'h00DF765F0000;        // 0.872i
    c_imag_in[8] = `Q_LEN'h010000000000;        // 1.0i
    c_imag_in[9] = `Q_LEN'h3FFFFFFFFFFF;        // -0.0000001i
    c_imag_in[10] = `Q_LEN'h3FDF765F0000;       // -0.128i
    c_imag_in[11] = `Q_LEN'h3FB333333333;       // -0.3i
    c_imag_in[12] = `Q_LEN'h3F00000000000;       // -1.0i
    c_imag_in[13] = `Q_LEN'h3E1C7A3900000;       // -1.88876i


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
 
