extern malloc
extern strcpy

;########### SECCION DE DATOS
section .data

;########### SECCION DE TEXTO (PROGRAMA)
section .text


; Completar las definiciones (serán revisadas por ABI enforcer):
TUIT_MENSAJE_OFFSET EQU 0
TUIT_FAVORITOS_OFFSET EQU 140
TUIT_RETUITS_OFFSET EQU 142
TUIT_ID_AUTOR_OFFSET EQU 144
TUIT_SIZE EQU 148

PUBLICACION_NEXT_OFFSET EQU 0
PUBLICACION_VALUE_OFFSET EQU 8
PUBLICACION_SIZE EQU 16

FEED_FIRST_OFFSET EQU 0 
FEED_SIZE EQU 8

USUARIO_FEED_OFFSET EQU 0
USUARIO_SEGUIDORES_OFFSET EQU 8
USUARIO_CANT_SEGUIDORES_OFFSET EQU 16 
USUARIO_SEGUIDOS_OFFSET EQU 24
USUARIO_CANT_SEGUIDOS_OFFSET EQU 32 
USUARIO_BLOQUEADOS_OFFSET EQU 40
USUARIO_CANT_BLOQUEADOS_OFFSET EQU 48
USUARIO_ID_OFFSET EQU 52
USUARIO_SIZE EQU 56


global tuitafeed
tuitafeed:
;void tuitafeed(tuit_t* tuit, feed_t* feed)
;tuit -> RDI
;feed -> RSI

;prologo
push rbp
mov rbp, rsp
push r12
push r13
push r14
push r15
push rbx
sub rsp, 8; alineo la pila 

mov r12, rdi; en r12 tengo mi tuit
mov r13, rsi; en r13 tengo feed->first

xor rdi, rdi
mov rdi, PUBLICACION_SIZE
call malloc

mov r14, rax; guardo en r14 mi newpost

mov [r14 + PUBLICACION_VALUE_OFFSET], r12

xor r8, r8
mov [r14 + PUBLICACION_NEXT_OFFSET], r8

cmp r13, 0
jne .else

mov [r13], r14; guardo en feed->first = newpost

.else:
    mov [r14 + PUBLICACION_NEXT_OFFSET], r13

    mov [r13], r14


;epilogo
add rsp, 8
pop rbx
pop r15
pop r14
pop r13
pop r12
pop rbp
ret

; tuit_t *publicar(char *mensaje, usuario_t *usuario);
global publicar
;mensaje -> RDI
;usuario -> RSI 
publicar:
;prologo
push rbp
mov rbp, rsp
push r12
push r13
push r14
push r15
push rbx
sub rsp, 8;alineo la pila 

mov r12,rdi; preservo rdi
mov r13, rsi; preservo rsi

xor rdi, rdi
mov rdi, TUIT_SIZE
call malloc; libero un espacio de memoria tamaño tuit_t

mov r14, rax; guardo en r14 newtuit

mov rdi, r14
mov rsi, r12
call strcpy;copio en r14 el nuevo mensaje


mov r8d, dword[r13 + USUARIO_ID_OFFSET] 

mov [r14 + TUIT_ID_AUTOR_OFFSET], r8d; guardo el autor de mi tuit en el mismo


mov rdi, r14
mov rsi, [r13 + USUARIO_FEED_OFFSET]
call tuitafeed

mov r15d, dword[r13 + USUARIO_CANT_SEGUIDORES_OFFSET]
mov rbx, [r13 + USUARIO_SEGUIDORES_OFFSET]

xor r12, r12; limpio el registro con el mensaje, pues ya no lo necesito
dec r12; r12 es mi contador i

.ciclo:
    inc r12
    cmp r12, r15
    je .fin

    mov rdi, [rbx + r12*8]; guardo en rdi seguidor[i]
    mov rsi, [rdi + USUARIO_FEED_OFFSET]
    mov rdi, r14

    call tuitafeed

    jmp .ciclo

.fin:
;epilogo
mov rax, r14
add rsp, 8
pop rbx
pop r15
pop r14
pop r13
pop r12
pop rbp
ret

