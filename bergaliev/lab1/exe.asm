STACK SEGMENT STACK
 DW 10h DUP(?)
STACK ENDS

DATA SEGMENT
NUM db '     ',0DH,0AH,'$'
PC db 'PC',0DH,0AH,'$'
PC_XT db 'PC/XT',0DH,0AH,'$'
AT db 'AT',0DH,0AH,'$'
PS2_30 db 'PS2 модель 30',0DH,0AH,'$'
PS2_80 db 'PS2 модель 80',0DH,0AH,'$'
PCjr db 'PSjr',0DH,0AH,'$'
PC_Conv db 'PS Convertible',0DH,0AH,'$'
PC_TYPE_STR db 'Тип IBM PC: $'
OS_VERSION_STR db 'Версия ОС: $'
LESS_2 db '<2.0',0DH,0AH,'$'
OEM_STR db 'OEM: $'
USER_NUM_STR db 'Серийный номер пользователя: $'
DATA ENDS

CODE SEGMENT
 ASSUME CS:CODE, DS:DATA, SS:STACK

TETR_TO_HEX PROC far       
 and AL,0Fh
 cmp AL,09
 jbe NEXT
 add AL,07
NEXT: add AL,30h
 ret
TETR_TO_HEX ENDP

BYTE_TO_HEX PROC far 
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

WRD_TO_HEX PROC far
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

BYTE_TO_DEC PROC far
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

PC_TYPE PROC far
 push AX
 push ES
 mov AX, 0F000h
 mov ES, AX
 mov AL, ES:[0FFFEh]
 cmp AL, 0FFh
 je _PC
 cmp AL, 0FEh
 je _PC_XT
 cmp AL, 0FDh
 je _PCjr
 cmp AL, 0FCh
 je _AT
 cmp AL, 0FBh
 je _PC_XT
 cmp AL, 0FAh
 je _PS2_30
 cmp AL, 0F9h
 je _PC_Conv
 cmp AL, 0F8h
 je _PS2_80
 _PC:
  mov DX, offset PC
  jmp end
 _PC_XT:
  mov DX, offset PC_XT
  jmp end
 _PCjr:
  mov DX, offset PCjr
  jmp end
 _AT:
  mov DX, offset AT
  jmp end
 _PS2_30:
  mov DX, offset PS2_30
  jmp end
 _PS2_80:
  mov DX, offset PS2_80
  jmp end
 _PC_Conv:
  mov DX, offset PC_Conv
 end:
  pop ES
  pop AX
  ret
PC_TYPE ENDP

OS_VERSION PROC far
 cmp AL, 0
 je _less_2
 mov SI, offset NUM
 call BYTE_TO_DEC
 mov DL, 2Eh
 add SI, 2
 mov [SI], DL
 inc SI
 mov AL, AH
 call BYTE_TO_DEC
 mov DX, offset NUM
 ret
 _less_2:
  mov DX, offset LESS_2
  ret
OS_VERSION ENDP

OEM PROC far
 mov AL, BH
 mov SI, offset NUM
 add SI, 2
 call BYTE_TO_DEC
 mov DX, offset NUM
 ret
OEM ENDP 

USER_NUM PROC far
 mov AL, BL
 mov DI, offset NUM
 call BYTE_TO_HEX
 mov [DI], AH
 mov [DI+1], AL
 add DI, 5
 mov AX, CX
 call WRD_TO_HEX
 mov DX, offset NUM
 ret
USER_NUM ENDP

PRINT_STR PROC far
 push AX
 mov AH, 09h
 int 21h
 pop AX
 ret
PRINT_STR ENDP

Main PROC far
 mov AX, DATA
 mov DS, AX
 mov AX, 0
 mov DX, offset PC_TYPE_STR
 call PRINT_STR
 call PC_TYPE
 call PRINT_STR
 mov AH, 30h
 int 21h
 mov DX, offset OS_VERSION_STR
 call PRINT_STR
 call OS_VERSION
 call PRINT_STR
 mov DX, offset OEM_STR
 call PRINT_STR
 call OEM
 call PRINT_STR
 mov DX, offset USER_NUM_STR
 call PRINT_STR
 call USER_NUM
 call PRINT_STR 
 xor AL,AL
 mov AH,4Ch
 int 21H
 ret
Main ENDP

CODE ENDS
END MAIN