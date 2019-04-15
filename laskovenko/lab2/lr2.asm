PSPPRINT SEGMENT
	ASSUME CS:PSPPRINT, DS:PSPPRINT
	ORG 100H
START: JMP BEGIN

;DATA
MEMORY_ADDRESS	db 'Memory address:    ',0DH,0AH,0DH,0AH,'$'
ENV_ADDRESS		db 'Environment address:    ',0DH,0AH,0DH,0AH,'$'
TAIL			db 'Command-line tail:$'
ENV 			db 'Environment contains:',0DH,0AH,'$'
PATH			db 'Path: $'

;PROC
TETR_TO_HEX PROC near
	and AL,0Fh
	cmp AL,09
	jbe NEXT
	add AL,07
NEXT: add AL,30h
	ret
TETR_TO_HEX ENDP


BYTE_TO_HEX PROC near
	push CX
	mov AH,AL
	call TETR_TO_HEX
	xchg AL,AH
	mov CL,4
	shr AL,CL
	call TETR_TO_HEX
	pop CX
	ret
BYTE_TO_HEX ENDP


WRD_TO_HEX PROC near
	push BX
	mov BH,AH
	call BYTE_TO_HEX
	mov [DI],AH
	dec DI
	mov [DI],AL
	dec DI
	mov AL,BH
	call BYTE_TO_HEX
	mov [DI],AH
	dec DI
	mov [DI],AL
	pop BX
	ret
WRD_TO_HEX ENDP


BYTE_TO_DEC PROC near
	push CX
	push DX
	xor AH,AH
	xor DX,DX
	mov CX,10
loop_bd: div CX
	or DL,30h
	mov [SI],DL
	dec SI
	xor DX,DX
	cmp AX,10
	jae loop_bd
	cmp AL,00h
	je end_l
	or AL,30h
	mov [SI],AL
end_l: pop DX
	pop CX
	ret
BYTE_TO_DEC ENDP
	

PRINT_STR PROC near
	push AX
	
	mov AH,09h
	int 21h
	
	pop AX

	ret
PRINT_STR ENDP

PRINT_ENDL PROC near
	push AX
	push DX

	mov AH,02h
	mov DL,0Dh
	int 21h
	mov DL,0Ah
	int 21h

	pop DX
	pop AX

	ret
PRINT_ENDL ENDP


GET_ADDRESS PROC near
	push AX

	mov AX,ES:[02h]
	mov DI,OFFSET MEMORY_ADDRESS
	add DI,19
	call WRD_TO_HEX

	mov AX,ES:[2Ch]
	mov DI,OFFSET ENV_ADDRESS
	add DI,24
	call WRD_TO_HEX

	pop AX

	ret
GET_ADDRESS ENDP

PRINT_TAIL PROC
	push AX
	push BX
	push DX

	mov DX, OFFSET TAIL
	call PRINT_STR

	mov AH,02h
	mov CL,ES:[80h]

	cmp CL,0
	je t_end

	mov BX, 0
t_loop:
	mov DL,ES:[81h+BX]
	int 21h
	inc BX
	loop t_loop
	
t_end:
	call PRINT_ENDL
	call PRINT_ENDL

	pop DX
	pop BX
	pop AX

	ret
PRINT_TAIL ENDP

PRINT_ENV PROC
	push AX
	push BX
	push DX
	push DS

	mov DX,OFFSET ENV
	call PRINT_STR

	mov AH,02h
	mov BX,ES:[2Ch]
	mov DS,BX
	mov BX,0
e_loop:
	mov DL,DS:[BX]
	inc BX
	cmp DL,00h
	je zero
	int 21H
	loop e_loop
	
zero:
	mov DL,DS:[BX]
	cmp DL,00h
	je e_end
	call PRINT_ENDL
	jmp e_loop

e_end:
	call PRINT_ENDL
	call PRINT_ENDL

	pop DS
	mov DX,OFFSET PATH
	call PRINT_STR
	push DS
	mov DX,BX
	mov BX,ES:[2Ch]
	mov DS,BX
	mov BX,DX

	add BX,3
p_loop:
	mov DL,DS:[BX]
	inc BX
	cmp DL,00h
	je p_zero
	int 21H
	loop p_loop


p_zero:
	pop DS
	pop DX
	pop BX
	pop AX

	ret
PRINT_ENV ENDP


BEGIN:
	call GET_ADDRESS
	mov DX,OFFSET MEMORY_ADDRESS
	call PRINT_STR
	mov DX,OFFSET ENV_ADDRESS
	call PRINT_STR

	call PRINT_TAIL

	call PRINT_ENV

	xor AL,AL
	mov AH,4Ch
	int 21H

PSPPRINT ENDS
 END START
