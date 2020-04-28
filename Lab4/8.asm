.model small
.stack 1000
.data
	old dd 0 
.code
.486
 
new_handle proc   
      
        push ds si es di dx cx bx ax      
        xor ax, ax 	
        in        al, 60h        ;Получаем скан-код символа
		
		cmp al, 10h        ;Сравниваем код с кодом буквы q
        je new_handler
        cmp al, 11h        ;Сравниваем код с кодом буквы w
        je new_handler
        cmp al, 13h        ;Сравниваем код с кодом буквы r
        je new_handler
        cmp al, 14h        ;Сравниваем код с кодом буквы t
        je new_handler
        cmp al, 19h        ;Сравниваем код с кодом буквы p
        je new_handler
		cmp al, 1Fh        ;Сравниваем код с кодом буквы s
        je new_handler
        cmp al, 20h        ;Сравниваем код с кодом буквы d
        je new_handler
        cmp al, 21h        ;Сравниваем код с кодом буквы f
        je new_handler
        cmp al, 22h        ;Сравниваем код с кодом буквы g
        je new_handler
        cmp al, 23h        ;Сравниваем код с кодом буквы h
        je new_handler
		cmp al, 24h        ;Сравниваем код с кодом буквы j
        je new_handler
        cmp al, 25h        ;Сравниваем код с кодом буквы k
        je new_handler
        cmp al, 26h        ;Сравниваем код с кодом буквы l
        je new_handler
        cmp al, 2Ch        ;Сравниваем код с кодом буквы z
        je new_handler
        cmp al, 2Dh        ;Сравниваем код с кодом буквы x
        je new_handler
		cmp al, 2Eh        ;Сравниваем код с кодом буквы c
        je new_handler
        cmp al, 2Fh        ;Сравниваем код с кодом буквы v
        je new_handler
        cmp al, 30h        ;Сравниваем код с кодом буквы b
        je new_handler
        cmp al, 31h        ;Сравниваем код с кодом буквы n
        je new_handler
        cmp al, 32h        ;Сравниваем код с кодом буквы m
        je new_handler
		
        jmp old_handler

        new_handler: 
                jmp exit
        
        old_handler: 
                pop ax bx cx dx di es si ds                       
                jmp dword ptr cs:old        ;вызов стандартного обработчика прерывания
                xor ax, ax
                mov al, 20h
                out 20h, al 		
                jmp exit
                
		
        exit:
		    		
                xor ax, ax	
				mov ax,5
                mov al, 20h
                out 20h, al 		
                pop ax bx cx dx di es si ds ;восстановление регистров перед выходом из нашего обработчика прерываний
				
        iret
new_handle endp


 
new_end:
 
start:
        mov ax, @data
        mov ds, ax
		
		
		
        cli ;сброс флага IF 	
        pushf 
		
        push 0        ;перебрасываем значение 0 в DS
        pop ds
        mov eax, ds:[09h*4] 
        mov cs:[old], eax ;сохранение системного обработчика
        		
        mov ax, cs
        shl eax, 16
        mov ax, offset new_handle
        mov ds:[09h*4], eax ;запись нового обработчика
		
        sti ;Установка флага IF     
		
		
        xor ax, ax
        mov ah, 31h
        INT 21H 
        MOV DX, (New_end - @code        + 10FH) / 16 ;вычисление размера резидентной части в параграфах(16 байт)
		
		
		
		
end start