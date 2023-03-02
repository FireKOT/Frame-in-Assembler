.model tiny

.code
org 100h
locals @@


Exit macro
nop

	mov ax, 4c00h
	int 21h

nop
endm


;<------------------------------------------------>
;
;Draws frame and text into it
;
;Parameters: type_of_frame text
;In text symbol '$' = '\n'
;
;Types of frame: 0 - User's, 1-4 - Standart types
;After 0 must be description of frame in format: color nine_symbols
;
;<------------------------------------------------>


Start:

	mov ax, 0b800h
	mov es, ax

	mov si, 82h

	call GetNum							;Gets type of frame, Destroys: ax, bx
	cmp cx, 0							;0 == user's tamplate

	jle UsersTemplate

		mov ax, offset TemplateHeart
		dec cx
		NextTemplate:

			add ax, 10

		loop NextTemplate
		jmp EndOfTemplateSelection

	UsersTemplate:

		mov ax, ds
		mov es, ax
		
		mov di, offset TemplateUser

		call GetNum
		mov al, cl
		stosb

		mov cx, 9
		NextPar:

			lodsb
			stosb

		loop NextPar

		inc si

		mov ax, 0b800h
		mov es, ax

		mov ax, offset TemplateUser

	EndOfTemplateSelection:	

	mov bx, 80h							;<------------------->	
	xor cx, cx 							;
	mov cl, [bx]						;Gets leth of text that will be print
	add cx, 80h							;
	sub cx, si							;
	inc cx								;<------------------->

	push si								;save next cmd args addr
	push cx								;save lenght of text that will be print

	push ax								;save ax

	call GetExprParams					;Destroys: ax, cx, si

	pop si								;set in si saved ax

	add dl, 6							;Set frame lenght & height
	add dh, 4							;relativly text lenght & height

	mov di, 80d * 25d					;<----------------------------->
										;
	xor ax, ax							;Set text offset to the center of screen
	mov al, dh							;
	shr ax, 1							;
	shl ax, 7							;
	sub di, ax							;
										;
	xor ax, ax							;
	mov al, dh							;
	shr ax, 1							;
	shl ax, 5							;
	sub di, ax							;
										;
	xor ax, ax							;
	mov al, dl							;
	shr ax, 1							;
	shl ax, 1							;
	sub di, ax							;<----------------------------->

	call DrawFrame						;Destroys: ax, bx, cx

	pop cx								;set in cx saved lenght of text that will be print
	pop si								;set in si svaed next cmd args addr

	sub dl, 6							;Return text lenght & height
	sub dh, 4							;save cmd args addr

	call PrintText						;Destroys: al, bx, di

	Exit


;--------------------------------------------------
;DrawFrame 
;--------------------------------------------------
;   Entry: dh = height, dl = lenght, si = template addr, di = offset
;  Assume: es = Vmem addr
;    Exit: si += 10, di += dh * dl
;Destroys: ax, bx, cx
;--------------------------------------------------
DrawFrame proc

	lodsb
	mov ah, al

	call DrawLine

	xor bx, bx
	mov bl, dl
	shl bx, 1
	add di, 160d
	sub di, bx

	xor cx, cx
	mov cl, dh
	sub cx, 2
	@@DrawCenter:
		
		mov bx, cx
		call DrawLine
		mov cx, bx

		xor bx, bx
		mov bl, dl
		shl bx, 1
		add di, 160d
		sub di, bx

		sub si, 3

	loop @@DrawCenter

	add si, 3
	call DrawLine

	ret
endp

;--------------------------------------------------
;DrawLine
;--------------------------------------------------
;   Entry: ah = color, dl = line's length, si = template addr, di = offset
;  Assume: es = Vmem addr
;    Exit: si += dl, di += 3d
;Destroys: al, cx
;--------------------------------------------------
DrawLine proc

	xor cx, cx
	mov cl, dl
	sub cl, 2d

	lodsb
	stosw

	lodsb
	rep stosw

	lodsb
	stosw

	ret
endp

;---------------------------------------
;Print Text
;---------------------------------------
;Entry   : cx = text length, dh = text height, dl = max line length, si = word's addr
;Assume  : es = VMem addr
;Exit    :
;Destroys: al, bx, di
;---------------------------------------
PrintText proc

	mov di, 80d * 25d		;<----------------------------->
							;Set text offset to the center of screen
	xor bx, bx				;
	mov bl, dh				;
	shr bx, 1				;
	shl bx, 7				;
	sub di, bx				;
							;
	xor bx, bx				;
	mov bl, dh				;
	shr bx, 1				;
	shl bx, 5				;
	sub di, bx				;
							;
	xor bx, bx				;
	mov bl, dl				;
	shr bx, 1				;
	shl bx, 1				;
	sub di, bx				;<----------------------------->

	mov bx, di

	@@NextSymbol:

		lodsb

		cmp al, '$'
		jne @@SimpleSymbol

			add bx, 160d
			mov di, bx
			jmp @@EndSymbolAnalys

		@@SimpleSymbol:
	
			stosb
			inc di

		@@EndSymbolAnalys:

	loop @@NextSymbol

ret
endp

;--------------------------------------------------
;GetNum
;--------------------------------------------------
;   Entry: si = addr of num
;  Assume:
;    Exit: cx = entred num
;Destroys: ax, bx
;--------------------------------------------------
GetNum proc

	xor cx, cx

	@@GetDigit:

		xor ax, ax
		lodsb

		cmp al, '0'
		jl @@End
		cmp al, '9'
		ja @@End

		sub al, '0'

		mov bx, cx
		shl cx, 3
		shl bx, 1
		add cx, bx

		add cx, ax

		jmp @@GetDigit

	@@End:
	ret
endp

;--------------------------------------------------
;GetExprParams
;--------------------------------------------------
;   Entry: cx = expr's lenght, si = expr's addr
;  Assume:
;    Exit: dh = height, dl = max lenght, si += expr's lenght
;Destroys: ax, cx, si
;--------------------------------------------------
GetExprParams proc

	xor ax, ax
	xor dx, dx

	@@NextSymbol:

		lodsb
		inc ah
		cmp al, '$'
		jne @@Next
		
		dec ah
		inc dh

		cmp ah, dl
		jbe @@NotLonger

			mov dl, ah

		@@NotLonger:
		xor ah, ah

		@@Next:

	loop @@NextSymbol

	inc dh

	cmp ah, dl
	jbe @@NotLongerLast

		mov dl, ah

	@@NotLongerLast:

	ret
endp


.data


TemplateUser    db 10 dup(0)

TemplateHeart   db 4eh,  03d,  03d,  03d,  03d,  ' ',  03d,  03d,  03d,  03d
TemplateRed     db 4eh,  201d, 205d, 187d, 186d, ' ', 186d, 200d, 205d, 188d
TemplateCrimson db 5eh,  201d, 205d, 187d, 186d, ' ', 186d, 200d, 205d, 188d
TemplateGreen   db 138d, 201d, 205d, 187d, 186d, ' ', 186d, 200d, 205d, 188d


end Start
	