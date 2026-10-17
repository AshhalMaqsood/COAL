[org 0x100]

mov si, 0
mov cl, [size]
mov ch, 0            

mov al, [array]
mov bh, al            

cmp al, 0
jge positive
neg al

positive:
mov bl, al            
inc si
dec cx

L1:
    mov al, [array+si]
    cmp al, 0
    jge positive2
    neg al
positive2:
    cmp al, bl
    jbe next
    mov bl, al
    mov bh, [array+si]
next:
    inc si
    loop L1

mov [max], bh

mov ax, 4c00h
int 21h

array db -3, 5, -10, 4, 6, -7, 1
size  db 7
max   db 0