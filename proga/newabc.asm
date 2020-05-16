.model large
.386p


;_______________________________________________________R-MODE CODE_____________________________________________________________________

CODE_RM segment para use16                      	 ;Сегмент кода реального режима       
CODE_RM_BEGIN   = $
    assume cs:CODE_RM,DS:DATA,ES:DATA           	 ;Инициализация регистров для ассемблирования

start:
		mov 	ax, DATA                              ;Инициализиция сегментных регистров
	    mov 	ds, ax                                   
	    mov		es, ax 

		mov 	ax, 03		;clear screen
		int 	10h
		mov     ah, 9
	    mov     dx, offset msg 				;Press any key to enter the p-mode.
	    int     21h

		mov     ah, 0						;reading key
	    int     16h

enable_a20:
    in  	al, 92h                     ;открыть адресную линию A20 для поддержки работы в p-mode (+сегмент памяти выше границы первого мб(обл. старш.пам.))                                       
    or  	al, 2                       ;установить бит 1 в 1                                                   
    out 	92h, al    

save_masks:                             ;Сохранить маски прерываний (Байты команды маскирования запросов прерывания выводятся соответственно в порты 21h и A1h)    
    in      al, 21h
    mov     int_mask_master, al                  
    in      al ,0A1h
    mov     int_mask_slave, al  

disable_interrupts:
    cli									;запрет маскируемых прерываний
    in      al, 70h						;запрет немаскируемых прерываний (обращение к порту 70h)
    or      al, 80h 					;изменение старшего бита порта
    out     70h, al

load_GDT:                               ;Заполнить глобальную таблицу дескрипторов     
; Формируем в dl:ax физический адрес, соответствующий сегментному адресу DATA       
    mov 	ax, DATA
    mov 	dl, ah
    xor 	dh, dh
    shl 	ax, 4						;линейный сдвиг на 4 бита
    shr 	dx, 4
    mov 	si, ax
    mov 	di, dx

; процедуры  write_x = для вычисления физического адреса и записи его в дескриптор

write_GDT:                                      ;Заполнить дескриптор GDT
    lea 	bx, GDT_GDT							
    mov 	ax, si
    mov 	dx, di
    ; Складываем со смещением
    add 	ax, offset GDT
    adc 	dl, 0
    ; Записываем физический адрес GDT в элемент GDT, описывающий саму GDT
    mov 	[bx][segment_descriptor.base_low], ax 		
    mov 	[bx][segment_descriptor.base_medium], dl
    mov 	[bx][segment_descriptor.base_high], dh	

write_code_RM:                                  ;Заполнить дескриптор сегмента кода реального режима
    lea 	bx, GDT_CODE_RM
    mov 	ax, cs
    xor 	dh, dh
    ; Формируем в dl:ax физический адрес, соответствующий сегментному адресу CODE_RM
    mov 	dl, ah
    shl 	ax, 4		
    shr 	dx, 4
    ; заполнение сегмента
    mov 	[bx][segment_descriptor.base_low], ax
    mov 	[bx][segment_descriptor.base_medium], dl
    mov 	[bx][segment_descriptor.base_high], dh

write_data:                                     ;Записать дескриптор сегмента данных
    lea 	bx, GDT_DATA
    mov 	ax, si
    mov 	dx, di
    ; заполнение сегмента
    mov 	[bx][segment_descriptor.base_low], ax
    mov		[bx][segment_descriptor.base_medium], dl
    mov 	[bx][segment_descriptor.base_high], dh

write_stack:                                    ;Записать дескриптор сегмента стека
    lea 	bx, GDT_STACK
    mov 	ax, ss
    xor 	dh, dh
    ; Формируем в dl:ax физический адрес, соответствующий сегментному адресу стека
    mov 	dl, ah
    shl 	ax, 4
    shr 	dx, 4
    ; заполнение сегмента
    mov 	[bx][segment_descriptor.base_low], ax
    mov 	[bx][segment_descriptor.base_medium], dl
    mov 	[bx][segment_descriptor.base_high], dh

