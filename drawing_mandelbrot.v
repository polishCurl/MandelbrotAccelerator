/*******************************************************************************************
* Author:       Krzysztof Koch
* Brief:        Mandelbrot set visualisation drawing module
* Date created: 17/11/2016
* Last edit:    26/11/2016
* 
* Note:      
*   "The" Mandelbrot set is the set obtained from the quadratic recurrence equation
*   (z_n+1) = (z_n)^2 + C  with z_0 = C, where points 'C' in the complex plane for which   
*   the orbit of 'z_n' does not tend to infinity are in the set. 
*
*   Given:
*       r0 - maximum number of iterations before mandelbrot set membership is determined
*       r1 - 'C_0' (real)
*       r2 - 'C_0' (imaginary)
*       r3 - step size in Argand plane
*   Each pixel coordinate on VGA screen (640x480) is mapped to a point in Argand plane 'C'. 
*   Then the recurrence equation is applied at most r0 times. The computation of single pixel
*   colour can terminate sooner if 'z_n' lies outside a circle of radius 2, which guarantees
*   the function will diverge. 
*
*   Optimisations introduced are:
*       1. Calulation of pixel colour starts with z_1 = C. so that one cycle is saved instead
*       of doing z_0 = 0 in the function (z_n+1) = (z_n)^2 + C
*       2. At least two cycles are needed to compute a pixel value and send the respective value
*       in the drawing interface. Some pipelining is introduced by sending the command while the 
*       computation of next pixel is started.
*******************************************************************************************/



/*------------------------------------------------------------------------------------------
* Definitions    
*-----------------------------------------------------------------------------------------*/
// FSM states
`define IDLE            0                   // Device is idle
`define NEW_PIXEL       1                   // Compute new pixel value
`define CONTINUE_PIXEL  2                   // Computation of pixel current pixel value in progress

// Global constants
`define Q_LEN           50                  // Size of registers holding complex numbers
`define FRAC_LEN        44                  // Number of bits for the fractional part
`define INT_LEN         `Q_LEN-`FRAC_LEN    // Number of bits for the integer part
`define INPUT_LEN       16                  // Input parameter size (in bits).
`define INPUT_INT_LEN   4                   // Number of bits for integer and fractional part of r1, r2 
`define INPUT_FRAC_LEN  `INPUT_LEN-`INPUT_INT_LEN

`define STEP_SIZE_SHIFT 4                   // Shift for conversion of step size (for better zoom)



/*******************************************************************************************
*  Module declaration          
*******************************************************************************************/
module drawing_mandelbrot (input  wire        clk,          // Master clock
                           input  wire        req,          // Command request
                           output reg         ack,          // Acknowledge command request
                           output wire        busy,         // Drawing module busy
                           input  wire [15:0] r0,           // Maximum number of iterations per pixel
                           input  wire [15:0] r1,           // Starting Real coordinate in Argand plane
                           input  wire [15:0] r2,           // Starting Imaginary coordinate in Argand plane
                           input  wire [15:0] r3,           // Step size in Argand space (32bit)
                           input  wire [15:0] r4,           // Step size in Argand space (32bit) 
                           input  wire [15:0] r5,           // Screen width (in pixels)
                           input  wire [15:0] r6,           // Screen height (in pixels)
                           input  wire [15:0] r7,           // not used
                           output wire        de_req,       // Drawing request
                           input  wire        de_ack,       // Acknowledge drawing request
                           output wire [17:0] de_addr,      // Word address of pixel to draw
                           output reg   [3:0] de_nbyte,     // Byte number of pixel to draw
                           output wire [31:0] de_data);     // Pixel value



/*------------------------------------------------------------------------------------------
*  Internal registers             
*-----------------------------------------------------------------------------------------*/
reg  [1:0]        draw_state;               // Current state of the Mandelbrot drawing FSM
reg  [15:0]       max_iterations;           // Max iterations before Mandelbrot set membership determined
reg  [15:0]       iteration;                // Iteration counter
reg  [`Q_LEN-1:0] init_c_r;                 // Initial value of real part of 'c'
reg  [`Q_LEN-1:0] z_r;                      // Current real part of 'z'
reg  [`Q_LEN-1:0] z_i;                      // Current imaginary part of 'z'
reg  [`Q_LEN-1:0] c_r;                      // Current real part of 'c'
reg  [`Q_LEN-1:0] c_i;                      // Current imaginary part of 'c'
reg  [`Q_LEN-1:0] argand_step;              // Step size in Argand plane
reg  [9:0]        screen_width;             // Screen size 
reg  [9:0]        screen_height;
reg  [9:0]        x_pos;                    // Current X coordinate of pixel computed
reg  [9:0]        y_pos;                    // Current Y coordinate of pixel computed



