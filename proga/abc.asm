.model small
Locals @@

    Descriptor struc            ; структура дескриптора
        limit dw 0              ; предел
        address_low dw 0        
        address_high db 0       
        access db 0             
        limit_extention db 0
        address_extention db 0
    ends

    CODE_SELECTOR       equ (gdt_code_seg - gdt_0)
    STACK_SELECTOR      equ (gdt_stack_seg - gdt_0)
    DATA_SELECTOR       equ (gdt_data_seg - gdt_0)
    VIDEO_SELECTOR      equ (gdt_video_seg - gdt_0)
    RMODE_CODE_SELECTOR equ (gdt_rmode_code - gdt_0)
    RMODE_DATA_SELECTOR equ (gdt_rmode_data - gdt_0)
    
    REAL_MODE_VIDEO_ADDRESS equ 0b8000h

    CODE_SEGMENT_LIMIT  equ 1024
    STACK_SEGMENT_LIMIT equ 1024
    VIDEO_SEGMENT_LIMIT equ 4000
    DATA_SEGMENT_LIMIT  equ 0ffffh       
    

; Биты байта доступа (по сути константы)
    ACC_PRESENT  EQU 10000000b ; сегмент есть в памяти
    ACC_CSEG     EQU 00011000b ; сегмент кода
    ACC_DSEG     EQU 00010000b ; сегмент данных
    ACC_EXPDOWN  EQU 00000100b ; сегмент расширяется вниз
    ACC_CONFORM  EQU 00000100b ; согласованный сегмент
    ACC_DATAWR   EQU 00000010b ; разрешена запись

; Типы сегментов
    CODE_SEGMENT_ACCESS  equ ACC_PRESENT OR ACC_CSEG OR ACC_CONFORM
    STACK_SEGMENT_ACCESS equ ACC_PRESENT OR ACC_DSEG OR ACC_DATAWR OR ACC_EXPDOWN
    DATA_SEGMENT_ACCESS  equ ACC_PRESENT OR ACC_DSEG OR ACC_DATAWR  
    VIDEO_SEGMENT_ACCESS equ ACC_PRESENT OR ACC_DSEG OR ACC_DATAWR  

.data


    rmode_ss dw ?
    rmode_ds dw ?
    rmode_es dw ?
    rmode_fs dw ?
    rmode_gs dw ?
    rmode_sp dw ?

    gdtr label fword
    gdt_limit   dw GDT_SIZE
    gdt_address dd ?

    GDT equ $
    gdt_0           Descriptor <0,0,0,0,0,0>
    gdt_code_seg    Descriptor ?
    gdt_stack_seg   Descriptor ?
    gdt_data_seg    Descriptor ?
    gdt_video_seg   Descriptor ?
    gdt_rmode_code  Descriptor ?
    gdt_rmode_data  Descriptor ?
    GDT_SIZE equ ($ - GDT)

    start db "Program in protected mode", '$'
    exit db "Protected mode exit message", '$'
        
.stack STACK_SEGMENT_LIMIT
.code
.386p

; bs - source 
; es - video mem 
; di - possition  
; ah - color 

Sleep proc
    push ax bx cx dx di si
    xor ax, ax
  
    mov bx, 60
    int 1ah
    mov si, cx
    mov di, dx
  pause:
    mov ah, 0
    int 1ah
    sub dx, di
    sbb cx, si
    cmp dx, bx
    jnz pause
    pop si di dx cx bx ax
    ret
endp 

WriteString proc 
    push eax ebx edi
    mov cx, 255
  @@_loop:
    mov al, [bx]
    cmp al, '$'
    je @@_end
    mov es:[di], word ptr ax
    add di, 2
    inc bx
    loop @@_loop

  @@_end:
    pop edi ebx eax
    ret
endp

ClearScreen proc 
    push cx dx ax 
    xor cx,cx
    mov dl, 100
    mov dh, 20
    mov ax,0600h        
    int 10h
    pop ax dx cx 
    ret
endp

