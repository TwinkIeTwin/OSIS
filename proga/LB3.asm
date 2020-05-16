.model small
.stack 256
.data
    errorStr db 'Error!$'
    endLine db 13, 10, '$'
    inputBuffer db '      $'
    outputBuffer db '      $'
    strDiv db '/$'
    strRovno db '=$'
.code
main:
    mov ax, @data
    mov ds, ax
	
    call task	
  endProgram:	
    mov ax, 4c00h
    int 21h	
;*************************************** procedures ***************************************
task:
    call inputWord	
    jc errorBlock      	
    call signWordToStr
    mov di, offset outputBuffer   ;первое число
    call printStr
    call printEndLine
;###	
    mov di, offset strDiv
    call printStr
    call printEndLine
	
    mov bx,ax
	
    mov di, offset inputBuffer
    call clear
    mov di, offset outputBuffer
    call clear
    xor di,di
;###	
    call inputWord
    jc errorBlock 
    call signWordToStr
    mov di, offset outputBuffer  ;второе число 
    call printStr
    call printEndLine
	
    xor dx,dx
    xchg ax,bx 
	cmp bx ,0
    jz errorBlock
	
    cmp ax,0
    jl point1
    jmp point2
    point1:
    cwd
    point2:
    idiv bx 
	
    mov di, offset strRovno
    call printStr
    call printEndLine

    mov di, offset inputBuffer
    call clear
    mov di, offset outputBuffer
    call clear

    call signWordToStr
    mov di, offset outputBuffer
    call printStr
    call printEndLine
    jmp endProgram
  errorBlock:
    mov di, offset errorStr
    call printStr
    call printEndLine
    jmp endProgram
ret
;$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$ очистка буфера $$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$
;ввод DI - адрес буфера		
clear:
  push cx
  mov cx,7 
    povtor:                
      mov [di],' '        ;Сохранение символа в буфере
      inc di              
    loop povtor 		
  pop cx
ret	
;################### вывод на экран #################
printStr: 				;передаётся адрес строки в регистре DI
    push ax	
    mov ah,9                ;Функция DOS 09h - вывод строки
    xchg dx,di  
    int 21h  				;Обращение к функции DOS
    xchg dx,di 
    pop ax
ret
	
printEndLine:          ; = \n
    push di
    mov di, offset endLine
    call printStr
    pop di
ret		
;!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!! превращение слова в строку !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
; AX - слово
; DI - буфер для строки (5 символов(65536)).		
WordToStr:
    push ax
    push bx
    push cx
    push dx
    push di
	
    xor cx,cx               ;Обнуление CX
    mov bx,10               ;В BX делитель (10) 
  remainder:                   ;Цикл получения остатков от деления
    xor dx,dx               ;Обнуление старшей части двойного слова
    div bx                  ;Деление AX остаток в DX
    add dl,'0'              ;Преобразование остатка в код символа
    push dx                 
    inc cx                  ;Увеличение счетчика символов
    test ax,ax              ;Проверка AX
    jnz remainder           		;Переход к началу цикла, если частное не 0.

  extraction:             		;Цикл извлечения символов из стека
    pop dx                  ;Восстановление символа из стека
    mov [di],dl             ;Сохранение символа в буфере
    inc di                  ;Инкремент адреса буфера
    loop extraction         
    pop di
    pop dx
    pop cx
    pop bx
    pop ax
ret	
;Процедура преобразования слова в строку в десятичном виде (со знаком)
; AX - слово
; DI - буфер для строки (6 символов).
signWordToStr:
    push ax
	mov di, offset outputBuffer
    test ax,ax              ;Проверка знака AX
    jns notSign      		;Если >= 0, преобразуем как беззнаковое
    mov [di],'-'            ;Добавление знака в начало строки
    inc di                  ;Инкремент DI
    neg ax                  ;Изменение знака значения AX
    notSign:
    call WordToStr          ;Преобразование беззнакового значения
    pop ax
ret
;@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@ Ввод строки и перевращение в слово @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
	
