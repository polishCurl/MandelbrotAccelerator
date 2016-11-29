;****************************************************************************************
; Author:       Krzysztof Koch
; Brief:        Demo program for the mandelbrot set hardware accelerator
; Date created: 29/11/2016
; Last edit:    29/11/2016
; 
; Note:
;****************************************************************************************



;----------------------------------------------------------------------------------------
; Allocate memory for stack
;----------------------------------------------------------------------------------------
				DEFS 	128, 0					
stack 										
				ALIGN



				; Assign the stack pointer
				ADR  	SP, stack 			
				


;----------------------------------------------------------------------------------------
; Main demo loop
;----------------------------------------------------------------------------------------
		
; Show some regions with number of iterations gradually increasing (growing detail)
demoStart		ADR		R4, growingDetail
				MOV	 	R5, #0
				ADR 	R6, detailDelayLen
				LDR 	R6, [R6]
				ADR 	R7, maxDetail
 	
nextDetailEx	LDR 	R8, [R4, R5, LSL #2]			
				LDRH 	R9, [R8]

incrDetail		MOV 	R0, R8
				MOV		R1, R9
				BL 		showDetail
				MOV 	R0, R6
				BL 		wait
				ADD 	R9, R9, #1
				LDR 	R10, [R7, R5, LSL #2]
				CMP		R9, R10
				BLT 	incrDetail

				ADD 	R5, R5, #1
				CMP 	R5, #noOfDetailEx
				BLT 	nextDetailEx


; Slideshow showing various points zoomed at
				ADR 	R4, slides 					; Load the look-up table with slides
				MOV 	R5, #0	 					; Initialise the slide counter
				ADR 	R6, slideDelayLen 			; Load the delay value between slides


nextSlide		LDR 	R0, [R4, R5, LSL #2] 		; Use the counter to index into the table
				BL 		showSlide 					; Show the slide
				LDR 	R0, [R6] 					; Wait for specified amount of time or until
				BL 		wait 						; the accelerator finishes serving the request
				ADD		R5, R5, #1 					
				CMP 	R5, #noOfSlides
				BLT 	nextSlide 					; Repeat if there are more slides to show

				B 		demoStart



;----------------------------------------------------------------------------------------
; Function:		showSlide
; Purpose:		Display the slide with address given in R0 on screen.
; Arguments:
; 	R0 - pointer to the slide to show
; Returns: 		-
;----------------------------------------------------------------------------------------
showSlide		PUSH 	{R4-R7}
				MOV 	R4, #drawingBase
				MOV 	R5, #0

nextParamSlide	LSL		R6, R5, #1
				LDRH 	R7, [R0, R6]
				STRH 	R7, [R4, R6]
				ADD 	R5, R5, #1
				CMP 	R5, #maxParamOffset
				BLT 	nextParamSlide

				MOV 	R5, #mandelbrot
				MOV 	R6, #commandOffset
				LSL 	R7, R6, #1
				STRB 	R5, [R4, R7]
				POP 	{R4-R7}
				MOV 	PC, LR



;----------------------------------------------------------------------------------------
; Function:		showDetail
; Purpose:		Similar to showSlide but the maximum number of iterations is specified as 
;				extra parameter
; Arguments:
; 	R0 - pointer to the mandelbrot set to show
; 	R1 - maximum number of iterations
; Returns: 		-
;----------------------------------------------------------------------------------------
showDetail		PUSH 	{R4-R7}
				MOV 	R4, #drawingBase
				STRH 	R1, [R4]
				MOV 	R5, #1

nextParamDetail	LSL 	R6, R5, #1
				LDRH 	R7, [R0, R6]
				STRH 	R7, [R4, R6]
				ADD 	R5, R5, #1
				CMP 	R5, #maxParamOffset
				BLT 	nextParamDetail

				MOV 	R5, #mandelbrot
				MOV 	R6, #commandOffset
				LSL 	R7, R6, #1
				STRB 	R5, [R4, R7]
				POP 	{R4-R7}
				MOV 	PC, LR



;----------------------------------------------------------------------------------------
; Function:		wait
; Purpose:		Wait for specified number of iterations or until the accelerator is not  
; 				busy depending on which time is longer
; Arguments:
; 	R0 - number of iterations to wait
; 	R1 - maximum number of iterations
; Returns: 		-
;----------------------------------------------------------------------------------------

wait			PUSH 	{R4-R7}
stillWait		SUBS 	R0, R0, #1
				BNE 	stillWait
				
				MOV 	R4, #drawingBase
				MOV 	R5, #statusOffset
				LSL 	R6, R5, #1

stillBusy		LDRH 	R7, [R4, R6]
				TST 	R7, #busyMask
				BNE 	stillBusy

				POP 	{R4-R7}
				MOV 	PC, LR






;----------------------------------------------------------------------------------------
; Important aliases
;----------------------------------------------------------------------------------------
drawingBase 	EQU		0x30000000		
maxParamOffset 	EQU 	7	
commandOffset 	EQU 	8
statusOffset 	EQU 	15			
mandelbrot 		EQU		0


busyMask		EQU 	0x0002




slideDelayLen 	DEFW 	1000000


detailDelayLen 	DEFW 	50000  			




;----------------------------------------------------------------------------------------
; Slides data
;----------------------------------------------------------------------------------------
noOfSlides 		EQU 	7 				; Number of slides to show

slides 			DEFW 	slide0 			; Slides look-up table
				DEFW 	slide1
				DEFW 	slide2
				DEFW 	slide3
				DEFW 	slide4 		
				DEFW 	slide5
				DEFW 	slide6


; Slide input parameters to the accelerator
slide0 			DEFH 	260 			; Number of iterations
				DEFH 	0xFEA0 			; Starting real value of 'z'
				DEFH 	0x0A7F 			; Starting imaginary value of 'z'
				DEFH 	0x0000 			; Step size in argand plane (32 bits)
				DEFH 	0x4000
				DEFH 	640 			; Screen width
				DEFH 	480 			; Screen height
				ALIGN

slide1 			DEFH 	120
				DEFH 	0xF370
				DEFH 	0x01C3
				DEFH 	0x0004
				DEFH 	0x0000
				DEFH 	640
				DEFH 	480
				ALIGN

slide2 			DEFH 	30
				DEFH 	0xF400
				DEFH 	0x0199
				DEFH 	0x0080
				DEFH 	0x0000
				DEFH 	640
				DEFH 	480
				ALIGN

slide3 			DEFH 	290
				DEFH 	0x0560
				DEFH 	0x0100
				DEFH 	0x0000
				DEFH 	0x0100
				DEFH 	640
				DEFH 	480
				ALIGN

slide4			DEFH 	80
				DEFH 	0x0500
				DEFH 	0x07B6
				DEFH 	0x0002
				DEFH 	0x0000
				DEFH 	640
				DEFH 	480
				ALIGN

slide5 			DEFH 	170
				DEFH 	0xF400
				DEFH 	0x0199
				DEFH 	0x0000
				DEFH 	0x2000
				DEFH 	640
				DEFH 	480
				ALIGN

slide6 			DEFH 	200
				DEFH 	0x0000
				DEFH 	0x1000
				DEFH 	0x0000
				DEFH 	0x0400
				DEFH 	640
				DEFH 	480
				ALIGN




;----------------------------------------------------------------------------------------
; Growing detail demo data
;----------------------------------------------------------------------------------------
noOfDetailEx 	EQU 	3 				; Number of growing detail examples

growingDetail 	DEFW 	detail0 		; Slides look-up table
				DEFW 	detail1
				DEFW 	detail2



maxDetail 	 	DEFW 	80
				DEFW 	90
				DEFW 	45


; Input parameters for showing a region in mandelbrot with increasing detail
detail0 		DEFH 	10
				DEFH 	0x0500
				DEFH 	0x07B6
				DEFH 	0x0002
				DEFH 	0x0000
				DEFH 	640
				DEFH 	480
				ALIGN

detail1 		DEFH 	30
				DEFH 	0xF400
				DEFH 	0x0199
				DEFH 	0x0000
				DEFH 	0x2000
				DEFH 	640
				DEFH 	480
				ALIGN

detail2 		DEFH 	1
				DEFH 	0xE000
				DEFH 	0xF000
				DEFH 	0x0147
				DEFH 	0x0000
				DEFH 	640
				DEFH 	480
				ALIGN