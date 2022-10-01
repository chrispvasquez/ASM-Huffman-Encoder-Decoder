; Chris Vasquez
; Copyright © 2020 by Chris Vasquez
; Semester Project
; EE3752
; July 20, 2020

;////////////////////////////////////////////////////////////////////////////////////////////

 ;*******************************Program's Functionality************************************
 ;	This program will reverse the given ARRAY0 and ARRAY1 and store them in literals newARRAY0 and newARRAY1, respectively.
 ;  Additionally, the program will construct a frequency table, Huffman tree, and Huffman code table stored in memory
 ;	within the literals FTable, root (stores address of root node of Huff tree), and CTable, respectively, for the given
 ;  string within newARRAY1. Lastly, the program will encode the string and store it in memory within the literal "encoded."
 
 ;**NOTE: The encoded string will appear as a hexidecimal in memory. The bit value of the said hexadecimal will correspond with
 ;		  the Huffman code table. Also, the bit values are divided into sets of 3, appended with 0's. 
 ;        For example, 'G' = 000, not just 0. The encoded bitwise value should be:
 
 ;		  000111111010001011100101110	(appended with 0's at the MSB to fill any remaining bits)
 
 ;		  Therefore, when looking at the bits of the hexadecimal to check if the outcome is correct, it is best
 ;		  to read the bit sets of 3 from right to left. (In this case starting with K's code of 110)

 ;  *******Frequency Table for "Good Luck" *************		********Huffman Code Table for "Good Luck"***********				********************Huffman Tree for "Good Luck"************************									
		
 ;				G = 1															G = 000																                *
 ;				o = 2													  [space] = 001 															               / \
 ;				d = 1															d = 010																              /   \
 ;		  [space] = 1															L = 011																             /     \
 ;				L = 1															u = 100																            /       \
 ;				u = 1															c = 101																           /         \
 ;				c = 1															k = 110																        0 /           \ 1
 ;				k = 1															o = 111																         /             \
 ;																																					        /               \
 ;																																				           /                 \
 ;																																					      /                   \
 ;																																				         /	                   \
 ;																																				        *	                    *
 ;																																					   / \                     / \
 ;																																				      /   \                   /   \
 ;																																				   0 /     \ 1             0 /     \ 1
 ;		  																																		    /       \               /       \
 ;																																		           /         \             /         \
 ;																																				  *           *           *           *
 ;																																			   0 / \ 1     0 / \ 1     0 / \ 1     0 / \ 1
 ;																																			    G	d  [space]  L	    u   c       k   o
 
 
 
 ;																																		***NOTE: "*" was used in place of the internal nodes due to their values being arbitrary


; **************Useful Addresses******************  (SEE READ/WRITE LITERAL POOL BELOW FOR DESCRIPTIONS & ORGANIZATION OF TABLES)

;	newARRAY0's address = 0x10000000
												
;	newARRAY1's address = 0x10000014
												
;	FTables's address = 0x10000028
	
;	CTables's address = 0x10000050
	
;	**root's address = 0x1000017C	 	**NOTE: This literal's address (0x1000017C) is NOT the root address of the Huffman Tree.
									 ; 		 This address (0x1000017C) stores the Huff Tree's actual root address
									 
;	encoded's address = 0x10000190	


;///////////////////////////////////////////////////////////////////////////////////////////


		AREA datasection, DATA, READWRITE
			
 ;*******READ/WRITE Literal Pool**********
												;**NOTE: Each consecutive literal is located
												; 		 +0x14 the previous literal's address
 
newARRAY0 DCD 0x00, 0x00, 0x00, 0x00, 0x00		; stores reversed ARRAY0.
newARRAY1 DCD 0x00, 0x00, 0x00, 0x00, 0x00		; stores reversed ARRAY1
	
FTable DCD 0x00, 0x00, 0x00, 0x00, 0x00			; Organization is by byte: [letter, frequency, letter, frequency...] (used only for reading) (null/0 terminated)
	
tempTable DCD 0x00, 0x00, 0x00, 0x00, 0x00		; Copy of FTable that is used for both Reading and Writing
	
CTable DCD 0x00, 0x00, 0x00, 0x00, 0x00			;Organization is by half words: [letter, code, letter, code...] 
CTable2 DCD 0x00, 0x00, 0x00, 0x00, 0x00		; Extension of CTable
	
heap0  DCD 0x00, 0x00, 0x00, 0x00, 0x00			; organization is by word: [frequency, left child, right child, frequency, ...] 
heap1  DCD 0x00, 0x00, 0x00, 0x00, 0x00			; heap0 - heap12 forms the Huffman tree.
heap2  DCD 0x00, 0x00, 0x00, 0x00, 0x00			; Min heaps are contructed within each heapX literal.
heap3  DCD 0x00, 0x00, 0x00, 0x00, 0x00			; As the tree is built, heaps will point to other heaps by storing their addresses
heap4  DCD 0x00, 0x00, 0x00, 0x00, 0x00			; based on the minimum pair of frequencies at each iteration.
heap5  DCD 0x00, 0x00, 0x00, 0x00, 0x00			; The heaps that store leaf nodes (i.e. characters of the string) 
heap6  DCD 0x00, 0x00, 0x00, 0x00, 0x00			; will point (through addresses) to the tempTable which will have the ASCII values
heap7  DCD 0x00, 0x00, 0x00, 0x00, 0x00			; still stored within it.
heap8  DCD 0x00, 0x00, 0x00, 0x00, 0x00
heap9  DCD 0x00, 0x00, 0x00, 0x00, 0x00
heap10 DCD 0x00, 0x00, 0x00, 0x00, 0x00
heap11 DCD 0x00, 0x00, 0x00, 0x00, 0x00
heap12 DCD 0x00, 0x00, 0x00, 0x00, 0x00	
root	DCD	0x00, 0x00, 0x00, 0x00, 0x00		; stores root address of the huffman tree
	
encoded	DCD 0x00, 0x00, 0x00, 0x00, 0x00		; stores encoded string


		AREA EM77X, CODE, READONLY

 ;***********Renamed Registers************
 
charCnt	RN 0 ;Rename R0 to charCnt (total # of chracters in string)
FreqTable RN 1; R1 will hold the address of the frequency table
temp 	RN 2 ; General temporary register
current RN 4 ;Rename R4 to current (acts as general register for storing currently examined data)
curChar RN 5 ;Rename R5 to cur Char (Current char we are examining from string)
counter RN 7 ;Rename R7 to counter
			
		ENTRY
		EXPORT __main
__main
			LDR  R0, =ARRAY0	; R0 will store the address of the current array we are reversing
			MOVS R4, #0 		; R4 will serve as our counter for the iterations loop

			
iterations 	CMP R4, #2			; Loop to run thorugh all provided Arrays (change 2nd compare value to number of arrays needed to be reversed)
			BGE huffPuff		
		
			LDR R3, =newARRAY0  ; R3 will store the memory address of the array we will reverse
			MOVS R5, #0x14		; R5 will hold the constant 0x14, as this is the spacing between each newArry in memory
			MULS R5, R4, R5 	; Calculate which array we will be reversing base on the iteration
			ADDS R3, R3, R5		; Set the proper memory address we will be storing to
			MOVS R5, #0			; Clear R5
		
			LDRB R1, [R0]		; R1 will store the number of indicies, with 1 being the staring index
			ADDS R0, R0, #1		; Add 1 to the array address for it to begin at the starting index, not the num of indicies
		
			BL  REVERSE			; Branch off to REVERSE subroutine

								; R0 now holds the address of the next array to reverse

			ADDS R4, R4, #1		; Increment the iterations loop counter
			B iterations
	
 ;*****************************END OF REGULAR SEMESTER PROJECT*******************************************			
			
 ; ****************************Beginning of Huffman Encoder**********************************************
huffPuff

		MOVS R0, #0			; Clean Registers
		MOVS R1, #0
		MOVS R2, #0
		MOVS R3, #0
		MOVS R4, #0
		MOVS R5, #0
		MOVS R6, #0
		MOVS R7, #0

		BL BUILDFREQTABLE		; Frequency table is now constructed, located at the address of FTable (NULL terminated)
			
		BL COPYFREQTABLE		; Create a copy of the Frequency Table into tempTable

		BL BUILDHUFFTREE		; We have now built our Huffman tree of heaps using addresses of huff literals and the temp table
 
		BL BUILDCODETABLE		; Encoding table is now constructed
 
		BL ENCODESTRING			; Pass our string and encode it, storing it in memory in the literal "encoded"	
			
STOP	B STOP

 ;*******************************END PROGRAM*******************************************************************

 ;////////////////////////////////////////////////////////////////////////////////////////////////////////////

 ;*********REVERSE Subroutine**********

REVERSE
			MOVS R7, #1			; R7 will be our counter for the pushingLoop "for loop"
			
pushingLoop	CMP R7, R1			; Check if counter > number of indicies
			BGT endPushingLoop
			LDRB R5, [R0]
			PUSH {R5}			; Push index onto the stack
			ADDS R0, R0, #1		; Move to next index
			ADDS R7, R7, #1 	; Increment loop counter
			B pushingLoop
endPushingLoop

			MOVS R7, #1		; Reset loop counter register for new loop

poppingLoop	CMP R7, R1			; Check if counter > number of indicies
			BGT endPoppingLoop
			POP {R2}			; Pop top of stack into R2
			STRB R2, [R3]		; Store reversed array index by index in new memory location
			ADDS R3, R3, #1		; Move to nex index in new memory location
			ADDS R7, R7, #1 	; Increment loop counter
			B poppingLoop
endPoppingLoop

			MOV PC, LR			; Move out of subroutine back to main routine

 ;////////////////////////////////////////////////////////////////////////////////////////////////////////////
 

 ;**************Frequency Table Subroutine*******************
 
BUILDFREQTABLE
									; Set addresses of literals the registers
			LDR R0, =FTable			
			LDR R1, =CTable
			LDR R2, =tempTable
			LDR R3, =heap0
			LDR R4, =heap1
			LDR R5, =heap2
			
									; will follow form: [letter, frequency, letter, frequency...]

			LDR FreqTable, =FTable  ;Start letter & frequency table at location 0x11000000
			MOVS R2, #0x00
			STR R2, [FreqTable]

			LDR charCnt, =ARRAY1
			LDRB charCnt, [charCnt]

			MOVS counter, #0  ; Get number of letters in the string to set counter
		  
freqCount	CMP counter, charCnt
			BGE endFreqCount
								; Get frequency of each chracter
			LDR curChar, =newARRAY1
			LDRB curChar, [curChar, counter]
			LDRB current, [FreqTable]	; current will start at the beginning of the table
		    MOVS temp, #0
			
			B Test1
			
	   ; Check letter frequency table to see if current char already in table
checkChar
			
			ADDS temp, temp, #2
			LDRB current, [FreqTable, temp]
			
Test1	  	CMP current, #0
			BEQ addToTable
			CMP current, curChar
			BEQ endCurLetCnt
			BNE checkChar
			
addToTable
			STRB curChar, [FreqTable, temp]
			ADDS temp, temp, #1	
			MOVS current, #1
			STRB current, [FreqTable, temp] ;Add one to frequency of added letter as placeholder
			ADDS temp, temp, #1
			MOVS current, #0
			STRB current, [FreqTable, temp] ; Move NULL (0x00) to new place, extending the table
			SUBS temp, temp, #2
			ADDS temp, FreqTable, temp		; Store the location in the table of the newly added char in temp
endCheckChar
		   
	;Count frequency of the chracter in the string if not in the table

			MOVS R6, counter		; Set R6 to be a temp counter for nested loop curLetCnt
			MOVS R3, #0				; temp = address of chracter in table, temp + 1 = address of frequency
						
curLetCnt 	CMP R6, charCnt
			BGE endCurLetCnt
		  
			LDR current, =newARRAY1	;store the current chracter in string we are on in comparing
			LDRB current, [current, R6]
			CMP curChar, current
			
			BNE notSameChar
			
			ADDS R3, R3, #1			; R3 will temporarily hold the frequency of the curChar in the string 
			STRB R3, [temp, #1]
			
notSameChar
		   
			ADDS R6, R6, #1
			B	curLetCnt
			
endCurLetCnt

			ADDS counter, counter, #1
			B freqCount
endFreqCount


			MOVS R2, #0			; Clean Registers
			MOVS R3, #0
			MOVS R4, #0
			MOVS R5, #0
			MOVS R6, #0
			MOVS R7, #0


			MOV PC, LR			; Move out of subroutine back to main routine
 ;////////////////////////////////////////////////////////////////////////////////////////////////////////////

 ;**************Copy Frequency Table Subroutine*******************
 
COPYFREQTABLE
 
			LDRB current, [FreqTable]
			B Test2			
copyTable		
			LDRB current, [FreqTable, counter]
			LDR temp, =tempTable
			STRB current, [temp, counter]
			ADDS counter, counter, #1

Test2		CMP current, #0
			BNE copyTable
			
			
endCopyTable


			MOV PC, LR			; Move out of subroutine back to main routine
 ;////////////////////////////////////////////////////////////////////////////////////////////////////////////
 
  ;**************"Build Heaps to Form Huffman Tree" Subroutine*******************
 
BUILDHUFFTREE
 
			LSRS counter, #1
			MOVS charCnt, counter	; Reset chracter counter to the number of characters in FTable, not the string we are reading
 
									;	Note: # of indicies in min heap array = number of chars + (num of chars - 1) 
			MOVS temp, #1
			MOVS current, #0
			MOVS counter, #1
			MOVS R1, #0
			LDR R6, =0xFFFFFFFF 
			
									;Go through the copied table and find pairs of the least frequency and store each in one of the heap literals
			
									;R3 and R1 will be our two registers for storing the adresses pf the smallest pairs of frequencies

			
smallPairs CMP counter, charCnt		; Execute the outer loop n - 1 times (where n = num of chars in string)
		   BGE endSmallPairs
									; R5 will be our inner loop counter
		   MOVS R1, #0				; nestSmall = finding R3
 		   MOVS R5, #0				; nestSmall2 = finding R1
		   MOVS R3, #0
		   LDR R6, =0xFFFFFFFF
		   MOVS temp, #1

		   
nestSmall  CMP R5, charCnt					;Run through the frequency table
		   BGE endNestSmall
		   
		   LDR current, =tempTable
		   LDRB current, [current, temp]
		   ADDS temp, temp, #2
		   ADDS R5, R5, #1
		   
		   
		   CMP current, #0
		   BEQ nestSmall
		   
		   CMP current, R6
		   BHS nestSmall
		   
		   MOVS R6, current
		   LDR R3, =tempTable 
		   ADDS R3, R3, temp
		   SUBS R3, R3, #2

		   B nestSmall
endNestSmall

		   MOVS R5, #0					;Reset registers and Check heaps for R3
		   MOVS temp, #0

runHeaps   CMP R5, #13
		   BGE endRunHeaps
		   
		   LDR current, =heap0
		   LDRB current, [current, temp]
		   ADDS temp, temp, #0x14
		   ADDS R5, R5, #1
		   
		   CMP current, #0
		   BEQ runHeaps
		   
		   CMP current, R6
		   BHS runHeaps
		   
		   MOVS R6, current
		   LDR R3, =heap0
		   ADDS R3, R3, temp
		   SUBS R3, R3, #0x14

		   B runHeaps					;***********R3 is now set with the smallest frequency address
endRunHeaps




			LDR R6, =0xFFFFFFFF
		    MOVS R5, #0
			MOVS temp, #1

nestSmall2									; R5 will be our inner loop counter
		   CMP R5, charCnt					;Run through the frequency table
		   BGE endNestSmall2
		   
		   LDR current, =tempTable
		   ADDS current, current, temp
		   CMP R3, current
		   
		   BEQ skip1
		   
		   LDRB current, [current]
		   ADDS temp, temp, #2
		   ADDS R5, R5, #1
		   
		   
		   CMP current, #0
		   BEQ nestSmall2
		   
		   CMP current, R6
		   BHS nestSmall2
		   
		   MOVS R6, current
		   LDR R1, =tempTable
		   ADDS R1, R1, temp
		   SUBS R1, R1, #2

skip1
		   ADDS temp, temp, #2
		   ADDS R5, R5, #1
		   B nestSmall2
			
endNestSmall2


		   MOVS R5, #0					;Reset registers and Check heaps for R1
		   MOVS temp, #0


runHeaps2  CMP R5, #13
		   BGE endRunHeaps2
		   
		   LDR current, =heap0
		   ADDS current, current, temp
		   CMP R3, current
		   
		   BEQ skip2
		   
		   LDRB current, [current]
		   ADDS temp, temp, #0x14
		   ADDS R5, R5, #1
		   
		   CMP current, #0
		   BEQ runHeaps2
		   
		   CMP current, R6
		   BHS runHeaps2
		   
		   MOVS R6, current
		   LDR R1, =heap0
		   ADDS R1, R1, temp
		   SUBS R1, R1, #0x14

skip2
		   ADDS temp, temp, #0x14
		   ADDS R5, R5, #1
		   B runHeaps2

		   B runHeaps2
endRunHeaps2						;***********R1 is now set with the smallest frequency address
									
									;Clean up registers
			MOVS temp, #0
			MOVS curChar, #0
			
travHeaps	CMP R5, #13						;Find an empty heap to store our small pair
			BGE endTravHeaps					
	
			LDR current, =heap0
			ADDS current, current, temp
			LDR current, [current]
			CMP current, #0
			BEQ endTravHeaps

			ADDS temp, temp, #0x14
			ADDS R5, R5, #1
			B travHeaps
endTravHeaps

			MOVS R5, #0

			LDR current, =heap0
			ADDS current, current, temp		; current now has the address of the first empty heap literal
			
											;Once found, store the data depending on if it is an internal node
											;or only a leaf node
						
			LDRB temp, [R1]
			LDRB curChar, [R3]
			ADDS temp, temp, curChar		; Temp now has the net frequency of smallest chars
			MOVS curChar, #0
			STR temp, [current]			;Net freq now stored in heap at the root
		    MOVS R5, #8

			LDR temp, =heap0
			
			CMP R3, temp				;Determine if the address points to internal node or chracter and modify
			BHS noSub1
			
			MOVS temp, #0				; Clear the already examined frequency from tempTable
			STRB temp, [R3]
			SUBS R3, R3, #1
			B done1
			
noSub1
			LDR temp, [R3]
			LSLS temp, R5
			STR temp, [R3]

done1
			LDR temp, =heap0

			CMP R1, temp
			BHS noSub2

			MOVS temp, #0				; Clear the already examined frequency from tempTable
			STRB temp, [R1]
			SUBS R1, R1, #1
			B done2

noSub2

			LDR temp, [R1]
			LSLS temp, R5
			STR temp, [R1]

done2

			STR R3, [current, #4] 		;Store the adresses in respective heap literal
			STR R1, [current, #8]

		
			ADDS counter, counter, #1
			B smallPairs
endSmallPairs
 
			MOV PC, LR					; Move out of subroutine back to main routine
 ;////////////////////////////////////////////////////////////////////////////////////////////////////////////

 ; **********************Encoding Table Subroutine*********************************
 
BUILDCODETABLE
 
									;NOTE: "current" has the address of the root node currently
									
			MOVS R6, #0				;Place root node into array
			MOVS counter, #0
			MOVS R5, #0						
			
			LDR temp, =root
			STR current, [temp]
			MOVS temp, #0
									; R1 holds the stack address, will be travered in words
									;current will hold the node we are currently on in the heap
									;current = addess of current node		current + #4 = address of the left child
									; current + #8 = address of the right child

			B Test3
while3		

			B Test4
while4
			PUSH {current}					;add letter code is associated with to the stack
			ADDS counter, counter, #1		;counter tells us how many items on stack
			PUSH {temp}						; add code to the stack	
			ADDS counter, counter, #1		; increment counter
			ADDS current, current, #4		; go to left child
			LDR current, [current]			;move to left child
			LSLS temp,  #1
			ADDS temp, #0x00

Test4
			LDR R3, =heap0
			CMP current, R3
			BHS while4
							
							
			LDR R3, =CTable			;R5 will count where we are in the CTable
			LDRB R6, [current]		; Extract the acctual char ascii value from the tempTable
			STRH R6, [R3, R5]
			ADDS R5, R5, #2			; Add the code and chracter to the CTable
			STRH temp, [R3, R5]
			ADDS R5, R5, #2
		
			SUBS counter, counter, #1
			POP{temp}					; pop code from stack
			SUBS counter, counter, #1
		    POP{current}				 ;pop node letter value from stack



			LDR current, [current, #8]	;go to the right child
			LSLS temp, #1
			ADDS temp, #0x01

Test3		
			LDR R3, [SP]			;while stack is not empty
			CMP R3, #0
			BNE while3
			CMP counter, #0
			BGE while3
			
									;Clean All registers
			
			MOVS R0, #0
			MOVS R1, #0
			MOVS R2, #0
			MOVS R3, #3
			MOVS R4, #0
			MOVS R5, #0
			MOVS R6, #0
			MOVS R7, #0

			MOV PC, LR				; Move out of subroutine back to main routine
 ;/////////////////////////////////////////////////////////////////////////////////////////////////////////////////
 
 ;*****************************Encode String within ARRAY1**********************************************
 
ENCODESTRING

		LDR R0, =ARRAY1
		LDRB R0, [R0]		;R0 will hold number of chracters in string
		LDR R1, =newARRAY1  ;R1 will hold the address of the string

		
loop9	CMP R7, R0			; R7 will serve as the loop counter
		BGE endLoop9
		
		LDR R6, =CTable		;R6 will store the address of the Code Table
		
		LDRB R2, [R1, R7]	; R2 will hold each current chracter we are looking at from the string
		
		LDRH R5, [R6]		;R5 will hold the poition we are at in the table
		
		B check9
Find	
		ADDS R6, R6, #4
		LDRH R5, [R6]

check9	CMP R2, R5
		BNE Find 
		
	;Once found, encode it and store in R3
		
		ADDS R6, R6, #2 	;Shift over in table to the coding data
		LDRH R5, [R6]		; R5 now holds corresponding code for the word

		ADDS R4, R4, R5		; R4 will store temporarily our encoded string
		ADDS R7, R7, #1		; Increment counter
		
		CMP R7, R0 
		BGE loop9
		LSLS R4, R4, R3		; Shift the bits by 4

		B loop9
		
endLoop9
		LDR R6, =encoded
		STR R4, [R6]
		
									; String stored in encoded literal in sets of 3 bits for each code (appended with 0's)

			;Clean All registers	
			MOVS R0, #0
			MOVS R1, #0
			MOVS R2, #0
			MOVS R3, #0
			MOVS R4, #0
			MOVS R5, #0
			MOVS R6, #0
			MOVS R7, #0
			
			MOV PC, LR				; Move out of subroutine back to main routine
 ;//////////////////////////////////////////////////////////////////////////////////////////////////////////
 
 ;*******READONLY Literal Pool**********
	   
ARRAY0 DCB 10,1,2,3,4,5,6,7,8,9,0
ARRAY1 DCB 9,"kcul doog"

		END