InitDesctiptor macro Descriptor, Limit, Access ; Макрос для заполнения дескриптора 
    push eax ebx
    mov bx, ax
    shr eax, 16

    mov [Descriptor].address_low, bx
    mov [Descriptor].address_high, al
    mov [Descriptor].address_extention, ah
    mov [Descriptor].limit, Limit
    mov [Descriptor].limit_extention, 0
    mov [Descriptor].access, Access
    pop ebx eax
endm

InitGDT proc    ; Подготовка таблицы дескрипторов
    
    xor eax, eax
    mov ax, cs
    shl eax, 4
    InitDesctiptor gdt_code_seg CODE_SEGMENT_LIMIT CODE_SEGMENT_ACCESS

    xor eax, eax
    mov ax, ss
    shl eax, 4
    InitDesctiptor gdt_stack_seg STACK_SEGMENT_LIMIT STACK_SEGMENT_ACCESS 

    xor eax, eax
    mov ax, ds
    shl eax, 4
    InitDesctiptor gdt_data_seg DATA_SEGMENT_LIMIT DATA_SEGMENT_ACCESS


    mov eax, REAL_MODE_VIDEO_ADDRESS
    InitDesctiptor gdt_video_seg VIDEO_SEGMENT_LIMIT VIDEO_SEGMENT_ACCESS

    xor eax, eax
    mov ax, cs
    shl eax, 4
    InitDesctiptor gdt_rmode_code 0ffffh CODE_SEGMENT_ACCESS

    xor eax, eax
    mov ax, ds 
    shl eax, 4
    InitDesctiptor gdt_rmode_data 0ffffh DATA_SEGMENT_ACCESS
    ret 
endp

EnterProtectedMode proc  ; Переход в защищённый режим 
    push eax ecx edx

    xor eax, eax
    mov ax, seg GDT 
    shl eax, 4
    xor edx, edx
    mov dx, offset GDT
    add eax, edx

    mov gdt_address, eax
    cli
    lgdt gdtr

    mov rmode_sp, sp

    mov eax, cr0
    or eax, 1
    mov cr0, eax
    ; protected mode
    
    db 0eah          ; jmp far flush
    dw offset @@flush
    dw CODE_SELECTOR

  @@flush:
    mov ax, VIDEO_SELECTOR
    mov es, ax
    mov ax, DATA_SELECTOR
    mov ds, ax
    mov ax, STACK_SELECTOR
    mov ss, ax

    pop edx ecx eax
    ret
endp

ExitProtectedMode proc
    push eax ebx edi

    mov ax, RMODE_DATA_SELECTOR
    mov ss, ax
    mov ds, ax
    mov es, ax
    mov fs, ax
    mov gs, ax 

    mov eax, cr0
    and al, 0feh
    mov cr0, eax

    ; real mode 
    
    db 0eah          ; jmp far flush
    dw @@flush
    rmode_cs dw ?

  @@flush:
    sti
	; Востановление сегментов из памяти 
    mov ss, rmode_ss 
    mov ds, rmode_ds
    mov es, rmode_es
    mov fs, rmode_fs
    mov gs, rmode_gs
    mov sp, rmode_sp

    pop ebx ecx eax
    ret
endp

InitRealModeSegments proc 
    ; запись сегментов в память 
    mov rmode_ss, ss
    mov rmode_ds, ds
    mov rmode_es, es
    mov rmode_fs, fs
    mov rmode_gs, gs
    mov rmode_cs, cs
    ret 
endp

MAIN:
    mov ax, @data
    mov ds, ax
	
    call ClearScreen          ; Очистка экрана 
    call InitRealModeSegments ; Подготовка регистров 
    call InitGDT              ; Инициализация таблицы дискрипторов
    call EnterProtectedMode   ; Включение защищённого режима
	mov ah, 7 ; color 
    mov bx, offset start
    mov di, 970 ; possition
    call WriteString
startlable:
    xor ax, ax
    in  al, 60h
	cmp ax, 1
    jne startlable 
	
    call ExitProtectedMode    ; Выход из защищённого режима 
	call ClearScreen
	mov dx, offset exit
    mov ah,9                 
    int 21h
	
	mov     ax, 4c00h
    int     21h	
end MAIN