write_code_PM:                                  ;Записать дескриптор кода защищенного режима
    lea 	bx, GDT_CODE_PM
    mov 	ax, CODE_PM
    xor 	dh, dh
    ; Формируем в dl:ax физический адрес, соответствующий сегментному адресу CODE_PM
    mov 	dl, ah 		
    shl 	ax, 4
    shr 	dx, 4
    ; заполнение сегмента
    mov 	[bx][segment_descriptor.base_low], ax
    mov 	[bx][segment_descriptor.base_medium], dl
    mov 	[bx][segment_descriptor.base_high], dh        
    or  	[bx][segment_descriptor.attributes], 40h

write_IDT:                                      ;Записать дескриптор IDT
    lea bx,GDT_IDT
    mov ax,si
    mov dx,di
    ; Формируем в dl:ax физический адрес, соответствующий сегментному адресу IDT
    ; Складываем со смещением
    add ax,offset IDT
    adc dx,0
    ; заполнение сегмента
    mov [bx][segment_descriptor.base_low],ax
    mov [bx][segment_descriptor.base_medium],dl
    mov [bx][segment_descriptor.base_high],dh        
    mov IDTR.IDT_low,ax
    mov IDTR.IDT_high,dx

fill_idt:   									;Заполнить таблицу дескрипторов шлюзов прерываний

    irpc    N, 0123456789ABCDEF                 ;Заполнить шлюзы 00-0F исключениями
        lea 	eax, EXC_0&N
        mov 	IDT_0&N.offset_low, ax
        shr 	eax, 16
        mov 	IDT_0&N.offset_high, ax
    endm

    irpc    N, 0123456789ABCDEF                 ;Заполнить шлюзы 10-1F исключениями
        lea 	eax, EXC_1&N
        mov 	IDT_1&N.offset_low, ax
        shr 	eax, 16
        mov 	IDT_1&N.offset_high, ax
    endm

    lea 	eax, DUMMY_IRQ_MASTER
    mov 	IDT_20.offset_low, AX
    shr 	eax, 16
    mov 	IDT_20.offset_high, AX

    lea 	eax, KEYBOARD_HANDLER                   ;Поместить обработчик прерывания клавиатуры на 21 шлюз
    mov 	IDT_KEYBOARD.offset_low, ax
    shr 	eax, 16
    mov 	IDT_KEYBOARD.offset_high, ax

    irpc    N, 234567                           ;Заполнить вектора 22-27 заглушками
        lea 	eax, DUMMY_IRQ_MASTER
        mov 	IDT_2&N.offset_low, AX
        shr 	eax, 16
        mov 	IDT_2&N.offset_high, AX
    endm

    irpc    N, 89ABCDEF                         ;Заполнить вектора 28-2F заглушками
        lea eax, DUMMY_IRQ_SLAVE
        mov IDT_2&N.offset_low, ax
        shr eax, 16
        mov IDT_2&N.offset_high, ax
    endm

    lgdt fword ptr GDT_GDT                      ;Загрузить регистр GDTR
    											;Так как дескриптор с адресом gdt_gdt описывает саму таблицу GDT
    											; (и формат этого дескриптора подходит для команды LGDT)
    lidt fword ptr IDTR                         ;Загрузить регистр IDTR

enter_pmodeode:
    mov     eax, cr0							;установить нулевой бит cr0
    or      al, 00000001b 
    mov     cr0, eax

overload_cs:                                    ;Перезагрузить сегмент кода на его дескриптор
    db  0EAH 									; Команда far jmp CODE_RM_DESC:CS
    dw  $+4
    dw  CODE_RM_DESC        

overload_segment_registers:                     ;Переинициализировать остальные сегментные регистры на дескрипторы
    mov 	ax, DATA_DESC
    mov 	ds, ax                         
    mov 	es, ax                         
    mov 	ax, STACK_DESC
    mov 	ss, ax                         
    xor 	ax, ax
    mov 	fs, ax                                 ;Обнулить регистр fs
    mov 	gs, ax                                 ;Обнулить регистр gs
    lldt 	ax                                     ;Обнулить регистр LDTR - не использовать таблицы локальных дескрипторов

