/******************************************************************************
* Author:       Krzysztof Koch
* Brief:        Mandelbrot set visualisation drawing module
* Date created: 17/11/2016
* Last edit:    17/11/2016
* 
* Note:
******************************************************************************/



/*----------------------------------------------------------------------------
* Definitions    
*---------------------------------------------------------------------------*/ 

// FSM states
`define IDLE    0                   // Device is idle
`define ACK     1                   // Module has received a drawing request
`define BUSY    2                   // Module is carrying out the request

// Small propagation delay
`define TPD 	2





/******************************************************************************
*  Module declaration          
******************************************************************************/
module drawing_mandelbrot (input  wire        clk,				// Master clock
					       input  wire        req,				// Command request
					       output reg         ack,				// Acknowledge command request
					       output wire        busy, 			// Drawing module busy
					       input  wire [15:0] r0, 				// Maximum number of iterations per pixel
					       input  wire [15:0] r1,				// not used
					       input  wire [15:0] r2,				// not used
					       input  wire [15:0] r3,				// not used
					       input  wire [15:0] r4,				// not used
					       input  wire [15:0] r5,				// not used
					       input  wire [15:0] r6,				// not used
					       input  wire [15:0] r7,				// not used
					       output wire        de_req,			// Drawing request
					       input  wire        de_ack,			// Acknowledge drawing request
					       output wire [17:0] de_addr,			// Word address of pixel to draw
					       output reg   [3:0] de_nbyte,			// Byte number of pixel to draw
					       output wire [31:0] de_data); 		// Pixel value


/*----------------------------------------------------------------------------
*  Internal signals and buses used              
*---------------------------------------------------------------------------*/
reg	 [1:0] current_state;
reg  [1:0] next_state;




/*----------------------------------------------------------------------------
* Next state logic
*---------------------------------------------------------------------------*/ 
always @ (*)
begin
    case (current_state)
        `IDLE:	next_state = req ? `IDLE
        `ACK: cmd_fsm_next_state = `BUSY;
        `BUSY:
        begin
            if (busy)
                cmd_fsm_next_state = `IDLE;
            else 
                cmd_fsm_next_state = `IDLE;
                
        end
        default: cmd_fsm_next_state = `IDLE;
    endcase
end




/*----------------------------------------------------------------------------
*  Decode the lower 2 bits of address to produce nbyte selects.  
*---------------------------------------------------------------------------*/
always @(address[1:0])
	case(address[1:0])
		2'b00 : de_nbyte <= 4'b1110;
		2'b01 : de_nbyte <= 4'b1101;
		2'b10 : de_nbyte <= 4'b1011;
		2'b11 : de_nbyte <= 4'b0111;
		default:de_nbyte <= 4'b1111;
	endcase

endmodule
