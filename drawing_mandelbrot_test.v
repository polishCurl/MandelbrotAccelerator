/******************************************************************************
* Author:       Krzysztof Koch
* Brief:        Stimulus file for functional testing of the line drawing module
* Date created: 09/10/2016
* Last edit:    13/10/2016
* 
* Note:
******************************************************************************/

`define CLOCK_PERIOD    20



/*----------------------------------------------------------------------------
* Global variables
*---------------------------------------------------------------------------*/
integer launch = 0;                 // flag to indicate a test should be run
integer test_no = 0;



/*----------------------------------------------------------------------------
* Generate the clock signal and set initial values
*---------------------------------------------------------------------------*/
initial 
begin 
    de_ack = 0;
    clk = 0;
    forever #(`CLOCK_PERIOD / 2) clk = ~clk;
end
 


/*----------------------------------------------------------------------------
* Task:         insertDrawingCmd
* Purpose:      Insert a command to the drawing module under test
* Inputs:       Data parameters       
*           
*---------------------------------------------------------------------------*/
task insertDrawingCmd(input [15:0] arg0,
                      input [15:0] arg1,
                      input [15:0] arg2,
                      input [15:0] arg3,
                      input [15:0] arg4,
                      input [15:0] arg5,
                      input [15:0] arg6,
                      input [15:0] arg7);

begin       
    r0 = arg0;                    // Initialise the request to the drawing module under
    r1 = arg1;                    // test by specifying the input parameters 
    r2 = arg2;             
    r3 = arg3;
    r4 = arg4;
    r5 = arg5;
    r6 = arg6;
    r7 = arg7;

    test_no = test_no + 1;
    launch = 1;                 // A request is ready to be triggerred
end                        
endtask



/*----------------------------------------------------------------------------
* Command interface specificaton
*---------------------------------------------------------------------------*/                      
always @(posedge clk)
begin
    if(launch == 1)             // If the launch flag is raised, current request
    begin                       // should be started (it is assumed that the parameters
        launch <= 0;            // are already specified at this point
        req <= 1;
    end
    else if(ack == 1)           // Clear the req signal if acknowledgement is received
        req <= 0;
end



/*----------------------------------------------------------------------------
* Drawing interface specificaton
*---------------------------------------------------------------------------*/ 
always @(posedge clk)
begin
    if(de_ack == 1)
        de_ack <= 0;            // Clear the de_ack after a clock cycle 
    else if(de_req == 1)
        de_ack <= 1;            // Send the acknowledgement in response to the drawing request
end



/*----------------------------------------------------------------------------
* Runs tests one by one
*---------------------------------------------------------------------------*/
always @ (negedge busy)         // when the previous test finishes...
begin
    case (test_no)
        0: insertDrawingCmd(10, 16'he000, 16'hf000, 16'h0147, 16'hxxxx, 16'hxxxx, 16'hxxxx, 16'hxxxx);
        default: $stop;
    endcase
    
end