/*------------------------------------------------------------------------------------------
*  Internal signals and buses         
*-----------------------------------------------------------------------------------------*/
wire              finished;                 // 1 if recurring function diverges
wire [`Q_LEN-1:0] next_z_r;                 // Next real value of 'z'
wire [`Q_LEN-1:0] next_z_i;                 // Next imaginary value of 'z'
wire [`Q_LEN-1:0] start_real;               // Starting point in argand plane (real and imaginary part).    
wire [`Q_LEN-1:0] start_imag;               // and step size in argand plane converted to internal complex
wire [`Q_LEN-1:0] step;                     // number representation
wire [19:0]       address;                  // Pixel address in frame store




/*------------------------------------------------------------------------------------------
* Initialise the combinatorial logic module for Mandelbrot set calculation             
*-----------------------------------------------------------------------------------------*/
mandelbrot_logic logic( .z_real(z_r),
                        .z_imag(z_i),
                        .c_real(c_r),
                        .c_imag(c_i),
                        .next_z_real(next_z_r),
                        .next_z_imag(next_z_i),
                        .finished(finished));
                        
                        

/*------------------------------------------------------------------------------------------
* Assign starting values of some of the outputs
*-----------------------------------------------------------------------------------------*/
initial draw_state = `IDLE;                 // Starting state
initial ack = 0;                            // Starting value of ack



/*------------------------------------------------------------------------------------------
* Simple output combinatorial logic
*-----------------------------------------------------------------------------------------*/
// Device is always busy unless in the idle state
assign busy = draw_state != `IDLE;

// Insert de_req when the pixel value computation is finished, de_ack is cleared and the 
// module is actually processing a request
assign de_req = busy && (finished || (iteration >= max_iterations));

// Convert the input parameters Q4.12 to Q6.44
assign start_real = {{(`INT_LEN-`INPUT_INT_LEN){r1[`INPUT_LEN-1]}}, r1, {(`FRAC_LEN-`INPUT_FRAC_LEN+8){1'b0}}};
assign start_imag = {{(`INT_LEN-`INPUT_INT_LEN){r2[`INPUT_LEN-1]}}, r2, {(`FRAC_LEN-`INPUT_FRAC_LEN+8){1'b0}}};

// Convert the step size from Q0.32 to Q6.44
assign step = {{`INT_LEN{1'b0}}, r3, r4, {(`FRAC_LEN-2*`INPUT_LEN){1'b0}}};

// Pixel value to write. Inside of the fractal is black. Colour is 8bit RGB so is
// repeated fo match the word size in memory
assign de_data = iteration == max_iterations ? 0 : {4{iteration[7:0]}};
                    
// Calculate pixel address in the frame store based on current x and y position
assign address = (y_pos << 9) + (y_pos << 7) + x_pos;
assign de_addr = address[19:2];

// Decode the lower 2 bits of address to produce nbyte selects.  
always @(address[1:0])
    case(address[1:0])
        2'b00 : de_nbyte <= 4'b1110;
        2'b01 : de_nbyte <= 4'b1101;
        2'b10 : de_nbyte <= 4'b1011;
        2'b11 : de_nbyte <= 4'b0111;
        default:de_nbyte <= 4'b1111;
    endcase



/*******************************************************************************************
* FSM
*******************************************************************************************/
always @ (posedge clk)
begin
    case (draw_state)

        /*----------------------------------------------------------------------------------
        * Idle state, device is waiting for a request
        *---------------------------------------------------------------------------------*/
        `IDLE:  
            // If a request arrives...
            if (req)
            begin
                // Load the input parameters from command interface
                max_iterations <= r0;       
                init_c_r <= start_real; 
                c_r <= start_real;                  // One mandelbrot iteration is saved by
                z_r <= start_real;                  // setting 'z' directly to 'c' instead of 0
                c_i <= start_imag;                  // This is why iteration counter is reset to 1
                z_i <= start_imag;
                argand_step <= step;
                screen_width <= r5;
                screen_height <= r6;
                    
                // Reset value of other registers
                ack <= 1;                           // Acknowledge the request
                iteration <= 1;                     // Reset the iteration counter
                x_pos <= 0;                         // Start with the top left pixel
                y_pos <= 0;                         
                draw_state <= `CONTINUE_PIXEL;      // Carry on with calculation of the first pixel
            end                                     // This saves a cycle, instead of goint to `NEW PIXEL

        /*----------------------------------------------------------------------------------
        * New pixel value to compute
        *---------------------------------------------------------------------------------*/
        `NEW_PIXEL:
            begin
                // Clear 'acknowledge' output signal in command interface and Reset the iteration counter
                ack <= 0;    

                // Wait for acknowledgement from memory to carry on with computing next pixel
                if (de_ack)
                begin                        
                    iteration <= 1;                     

                    // If the last pixel in a row has been computed
                    if (x_pos + 1 >= screen_width)
                    begin
                        // If both the pixel X and Y coordinate have 'overflowed' then the request has been
                        // completed 
                        if (y_pos + 1 >= screen_height)
                            draw_state <= `IDLE;
             
                        // Go to the row below to avoid going off screen. Update both the pixel coordinates
                        // and Argand plane coordinates and set the next state to continue calculation
                        else
                        begin
                            x_pos <= 0;                 
                            y_pos <= y_pos + 1;
                            c_r <= init_c_r;           
                            z_r <= init_c_r;
                            c_i <= c_i + argand_step;
                            z_i <= c_i + argand_step;
                            draw_state <= `CONTINUE_PIXEL;  
                        end
                    end
                    // Simplest case, next pixel to compute is to the right of the previous one
                    else
                    begin
                        x_pos <= x_pos + 1;
                        c_r <= c_r + argand_step;
                        z_r <= c_r + argand_step;
                        z_i <= c_i;
                        draw_state <= `CONTINUE_PIXEL;
                    end
                end
            end

        /*----------------------------------------------------------------------------------
        * Pixel value still computed (Mandelbrot set membership is not determined)
        *---------------------------------------------------------------------------------*/
        `CONTINUE_PIXEL:
            begin
                // Clear 'acknowledge' output signal in command interface
                ack <= 0;

                // If either the 'z' value has overflown or max number of iterations is reached
                // computation is over.
                if (finished || iteration >= max_iterations)
                    draw_state <= `NEW_PIXEL;

                // Update current 'Z' and increment the iteration counter
                else 
                begin
                    iteration <= iteration + 1;
                    z_r <= next_z_r;
                    z_i <= next_z_i; 
                end
            end
        default: draw_state <= `IDLE;
    endcase
end
endmodule