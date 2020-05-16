.model small
.stack 256
.data
    
	N dw ?
	K dw ?
	M dw ?
	L dw ?
	strLength dw ?
	flag dw 0
	decimalConst dw 10
	arrayA db 50 dup(0)
	arrayB db 50 dup(0)
	arrayC db 50 dup(0)
	enterArrayAMessage db 'Enter first matrix: ',13,10,'$'
	enterArrayBMessage db 'Enter second matrix: ',13,10,'$'
	spaceChar db ' ','$'
	endlSymbol db 13,10,'$'
	errorBlockMessage db 'Something go wrong',13,10,'$'
	exceptionMessage db 'Print something',13,10,'$'
	enterColumnsNumberMessage db 'Print number of columns: ',13,10,'$'
	enterLinesnumberMessage db 'Print number of lines: ',13,10,'$'
	
	
.code

PrintStr proc

	push ax
	
	mov ah,9 
	int 21h
	xor dx,dx
	
	pop ax
	
	ret
PrintStr endp

EnterNumber proc

	push bx
	push cx
	push dx
	push si
	
	xor si,si
	xor bx,bx
	
entering:	
	mov ah,01h
	int 21h
	cmp al,8
	je backspaceChar
	cmp al,13
	je enterChar
	cmp al, '-'
	je minusChar	
	cmp al,'0'
	jb badChar
	cmp al,'9'
	ja badChar
	
	
	xor ah,ah
	sub ax,'0'
	mov cx,ax
	mov ax,bx
	xor dx,dx
	mul decimalConst
	cmp dx,0
	jnz errorBlock 
	add ax,cx
	jc errorBlock
	cmp si,1
	je checkForOverflow 
	cmp ax,32767
	jnbe errorBlock
endEntering:
	mov bx,ax
	jmp entering
	
signCheck:
	cmp si,0
	je clearSymbol
	mov si,0
	jmp clearSymbol
	
checkForOverflow:
	cmp ax,-32768
	jnbe errorBlock
	jmp endEntering
	
backspaceChar:
	test bx,bx
	je signCheck
clearSymbol:
	xchg bx,ax 
	xor dx,dx 
	div decimalConst
	xchg bx,ax 
	call RemoveSymbol
	jmp entering 

enterChar:
	test bx,bx
	je exception 
	cmp si,0
	je toExit
	neg bx
	jmp toExit
	
minusChar:
	cmp bx,0
	jne errorBlock
	cmp si,0
	jne errorBlock
	mov si,1
	jmp entering
	
badChar:
	mov dl,8 
	mov ah,02h 
	int 21h
	call RemoveSymbol
	jmp entering
	
errorBlock:
	xor bx,bx
	mov si,0
	mov dx, offset errorBlockMessage
	call PrintStr
	jmp entering
	
exception:
	mov dx, offset exceptionMessage
	call PrintStr
	jmp entering
	
		
toExit:
	mov ax,bx
	
	pop si
	pop dx
	pop cx
	pop bx
		
	ret
EnterNumber endp

RemoveSymbol proc

	push ax 
	push bx 
	push cx 

	mov ah, 0AH  
	mov bh, 0 
	mov al, ' ' 
	mov cx, 1 
	int 10h 

	pop cx 
	pop bx 
	pop ax
	
	ret 
RemoveSymbol endp

ConvertToStr proc
	
	push bx
	push cx
	push dx

	test ax,ax
	jns continue
	push ax
	mov ah,02h
	mov dx,'-'
	int 21h
	xor ah,ah
	pop ax
	neg ax
	
continue:
	xor cx,cx
convertingFromNumber:
	xor dx,dx
	div decimalConst
	push dx
	inc cx
	test ax,ax
	jnz convertingFromNumber
	
convertingToStr:
	mov ah,02h
	pop dx
	add dx,'0'
	int 21h
	loop convertingToStr
	
	pop dx
	pop cx
	pop bx

	ret
ConvertToStr endp

EnterMatrix proc

	push ax
	push cx
	push bx
	push dx
	
	cmp flag,0
	je firstMatrix
	
	lea dx,enterArrayBMessage
	call PrintStr
	jmp repeatFirstNumber
	
firstMatrix:
	lea dx,enterArrayAMessage
	call PrintStr
	
repeatFirstNumber:
	xor ax,ax
	lea dx,enterLinesNumberMessage
	call PrintStr
	call EnterNumber
	cmp ax,0
	jle	repeatFirstNumber
	
	cmp flag,0
	je firstMatrixN
	
	mov L,ax
	xor ax,ax
	jmp repeatSecondNumber
	
firstMatrixN:
	mov N,ax
	xor ax,ax
	
repeatSecondNumber:
	lea dx,enterColumnsNumberMessage
	call PrintStr
	call EnterNumber
	cmp ax,0
	jle repeatSecondNumber
	
	cmp flag,0
	je firstMatrixK
	
	mov M,ax
	xor ax,ax
	jmp continueEntering
	
firstMatrixK:	
	mov K,ax
	xor ax,ax
	
continueEntering:

	cmp flag,0
	je firstMatrixArray

	
	

	
	
	
	
firstMatrixArray:
	mov ax,N
	mov bx,K
	xor dx,dx
	mul bx
	mov cx,ax
	lea si,arrayA

enteringArray:
	call EnterNumber
	mov [si],ax
	inc si
	loop enteringArray
	
	inc flag
	
	pop dx
	pop bx
	pop cx
	pop ax

	ret
EnterMatrix endp

PrintMatrix proc

	push ax
	push cx
	push bx
	push dx
	
	xor ax,ax
	xor bx,bx
	xor cx,cx
	xor si,si
	xor dx,dx
	
	cmp flag,0
	je PrintArrayA
	cmp flag,1
	je PrintArrayB
	cmp flag,2
	je PrintArrayC
	
PrintArrayA:
	mov ax,N
	mov [strLength],ax
	mul bx
	mov cx,ax
	mov ax,N
	;mov strLength,ax  ;Ты ведь уже присвоил нужное значение в strLength
	lea si,arrayA
	jmp printingArray
	
PrintArrayB:
	mov ax,L
	mov [strLength],ax
	mov bx,M
	mul bx
	mov cx,ax
	lea si, arrayB
	jmp printingArray
	
PrintArrayC:
	mov ax,N
	mov [strLength],ax
	mov bx,M
	mul bx
	mov cx,ax
	lea si, arrayC
	
printingArray:	
	xor ax,ax
	mov ax,[si]
	call ConvertToStr
	lea dx,spaceChar
	call PrintStr
	inc si
	mov ax,cx
	div [strLength]
	cmp dx,0
	je printEndl
	xor dx,dx
	loop printingArray
	jmp exitFromPrinting
	
printEndl:
	xor dx,dx
	lea dx,endlSymbol
	call PrintStr
	jmp printingArray
	
	
	
exitFromPrinting:	
	pop dx
	pop bx
	pop cx
	pop ax
	
	ret
PrintMatrix endp	

main:

	mov ax,@data
	mov ds,ax
	xor ax,ax
	
	call EnterMatrix
	call PrintMatrix
	

	mov ax, 4C00h
	int 21h

end main