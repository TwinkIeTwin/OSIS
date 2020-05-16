model small
.stack 256
.data
	string db 'Hello hEllP Me World 2312+- 98 ,.', 13,10,'$'
.code
main:
	mov ax, @data
    mov ds, ax
    mov es, ax

	xor ax,ax
	lea dx,string
	mov ah,9
	int 21h
	
    mov ax, 4c00h
    int 21h   
end main	