; Процедура ввода строки c консоли
; вход:  AL - максимальная длина (с символом $) 
; выход: AL - длина введённой строки (не считая символа $)
; DX - адрес строки, заканчивающейся символом $
inputStr:
    push cx                 
    mov cx,ax               ;Сохранение AX в CX
    mov ah,0Ah              ;Функция DOS 0Ah - ввод строки в буфер
    mov [inputBuffer],al        ;Запись максимальной длины в первый байт буфера
    mov byte[inputBuffer+1],0   ;Обнуление второго байта (фактической длины)
    mov dx,offset inputBuffer   
    int 21h                 
    mov al,[inputBuffer+1]      ;AL = длина введённой строки
    add dx,2                ;DX = адрес строки
    mov ah,ch               ;Восстановление AH
    pop cx                  
ret
; Процедура преобразования десятичной строки в слово без знака
; вход: AL - длина строки
; DX - адрес строки, заканчивающейся символом CR(0Dh)
; выход: AX - слово (в случае ошибки AX = 0)
; CF = 1 - ошибка
strToWord:
    push cx                 
    push dx
    push bx
    push si
    push di
 
    mov si,dx               ;SI = адрес строки
    mov di,10               ;DI = множитель 10 (основание системы счисления)
	xor ah,ah
    mov cx,ax 				;CX = счётчик цикла = длина строки
    cmp cx ,0
	jz wordError	        ;Если длина = 0, возвращаем ошибку
    xor ax,ax               ;AX = 0
    xor bx,bx               ;BX = 0
translation:
    mov bl,[si]             ;Загрузка в BL очередного символа строки
    inc si                  ;Инкремент адреса
    cmp bl,'0'              ;Если код символа меньше кода '0'
    jl wordError           ; возвращаем ошибку
    cmp bl,'9'              ;Если код символа больше кода '9'
    jg wordError           ; возвращаем ошибку
    sub bl,'0'              ;Преобразование символа-цифры в число
    mul di                  ;AX = AX * 10
    jc wordError           ;Если результат больше 16 бит - ошибка
    add ax,bx               ;Прибавляем цифру
    jc wordError           ;Если переполнение - ошибка
    loop translation         
    jmp wordExit           ;Успешное завершение (здесь всегда CF = 0)
wordError:
    xor ax,ax               ;AX = 0
    stc                     ;CF = 1 (Возвращаем ошибку) 
wordExit:
    pop di                  
    pop si
    pop bx
    pop dx
    pop cx
ret
;Процедура преобразования десятичной строки в слово со знаком
;  вход: AL - длина строки
;        DX - адрес строки, заканчивающейся символом CR(0Dh)
; выход: AX - слово (в случае ошибки AX = 0)
;        CF = 1 - ошибка
strToSignWord:
    push bx                 
    push dx
 
    test al,al              ;Проверка длины строки
    jz ToSignError          ;Если равно 0, возвращаем ошибку
    mov bx,dx               ;BX = адрес строки
    mov bl,[bx]             ;BL = первый символ строки
    cmp bl,'-'              ;Сравнение первого символа с '-'
    jne notToSign          ;Если не равно, то преобразуем как число без знака
    inc dx                  ;Инкремент адреса строки
    dec al                  ;Декремент длины строки
	
	notToSign:
    call strToWord        ;Преобразуем строку в слово без знака
    jc ToSignExit           ;Если процедура strToWord выдаёт ошибку, то возвращаем ошибку
    cmp bl,'-'              ;Снова проверяем знак
    jne ToSignPlus          ;Если первый символ не '-', то число положительное
    cmp ax,32768            ;Модуль отрицательного числа должен быть не больше 32768
    ja ToSignError          ;Если больше (без знака), возвращаем ошибку
    neg ax                  ;Инвертируем число
    jmp ToSignOk            ;Переход к нормальному завершению процедуры
	
	ToSignPlus:
    cmp ax,32767            ;Положительное число должно быть не больше 32767
    ja ToSignError          ;Если больше (без знака), возвращаем ошибку
 
ToSignOk:
    clc                     ;CF = 0
    jmp ToSignExit          ;Переход к выходу из процедуры
ToSignError:
    xor ax,ax               ;AX = 0
    stc                     ;CF = 1 (Возвращаем ошибку
ToSignExit:
    pop dx                  
    pop bx
ret

;Процедура ввода слова с консоли в десятичном виде (со знаком)
; выход: AX - слово (в случае ошибки AX = 0)
; CF = 1 - ошибка
inputWord:
    push dx                 
    mov al,7                ;Ввод максимум 7 символов (-32768) + конец строки
    call inputStr          ;Вызов процедуры ввода строки
    call strToSignWord   ;Преобразование строки в слово (со знаком)
    pop dx                  
ret	
end main