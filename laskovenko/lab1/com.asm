TESTPC SEGMENT
	ASSUME CS:TESTPC, DS:TESTPC, ES:NOTHING, SS:NOTHING
	ORG 100H
START: JMP BEGIN

; ДАННЫЕ
OS_TYPE 	db 'OS Type: $'
OS_VERSION 	db 'OS Version:  .  ',0DH,0AH,'$'
OS_OEM 		db 'OEM:    ',0DH,0AH,'$'
SERIAL_NUM 	db 'Serial number:       ',0DH,0AH,'$'

PC 			db 'PC',0DH,0AH,'$'
PCXT 		db 'PC/XT',0DH,0AH,'$'
AT 			db 'AT',0DH,0AH,'$'
PS2_30 		db 'PS2 model 30',0DH,0AH,'$'
PS2_80 		db 'PS2 model 80',0DH,0AH,'$'
PCjr 		db 'PCjr',0DH,0AH,'$'
PC_Cnv 		db 'PC Convertible',0DH,0AH,'$'

; ПРОЦЕДУРЫ
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
	mov AH,09h
	int 21h
	ret
PRINT_STR ENDP

GET_OS_INFO PROC near
; Вызов функции 30h прерывания 21h
	mov AX,0
	mov AH,30h
	int 21h
	ret
GET_OS_INFO ENDP

GET_OS_TYPE PROC near
	; Загрузка в регистр AX данных по адресу предпоследнего бита ROM BIOS
	mov AX,0F000h
	mov ES,AX
	mov AX,ES:0FFFEh

	; Вывод строки OS_TYPE на экран
	mov DX,OFFSET OS_TYPE
	call PRINT_STR

	; Сравнение 
	cmp AL,0FFh
	je PC_label
	cmp AL,0FEh
	je PCXT_label
	cmp AL,0FBh
	je PCXT_label
	cmp AL,0FCh
	je AT_label
	cmp AL,0FAh
	je PS2_30_label
	cmp AL,0F8h
	je PS2_80_label
	cmp AL,0FDh
	je PCjr_label
	cmp AL,0F9h
	je PC_Convertible_label
	PC_label:
		mov DX,OFFSET PC
		call PRINT_STR
		jmp end_label
	PCXT_label:
		mov DX,OFFSET PCXT
		call PRINT_STR
		jmp end_label
	AT_label:
		mov DX,OFFSET AT
		call PRINT_STR
		jmp end_label
	PS2_30_label:
		mov DX,OFFSET PS2_30
		call PRINT_STR
		jmp end_label
	PS2_80_label:
		mov DX,OFFSET PS2_80
		call PRINT_STR
		jmp end_label
	PCjr_label:
		mov DX,OFFSET PCjr
		call PRINT_STR
		jmp end_label
	PC_Convertible_label:
		mov DX,OFFSET PC_Cnv
		call PRINT_STR
		jmp end_label

end_label:
	ret
GET_OS_TYPE ENDP


GET_OS_VERSION PROC near
	; Формирование строки OS_VERSION: номер основной версии
	mov SI,OFFSET OS_VERSION
	add SI,12
	push AX
	call BYTE_TO_DEC

	; Формирование строки OS_VERSION: номер модификации
	pop AX
	mov AL,AH
	add SI,3
	call BYTE_TO_DEC

	ret
GET_OS_VERSION  ENDP


GET_OS_OEM PROC near
	; Формирование строки OS_OEM 
	mov SI,OFFSET OS_OEM
	add SI,7
	mov AL,BH
	call BYTE_TO_DEC

	ret
GET_OS_OEM	ENDP


GET_SERIAL_NUM PROC near 
	; Формирование строки SERIAL_NUM: первые 8 бит номера
	mov AL,BL
	call BYTE_TO_HEX
	mov DI,OFFSET SERIAL_NUM
	add DI,16
	mov [DI],AH
	dec DI
	mov [DI],AL
	
	; Формирование строки SERIAL_NUM: оставшиеся 16 бит номера
	mov AX,CX
	mov DI,OFFSET SERIAL_NUM
	add DI,20
	call WRD_TO_HEX
	
	ret
GET_SERIAL_NUM 	ENDP


BEGIN:
	call GET_OS_TYPE

	call GET_OS_INFO

	call GET_OS_VERSION
	mov DX,OFFSET OS_VERSION
	call PRINT_STR

	call GET_OS_OEM
	mov DX,OFFSET OS_OEM
	call PRINT_STR

	call GET_SERIAL_NUM
	mov DX,OFFSET SERIAL_NUM
	call PRINT_STR
	
	xor AL,AL
	mov AH,4Ch
	int 21H
TESTPC ENDS
 END START