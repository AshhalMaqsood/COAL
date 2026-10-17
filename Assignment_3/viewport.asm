[org 0x0100]

jmp start

Top: dw 3
Bottom: dw 21
Left: dw 8
Right: dw 72

title:     db ' TEXT VIEWPORT MANAGER ', 0

lines:
    dw L1, L2, L3, L4, L5 ,L6, L7, L8, L9, L10
    dw L11, L12, L13, L14, L15 ,L16, L17, L18, L19, L20

L1: db 'In text mode every screen cell takes two bytes in memory.', 0
L2: db 'The first byte is the character and the second byte is', 0
L3: db 'the attribute that controls colour and blinking. Writing', 0
L4: db 'assembly code for the 8088 means working with segments,', 0
L5: db 'registers and the stack directly. A good assembly', 0
L6: db 'programmer keeps every subroutine small and uses the', 0
L7: db 'stack frame to pass parameters in a clean way. The caller', 0
L8: db 'pushes the arguments and the callee cleans them using', 0
L9: db 'ret n. String instructions such as lodsb, stosw, movsw', 0
L10: db 'and cmpsb make assembly loops short and fast because the', 0
L11: db 'direction flag controls the walk through memory. This', 0
L12: db 'viewport scrolls only the inside of the window so the', 0
L13: db 'double line border is never damaged. Moving a block of', 0
L14: db 'text one row at a time is done with movsw, then the last', 0
L15: db 'row is blanked with stosw. When the keyword is found the', 0
L16: db 'attribute byte is changed and the character stays the', 0
L17: db 'same. Searching the screen is a plain byte comparison.', 0
L18: db 'Another assembly trick is to scan with repe cmpsb and', 0
L19: db 'stop at the first mismatch. Good assembly code is also', 0
L20: db 'well commented so that every register is easy to follow.', 0


scrollRows: dw 0
keyword: db 'assembly',0

status_text db 'Total Matches Found: ', 0
status_tail db ' | Viewport Status: ACTIVE', 0

tempRow: times 64 db 0 ; used to store the code bytes(characters) of a row for seacrching and comparing 
match_count: dw 0



start:
	push cs
	pop ds
	push cs
	pop es
	
	call clear_screen
	
	mov  ax, [Top]			; top
    push ax	
	mov  ax, [Left]			; left
    push ax	
    mov  ax, [Bottom]			;bottom
    push ax
    mov  ax, [Right]			; right
    push ax	
    call draw_window
	
	; === Print tilte
	mov  ax, title              ; text address
    push ax
	mov  ax, 0x1E               ; attribute
    push ax
	mov  ax, 3			; row
    push ax
	mov ax, 29        ; col
    push ax
    call print_string


    ; Print document lines using a loop
    mov si, 0              ; SI = offset within address array
    mov cx, 17             ; 17 lines fit in rows 4 through 20
    mov dx, 4              ; first interior row

print_loop:
    push cx                ; preserve loop counter
    push dx                ; preserve current row

    mov ax, [lines + si]   ; get address of current string
    push ax                ; string address

    mov ax, 07h
    push ax                ; attribute

    push dx                ; row
    mov ax, 10
    push ax                ; column

    call print_string      ; prints string, removes 8 parameter bytes

    pop dx                 ; restore row
    pop cx                 ; restore loop counter

    add si, 2              ; next word/address
    inc dx                 ; next screen row

    loop print_loop
	
;=== Scroll Up
	
	mov  ax, [Top]			; top
    push ax	
	mov  ax, [Left]			; left
    push ax	
    mov  ax, [Bottom]			;bottom
    push ax
    mov  ax, [Right]			; right
    push ax
    mov  ax, [scrollRows]        ; number of lines to scroll
    push ax
    call scroll_window_up


;=== highlight

	mov  ax, keyword
    push ax
    mov  ax, 0xCE
    push ax
    call find_and_highlight
	push word [match_count]
	call showstatus

