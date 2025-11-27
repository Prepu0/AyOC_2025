extern free

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

USUARIO_FEED_OFFSET EQU 0;
USUARIO_SEGUIDORES_OFFSET EQU 8; 
USUARIO_CANT_SEGUIDORES_OFFSET EQU 16; 
USUARIO_SEGUIDOS_OFFSET EQU 24; 
USUARIO_CANT_SEGUIDOS_OFFSET EQU 32; 
USUARIO_BLOQUEADOS_OFFSET EQU 40; 
USUARIO_CANT_BLOQUEADOS_OFFSET EQU 48; 
USUARIO_ID_OFFSET EQU 52; 
USUARIO_SIZE EQU 56

; void bloquearUsuario(usuario_t *usuario, usuario_t *usuarioABloquear);
;usuario -> RDI
;usuarioABloquear -> RSI
global bloquearUsuario 
bloquearUsuario:
;prologo
push rbp
mov rbp, rsp
push r12
push r13
pus r14
push r15
push rbx
sub rsp, 8

mov r8, [rdi + USUARIO_CANT_BLOQUEADOS_OFFSET]
shl r8, 3

mov r9, [rdi + USUARIO_BLOQUEADOS_OFFSET]
mov [r9 + r8], rsi; guardo en lista bloqueados el usuarioABloquear





;epilogo
add rsp, 8
pop rbx
pop r15
pop r14
pop r13
pop r12
pop rbp
ret
