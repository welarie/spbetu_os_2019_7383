TESTPC SEGMENT
 ASSUME CS:TESTPC, DS:TESTPC, ES:NOTHING, SS:NOTHING
 ORG 100H
START: JMP BEGIN
TypeOS db 'type OS: $'
VERS db 'Version:  .  ',0DH,0AH,'$'
OEM db 'OEM:    ',0DH,0AH,'$'
USR_NUM db 'Serial number user: ','$'
ENDSTR db 0DH,0AH,'$'

PC db 'PC',0DH,0AH,'$'
PC_XT db 'PC/XT',0DH,0AH,'$'
AT db 'AT',0DH,0AH,'$'
PS2_30 db 'PS2 model 30',0DH,0AH,'$'
PS2_80 db 'PS2 model 80',0DH,0AH,'$'
PCjr db 'PCjr',0DH,0AH,'$'
PC_Conv db 'PC Convertible',0DH,0AH,'$'

; Вывод на консоль
Write PROC near
	mov AH,09h
	int 21h
	ret
Write ENDP
	
; Запись и вывод типа системы
TYPE_OS PROC near
	mov dx, OFFSET TypeOS
	call Write
	mov ax,0F000h
	mov es,ax
	mov ax,es:0FFFEh
	
	; Сравниваем ключи для определения типа системы	
	cmp al,0FFh
		je PCpt
	cmp al,0FEh
		je PC_XTpt
	cmp al,0FBh
		je PC_XTpt
	cmp al,0FCh
		je ATpt
	cmp al,0FAh
		je PS2_30pt
	cmp al,0F8h
		je PS2_80pt
	cmp al,0FDh
		je PCjrpt
	cmp al,0F9h
		je PC_Convpt
	
	PCpt:
		mov dx, OFFSET PC
			jmp close
	PC_XTpt:
		mov dx, OFFSET PC_XT
			jmp close
	ATpt:
		mov dx, OFFSET AT
			jmp close
	PS2_30pt:
		mov dx, OFFSET PS2_30
			jmp close
	PS2_80pt:
		mov dx, OFFSET PS2_80
			jmp close
	PCjrpt:
		mov dx, OFFSET PCjr
			jmp close
	PC_Convpt:
		mov dx, OFFSET PC_Conv
			jmp close
	
	close:
		call Write
		ret
TYPE_OS ENDP

; Запись Version и OEM
VERSION PROC near
	; Получаем номер версии и модификации версии системы
	mov ax,0
	mov ah,30h
	int 21h
	
	; Запись версии системы в строку VERS
	mov si,offset VERS
	add si,9
	call BYTE_TO_DEC 
	
	; Запись модификации в строку VERS
	mov al,ah
	add si,3
	call BYTE_TO_DEC 
	
	; Вывод полной версии в консоль
	mov dx,offset VERS 
	call Write
	
	; Вывод OEM
	mov si,offset OEM
	add si,7
	mov al,bh
	call BYTE_TO_DEC
	mov dx,offset OEM
	call Write
	
	; Вывод серийного номера юзера
	mov dx,offset USR_NUM
	call Write
	mov al,bl
	call HELP_BYTE_TO_HEX
	mov al,ch
	call HELP_BYTE_TO_HEX
	mov al,cl
	call HELP_BYTE_TO_HEX

	mov dx,offset ENDSTR
	call Write
	
	ret
VERSION ENDP

HELP_BYTE_TO_HEX PROC near
	call BYTE_TO_HEX
	mov bx,ax
	mov dl,bl
	mov ah,02h
	int 21h
	mov dl, bh
	int 21h
HELP_BYTE_TO_HEX ENDP

TETR_TO_HEX PROC near
	and AL,0Fh
	cmp AL,09
		jbe NEXT
	add AL,07
NEXT: add AL,30h
	ret
TETR_TO_HEX ENDP

; Байт AL переводится в два символа шестн. числа AX
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



; Перевод в 10сс, SI - адрес поля младшей цифры
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

BEGIN:
	call TYPE_OS
	call VERSION
	xor AL,AL
	mov AH,4Ch
	int 21H
TESTPC ENDS
 END START