terminate:
	mov ax, 0x4C00
    int 0x21
	
	
	

clear_screen:
	push bp
    mov  bp, sp
    push ax
    push cx
    push di
    push es
	
    mov  ax, 0xB800
    mov  es, ax
    xor  di, di
	mov ax,0x0720
    mov  cx, 2000
	
    cld
    rep  stosw
	
    pop  es
    pop  di
    pop  cx
    pop  ax
    pop  bp
    ret  
	
	
draw_window:
    push bp
    mov  bp, sp
	sub  sp, 2 
    push ax
    push bx
    push cx
    push dx
    push di
    push si
    push es

    cld                         ; DI must move forward for stosw
    mov  ax, 0xB800
    mov  es, ax

    ; ---- Top-left corner ----
    mov  ax, [bp+10]            ; top row
    mov  bx, 160                ; bytes per screen row
    mul  bx                     ; AX = top * 160
    mov  di, ax
    mov  ax, [bp+8]             ; left column
    shl  ax, 1                  ; * 2
    add  di, ax
    mov  ax, 0x07C9             ; corner (attribute 07, char C9)
    stosw

    ; ---- Top horizontal line ----
    mov  cx, [bp+4]
    sub  cx, [bp+8]
    dec  cx                     ; cells between the corners
    mov  ax, 0x07CD
    rep  stosw

    ; ---- Top-right corner ----
    mov  ax, 0x07BB
    stosw

    ; ---- Left and right vertical borders ----
    mov  ax, [bp+10]
    inc  ax
    mov  [bp-2], ax

vertical_loop:
    mov  ax, [bp-2]
    cmp  ax, [bp+6]
    jae  bottom_line           ; reached the bottom row

    mov  ax, [bp-2]              ; --- left wall ---
    mov  bx, 160
    mul  bx
    mov  di, ax
    mov  ax, [bp+8]
    shl  ax, 1
    add  di, ax
    mov  ax, 0x07BA
    mov  [es:di], ax

    mov  ax, [bp-2]                 ; --- right wall (DI recomputed!) ---
    mov  bx, 160
    mul  bx
    mov  di, ax
    mov  ax, [bp+4]
    shl  ax, 1
    add  di, ax
    mov  ax, 0x07BA
    mov  [es:di], ax

    inc  word [bp-2]
    jmp  vertical_loop

bottom_line:
    ; ---- Bottom-left corner ----
    mov  ax, [bp+6]
    mov  bx, 160
    mul  bx
    mov  di, ax
    mov  ax, [bp+8]
    shl  ax, 1
    add  di, ax
    mov  ax, 0x07C8
    stosw

    ; ---- Bottom horizontal line ----
    mov  cx, [bp+4]
    sub  cx, [bp+8]
    dec  cx
    mov  ax, 0x07CD
    rep  stosw

    ; ---- Bottom-right corner ----
    mov  ax, 0x07BC
    stosw

    pop  es
    pop  si
    pop  di
    pop  dx
    pop  cx
    pop  bx
    pop  ax
    mov  sp, bp
    pop  bp
    ret  8

print_string:
    push bp
    mov bp, sp
    push ax
    push bx
    push dx
    push si
    push di
    push es

    mov ax, 0xB800
    mov es, ax

    mov si, [bp+10]
    mov bl, [bp+8]

    mov ax, [bp+6]
    mov dx, 160
    mul dx
    mov di, ax

    mov ax, [bp+4]
    shl ax, 1
    add di, ax

    cld

next_char:
    lodsb
    test al, al
    jz done

    mov ah, bl
    stosw
    jmp next_char

done:
    pop es
    pop di
    pop si
    pop dx
    pop bx
    pop ax
    pop bp
    ret 8

