DATA SEGMENT
PC_TYPE		db	'PC Type:  ',0DH,0AH,'$'
SYS_VERS 	db      'System version:  .  ',0DH,0AH,'$'
OEM_NUM		db	'OEM number:      ',0DH,0AH,'$'
SER_NUM	db	'User serial number:               ',0DH,0AH,'$'
DATA ENDS

AStack SEGMENT STACK
	DW 010H DUP(?)
AStack ENDS
CODE SEGMENT
	ASSUME CS:CODE, DS:DATA, ES:NOTHING, SS:AStack
;ПРОЦЕДУРЫ
;------------------------------------------------------------------
TETR_TO_HEX  PROC  near
	add	AL, 0Fh
	cmp	AL, 09
	jbe	NEXT
	add	AL, 07
NEXT:	add     AL, 30h
	ret
TETR_TO_HEX  ENDP
;------------------------------------------------------------------
BYTE_TO_HEX  PROC  near
;байт в AL переводиться в два символа шестнадцатеричного числа в AX
	push	CX
	mov 	AH, AL
	call	TETR_TO_HEX
	xchg	AL, AH
	mov	CL, 4
	shr	AL, CL
	call	TETR_TO_HEX ;в AL старшая цифра
	pop	CX	    ;в AH младшая
	ret
BYTE_TO_HEX  ENDP
;------------------------------------------------------------------
WRD_TO_HEX  PROC  near
;перевод в 16 СС 16-ти разрядного числа
;в АХ - числоб DI - адрес последнего символа

	push 	BX
	mov	BH, AH
	call	BYTE_TO_HEX
	mov	[DI], AH
	dec	DI
	mov	[DI], AL
	dec	DI
	mov	AL, BH
	call	BYTE_TO_HEX
	mov	[DI], AH
	dec	DI
	mov	[DI], AL
	pop	BX
	ret
WRD_TO_HEX  ENDP
;------------------------------------------------------------------
BYTE_TO_DEC  PROC  near
;перевод в 10 СС, SI - адрес поля младшей цифры
	push	CX
	push	DX
	xor	AH, AH
	xor	DX, DX
	mov	CX, 10
loop_bd:  div	CX
	or	DL, 30h
	mov	[SI], DL
	dec	SI
	xor	DX, DX
	cmp	AX, 10
	jae	loop_bd
	cmp	AL, 00h
	je	end_l
	or	AL, 30h
	mov	[SI], AL
end_l:	pop	DX
		pop	CX
		ret
BYTE_TO_DEC  ENDP
;------------------------------------------------------------------
GET_PC_TYPE  PROC  near   
	push	ES
	push	BX
	push	AX
	mov	BX, 0F000H
	mov	ES, BX
	mov	AX, ES:[0FFFEH]
	mov	AH, AL
	call	BYTE_TO_HEX
	lea	BX, PC_TYPE
	mov	[BX+9], AX
	pop	AX
	pop	BX
	pop	ES
GET_PC_TYPE  ENDP
;------------------------------------------------------------------
GET_SYS_VERS  PROC  near
	push	AX
	push	SI
	lea	SI, SYS_VERS
	add	SI, 16       ;основная версия
	call	BYTE_TO_DEC
	add	SI, 3        ;модификация
	mov	AL, Ah
	call	BYTE_TO_DEC
	pop	SI
	pop	AX
	ret	
GET_SYS_VERS  ENDP
;------------------------------------------------------------------
GET_OEM_NUM  PROC  near
	push	AX
	push	BX
	push	SI
	mov	AL, BH
	lea	SI, OEM_NUM
	add	SI, 14
	call	BYTE_TO_DEC
	pop	SI
	pop	BX
	pop	AX
	ret
GET_OEM_NUM  ENDP
;------------------------------------------------------------------
GET_SERIAL_NUM  PROC  near
	push	AX
	push	BX
	push	CX
	push	SI
	mov	AL, BL
	call	BYTE_TO_HEX
	lea	DI, SER_NUM
	add	DI, 22
	mov	[DI], AX
	mov	AX, CX
	lea	DI, SER_NUM
	add	DI, 27
	call	WRD_TO_HEX
	pop	SI
	pop	CX
	pop	BX
	pop	AX
	ret   	
GET_SERIAL_NUM  ENDP
;------------------------------------------------------------------
PRINT_MSG  PROC  near
	mov	AH, 09h
	int	21h
	ret
PRINT_MSG  ENDP
;------------------------------------------------------------------
MAIN  PROC  near
	push	DS
	sub	AX, AX
	mov	AX, DATA
	mov	DS, AX
	sub	AX, AX
;Определение типа ПК и версии ОС
	call	GET_PC_TYPE
	mov	AH, 30h
	int	21h
	call	GET_SYS_VERS
	call	GET_OEM_NUM
	call	GET_SERIAL_NUM
;------------------------------------------------------------------
;Вывод информации
	lea	DX, PC_TYPE
	call	PRINT_MSG
	lea	DX, SYS_VERS
	call	PRINT_MSG
	lea	DX, OEM_NUM
	call	PRINT_MSG
	lea	DX, SER_NUM
	call	PRINT_MSG
;------------------------------------------------------------------        	
;Выход в DOS
	xor	AL, AL
	mov	AH, 4Ch
	int	21h
MAIN	ENDP
CODE    ENDS
	END MAIN
;------------------------------------------------------------------