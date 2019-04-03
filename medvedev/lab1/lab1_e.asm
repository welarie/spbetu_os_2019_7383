EOL EQU '$'
AStack SEGMENT STACK
		DW 512 DUP(?)
AStack ENDS

DATA 	SEGMENT
	VersPC	db	'Version PC: $'
	VersMSDOS	db	'Version MS-DOS:  .  ',0DH,0AH,'$'
	NumOEM	db	'Number OEM:   ',0DH,0AH,'$'
	SerNum	db	'Serial Number:       ',0DH,0AH,'$'

	PC 			db 'PC',0DH,0AH,'$'
	PCXT 		db 'PC/XT',0DH,0AH,'$'
	AT 			db 'AT',0DH,0AH,'$'
	PS2_30 		db 'PS2 model 30',0DH,0AH,'$'
	PS2_50_60	db 'PS2 model 50/60',0DH,0AH,'$'
	PS2_80 		db 'PS2 model 80',0DH,0AH,'$'
	PCjr 		db 'PCjr',0DH,0AH,'$'
	PC_Convert 	db 'PC Convertible',0DH,0AH,'$'
DATA	ENDS


CODE	SEGMENT
	ASSUME CS:CODE,	DS:DATA, SS:AStack
Output		PROC FAR
		mov 	ah,09h
		int	21h
		ret
Output		ENDP

TETR_TO_HEX		PROC	FAR
		and	al,0fh
		cmp	al,09
		jbe	NEXT
		add	al,07
NEXT:		add	al,30h
		ret
TETR_TO_HEX		ENDP

BYTE_TO_HEX		PROC FAR
		push	cx
		mov	al,ah
		call	TETR_TO_HEX
		xchg	al,ah
		mov	cl,4
		shr	al,cl
		call	TETR_TO_HEX 	
		pop	cx 		
		ret
BYTE_TO_HEX		ENDP

WRD_TO_HEX		PROC	FAR
		push	bx
		mov	bh,ah
		call	BYTE_TO_HEX
		mov	[di],ah
		dec	di
		mov	[di],al
		dec	di
		mov	al,bh
		xor	ah,ah
		call	BYTE_TO_HEX
		mov	[di],ah
		dec	di
		mov	[di],al
		pop	bx
		ret
WRD_TO_HEX		ENDP

BYTE_TO_DEC		PROC	FAR
		push	cx
		push	dx
		push	ax
		xor	ah,ah
		xor	dx,dx
		mov	cx,10
loop_bd:		div	cx
		or 	dl,30h
		mov 	[si],dl
		dec 	si
		xor	dx,dx
		cmp	ax,10
		jae	loop_bd
		cmp	ax,00h
		jbe	end_l
		or	al,30h
		mov	[si],al
end_l:		pop	ax
		pop	dx
		pop	cx
		ret
BYTE_TO_DEC		ENDP	

PC_VERSION		PROC FAR	

		mov 	bx,0F000h
		mov 	es,bx
		mov 	al,es:[0FFFEh]
		mov	dx,offset VersPC
		call Output
		cmp al,0FFh
		je PC_lab
		cmp al,0FEh
		je PCXT_lab
		cmp al,0FBh
		je PCXT_lab
		cmp al,0FCh
		je AT_lab
		cmp al,0FAh
		je PS2_30_lab
		cmp al,0F8h
		je PS2_80_lab
		cmp al,0FDh
		je PCjr_lab
		cmp al,0F9h
		je PCConvert_lab
		PC_lab:
			mov dx, offset PC
			jmp end_lab
		PCXT_lab:
			mov dx, offset PCXT
			jmp end_lab
		AT_lab:
			mov dx, offset AT
			jmp end_lab
		PS2_30_lab:
			mov dx, offset PS2_30
			jmp end_lab
		PS2_80_lab:
			mov dx, offset PS2_80
			jmp end_lab
		PCjr_lab:
			mov dx, offset PCjr
			jmp end_lab
		PCConvert_lab:
			mov dx, offset PC_Convert
			jmp end_lab

		end_lab:
			call Output
			mov 	ah,30h
			int	21h
			ret


PC_VERSION	ENDP


VERSION_MS_DOS	PROC NEAR	

		lea	si,VersMSDOS
		add	si,16
		call	BYTE_TO_DEC
		add	si,3
		mov 	al,ah
		call   	BYTE_TO_DEC

		ret
VERSION_MS_DOS	ENDP


NUMBER_OEM			PROC FAR

		mov 	al,bh
		lea	si,NumOEM
		add	si,13
		call	BYTE_TO_DEC

		ret
NUMBER_OEM	ENDP


SERIAL_NUMBER	PROC FAR
		mov 	al,bl
		call	BYTE_TO_HEX
		lea	di,SerNum
		add	di,14
		mov 	[di],ax
		mov 	ax,cx
		lea	di,SerNum
		add	di,19
		call	WRD_TO_HEX

		ret
SERIAL_NUMBER		ENDP



Main 			PROC FAR
		
		mov 	ax, DATA
		mov 	ds,ax
		call 	PC_VERSION
		call	VERSION_MS_DOS
		call	NUMBER_OEM
		call	SERIAL_NUMBER

		lea	dx,VersMSDOS
		call	Output	
		lea	dx,NumOEM
		call 	Output	
		lea	dx,SerNum
		call	Output	

		mov 	ah,4ch
		int	21h
		ret
Main 			ENDP
CODE			ENDS		
			END Main
