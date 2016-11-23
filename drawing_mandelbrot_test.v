/****************************************************************************************
* Author:       Krzysztof Koch
* Brief:        Stimulus file for functional testing of the line drawing module
* Date created: 09/10/2016
* Last edit:    13/10/2016
* 
* Note:
****************************************************************************************/

`define CLOCK_PERIOD    20          // Clock period in time units
`define TEST_VECTORS    3           // Number of test vectors
`define VECTOR_LENGTH   4           // Test vector length



/*--------------------------------------------------------------------------------------
* Global variables
*-------------------------------------------------------------------------------------*/
integer launch = 0;                 // Flag to indicate a test should be run
integer test_no = 0;                // Test case counter
integer test_vectors;               // File handle for input vectors
integer drawing_output;             // File handle for saving drawing interface output
integer i;                           

// 2-D array to store the test vectors
reg [15:0] test_data [0:(`TEST_VECTORS - 1)][0:(`VECTOR_LENGTH - 1)];     



/*--------------------------------------------------------------------------------------
* Load the test vectors from a file and open the file for saving debug data
*-------------------------------------------------------------------------------------*/
initial
begin
    drawing_output = $fopen("/home/mbax4kk2/MandelbrotAccelerator/drawingOutput.txt","w");
    test_vectors = $fopen("/home/mbax4kk2/MandelbrotAccelerator/testVectors.txt","r");          
    for (i = 0; i < `TEST_VECTORS; i = i + 1)         
        $fscanf(test_vectors, "%d %x %x %x", test_data[i][0], test_data[i][1], test_data[i][2], test_data[i][3]);
end



/*--------------------------------------------------------------------------------------
* Generate the clock signal and set initial values
*-------------------------------------------------------------------------------------*/
initial 
begin 
    de_ack = 0;
    clk = 0;
    forever #(`CLOCK_PERIOD / 2) clk = ~clk;
end
 


/*--------------------------------------------------------------------------------------
* Task:         insertDrawingCmd
* Purpose:      Insert a command to the drawing module under test
* Inputs:       Data parameters       
*-------------------------------------------------------------------------------------*/
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

    launch = 1;                 // A request is ready to be triggerred
end                        
endtask



/*--------------------------------------------------------------------------------------
* Command interface specificaton
*-------------------------------------------------------------------------------------*/                      
always @(posedge clk)
begin
    if(launch)             // If the launch flag is raised, current request
    begin                       // should be started (it is assumed that the parameters
        launch <= 0;            // are already specified at this point
        req <= 1;
    end
    else if(ack)           // Clear the req signal if acknowledgement is received
        req <= 0;
end



/*--------------------------------------------------------------------------------------
* Drawing interface specificaton
*-------------------------------------------------------------------------------------*/ 
always @(posedge clk)
begin
    if(de_ack)
        de_ack <= 0;            // Clear the de_ack after a clock cycle 
    else if(de_req)
        de_ack <= 1;            // Send the acknowledgement in response to the drawing request
end



/*--------------------------------------------------------------------------------------
* Runs tests one by one
*-------------------------------------------------------------------------------------*/
always @ (negedge busy)         // when the previous test finishes...
begin
    if (test_no < `TEST_VECTORS)
    begin
        insertDrawingCmd(test_data[test_no][0], test_data[test_no][1], test_data[test_no][2], 
                         test_data[test_no][3], 16'hxxxx, 16'hxxxx, 16'hxxxx, 16'hxxxx);
        test_no = test_no + 1;
    end 
    else 
        $stop; 
end



/*--------------------------------------------------------------------------------------
* Dump the data from drawing interface for functional testing
*-------------------------------------------------------------------------------------*/
always @ (posedge de_ack)
begin
    $fdisplay(drawing_output, "%x\t%x\t%x", de_data, de_addr, de_nbyte);
end