scroll_window_up:
    push bp
    mov  bp, sp
    sub  sp, 2                  ; local [bp-2] = lines to scroll (after clamp)
    push ax
    push bx
    push cx
    push dx
    push si
    push di
    push es
    push ds

    mov  ax, 0B800h
    mov  es, ax
    mov  ds, ax
    cld

    ; [bp+4]=n  [bp+6]=right  [bp+8]=bottom  [bp+10]=left  [bp+12]=top

    mov  ax, [bp+4]
    cmp  ax, 0
    je   scroll_done2

    ; clamp n to the interior height
    mov  dx, [bp+8]
    sub  dx, [bp+12]
    dec  dx                     ; DX = interior height
    cmp  ax, dx
    jbe  scroll_count_ok
    mov  ax, dx
scroll_count_ok:
    mov  [bp-2], ax             ; keep n safe (MUL destroys DX!)

    ; interior width in cells
    mov  bx, [bp+6]
    sub  bx, [bp+10]
    dec  bx

    ; source = row (top+1+n), col (left+1)
    mov  ax, [bp+12]
    inc  ax
    add  ax, [bp-2]
    mov  cx, 160
    mul  cx
    mov  si, ax
    mov  ax, [bp+10]
    inc  ax
    shl  ax, 1
    add  si, ax

    ; destination = row (top+1), col (left+1)
    mov  ax, [bp+12]
    inc  ax
    mov  cx, 160
    mul  cx
    mov  di, ax
    mov  ax, [bp+10]
    inc  ax
    shl  ax, 1
    add  di, ax

    ; rows to copy = height - n
    mov  ax, [bp+8]
    sub  ax, [bp+12]
    sub  ax, [bp-2]
    dec  ax
    mov  cx, ax
    jcxz scroll_blank_start

scroll_copy:
    push cx
    mov  cx, bx
    rep  movsw                  ; copy one interior row

    mov  ax, bx
    shl  ax, 1
    mov  dx, 160
    sub  dx, ax                 ; bytes to skip to reach the next row start
    add  si, dx
    add  di, dx

    pop  cx
    loop scroll_copy

scroll_blank_start:
    ; DI now points at the first vacated row. Blank n rows.
    mov  cx, [bp-2]
blank_loop:
    push cx
    mov  cx, bx
    mov  ax, 0x0720             ; blank, grey
    rep  stosw
    mov  ax, bx
    shl  ax, 1
    mov  dx, 160
    sub  dx, ax
    add  di, dx
    pop  cx
    loop blank_loop

scroll_done2:
    pop  ds
    pop  es
    pop  di
    pop  si
    pop  dx
    pop  cx
    pop  bx
    pop  ax
    mov  sp, bp                 ; discard the local
    pop  bp
    ret  10
	
	

find_and_highlight:
    push bp
    mov bp, sp
    sub sp, 12

    push ax
    push bx
    push cx
    push dx
    push si
    push di
    push ds
    push es

    push cs
    pop ds
    cld

    ; Parameters:
    ; [bp+6] = keyword address
    ; [bp+4] = highlight attribute

    mov ax, [bp+4]
    mov [bp-8], ax          ; local attribute

    mov word [bp-12], 0

    ; Calculate keyword length using LODSB
    mov si, [bp+6]
    xor cx, cx

length_loop:
    lodsb
    cmp al, 0
    je length_done
    inc cx
    jmp length_loop

length_done:
    mov [bp-2], cx          ; local keyword length

    ; Empty keyword? Nothing to search
    cmp cx, 0
    je find_done

    ; Interior width = Right - Left - 1
    mov ax, [Right]
    sub ax, [Left]
    dec ax
    mov [bp-10], ax         ; local interior width

    ; Begin at the first interior row
    mov ax, [Top]
    inc ax
    mov [bp-4], ax          ; local current row

