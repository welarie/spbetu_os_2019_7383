STACK SEGMENT STACK
	DW 100 DUP (?)
STACK ENDS


DATA SEGMENT
	wasloaded DB 'Interruption had been set earlier!',0DH,0AH,'$'
	unloaded DB 'Interruption has been unloaded!',0DH,0AH,'$'
	loading DB 'Interruption has been set!',0DH,0AH,'$'
DATA ENDS


CODE SEGMENT
 ASSUME CS:CODE, DS:DATA, ES:DATA, SS:STACK
START: JMP BEGIN


PRINT PROC NEAR
	push ax
	mov ah, 09h
	int 21h
	pop ax
	ret
PRINT ENDP


setCurs PROC ; установка позиции курсора
	push AX
	push BX
	push CX
	mov AH,02h
	mov BH,00h
	int 10h
	pop CX
	pop BX
	pop AX
	ret
setCurs ENDP


getCurs PROC ; определение позиции и размера курсора
	push AX
	push BX
	push CX
	mov AH,03h
	mov BH,00h
	int 10h
	pop CX
	pop BX
	pop AX
	ret
getCurs ENDP


ROUT PROC FAR ; обработчик прерываний
	jmp ROUT_
	
; Данные
_DATA:
	SIGN DB '0000'
	KEEP_CS DW 0
	KEEP_IP DW 0
	KEEP_PSP DW 0
	VALUE DB 0
	COUNTER DB '    Number of calls: 00000    $' ; счетчик
	STACK_	DW 	64 dup (?)
	KEEP_SS DW 0
	KEEP_AX	DW 	?
    KEEP_SP DW 0
	
	ROUT_:
	mov KEEP_SS, SS
	mov KEEP_AX, AX
	mov KEEP_SP, SP
	mov AX, seg STACK_
	mov SS, AX
	mov SP, 0
	mov AX, KEEP_AX
	
	push AX
	push DX
	push DS
	push ES
	cmp VALUE, 1
	je ROUT_RES
	call getCurs
	push DX
	mov DH,7
	mov DL,15
	call setCurs

ROUT_SUM: ; счетчик количества прерываний	
	push SI
	push CX 
	push DS
	push AX
	mov AX,SEG COUNTER
	mov DS,AX
	mov bx, offset COUNTER
	add bx, 22
	mov si, 3
next_:
	mov ah, [bx+si]
	inc ah
	cmp ah, 58
	jne ROUT_NEXT
	mov ah, 48
	mov [bx+si], ah
	dec si
	cmp si, 0
	jne next_
ROUT_NEXT:
	mov [bx+si],ah
	pop ds
	pop si
	pop bx
	pop ax
	push es 
	push bp
	mov ax,SEG COUNTER
	mov es,ax
	mov ax,offset COUNTER
	mov bp,ax
	mov ah,13h 
	mov al,0 
	mov cx,30
	mov bh,0
	int 10h
	pop bp
	pop es
	pop dx
	call setCurs
	jmp ROUT_END
	
ROUT_RES: ; восстановление вектора прерывания
	CLI
	mov DX,KEEP_IP
	mov AX,KEEP_CS
	mov DS,AX
	mov AH,25h 
	mov AL,1Ch 
	int 21h 
	mov ES, KEEP_PSP 
	mov ES, ES:[2Ch]
	mov AH, 49h  
	int 21h
	mov ES, KEEP_PSP
	mov AH, 49h
	int 21h
	STI
	
ROUT_END: ; восстановление регистров
	pop ES
	pop DS
	pop DX
	pop AX 
	
	mov AX, KEEP_SS
	mov SS, AX
	mov SP,KEEP_SP
	mov AX,KEEP_AX
	iret
ROUT ENDP


CHECKING PROC  ; проверка пользовательского прерывания
	mov AH,35h 
	mov AL,1Ch 
	int 21h 		
	mov SI, offset SIGN 
	sub SI, offset ROUT 
	mov AX,'00'
	cmp AX,ES:[BX+SI] 
	jne UNLOAD 
	cmp AX,ES:[BX+SI+2] 
	je LOAD
	
UNLOAD:
	call SET_INTERRUPT
	mov DX,offset LAST_BYTE
	mov CL,4
	shr DX,CL
	inc DX
	add DX,CODE
	sub DX,KEEP_PSP
	xor AL,AL
	mov AH,31h 
	int 21h
LOAD:
	push ES
	push AX
	mov AX,KEEP_PSP 
	mov ES,AX
	cmp byte ptr ES:[82h],'/'
	jne BACK 
	cmp byte ptr ES:[83h],'u'
	jne BACK 
	cmp byte ptr ES:[84h],'n' 
	je UNLOAD_
BACK:
	pop AX
	pop ES
	mov dx,offset wasloaded
	call PRINT
	ret
UNLOAD_:
	pop AX
	pop ES
	mov byte ptr ES:[BX+SI+10],1
	mov dx,offset unloaded
	call PRINT
	ret
CHECKING ENDP


SET_INTERRUPT PROC ; добавление нового прерывания
	push DX
	push DS
	mov AH,35h
	mov AL,1Ch 
	int 21h
	mov KEEP_IP,BX 
	mov KEEP_CS,ES 
	mov DX,offset ROUT 
	mov AX,seg ROUT 
	mov DS,AX 
	mov AH,25h 
	mov AL,1Ch 
	int 21h
	pop DS
	mov DX,offset loading 
	call PRINT
	pop DX
	ret
SET_INTERRUPT ENDP 


BEGIN:
	mov AX,DATA
	mov DS,AX
	mov KEEP_PSP,ES
	call CHECKING
	xor AL,AL
	mov AH,4Ch
	int 21H
LAST_BYTE:
	CODE ENDS
	END START