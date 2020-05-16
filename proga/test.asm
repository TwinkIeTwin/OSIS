.model small
.stack 256
.data
    a dw -4
    b dw -2
    message db 'Hello world!', 13, 10, '$'
.code
main:
    mov ax, @data
    mov ds, ax
    
    mov ax, a
	CWD
    mov bx, b

    idiv bx   
    mov ax, 4c00h
    int 21h
end main