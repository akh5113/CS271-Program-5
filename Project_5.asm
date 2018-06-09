TITLE Project 5     (Project 5.asm)

; Author: Anne Harris	harranne@oregonstate.edu
; Course / Project ID: CS271-400/Project 5                 Date: 3/4/2018
; Description: This program implements passing parameters on the stack, either by value or address.
;	The program asks the user for a number in a specified range, validates it's in range, then fills
;	an array with that many randomly generated numbers. It then sorts the numbers, finds the mean and
;	displays it, then displays the sorted list

INCLUDE Irvine32.inc

;Constant Definitions
MIN = 10		;minimum number of random numbers to display/sort
MAX = 200		;maximum number of random numbers to display/sort
LO = 100		;low end of range for random integers 
HI = 999		;high end of range for random integers 

.data
;string variables
prgmTitle	BYTE	"Sorting Random Integers		Programmed by Anne Harris",0
intro		BYTE	"This program generates random numbers in the range 100 to 999.",0dh, 0ah
			BYTE	"It will display the original list, then sort the list, calculate the",0dh,0ah
			BYTE	"median value, and finally display the list sorted in descending order",0
prompt		BYTE	"How many numbers should be generated? Enter a number between 10 and 200: ",0
the			BYTE	"The ",0
unsorted	BYTE	"unsorted random numbers:",0
sorted		BYTE	"sorted list:",0
medianTxt	BYTE	"The median is ",0
invalid		BYTE	"Invalid input, number must be in range [10...200]",0
tabLine		BYTE	"	",0

request		DWORD	?			;user entered number for how many random ints to display
medianNum	DWORD	0			;median number of values in array
medianVal	DWORD	0			;value of the median number
lineCount	DWORD	0			;number of ints printed per line
array		DWORD	MAX DUP(?)	;array for storing randomly generated numbers, then to sort
range		DWORD	?			;range for RandomRange procedure



.code
main PROC

	;introduce program
	call	introduction

	;prompt user and get data {parameters: request (reference)}
	push	OFFSET request		;[esp + 4]	address of request
	call	getData				;[esp]		return address

	;fill the array with random numbers {parameters: request (value), array (reference)}
	call	Randomize			;calling in main proc per lecture 20 advice
	push	OFFSET array		;[esp + 8]	address of first value of array
	push	request				;[esp + 4]	requet value
	call	fillArray			;[esp]		return address

	;display unsorted array	{parameters: array (reference), request (value), linCount (value), title(reference)}
	push	OFFSET array		;[esp + 16]	address of first value of array
	push	request				;[esp + 12]	request value
	push	lineCount			;[esp + 8]	line count value
	push	OFFSET unsorted		;[esp + 4]	address of array title
	call	displayList			;[esp]		return address

	;sort the array	{parameters: array (reference), request (value)}
	push	OFFSET array		;[esp + 8]	address of array
	push	request				;[esp + 4]	value request
	call	sortList			;[esp]		return address

	;call display median {parameters: array (reference), request (value), medainVal (value), medianNum (value)}
	push	OFFSET array		;[esp + 16]	address of array
	push	request				;[esp + 12]	request value
	push	medianVal			;[esp + 8]	median value passed as value
	push	medianNum			;[esp + 4]	median number pass as value
	call	displayMedian		;[esp]		return address

	;display sorted list {parameters: array (reference), request (value), lineCount (value), title(reference)}
	push	OFFSET array		;[esp + 16]	address of first value of array
	push	request				;[esp + 12]	request value 
	push	lineCount			;[esp + 8]	line count value
	push	OFFSET sorted		;[esp + 4]	address of array title
	call	displayList			;[esp]		return address

	exit	; exit to operating system
main ENDP

;-------------------------------------------------
;Displays the program title and instructions
;Receives: global variable prgmTitle, intor
;Returns: n/a
;Preconditions: n/a
;Registers Changed: edx 
;-------------------------------------------------
introduction PROC
	;display program title
	mov		edx, OFFSET prgmTitle
	call	WriteString
	call	Crlf
	call	Crlf

	;display instrctions
	mov		edx, OFFSET intro
	call	WriteString
	call	Crlf
	call	Crlf

	ret
introduction ENDP

;-------------------------------------------------
;Prompts user to enter value between 10 and 200, 
;	validates the number
;Receives: address of request on system stack
;Returns: user entred number for request nums
;Preconditions: none
;Registers Changed: eax, ebx, edx
;-------------------------------------------------
getData PROC
	;[ebp + 8]	reference of request
	;[ebp + 4]	return address
	;[ebp]		top of stack

	;set up stack frame
	push	ebp					;save epb on stack
	mov		ebp, esp			;set ebp to esp
	pushad						;save all registers

	;prompt the user
beginning:
	mov		ebx, [ebp + 8]		;move address of request value into ebx
	mov		edx, OFFSET prompt
	call	WriteString
	call	ReadInt

	;validate
	cmp		eax, MAX			;compare to upper limit
	jg		invalidNum
	cmp		eax, MIN			;compare to lower limit
	jl		invalidNum

	;store valid number and finish
	mov		[ebx], eax			;move user input at address in ebx
	jmp		done

invalidNum:
	mov		edx, OFFSET invalid
	call	WriteString
	call	Crlf
	jmp		beginning

done:
	pop		ebx
	popad						;restore all registers

	ret		8
