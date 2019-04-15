AStack SEGMENT STACK
	dw 64 dup (?)
AStack ENDS


CODE SEGMENT
	ASSUME CS:CODE, DS:DATA, SS:AStack

ROUT PROC FAR
	jmp start		;Точка входа
	;ROUT DATA:
	KEEP_CS 		dw 0
	KEEP_IP 		dw 0
	UNIQUE  		db 'USER$'				;Сигнатура, идентифицирующая резидент
	KEEP_PSP		dw 0
	KEEP_SP			dw 0
	KEEP_SS			dw 0
	COUNTER			dw 0
	COUNT_MESSAGE	db 'ROUT CALLED:      $'
	ROUT_STACK 		dw 64 dup (?)			;Стек для резидента
	stack_ptr		=$

start:
	;Инициализация стека:
	mov KEEP_SP,SP
	mov KEEP_SS,SS
	mov AX,seg ROUT_STACK
	mov SS,AX
	mov SP,offset stack_ptr

	;Сохранение всех регистров:
	push AX
	push BX
	push CX
	push DX

	;Получение старого положения курсора:
	mov AH,03h
	mov BH,00h
	int 10h
	push DX		;Сохранение положения курсора
	;Установка нового положения курсора:
	mov AH,02h
	mov BH,0
	mov DX,071Ch
	int 10h
	;Увеличение счетчика:
	push DS
	mov AX,seg COUNTER
	mov DS,AX
	mov AX,COUNTER
	inc AX
	mov COUNTER,AX
	;Формирование строки счетчика:
	push DI
	mov DI,offset COUNT_MESSAGE
	add DI,17
	call WRD_TO_HEX
	pop DI
	pop DS
	;Вывод строки:
	push ES
	push BP
	mov AX,seg COUNT_MESSAGE
	mov ES,AX
	mov BP,offset COUNT_MESSAGE
	mov AH,13h
	mov AL,0
	mov CX,12h
	mov BH,0
	int 10h
	pop BP
	pop ES
	;Восстановление старого положения курсора:
	pop DX
	mov AH,02h
	mov BH,00h
	int 10h

	;Восстановление всех регистров:
	pop DX
	pop CX
	pop BX
	pop AX
	mov SP,KEEP_SP
	mov SS,KEEP_SS
	;Возврат из обработчика прерывания:
	mov AL,20h
	out 20h,AL
	iret	
ROUT ENDP

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

endrout=$			;Последний байт резидента

PRINT_STR PROC FAR
	push AX

	mov AX,0900h
	int 21h

	pop AX
	ret
PRINT_STR ENDP

CHECK_ROUT PROC FAR
	push AX
	push BX
	push CX
	push DI
	push SI
	push ES

	;Чтение исходного вектора прерывания 1Ch:
	mov AX,351Ch
	int 21h
	;Проверка сигнатуры:
	cld
	mov CX,5
	lea DI,ES:UNIQUE
	lea SI,CHECK_UNIQUE
	repe cmpsb
	jne non_equal
	;Вывод сообщения:
	mov DX,offset ROUT_CHECK_MESSAGE
	call PRINT_STR
	;Завершение программы:
	mov AX,4C00h
	int 21h

non_equal:
	pop ES
	pop SI
	pop DI
	pop CX
	pop BX
	pop AX
	ret
CHECK_ROUT ENDP

SET_ROUT PROC FAR
	push AX
	push BX
	push DX
	push DS
	push ES

	;Чтение исходного вектора прерывания 1Ch:
	push ES
	mov AX,351Ch
	int 21h
	;Сохранение исходного вектора:
	mov KEEP_IP,BX
	mov KEEP_CS,ES
	;Заполнение вектора 1Ch:
	pop ES
	mov DX,offset ROUT
	mov AX,seg ROUT
	mov DS,AX
	mov AX,251Ch
	int 21h
	
	pop ES
	pop DS
	mov DX,offset ROUT_LOAD_MESSAGE
	call PRINT_STR
	pop DX
	pop BX
	pop AX
	ret
SET_ROUT ENDP

MAKE_RESIDENT PROC FAR
	;Установление резидента:
	mov DX,offset endrout
	mov CL,04h
	shr DX,CL
	add DX,100h
	mov AX,3100h
	int 21h

	ret
MAKE_RESIDENT ENDP

UNLOAD_ROUT PROC FAR
	cli

	;Восстановление старого вектора:
	push DS
	mov DX,ES:KEEP_IP
	mov AX,ES:KEEP_CS
	mov DS,AX
	mov AX,251Ch
	int 21h
	pop DS
	;Освобождение памяти резидента:
	mov SI,offset KEEP_PSP
	mov AX,ES:[BX+SI]
	mov ES,AX
	mov AX,ES:[2Ch]
	push ES
	mov ES,AX
	mov AH,49h
	int 21h
	pop ES
	int 21h

	sti

	;Завершение программы:
	mov DX,offset UNLOAD_ROUT_MESSAGE
	call PRINT_STR
	mov AX,4C00h
	int 21h

	ret
UNLOAD_ROUT ENDP

MAIN PROC FAR
	;Инициализация DS:
	push DS				;Сохранение адреса PSP
	mov AX,seg DATA
	mov DS,AX

	mov KEEP_PSP,ES 	;Сохранение адреса PSP в резиденте

	;Чтение хвоста командной строки:
	mov CL,ES:[80h]
	cmp CL,4
	jne wrong_tail
	mov BX,0
	mov SI,offset TAIL
tail_loop:
	mov AL,ES:[81h+BX]
	mov [SI],AL
	inc SI
	inc BX
	loop tail_loop
	;Проверка хвоста на совпадение с /un:
	mov CX,4
	mov AX,seg DATA	;ES -
	mov ES,AX		;- на DATA 
	lea DI,UNLOAD_TAIL
	lea SI,TAIL
	cld
	repe cmpsb
	pop ES 			;ES на PSP
	jne wrong_tail
	;Выгрузка пользовательского прерывания:
	;Чтение исходного вектора прерывания 1Ch:
	mov AX,351Ch
	int 21h
	;Проверка сигнатуры:
	cld
	mov CX,5
	lea DI,ES:UNIQUE
	lea SI,CHECK_UNIQUE
	repe cmpsb
	jne non_equal_unload
	call UNLOAD_ROUT
non_equal_unload:
	mov DX,offset UNLOAD_MESSAGE
	call PRINT_STR
	;Завершение программы:
	mov AX,4C00h
	int 21h

wrong_tail:
	call CHECK_ROUT
	call SET_ROUT
	call MAKE_RESIDENT
	
	mov AX,4C00h
	int 21H
	ret
MAIN ENDP
CODE ENDS


DATA SEGMENT
	CHECK_UNIQUE 		db 'USER$'
	ROUT_LOAD_MESSAGE   db 'Rout is loaded.',0Dh,0Ah,'$'
	ROUT_CHECK_MESSAGE  db 'Rout has been already loaded.',0Dh,0Ah,'$'
	UNLOAD_MESSAGE      db 'User rout has not been loaded yet.',0Dh,0Ah,'$'
	UNLOAD_ROUT_MESSAGE db 'Rout is unloaded.',0Dh,0Ah,'$'
	UNLOAD_TAIL  		db ' /un'
	TAIL         		db '    '
DATA ENDS 


END MAIN