prepare_to_return:
    push 	cs                                      ;Сегмент кода
    push 	offset back_to_rmode                    ;Смещение точки возврата
    lea  	edi, enter_pmode                        ;Получить точку входа в защищенный режим
    mov  	eax, CODE_PM_DESC                       ;Получить дескриптор кода защищенного режима
    push 	eax                                     ;Занести их в стек
    push 	edi

reinit_controller_for_pmode:               			 ;Переинициализировать контроллер прерываний на вектора 20h, 28h
    mov 	al, 00010001b                            ;ICW1 - переинициализация контроллера прерываний
    out 	20h, al                                  ;Переинициализируем ведущий контроллер
    out 	0A0h, al                                 ;Переинициализируем ведомый контроллер
    mov 	al, 20h                                  ;ICW2 - номер базового вектора прерываний
    out 	21h, al                                  ;ведущего контроллера
    mov 	al, 28h                                  ;ICW2 - номер базового вектора прерываний
    out 	0A1h, al                                 ;ведомого контроллера
    mov 	al, 04h                                  ;ICW3 - ведущий контроллер подключен к 3 линии
    out 	21h, al       
    mov 	al, 02h                                  ;ICW3 - ведомый контроллер подключен к 3 линии
    out 	0A1h, al      
    mov 	al, 11h                                  ;ICW4 - режим специальной полной вложенности для ведущего контроллера
    out 	21h, al        
    mov 	al, 01h                                  ;ICW4 - режим обычной полной вложенности для ведомого контроллера
    out 	0A1h, al       
    mov 	al, 0                                    ;Размаскировать прерывания
    out 	21h, al                                  ;Ведущего контроллера
    out 	0A1h, al                                 ;Ведомого контроллера


enable_interrupts:
    in      al, 70h			 ;разрешение немаскируемых прерываний
    and     al, 01111111b 	 ; сброс бита 7 отменяет блокирование NMI
    out     70h, al
    sti						 ;разрешение маскируемых прерываний
                                   
go_to_pmode_code:            ;Переход к сегменту кода защищенного режима
    db 	66h                                      
    retf

back_to_rmode:                                      ;Точка возврата в реальный режим
    cli                                             ;Запрет маскируемых прерываний
    in  	al, 70h	                                ;И не маскируемых прерываний
	or		AL, 10000000b                           ;Установить 7 бит в 1 для запрета немаскируемых прерываний
	out		70h, AL

reinit_controller:                      			 ;Переиницализация контроллера прерываний               
    mov 	al, 00010001b                            ;ICW1 - переинициализация контроллера прерываний
    out 	20h, al                                  ;Переинициализируем ведущий контроллер
    out 	0A0h, al                                 ;Переинициализируем ведомый контроллер
    mov 	al, 8h                                   ;ICW2 - номер базового вектора прерываний
    out 	21h, al                                  ;ведущего контроллера
    mov 	al, 70h                                  ;ICW2 - номер базового вектора прерываний
    out 	0A1h, al                                 ;ведомого контроллера
    mov 	al, 04h                                  ;ICW3 - ведущий контроллер подключен к 3 линии
    out 	21h, al       
    mov 	al, 02h                                  ;ICW3 - ведомый контроллер подключен к 3 линии
    out 	0A1h, al      
    mov 	al, 11h                                  ;ICW4 - режим специальной полной вложенности для ведущего контроллера
    out 	21h, al        
    mov 	al, 01h                                  ;ICW4 - режим обычной полной вложенности для ведомого контроллера
    out 	0A1h, al

