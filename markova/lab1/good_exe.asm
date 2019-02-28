ASTACK SEGMENT STACK
       DW 010H DUP(?)    
ASTACK ENDS	
	   
DATA SEGMENT
;ДАННЫЕ ПРОГРАММЫ
;--------------------------------------------------------------------------------------------
PC_TYPE    db 'Type PC: $'                                       ; объявление строк
PC_VERS    db 0DH,0AH,'System version:  . ',0DH,0AH,'$'          ; $ - конец строки
PC_OEM     db 'Original Equipment Manufacturer:    ',0DH,0AH,'$'
SER_NUM    db 'User serial number:        ',0DH,0AH,'$'          ; 0DH - возврат каретки, 0AH - перевод строки
;ТИП IBM PC
;--------------------------------------------------------------------------------------------
TYPE_PC         db 'PC $'
TYPE_PCXT       db 'PC/XT $'
TYPE_AT         db 'AT $'
TYPE_PS2_30     db 'PS2 model 30 $'
TYPE_PS2_50_60  db 'PS2 model 50/60 $'
TYPE_PS2_80     db 'PS2 model 80 $'
TYPE_PCjr       db 'PCjr $'
TYPE_PC_Con     db 'PC Convertible $'
DATA ENDS
CODE SEGMENT
ASSUME CS:CODE, DS:DATA, ES:NOTHING, SS:ASTACK
;ПРОЦЕДУРЫ
;--------------------------------------------------------------------------------------------
TETR_TO_HEX PROC near                                            ; из двоичной в шестнадцатеричную сс
	and AL,0Fh                                               ; PROC near - вызывается в том же сегменте, в котором определена
	cmp AL,09
	jbe NEXT
	add AL,07
NEXT:   add AL,30h
	ret
TETR_TO_HEX ENDP

BYTE_TO_HEX PROC near                                            ; байтовое число в шестнадцатеричную сс
	push CX
	mov  AH,AL
	call TETR_TO_HEX
	xchg AL,AH
	mov  CL,4
	shr  AL,CL
	call TETR_TO_HEX
	pop  CX
	ret
BYTE_TO_HEX ENDP
 
WRD_TO_HEX PROC near                                             ; шестнадцатибитовое число в шестнадцатеричную сс
	push BX
	mov  BH,AH
	call BYTE_TO_HEX
	mov  [DI],AH
	dec  DI
	mov  [DI],AL
	dec  DI
	mov  AL,BH
	call BYTE_TO_HEX
	mov  [DI],AH
	dec  DI
	mov  [DI],AL
	pop  BX
	ret
WRD_TO_HEX ENDP

BYTE_TO_DEC PROC near                                            ; байтовое число в десятичную сс
	push CX
	push DX
	xor  AH,AH
	xor  DX,DX
	mov  CX,10
loop_bd: div CX
	or   DL,30h
	mov  [SI],DL
	dec  SI
	xor  DX,DX
	cmp  AX,10
	jae  loop_bd
	cmp  AL,00h
	je   end_l
	or   AL,30h
	mov  [SI],AL
end_l:  pop  DX
	pop  CX
	ret
BYTE_TO_DEC ENDP
;--------------------------------------------------------------------------------------------
LINE_OUTPUT PROC near                                            ; вывод строки
        mov  AH,09H
	int  21H
	ret
LINE_OUTPUT ENDP

GET_PC_TYPE PROC near                                            ; определение типа IBM PC
	mov AX,0F000H                                            ; указывает ES на ПЗУ
	mov ES,AX
	mov AL,ES:[0FFFEH]                                       ; получаем байт
	ret
GET_PC_TYPE ENDP

