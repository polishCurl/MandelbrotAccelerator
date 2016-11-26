/****************************************************************************************
* Author:       Krzysztof Koch
* Brief:        Test fixture for mandelbrot_logic.v
* Date created: 18/11/2016
* Last edit:    25/11/2016
* 
* Note:         Functional test of internal combinatorial logic for determining
****************************************************************************************/


/*---------------------------------------------------------------------------------------
* Definitions    
*--------------------------------------------------------------------------------------*/ 
`define Q_LEN               50      // Size of registers holding complex numbers
`define TIME_DELAY          5       // Delay between sucessive tests
`define TEST_VECTORS_NO     19      // Number of test vectors
`define MAX_ITER_VEC_NO     3       // Number of different iteration limits



/*---------------------------------------------------------------------------------------
* Global variables    
*--------------------------------------------------------------------------------------*/ 
integer iteration;                  // number of iterations for mandelbrot set
integer real_index;                 // index into c_real_in
integer imag_index;                 // index into c_imag_in
integer iter_limits_index;          // index into iter_limits

// Test cases
reg  [`Q_LEN-1:0] c_real_in  [0:`TEST_VECTORS_NO];     
reg  [`Q_LEN-1:0] c_imag_in  [0:`TEST_VECTORS_NO];   
reg  [9:0]        iter_limits[0:`MAX_ITER_VEC_NO]; 



/*---------------------------------------------------------------------------------------
* Test bench  
*--------------------------------------------------------------------------------------*/ 
initial
begin

    // Initialise iteration limits
    iter_limits[0] = 20;
    iter_limits[1] = 1;
    iter_limits[2] = 1000;

    // Initialise test cases, all values are Q(6.44). Sign bit included in the integer part
    c_real_in[0] = 0;                            // 0.0
    c_real_in[1] = `Q_LEN'h000000A700000;        // 0.00001
    c_real_in[2] = `Q_LEN'h0019999999999;        // 0.1
    c_real_in[3] = `Q_LEN'h004CCCCCCCCCC;        // 0.3          
    c_real_in[4] = `Q_LEN'h0080000000000;        // 0.5
    c_real_in[5] = `Q_LEN'h0099999999999;        // 0.6
    c_real_in[6] = `Q_LEN'h001C7A3900000;        // 0.11124
    c_real_in[7] = `Q_LEN'h00DF765F00000;        // 0.872
    c_real_in[8] = `Q_LEN'h0100000000000;        // 1.0
    c_real_in[9] = `Q_LEN'h3FDF765F00000;        // -0.128
    c_real_in[10] = `Q_LEN'h3FB3333333333;       // -0.3
    c_real_in[11] = `Q_LEN'h3F00000000000;       // -1.0
    c_real_in[12] = `Q_LEN'h3E1C7A3900000;       // -1.88876
    c_real_in[13] = `Q_LEN'h0000000000000;       // smallest positive number possible
    c_real_in[14] = `Q_LEN'h3FFFFFFFFFFFF;       // largest negative number possible
    c_real_in[15] = `Q_LEN'h1F00000000000;       // largest positive number possible
    c_real_in[16] = `Q_LEN'h2000000000000;       // smallest negative number
    c_real_in[17] = `Q_LEN'h333333CCCCCCC;       // weird bit-patterns
    c_real_in[18] = `Q_LEN'h0F0F0F0F0F0F0;       

    c_imag_in[0] = 0;                            // 0.0i
    c_imag_in[1] = `Q_LEN'h000000A700000;        // 0.00001i
    c_imag_in[2] = `Q_LEN'h0019999999999;        // 0.1i
    c_imag_in[3] = `Q_LEN'h004CCCCCCCCCC;        // 0.3i   
    c_imag_in[4] = `Q_LEN'h0080000000000;        // 0.5i
    c_imag_in[5] = `Q_LEN'h0099999999999;        // 0.6i
    c_imag_in[6] = `Q_LEN'h001C7A3900000;        // 0.11124i
    c_imag_in[7] = `Q_LEN'h00DF765F00000;        // 0.872i
    c_imag_in[8] = `Q_LEN'h0100000000000;        // 1.0i
    c_imag_in[9] = `Q_LEN'h3FDF765F00000;        // -0.128i
    c_imag_in[10] = `Q_LEN'h3FB3333333333;       // -0.3i
    c_imag_in[11] = `Q_LEN'h3F00000000000;       // -1.0i
    c_imag_in[12] = `Q_LEN'h3E1C7A3900000;       // -1.88876i
    c_imag_in[13] = `Q_LEN'h0000000000000;       // smallest positive number possible
    c_imag_in[14] = `Q_LEN'h3FFFFFFFFFFFF;       // largest negative number possible
    c_imag_in[15] = `Q_LEN'h1F00000000000;       // largest positive number possible
    c_imag_in[16] = `Q_LEN'h2000000000000;       // smallest negative number
    c_imag_in[17] = `Q_LEN'h333333CCCCCCC;       // weird bit-patterns
    c_imag_in[18] = `Q_LEN'h0F0F0F0F0F0F0;       


    // Go through all possible iteration limits
    for (iter_limits_index = 0; iter_limits_index < `MAX_ITER_VEC_NO; iter_limits_index = iter_limits_index + 1)
    begin
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
                while ((iteration < iter_limits[iter_limits_index]) && ~finished)
                begin
                    #`TIME_DELAY
                    iteration = iteration + 1;
                    z_real = next_z_real;
                    z_imag = next_z_imag;
                end
            end
        end
    end
    $stop;
end