getData ENDP


;--------------------------------------------------------
;Fills the array with the user entered number of
;	randomly generated numbers
;Receives: address of array and the request number 
;	by value
;Returns: array filled with random numbers
;Preconditions: request must be populated with a 
;	postive int
;Registers Changed: eax, ecx,  
;Implementation Notes: Adapted from course's lecture 20
;	slide 3, and RandomRange example
;-------------------------------------------------------
fillArray PROC
	;[ebp + 12]		address of array
	;[ebp + 8]		value of request
	;[ebp + 4]		return address
	;[ebp]

	;set up stack frame
	push	ebp
	mov		ebp, esp
	pushad

	;set up array
	mov		edi, [ebp + 12]		;address of array
	mov		ecx, [ebp + 8]		;value of count in ecx
	
arryLoop:
	;generate random number
	mov		eax, HI				;999
	sub		eax, LO				;999 - 100 = 899
	inc		eax					;899 + 1 = 900
	call	RandomRange
	add		eax, LO
	;put random number in array
	mov		[edi], eax
	add		edi, 4
	loop	arryLoop

	pop		ebp
	popad

	ret		12
fillArray ENDP

;-------------------------------------------------
;Sorts the array of random numbers using a bubble
;	sort
;Receives: address of array and the request number 
;	by value
;Returns: array with values in order
;Preconditions: array is filled, request is populated
;Registers Changed: eax, ecx
;Implementation Notes: implemented bubble sort from
;	page 375 of Kip Irvine book Assembly Language for  
;	x86 Processors, 7th edition
;-------------------------------------------------
sortList	PROC
	;[ebp + 12]		address of array
	;[ebp + 8]		value of request
	;[ebp + 4]		return address
	;[ebp]

	;set up stack frame
	push	ebp
	mov		ebp, esp
	pushad

	mov		ecx, [ebp + 8]		;move size of array to counter
	dec		ecx					;decrement count
L1:								;outer loop
	push	ecx					;save outter count loop
	mov		esi, [ebp + 12]		;point to the first value of array
L2:								;inner loop
	mov		eax, [esi]			;get the array value
	cmp		[esi + 4], eax		;comare the next value to first value
	jl		L3					;if [esi + 4] is less, no exchange
	xchg	eax, [esi + 4]		;exchange the two numbers
	mov		[esi], eax
L3:
	add		esi, 4				;increment pointers forward
	loop	L2					;inner loop

	pop		ecx					;retrive outer loop count
	loop	L1					;else repeat outer loop

	pop		ebp
	popad
	ret		12
sortList	ENDP



;-------------------------------------------------
;Calculates the meadian number of the array and
;	displays it
;Receives: address of sorted array, request value, 
;	median value (starts at 0) and median number (starts
;	at 0)
;Returns: median value and median number
;Preconditions: Array is sorted
;Registers Changed: eax, ebx, edx
;-------------------------------------------------
displayMedian	PROC
	;[ebp + 20]		address of array 
	;[ebp + 16]		requst value
	;[ebp + 12]		medianVal value
	;[ebp + 8]		medianNum value
	;[ebp + 4]		return address
	;[ebp]

	push	ebp
	mov		ebp, esp
	pushad

	mov		esi, [ebp + 20]		;move address of array into esi

	;find the middle position of the array
	mov		eax, [ebp + 16]		;move size of array into eax
	cdq
	mov		ebx, 2				;divide by 2
	div		ebx
	mov		[ebp + 8], eax		;move the middle position in to memory
	
	;address of nth element is list+n*sizeof DWORD
	;[ebp+8] * 4
	mov		ebx, [ebp +8]
	mov		eax, [esi + ebx * 4]
	mov		[ebp + 12], eax

	;display median
	mov		edx, OFFSET medianTxt
	call	WriteString
	mov		eax, [ebp + 12]
	call	WriteDec
	call	Crlf
	call	Crlf

	pop		ebp
	popad
	ret		16
displayMedian	ENDP

;-------------------------------------------------
;Displays the array
;Receives: address of array, request value, line count
;	value, address of the array title 
;Returns: none	
;Preconditions: Array is popluated with values
;Registers Changed: eax, ebx, ecx, edx
;-------------------------------------------------
displayList	PROC
	;[ebp + 20]	address of first value of array
	;[ebp + 16]	request value 
	;[ebp + 12]	lineCount value
	;[ebp + 8]	address of array title
	;[ebp + 4]	return address
	;[ebp]

	push	ebp
	mov		ebp, esp
	pushad

	;display first line with what type of array it is (sorted or unsorted)
	mov		edx, OFFSET the
	call	WriteString
	mov		edx, [ebp + 8]
	call	WriteString
	call	Crlf

	mov		ebx, [ebp + 12]			;lineCount to keep track of how many values have been printed
	mov		esi, [ebp + 20]			;array address
	mov		ecx, [ebp + 16]			;nums in the array

printLoop:
	mov		eax, [esi]
	call	WriteDec
	inc		ebx
	cmp		ebx, 10
	je		lineEnter
lineTab:							;same line, tab
	mov		edx, OFFSET tabLine
	call	WriteString
	jmp		advance
lineEnter:							;new line
	mov		ebx, 0
	call	Crlf
advance:
	add		esi, 4
	loop	printLoop

	call	Crlf

	pop		ebp
	popad
	ret		20
displayList ENDP



END main
