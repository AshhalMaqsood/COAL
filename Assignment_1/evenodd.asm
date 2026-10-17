[org 0x0100]

mov ax,0
mov si,0
mov cx,10

Even:

mov bx,[array+si]
and bx,1
jnz Odd

inc ax

Odd:
add si,2
loop Even



mov ax,0x4c00
int 0x21

array: dw 1,2,3,4,5,6,7,8,9,10