prepare_segments:                   	             ;Подготовка сегментных регистров для возврата в реальный режим          
    mov 	GDT_CODE_RM.limit, 0FFFFh                ;Установка лимита сегмента кода в 64KB
    mov 	GDT_DATA.limit, 0FFFFh                   ;Установка лимита сегмента данных в 64KB
    mov 	GDT_STACK.limit, 0FFFFh                  ;Установка лимита сегмента стека в 64KB
    db  	0EAH                                     ;Перезагрузить регистр cs
    dw  	$+4
    dw  	CODE_RM_DESC                             ;На сегмент кода реального режима
    mov 	ax, DATA_DESC                            ;Загрузим сегментные регистры дескриптором сегмента данных
    mov 	ds, ax                                   
    mov 	es, ax                                   
    mov 	fs, ax                                   
    mov 	gs, ax                                   
    mov 	ax, STACK_DESC
    mov 	ss, ax      


enable_real_mode:
    mov     eax, cr0				;сброс нулевого бита cr0 => переход в реальный режим
    and     al, 11111110b			; нулевой бит в 0
    mov     cr0, eax
    db  	0EAH
    dw  	$+4
    dw  	CODE_RM                 ;Перезагрузим регистр кода
    mov 	ax, STACK_A
    mov 	ss, ax                      
    mov 	ax, DATA
    mov 	ds, ax                      
    mov		es, ax
    xor 	ax, ax
    mov 	fs, ax
    mov 	gs, ax
    mov 	IDTR.limit, 3FFH                
    mov 	dword ptr  IDTR+2, 0            
    lidt 	fword ptr IDTR    

repair_mask_of_int:                       	        ;Восстановить маски прерываний
    mov 	al, int_mask_master
    out 	21h, al                              	;Ведущего контроллера
    mov 	al,	 int_mask_slave
    out 	0A1h, al            

disable_a20:                                        ;закрыть вентиль A20
    in 	 	al, 92h
    and 	al, 11111101b                            ;обнулить 1 бит - запретить линию A20
    out 	92h, al

exit:
	mov 	ax, 03		;clear screen
	int 	10h
	mov     ah, 9
    mov     dx, offset msg2 		
    int     21h

key proc near
	mov 	ah, 2
    int 	16h
    test    al, 2
    jnz 	start			 	; нажат левый шифт
    mov 	ah, 1
    int 	16h
    jz  	key 				; переход на начало подпрограммы, если ничего не нажато
    mov 	ah, 0				; что-то нажато
    int 	16h
key endp

	mov 	ax, 4C00h
    int 	21H  
	.exit
    ret

SIZE_CODE_RM    = ($ - CODE_RM_BEGIN)           ;Лимит сегмента кода реального режима
CODE_RM ends
;____________________________________________________________________________________________________________________________




;_______________________________________________P-MODE CODE__________________________________________________________________

CODE_PM  segment para use32
CODE_PM_BEGIN   = $
    assume cs:CODE_PM,ds:DATA,es:DATA      		    ;Указание сегментов для компиляции

    enter_pmode:                                    ;Точка входа в защищенный режим                   
    call 	clear_console                                  ;call clear_console     
	xor  	edi, edi                                ;В edi смещение на экране
    lea  	esi, mg                 				;В esi адрес буфера
    call 	print_from_buffer                           ;Вывести строку-приветствие в защищенном режиме  
	
reaction_waiting:                                 	    ;Ожидание нажатия кнопки выхода из защищенного режима
    jmp  	reaction_waiting                            ;Если был нажата не клавиша выхода

quit_pmode:                                        ;Точка выхода из 32-битного сегмента кода    
    db 		66H
    retf                                       	   ;Переход в 16-битный сегмент кода

quit_pmode_from_int:                               ;Точка выхода для выхода напрямую из обработчика прерываний
    popad 										   ; восстанавливает содержимое всех регистров общего назначени
    pop 	es
    pop 	ds
    pop 	eax                                     ;Снять со стека старый EIP (он указывает на текущую исполняемую инструкцию процессора.)
    pop 	eax                                     ;CS  
    pop 	eax                                     ;И EFLAGS
    sti                                         	;Обязательно, без этого обработка аппаратных прерываний отключена
    db 		66H
    retf        									;Переход в 16-битный сегмент кода    

