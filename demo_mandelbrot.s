;****************************************************************************************
; Author:       Krzysztof Koch
; Brief:        Demo program for the mandelbrot set hardware accelerator
; Date created: 29/11/2016
; Last edit:    01/12/2016
; 
; Note:
;****************************************************************************************


;----------------------------------------------------------------------------------------
; Allocate memory for stack and assign the stack pointer
;----------------------------------------------------------------------------------------
                DEFS    128, 0                  
stack                                       
                ALIGN

                ADR     SP, stack           
            


;----------------------------------------------------------------------------------------
; Main demo loop
;----------------------------------------------------------------------------------------

;****************************************************************************************
; Slideshow showing various points zoomed at
;****************************************************************************************
demoStart       ADR     R4, slides                  ; Load the look-up table with slides
                MOV     R5, #0                      ; Initialise the slide counter
                ADR     R6, slideDelayLen           ; Load the delay value between slides

nextSlide       LDR     R0, [R4, R5, LSL #2]        ; Use the counter to index into the table
                BL      showSlide                   ; Show the slide
                LDR     R0, [R6]                    ; Wait for specified amount of time or until
                BL      wait                        ; the accelerator finishes serving the request
                ADD     R5, R5, #1                  
                CMP     R5, #noOfSlides
                BLT     nextSlide                   ; Repeat if there are more slides to show


;****************************************************************************************
; Show some regions with number of iterations gradually increasing (growing detail)
;****************************************************************************************
                ADR     R4, growingDetail           ; Load the look-up table with examples
                MOV     R5, #0                      ; Initialise the example counter
                ADR     R6, detailDelayLen          ; Load the delay value between successive
                LDR     R6, [R6]                    ; maximum iteration values
                ADR     R7, maxDetail               ; Load the value for maximum number of iterations
    
nextDetailEx    LDR     R8, [R4, R5, LSL #2]        ; Use the counter to index into the table   
                LDRH    R9, [R8]                    ; Load the starting number of iterations

incrDetail      MOV     R0, R8                      ; Show the point with given number of iterations
                MOV     R1, R9
                BL      showDetail
                MOV     R0, R6                      ; Introduce a delay
                BL      wait
                ADD     R9, R9, #1                  ; Increment the number of iterations
                LDR     R10, [R7, R5, LSL #2]       ; Check if the maximum on is reached, terminate,
                CMP     R9, R10                     ; if so
                BLT     incrDetail

                ADD     R5, R5, #1                  ; Update the example counter
                CMP     R5, #noOfDetailEx           ; Check if the last example has been shown
                BLT     nextDetailEx


;****************************************************************************************
; Show some regions by gradually zooming-in
;****************************************************************************************
                ADR     R4, zoomIn                  ; Load the look-up table with examples
                MOV     R5, #0                      ; Initialise the example counter
                ADR     R6, zoomDelayLen            ; Load the delay value between successive
                LDR     R6, [R6]                    ; 'zooms'
                ADR     R7, maxZoom                 ; Load the minimum and maximum zoom values
                ADR     R8, minZoom

nextZoomEx      LDR     R9, [R4, R5, LSL #2]        ; Use the counter to index into the table with examples
                LDR     R10, [R8, R5, LSL #2]       ; Load the initial 'zoom' value

incrZoom        MOV     R0, R9                      ; Show the point with given step size in Argand plane
                MOV     R1, R10
                BL      showZoom
                MOV     R0, R6
                BL      wait                        ; Introduce a delay
                SUB     R10, R10, R10, ASR #3       ; Decrease the step size by 1/8 of the previous value
                LDR     R11, [R7, R5, LSL #2]       ; Check if the maximum zoom has been reached.
                CMP     R10, R11                    ; if not, carry on
                BGT     incrZoom

                ADD     R5, R5, #1                  ; Update the example counter
                CMP     R5, #noOfZoomEx             ; Check if the last example has been shown
                BLT     nextZoomEx

                B       demoStart                   ; Start from the beginning



;----------------------------------------------------------------------------------------
; Function:     showSlide
; Purpose:      Display the slide with address given in R0 on screen.
; Arguments:
;   R0 - pointer to the slide to show
; Returns:      -
;----------------------------------------------------------------------------------------
showSlide       PUSH    {R4-R7}
                MOV     R4, #drawingBase
                MOV     R5, #0

nextParamSlide  LSL     R6, R5, #1
                LDRH    R7, [R0, R6]
                STRH    R7, [R4, R6]
                ADD     R5, R5, #1
                CMP     R5, #maxParamOffset
                BLT     nextParamSlide

                MOV     R5, #mandelbrot
                MOV     R6, #commandOffset
                LSL     R7, R6, #1
                STRB    R5, [R4, R7]
                POP     {R4-R7}
                MOV     PC, LR



;----------------------------------------------------------------------------------------
; Function:     showDetail
; Purpose:      Similar to showSlide but the maximum number of iterations is specified as 
;               extra parameter
; Arguments:
;   R0 - pointer to the mandelbrot set to show
;   R1 - maximum number of iterations
; Returns:      -
;----------------------------------------------------------------------------------------
showDetail      PUSH    {R4-R7}
                MOV     R4, #drawingBase
                STRH    R1, [R4]
                MOV     R5, #1

nextParamDetail LSL     R6, R5, #1
                LDRH    R7, [R0, R6]
                STRH    R7, [R4, R6]
                ADD     R5, R5, #1
                CMP     R5, #maxParamOffset
                BLT     nextParamDetail

                MOV     R5, #mandelbrot
                MOV     R6, #commandOffset
                LSL     R7, R6, #1
                STRB    R5, [R4, R7]
                POP     {R4-R7}
                MOV     PC, LR



;----------------------------------------------------------------------------------------
; Function:     showZoom
; Purpose:      Similar to showSlide but the step size in Argand plane is specified in 
;               in an extra parameter
; Arguments:
;   R0 - pointer to the mandelbrot set to show
;   R1 - step size in Argand plane (the smaller, the bigger the zoom)
; Returns:      -
;----------------------------------------------------------------------------------------
showZoom        PUSH    {R4-R7}
                MOV     R4, #drawingBase
                MOV     R5, #stepSizeOffset
                STR     R1, [R4, R5, LSL #1]
                
                LDRH    R5, [R0]
                STRH    R5, [R4]
                LDRH    R5, [R0, #2]
                STRH    R5, [R4, #2]
                LDRH    R5, [R0, #4]
                STRH    R5, [R4, #4]
                LDRH    R5, [R0, #10]
                STRH    R5, [R4, #10]
                LDRH    R5, [R0, #12]
                STRH    R5, [R4, #12]

                MOV     R5, #mandelbrot
                MOV     R6, #commandOffset
                LSL     R7, R6, #1
                STRB    R5, [R4, R7]
                POP     {R4-R7}
                MOV     PC, LR



;----------------------------------------------------------------------------------------
; Function:     wait
; Purpose:      Wait for specified number of iterations or until the accelerator is not  
;               busy serving previous request, depending on which time is longer
; Arguments:
;   R0 - number of iterations to wait
; Returns:      -
;----------------------------------------------------------------------------------------
wait            PUSH    {R4-R7}
stillWait       SUBS    R0, R0, #1
                BNE     stillWait
                
                MOV     R4, #drawingBase
                MOV     R5, #statusOffset
                LSL     R6, R5, #1

stillBusy       LDRH    R7, [R4, R6]
                TST     R7, #busyMask
                BNE     stillBusy

                POP     {R4-R7}
                MOV     PC, LR



;----------------------------------------------------------------------------------------
; Important aliases. (Offsets are in halfwords - 16bit)
;----------------------------------------------------------------------------------------
drawingBase     EQU     0x30000000          ; Base address of the interface to the accelerato
maxParamOffset  EQU     7                   ; Maximum address offset for input parameters
commandOffset   EQU     8                   ; Offset for specifying the command - mandelbrot
statusOffset    EQU     15                  ; Status register offset
stepSizeOffset  EQU     3                   ; Step size paraemeter offset
mandelbrot      EQU     0                   ; Mandelbrot command code
busyMask        EQU     0x0002              ; Mask off all the bits except the busy one in status reg
slideDelayLen   DEFW    2000000             ; Delay between slides (in number of iterations)
detailDelayLen  DEFW    50000               ; Minimum delay before level of detail is incremented
zoomDelayLen    DEFW    350000              ; Minimum delay before the zoom is incremented



;----------------------------------------------------------------------------------------
; Slides data
;----------------------------------------------------------------------------------------
noOfSlides      EQU     10              ; Number of slides to show

slides          DEFW    slide0          ; Slides look-up table
                DEFW    slide1
                DEFW    slide2
                DEFW    slide3
                DEFW    slide4      
                DEFW    slide5
                DEFW    slide6
                DEFW    slide7
                DEFW    slide8
                DEFW    slide9

; Slide input parameters to the accelerator
slide0          DEFH    50              ; Number of iterations
                DEFH    0xE000          ; Starting real value of 'z'
                DEFH    0xF000          ; Starting imaginary value of 'z'
                DEFH    0x0100          ; Step size in argand plane (32 bits)
                DEFH    0x0000
                DEFH    640             ; Screen width
                DEFH    480             ; Screen height
                ALIGN

slide1          DEFH    120
                DEFH    0xF370
                DEFH    0x01C3
                DEFH    0x0004
                DEFH    0x0000
                DEFH    640
                DEFH    480
                ALIGN

slide2          DEFH    30
                DEFH    0xF400
                DEFH    0x0199
                DEFH    0x0080
                DEFH    0x0000
                DEFH    640
                DEFH    480
                ALIGN

slide3          DEFH    290
                DEFH    0x0560
                DEFH    0x0100
                DEFH    0x0000
                DEFH    0x0100
                DEFH    640
                DEFH    480
                ALIGN

slide4          DEFH    80
                DEFH    0x0500
                DEFH    0x07B6
                DEFH    0x0002
                DEFH    0x0000
                DEFH    640
                DEFH    480
                ALIGN

slide5          DEFH    170
                DEFH    0xF400
                DEFH    0x0199
                DEFH    0x0000
                DEFH    0x2000
                DEFH    640
                DEFH    480
                ALIGN

slide6          DEFH    200
                DEFH    0x0000
                DEFH    0x1000
                DEFH    0x0000
                DEFH    0x0400
                DEFH    640
                DEFH    480
                ALIGN

slide7          DEFH    260             
                DEFH    0xFEA0          
                DEFH    0x0A7F          
                DEFH    0x0000          
                DEFH    0x4000
                DEFH    640             
                DEFH    480             
                ALIGN

slide8          DEFH    241
                DEFH    0x0531
                DEFH    0x00C6
                DEFH    0x0000
                DEFH    0x00B0
                DEFH    640
                DEFH    480
                ALIGN

slide9          DEFH    100
                DEFH    0xF95C
                DEFH    0xF512
                DEFH    0x0008
                DEFH    0x0000
                DEFH    640
                DEFH    480
                ALIGN



;----------------------------------------------------------------------------------------
; Growing detail demo data
;----------------------------------------------------------------------------------------
noOfDetailEx    EQU     3               ; Number of growing detail examples

growingDetail   DEFW    detail0         ; Growing detail examples look-up table
                DEFW    detail1
                DEFW    detail2

maxDetail       DEFW    70              ; maximum number of iterations (maximum level of detail)
                DEFW    90
                DEFW    45

; Input parameters for showing a region in mandelbrot with increasing detail
detail0         DEFH    10              ; starting number of iterations
                DEFH    0x0500          ; Starting real value of 'z'
                DEFH    0x07B6          ; Starting imaginary value of 'z'
                DEFH    0x0002          ; Step size in argand plane (32 bits)
                DEFH    0x0000
                DEFH    640             ; Screen width
                DEFH    480             ; Screen height
                ALIGN

detail1         DEFH    30
                DEFH    0xF400
                DEFH    0x0199
                DEFH    0x0000
                DEFH    0x2000
                DEFH    640
                DEFH    480
                ALIGN

detail2         DEFH    1
                DEFH    0xE000
                DEFH    0xF000
                DEFH    0x0147
                DEFH    0x0000
                DEFH    640
                DEFH    480
                ALIGN



;----------------------------------------------------------------------------------------
; Increasing zoom demo data
;----------------------------------------------------------------------------------------
noOfZoomEx      EQU     2               ; Number of increasing zoom examples


zoomIn          DEFW    zoom0           ; Zoom examples look-up table
                DEFW    zoom1

maxZoom         DEFW    0x00010000      ; Maximum zooms (minimum step size)
                DEFW    0x00010000

minZoom         DEFW    0x00100000      ; Minimum zooms (maximum step size)
                DEFW    0x01000000  

zoom0           DEFH    210             ; Number of iterations  
                DEFH    0x0560          ; Starting real value of 'z'
                DEFH    0x0100          ; Starting imaginary value of 'z'
                DEFH    0x0000          ; Not used
                DEFH    0x0000
                DEFH    640             ; Screen width
                DEFH    480             ; Screen height
                ALIGN

zoom1           DEFH    170                 
                DEFH    0xF38F
                DEFH    0x0199
                DEFH    0x0000
                DEFH    0x0000
                DEFH    640
                DEFH    480
                ALIGN