Write_PC_TYPE PROC near                                          ; вывод на экран типа PC
        push DX
	push AX
	mov  DX, OFFSET PC_TYPE                                  ; помещаем в DX смещение строки
	call LINE_OUTPUT                                         ; вызов процедуры 
	call GET_PC_TYPE                                           
                                                                 
	cmp  AL,0FFH                                             ; функция сравнения
	je   PC                                                  ; переход, если значения равны
	
	cmp  AL,0FEH
	je   PCXT
	
	cmp  AL,0FBH
	je   PCXT
	
	cmp  AL,0FCH
	je   PC_AT
	
	cmp  AL,0FAH
	je   PS2_30
	
	cmp  AL,0F8H
	je   PS2_80
	
	cmp  AL,0FDH
	je   PCjr
	
	cmp  AL,0F9H
	je   PC_Convertible

	PC:
		mov  DX, OFFSET TYPE_PC
		jmp  print
	PCXT:
		mov  DX, OFFSET TYPE_PCXT
		jmp  print
	PC_AT:
		mov  DX, OFFSET TYPE_AT
		jmp  print
	PS2_30:
		mov  DX, OFFSET TYPE_PS2_30
		jmp  print
	PS2_80:
		mov  DX, OFFSET TYPE_PS2_80
		jmp  print
	PCjr:
		mov  DX, OFFSET TYPE_PCjr
		jmp  print
	PC_Convertible:
		mov  DX, OFFSET TYPE_PC_Con
		jmp  print
    print:
        call LINE_OUTPUT
	    pop AX
	    pop DX
        ret
Write_PC_TYPE ENDP

Write_PC_VERS PROC near                                          ; вывод на экран номера версии PC
        mov  AX,0
	mov  AH,30H                                              ; номер функции получения версии
	int  21H                                                 ; получить номер версии
   	push AX
	push SI
	mov  SI,OFFSET PC_VERS                                   ; SI - индексный регистр
	add  SI,18                                               ; смещение начала строки
	call BYTE_TO_DEC
                                                                 ; модификация ОС
	mov  AL,AH                                               ; AL - старший номер версии,AH - младший
	add  SI,3
	call BYTE_TO_DEC
	mov  DX,OFFSET PC_VERS
	call LINE_OUTPUT
	pop  SI
	pop  AX
	ret
Write_PC_VERS  ENDP
	
Write_PC_OEM PROC near                                           ; вывод на экран OEM версии
        push AX
	push BX
	push SI
	mov  SI,OFFSET PC_OEM
	add  SI,35
	mov  AL,BH                                                   ; |  функция 30H через регистр BH возвращает
	call BYTE_TO_DEC                                             ; |> программе OEM-код фирмы-производителя
	mov  DX,OFFSET PC_OEM                                        ; |  операционной системы
	call LINE_OUTPUT
	pop  SI
	pop  BX
	pop  AX
	ret
Write_PC_OEM ENDP

Write_SER_NUM PROC near                                          ; вывод на экран серийного номера пользователя
	push AX
	push BX
	push CX
	push SI
	mov  AL,BL                                                   ; |  в регистре BL после вызова функции 30H
	call BYTE_TO_HEX                                             ; |> находится серийн
	mov  DI,OFFSET SER_NUM                                       ; |  операционной системы
	add  DI,20
	mov  [DI],AX
	mov  AX,CX
	mov  DI,OFFSET SER_NUM
	add  DI,25
	call WRD_TO_HEX
	mov  DX,OFFSET SER_NUM
	call LINE_OUTPUT
	pop  SI
	pop  CX
	pop  BX
	pop  AX
	ret
Write_SER_NUM ENDP
;--------------------------------------------------------------------------------------------
BEGIN:
	
	mov  AX,DATA
	mov  DS,AX
        call Write_PC_TYPE                                       ; вывод данных
	call Write_PC_VERS
	call Write_PC_OEM
	call Write_SER_NUM
; ВЫХОД В DOS
;--------------------------------------------------------------------------------------------
	xor AL,AL                                                ; обнуление регистра
	mov AH,4CH
	int 21H
CODE ENDS
END BEGIN