M = 0                           
IRPC N0, 0123456789ABCDEF
EXC_0&N0 label word                              ;Обработчики исключений
    cli 
    jmp EXC_HANDLER
endm

M = 010H
IRPC N1, 0123456789ABCDEF                        ;Обработчики исключений
EXC_1&N1 label word                          
    cli
    jmp EXC_HANDLER
endm

EXC_HANDLER proc near      		                    ;Процедура вывода обработки исключений
    lea  	esi, MSG_EXC
    mov  	edi, 40*2
    call 	print_from_buffer                   	    ;Вывод предупреждения
    pop 	eax                                     ;Снять со стека старый EIP
    pop 	eax                                     ;CS  
    pop 	eax                                     ;И EFLAGS
    db 		66H
    retf                                        ;Переход в 16-битный сегмент кода    
EXC_HANDLER     ENDP

DUMMY_IRQ_MASTER proc near                      ;Заглушка для аппаратных прерываний ведущего контроллера
    push 	eax
    mov  	al, 20h
    out  	20h, al
    pop  	eax
    iretd
DUMMY_IRQ_MASTER endp

DUMMY_IRQ_SLAVE  proc near                      ;Заглушка для аппаратных прерываний ведомого контроллера
    push 	eax
    mov  	al, 20h
    out  	0A0h, al
    pop  	eax
    iretd
DUMMY_IRQ_SLAVE  endp

KEYBOARD_HANDLER proc near                      ;Обработчик прерывания клавиатуры
    push 	ds
    push 	es
    pushad                                      ;Сохранить расширенные регистры общего назначения
    in   al, 60h                                ;Считать скан код последней нажатой клавиши                                ;
    
    cmp  al, 1                         		    ;Если была нажата кнопка выхода
    je   KEYBOARD_EXIT                          ;Тогда на выход из защищенного режима    
    jmp  KEYBOARD_RETURN  

KEYBOARD_EXIT:
    mov  al,20h
    out  20h,al
    db 0eah
    dd OFFSET quit_pmode_from_int 
    dw CODE_PM_DESC  

KEYBOARD_RETURN:
    mov  	al, 20h
    out  	20h, al                             ;Отправка сигнала контроллеру прерываний
    popad                                       ;Восстановить значения регистров
    pop 	es
    pop 	ds
    iretd                                       ;Выход из прерывания
KEYBOARD_HANDLER endp

clear_console  proc near                            ;Процедура очистки консоли
    push 	es
    pushad 											;Поместить в стек значения всех 32-битных регистров общего назначения
    mov  	ax, TEXT_DESC                           ;Поместить в ax дескриптор текста
    mov  	es, ax
    xor  	edi, edi
    mov  	ecx, 80*25                              ;Количество символов в окне
    mov  	ax, 700h
    rep  	stosw									; сохранить элементы строки слов
    popad
    pop  	es
    ret
clear_console  endp

print_from_buffer proc near                         ;Процедура вывода текстового буфера, оканчивающегося 0
    push 	es
    pushad
    mov  	ax, TEXT_DESC                       ;Поместить в es селектор текста
    mov  	es, ax

printing:                                    ;Цикл по выводу буфера
    lodsb                                     ; загрузка строкового операнда в al  
    or   	al, al
    jz  	end_printing                         ;Если дошло до 0, то конец выхода
    stosb
    inc  	edi
    jmp  	printing

end_printing:                                    ;Выход из процедуры вывода
    popad
    pop  	es
    ret
print_from_buffer ENDP


SIZE_CODE_PM     =       ($ - CODE_PM_BEGIN)
CODE_PM  ENDS


;____________________________________________________________________________________________________________________________






