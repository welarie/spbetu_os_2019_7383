EOL EQU '$'

DATA    SEGMENT
PC_TYPE            db        'PC type: $'
STM_VER            db        0dh,0ah,'System version:  .  ',0dh,0ah,'$'
OEM_NUM            db        'OEM number:      ',0dh,0ah,'$'
SRL_NUM            db        'User serial number:              ',0dh,0ah,'$'
TYPE_PS2_80     db      'PS2 model 80 $'
TYPE_PC_Con     db      'PC Convertible $'
TYPE_PS2_30     db      'PS2 model 30 $'
TYPE_PC_XT      db      'PC/XT $'
TYPE_AT         db      'AT $'
TYPE_PCjr       db      'PCjr $'
TYPE_PC         db      'PC $'
DATA ENDS

CODE    SEGMENT
ASSUME CS:CODE, DS:DATA, SS:AStack
Write_msg        PROC    FAR
mov        ah,09h
int        21h
ret
Write_msg        ENDP

AStack    SEGMENT  STACK
DW 512 DUP(?)
AStack  ENDS

TETR_TO_HEX        PROC    FAR
and        al,0fh
cmp        al,09
jbe        NEXT
add        al,07
NEXT:    add        al,30h
ret
TETR_TO_HEX        ENDP

BYTE_TO_HEX        PROC FAR
push    cx
mov        al,ah
call    TETR_TO_HEX
xchg    al,ah
mov        cl,4
shr        al,cl
call    TETR_TO_HEX
pop        cx
ret
BYTE_TO_HEX        ENDP

WRD_TO_HEX        PROC    FAR
push    bx
mov        bh,ah
call    BYTE_TO_HEX
mov        [di],ah
dec        di
mov        [di],al
dec        di
mov        al,bh
xor        ah,ah
call    BYTE_TO_HEX
mov        [di],ah
dec        di
mov        [di],al
pop        bx
ret
WRD_TO_HEX        ENDP

BYTE_TO_DEC        PROC    FAR
push    cx
push    dx
push    ax
xor        ah,ah
xor        dx,dx
mov        cx,10
loop_bd:div        cx
or         dl,30h
mov     [si],dl
dec     si
xor        dx,dx
cmp        ax,10
jae        loop_bd
cmp        ax,00h
jbe        end_l
or        al,30h
mov        [si],al
end_l:    pop        ax
pop        dx
pop        cx
ret
BYTE_TO_DEC        ENDP

SET_PC_TYPE    PROC    FAR
push     es
push    bx
push    ax
push    dx
mov     bx,0f000h
mov     es,bx
mov     ax,es:[0fffeh]
lea     dx, PC_TYPE
cmp     al,0f8H
je      set_PS2_80
cmp     al,0f9h
je      set_PC_Con
cmp     al,0fah
je      set_PS2_30
cmp     al,0fbh
je      set_PC_XT
cmp     al,0fch
je      set_AT
cmp     al,0fdh
je      set_PCjr
cmp     al,0ffh
je      set_PC
mov     ah,al
call    BYTE_TO_HEX
lea     bx, PC_TYPE
mov     [bx+9],ax
call    Write_msg
jmp     PC_TYPE_SET
set_PS2_80:call    Write_msg
mov     dx, OFFSET TYPE_PS2_80
call    Write_msg
jmp     PC_TYPE_SET
set_PC_Con:call    Write_msg
mov     dx, OFFSET TYPE_PC_Con
call    Write_msg
jmp     PC_TYPE_SET
set_PS2_30:call    Write_msg
mov     dx, OFFSET TYPE_PS2_30
call    Write_msg
jmp     PC_TYPE_SET
set_PC_XT:call    Write_msg
mov     dx, OFFSET TYPE_PC_XT
call    Write_msg
jmp     PC_TYPE_SET
set_AT:call    Write_msg
mov     dx, OFFSET TYPE_AT
call    Write_msg
jmp     PC_TYPE_SET
set_PCjr:call    Write_msg
mov     dx, OFFSET TYPE_PCjr
call    Write_msg
jmp     PC_TYPE_SET
set_PC:call    Write_msg
mov     dx, OFFSET TYPE_PC
call    Write_msg
jmp     PC_TYPE_SET
PC_TYPE_SET:
pop dx
pop        ax
pop        bx
pop        es
ret
SET_PC_TYPE    ENDP

SET_STM_VER    PROC    FAR
push    ax
push     si
lea        si,STM_VER
add        si,18
call    BYTE_TO_DEC
add        si,3
mov     al,ah
call    BYTE_TO_DEC
pop     si
pop     ax
ret
SET_STM_VER    ENDP

SET_OEM_NUM        PROC    FAR
push    ax
push    bx
push    si
mov     al,bh
lea        si,OEM_NUM
add        si,14
call    BYTE_TO_DEC
pop        si
pop        bx
pop        ax
ret
SET_OEM_NUM        ENDP

SET_SRL_NUM        PROC    FAR
push    ax
push    bx
push    cx
push    si
mov        al,bl
call    BYTE_TO_HEX
lea        di,SRL_NUM
add        di,22
mov        [di],AX
mov        ax,cx
lea        di,SRL_NUM
add        di,27
call    WRD_TO_HEX
pop        si
pop        cx
pop        bx
pop        ax
ret
SET_SRL_NUM        ENDP
Main              PROC  FAR
push      DS
sub       AX,AX
push      AX
mov       AX,DATA
mov       DS,AX
sub       AX,AX
call     SET_PC_TYPE
mov        ah,30h
int        21h
call    SET_STM_VER
call    SET_OEM_NUM
call    SET_SRL_NUM

lea        dx,STM_VER
call    Write_msg
lea        dx,OEM_NUM
call    Write_msg
lea        dx,SRL_NUM
call    Write_msg
xor        al,al
mov        ah,3Ch
int        21h
ret
Main            ENDP
CODE            ENDS
END Main
