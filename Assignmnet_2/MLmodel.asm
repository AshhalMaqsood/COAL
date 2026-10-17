[org 0x0100]

jmp start

obs:     dw 0x6552, 0x2C91, 0x7FA3     ; packed observations
numObs:  db 3

weights: db 2, -3, -1, 10              ; NORMAL:     W1, W2, W3, Bias
         db 1,  4,  2,  0              ; SUSPICIOUS: W1, W2, W3, Bias
         db -2, 5,  4, -5              ; ATTACK:     W1, W2, W3, Bias

normScore: dw 0,0,0
susScore: dw 0,0,0
atkScore: dw 0,0,0
predFlag: db 0,0,0

x1:	dw 0
x2:	dw 0
x3:	dw 0

temp: dw 0



start:


mov si,0            	; observation offset
mov di,0		; score offset
mov bp,0		; flag offset

mov cl,[numObs]
mov ch,0

next_obs:


;------Connection Rate (15-10 bits)

mov ax,[obs+si]
shr ax,10
and ax,003Fh   ; as 003Fh= 0000 0000 0011 1111   to clear all other bits
sub ax,20
mov[x1],ax 

;------Failed Attempts (9-5 bits)

mov ax,[obs+si]
shr ax,5
and ax,001Fh   ; as 003Fh= 0000 0000 0001 1111
sub ax,8
mov[x2],ax

;------Payload Entropy (4-0 bits)

mov ax,[obs+si]
and ax,001Fh   ; as 003Fh= 0000 0000 0001 1111
sub ax,16
mov[x3],ax

;------Normal Score

mov bx,[x1]
mov dl,[weights]

mov ax,0

cmp dl,0
je normal_x1_done

jns normal_x1_pos

neg dl;

normal_x1_neg:
add ax,bx
dec dl;
jnz normal_x1_neg
neg ax
jmp normal_x1_done

normal_x1_pos:

add ax,bx
dec dl
jnz normal_x1_pos

normal_x1_done:
mov bx,ax

mov [temp],bx
mov bx,[x2]
mov dl,[weights+1]

mov ax,0

cmp dl,0
je normal_x2_done

jns normal_x2_pos

neg dl;

normal_x2_neg:
add ax,bx
dec dl;
jnz normal_x2_neg
neg ax
jmp normal_x2_done

normal_x2_pos:

add ax,bx
dec dl
jnz normal_x2_pos

normal_x2_done:
mov bx,[temp]
add bx,ax

mov [temp],bx
mov bx,[x3]
mov dl,[weights+2]

mov ax,0

cmp dl,0
je normal_x3_done

jns normal_x3_pos

neg dl;

normal_x3_neg:
add ax,bx
dec dl;
jnz normal_x3_neg
neg ax
jmp normal_x3_done

normal_x3_pos:

add ax,bx
dec dl
jnz normal_x3_pos

normal_x3_done:
mov bx,[temp]
add bx,ax




mov dl,[weights+3]
mov dh,0

test dl,80h
jz normal_bias_pos
mov dh,0FFh

normal_bias_pos:
add bx,dx


mov [normScore+di],bx

;------Suspicious Score

mov bx,[x1]
mov dl,[weights+4]

mov ax,0

cmp dl,0
je sus_x1_done

jns sus_x1_pos

neg dl;

sus_x1_neg:
add ax,bx
dec dl;
jnz sus_x1_neg
neg ax
jmp sus_x1_done

sus_x1_pos:

add ax,bx
dec dl
jnz sus_x1_pos

sus_x1_done:
mov bx,ax

mov [temp],bx
mov bx,[x2]
mov dl,[weights+5]

mov ax,0

cmp dl,0
je sus_x2_done

jns sus_x2_pos

neg dl;

sus_x2_neg:
add ax,bx
dec dl;
jnz sus_x2_neg
neg ax
jmp sus_x2_done

sus_x2_pos:

add ax,bx
dec dl
jnz sus_x2_pos

sus_x2_done:
mov bx,[temp]
add bx,ax

mov [temp],bx
mov bx,[x3]
mov dl,[weights+6]

mov ax,0

cmp dl,0
je sus_x3_done

jns sus_x3_pos

neg dl;

sus_x3_neg:
add ax,bx
dec dl;
jnz sus_x3_neg
neg ax
jmp sus_x3_done

sus_x3_pos:

add ax,bx
dec dl
jnz sus_x3_pos

sus_x3_done:
mov bx,[temp]
add bx,ax




mov dl,[weights+7]
mov dh,0

test dl,80h
jz sus_bias_pos
mov dh,0FFh

sus_bias_pos:
add bx,dx



mov [susScore+di],bx

;------Attack Score


mov bx,[x1]
mov dl,[weights+8]

mov ax,0

cmp dl,0
je atk_x1_done

jns atk_x1_pos

neg dl;

atk_x1_neg:
add ax,bx
dec dl;
jnz atk_x1_neg
neg ax
jmp atk_x1_done

atk_x1_pos:

add ax,bx
dec dl
jnz atk_x1_pos

atk_x1_done:
mov bx,ax

mov [temp],bx
mov bx,[x2]
mov dl,[weights+9]

mov ax,0

cmp dl,0
je atk_x2_done

jns atk_x2_pos

neg dl;

atk_x2_neg:
add ax,bx
dec dl;
jnz atk_x2_neg
neg ax
jmp atk_x2_done

atk_x2_pos:

add ax,bx
dec dl
jnz atk_x2_pos

atk_x2_done:
mov bx,[temp]
add bx,ax

mov [temp],bx
mov bx,[x3]
mov dl,[weights+10]

mov ax,0

cmp dl,0
je atk_x3_done

jns atk_x3_pos

neg dl;

atk_x3_neg:
add ax,bx
dec dl;
jnz atk_x3_neg
neg ax
jmp atk_x3_done

atk_x3_pos:

add ax,bx
dec dl
jnz atk_x3_pos

atk_x3_done:
mov bx,[temp]
add bx,ax




mov dl,[weights+11]
mov dh,0

test dl,80h
jz atk_bias_pos
mov dh,0FFh

atk_bias_pos:
add bx,dx

mov [atkScore+di],bx

;------Compare Scores

mov ax,[normScore+di]
cmp ax,[susScore+di]
jge check_attack_normal

; Suspicious greater then Normal
mov ax,[susScore+di]
cmp ax,[atkScore+di]
jge suspicious_flag

; Attack is greater
mov byte [predFlag+bp],3
jmp next_iteration

check_attack_normal:

mov ax,[normScore+di]
cmp ax,[atkScore+di]
jge normal_flag

; Attack is Greater
mov byte [predFlag+bp],3
jmp next_iteration

normal_flag:
mov byte [predFlag+bp],1
jmp next_iteration

suspicious_flag:
mov byte [predFlag+bp],2

next_iteration:
add si,2
add di,2
inc bp

dec cx
jz end
jmp next_obs




end:
mov ax,0x4c00
int 0x21