;Сегмент данных реального/защищенного режима_________________________________________________________________________________
DATA    segment para use16                      ;Сегмент данных реального/защищенного режима
DATA_BEGIN      = $

	;____________________СТРУКТУРА СЕГМЕТНОГО ДЕСКРИПТОРА_____________________________
	segment_descriptor  struc              ;cтруктура сегментного дескриптора (задает смещение последующего сегмента относительно предыдущего)
	    limit           dw 0               ;лимит сегмента  
	    base_low        dw 0               ;адрес базы, младшая часть (база - адрес начала сегмента)
	    base_medium     db 0               ;адрес базы, средняя часть
	    access          db 0               ;тип дескриптора: байт доступа (доступность/присутствие(0-1), уровень защиты(0-3), тип - системный(0)/пользовательский(1))
	    attributes      db 0               ;лимит сегмента и атрибуты
	    base_high       db 0               ;адрес базы, старшая часть
	segment_descriptor  ends  
	;_________________________________________________________________________________


	;_________________СТРУКТУРА ДЕСКРИПТОРА ТАБЛИЦЫ ПРЕРЫВАНИЙ________________________
	interrupt_descriptor struc                ;cтруктура дескриптора таблицы прерываний
	    offset_low      dw 0                  ;aдрес обработчика
	    selector        dw 0                  ;cелектор кода, содержащего код обработчика
	    params_count    db 0                  ;параметры
	    access          db 0                  ;уровень доступа
	    offset_high     dw 0                  ;адрес обработчика
	interrupt_descriptor  ends        
	;_________________________________________________________________________________



	;___________________СТРУКТУРА ТАБЛИЦЫ ВЕКТОРОВ ПРЕРЫВАНИЙ__________________________
	R_IDTR  struc                         ;структура IDTR (таблицы векторов прерываний)
	    limit       dw 0                  ; предел IDT
	    IDT_low     dw 0                  ;смещение биты (0-15) (мл. слово физического адреса)
	    IDT_high    dw 0                  ;смещение биты (31-16) ( ст. байт физического адреса)
	R_IDTR  ends
	;_________________________________________________________________________________


    ;________________________GDT - глобальная таблица дескрипторов_______________________
    GDT_BEGIN   = $
    GDT label       word                        									;Метка начала GDT
    GDT_0           segment_descriptor <0,0,0,0,0,0>   								;Самый первый дескриптор в таблицах GDT и LDT никогда не используется                           
    GDT_GDT         segment_descriptor <GDT_SIZE-1,,,ACS_DATA,0,>                 	;описание таблицы GDT
    GDT_CODE_RM     segment_descriptor <SIZE_CODE_RM-1,,,ACS_CODE,0,>             
    GDT_DATA        segment_descriptor <SIZE_DATA-1,,,ACS_DATA+ACS_DPL_3,0,>   
    GDT_STACK       segment_descriptor <1000h-1,,,ACS_DATA,0,>                    
    GDT_TEXT        segment_descriptor <2000h-1,8000h,0Bh,ACS_DATA+ACS_DPL_3,0,0> 
    GDT_CODE_PM     segment_descriptor <SIZE_CODE_PM-1,,,ACS_CODE+ACS_READ,0,>    
    GDT_IDT         segment_descriptor <SIZE_IDT-1,,,ACS_IDT,0,>                                      
    GDT_SIZE        = ($ - GDT_BEGIN)               								;Размер GDT
    																				; для проверки правильности задаваемых программой селекторов.
    																				; Поле индекса селектора должно содержать ссылки только на существующие элементы таблицы GDT
    																				; в противном случае произойдет прерывание.
    

    ;______________________________Селекторы сегментов_____________________________________
    CODE_RM_DESC    = (GDT_CODE_RM - GDT_0)
    DATA_DESC       = (GDT_DATA - GDT_0)+ 3  
    STACK_DESC      = (GDT_STACK - GDT_0)       
    TEXT_DESC       = (GDT_TEXT - GDT_0)+ 3
    CODE_PM_DESC    = (GDT_CODE_PM - GDT_0)     
    IDT_DESC        = (GDT_IDT - GDT_0)         


    ;_____________________________IDT - таблица дескрипторов прерываний_____________________________________
    ; содержит дескрипторы для обработчиков исключений и аппаратных прерываний

    IDTR    R_IDTR  <SIZE_IDT,0,0>                  ;Формат регистра ITDR   
    IDT label   word                                ;Метка начала IDT
    IDT_BEGIN   = $

    IRPC    N, 0123456789ABCDEF
        IDT_0&N interrupt_descriptor <0, CODE_PM_DESC,0,ACS_TRAP,0>            ; 00...0F
    ENDM

    IRPC    N, 0123456789ABCDEF
        IDT_1&N interrupt_descriptor <0, CODE_PM_DESC, 0, ACS_TRAP, 0>         ; 10...1F
    ENDM

    IDT_20    interrupt_descriptor <0,CODE_PM_DESC,0,ACS_INT,0>             ;IRQ 0 - прерывание системного таймера

    IDT_KEYBOARD interrupt_descriptor <0,CODE_PM_DESC,0,ACS_INT,0>             ;IRQ 1 - прерывание клавиатуры

    IRPC    N, 23456789ABCDEF
        IDT_2&N         interrupt_descriptor <0, CODE_PM_DESC, 0, ACS_INT, 0>  ; 22...2F
    ENDM

    SIZE_IDT        =       ($ - IDT_BEGIN)

    ;___________________________________________ФЛАГИ УРОВНЕЙ ДОСТУПА_________________________
		    ;Флаги уровней доступа сегментов
		ACS_PRESENT     EQU 10000000B        				;PXXXXXXX - бит присутствия, сегмент присутствует в оперативной памяти           
		ACS_CSEG        EQU 00011000B                  		;XXXXIXXX - тип сегмента, для данных = 0, для кода 1
		ACS_DSEG        EQU 00010000B                  		;XXXSXXXX - бит сегмента, данный объект сегмент(системные объекты могут быть не сегменты)                
		ACS_READ        EQU 00000010B                 	 	;XXXXXXRX - бит чтения, возможность чтения из другого сегмента                  
		ACS_WRITE       EQU 00000010B                	  	;XXXXXXWX - бит записи, для сегмента данных разершает запись                
		ACS_CODE        EQU 10011000B                	  	;AR сегмента кода                
		ACS_DATA        EQU 10010010B                	  	;AR сегмента данных               
		ACS_STACK       EQU 10010010B               	   	;AR сегмента стека                 
		ACS_INT_GATE    EQU 00001110B               	   	
		ACS_TRAP_GATE   EQU 00001111B               	   	;XXXXSICR - сегмент, подчиненный сегмент кода, доступен для чтения               
		ACS_IDT         EQU ACS_DATA               		   	;AR таблицы IDT                 
		ACS_INT         EQU ACS_PRESENT or ACS_INT_GATE     ; вентиль прерывания
		ACS_TRAP        EQU ACS_PRESENT or ACS_TRAP_GATE    ; вентиль исключения
		ACS_DPL_3       EQU 01100000B                  				                  


    ;____________________________________MESSAGES + _____________________________________________
    msg 				db 'Press any key to enter the protected mode.', '$'
    msg2 				db 'Press SHIFT to enter the protected mode or any key to exit.', '$'
    mg  				db 'Press esc to return to the real mode.', 0
    MSG_EXC             db "exception: XX",0
    int_mask_master     db  1 dup(?)            ;Значение регистра масок ведущего контроллера
    int_mask_slave      db  1 dup(?)            ;Значение регистра масок ведомого контроллера             


SIZE_DATA   = ($ - DATA_BEGIN)                  ;Размер сегмента данных
DATA    ends
;____________________________________________________________________________________________________________________________




;___________________________Сегмент стека реального/защищенного режима_______________________________________________________
STACK_A segment para stack
	;para - сегмент начинается по адресу, кратному 16, то есть последняя шестнадцатеричная цифра адреса должна быть 0h (выравнивание по границе параграфа);
    db  1000h dup(?)
STACK_A  ends
;____________________________________________________________________________________________________________________________


end start