row_loop:
    ; Stop before the bottom border
    mov ax, [bp-4]
    cmp ax, [Bottom]
    jae find_done

    ; ES = video memory
    mov ax, 0B800h
    mov es, ax

    ; Calculate screen offset:
    ; row * 160 + (Left + 1) * 2
    mov ax, [bp-4]
    mov cx, 160
    mul cx
    mov si, ax

    mov ax, [Left]
    inc ax
    shl ax, 1
    add si, ax

    ; Copy only character bytes into row_buffer
    xor bx, bx
    mov cx, [bp-10]

copy_row:
    mov al, [es:si]
    mov [tempRow+bx], al
    add si, 2
    inc bx
    loop copy_row

    ; Search each possible starting column
    mov word [bp-6], 0

candidate_loop:
    ; Candidate column + keyword length <= width?
    mov ax, [bp-6]
    add ax, [bp-2]
    cmp ax, [bp-10]
    ja row_finished

    ; Compare keyword with row_buffer
    mov si, [bp+6]
    mov di, tempRow
    add di, [bp-6]
    mov cx, [bp-2]

    ; CMPSB compares DS:SI with ES:DI
    push ds
    pop es
    repe cmpsb
    jne next_candidate

    ; Match found. Restore video-memory segment.
    mov ax, 0B800h
    mov es, ax

    ; Calculate screen offset of matching character:
    ; row * 160 + (Left + 1 + column) * 2
    mov ax, [bp-4]
    mov cx, 160
    mul cx
    mov di, ax

    mov ax, [Left]
    inc ax
    add ax, [bp-6]
    shl ax, 1
    add di, ax

    ; Move to the attribute byte
    inc di

    ; Change attributes only, preserving characters
    mov cx, [bp-2]
    mov al, [bp-8]

highlight_loop:
    mov [es:di], al
    add di, 2
    loop highlight_loop

    inc word [bp-12]

next_candidate:
    inc word [bp-6]
    jmp candidate_loop

row_finished:
    inc word [bp-4]
    jmp row_loop

find_done:
    mov ax, [bp-12]
    mov [match_count], ax
	
    pop es
    pop ds
    pop di
    pop si
    pop dx
    pop cx
    pop bx
    pop ax

    mov sp, bp
    pop bp
    ret 4



printNum:
    push bp
    mov  bp, sp
    sub  sp, 2

    push ax
    push bx
    push cx
    push dx
    push di
    push es

    mov  word [bp-2], 0       ; digit counter
    mov  ax, [bp+10]          ; number
    mov  bx, 10

    ; Convert number into decimal digits
divide:
    xor  dx, dx
    div  bx
    push dx
    inc  word [bp-2]
    cmp  ax, 0
    jne  divide

    ; Calculate video offset = row*160 + column*2
    mov  ax, [bp+8]
    mov  bx, 160
    mul  bx
    mov  di, ax

    mov  ax, [bp+6]
    shl  ax, 1
    add  di, ax

    ; Set video memory and attribute
    mov  ax, 0B800h
    mov  es, ax
    mov  ah, [bp+4]

    mov  cx, [bp-2]
    cld

print:
    pop  dx
    mov  al, dl
    add  al, '0'
    stosw
    loop print

    pop  es
    pop  di
    pop  dx
    pop  cx
    pop  bx
    pop  ax

    mov  sp, bp
    pop  bp
    ret  8



showstatus:
	push bp
    mov  bp, sp
    push ax

    ; Print "Total Matches Found: " at row 23, column 0
    mov ax, status_text
    push ax
    mov ax, 07h
    push ax
    mov ax, 23
    push ax
    mov ax, 0
    push ax
    call print_string

    ; Print match_count at row 23, column 21
    push word [bp+4] 
    mov ax, 23
    push ax
    mov ax, 21
    push ax
    mov ax, 07h
    push ax
    call printNum

    ; Print status tail after the count
    mov ax, status_tail
    push ax
    mov ax, 07h
    push ax
    mov ax, 23
    push ax
    mov ax, 26
    push ax
    call print_string

	pop  ax
    pop  bp
    ret 2
