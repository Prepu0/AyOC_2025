extern free

;########### SECCION DE DATOS
section .data

;########### SECCION DE TEXTO (PROGRAMA)
section .text

; Completar las definiciones (serán revisadas por ABI enforcer):
;La estructura esta alineada a 4bytes
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


;ALINEADO A 8BYTES (por los punteros)
USUARIO_FEED_OFFSET EQU 0;
USUARIO_SEGUIDORES_OFFSET EQU 8; 
USUARIO_CANT_SEGUIDORES_OFFSET EQU 16; 
USUARIO_SEGUIDOS_OFFSET EQU 24; 
USUARIO_CANT_SEGUIDOS_OFFSET EQU 32; 
USUARIO_BLOQUEADOS_OFFSET EQU 40; 
USUARIO_CANT_BLOQUEADOS_OFFSET EQU 48; 
USUARIO_ID_OFFSET EQU 52; 
USUARIO_SIZE EQU 56

global bloquearUsuario 

;void borrar_publicaciones(feed_t* feed,uint32_t id)
borrar_publicaciones:
    push rbp
    mov rbp, rsp
    push rbx
    push r12
    push r13
    push r14

    mov rbx,rdi ;feed
    mov r12d,esi ;id

    mov r13,0 ;anterior
    mov r14, [rbx] ;cargo la primer publicacion
    ;r13 anterior,r14 actual
    whileBP:
    cmp r14,0
    je finBP

    mov rax,[r14+PUBLICACION_VALUE_OFFSET] ;cargo el tuit
    cmp [rax+TUIT_ID_AUTOR_OFFSET],r12d ;comparo con el id
    jne actualizar

    cmp r13,0 ;chequeo si el anterior es NULL
    jne borrar

    ;casoPrimero
    mov rdi,r14 ;muevo a rdi el actual
    ;mov rax,r14
    mov rdx,[r14+PUBLICACION_NEXT_OFFSET] ;cargo el siguiente
    mov [rbx],rdx ;indico el nuevo first
    ;mov r13,0 ;anterior NULL
    mov r14,rdx ;actual=actual->siguiente
    call free
    jmp whileBP

    borrar:
    mov rdi,r14 ;muevo a rdi el actual
    mov rdx,[r14+PUBLICACION_NEXT_OFFSET] ;cargo el siguiente
    mov [r13+PUBLICACION_NEXT_OFFSET],rdx ;anterior->siguiente = actual->siguiente

    ;r13 se mantien
    mov r14,rdx ;actual=actual->siguiente
    call free
    jmp whileBP

    actualizar:
    mov r13,r14  ;anterior=actual
    mov r14,[r14+PUBLICACION_NEXT_OFFSET] ;actual=actual->siguiente
    jmp whileBP

    finBP:
    pop r14
    pop r13
    pop r12
    pop rbx
    pop rbp
    ret


; void bloquearUsuario(usuario_t *usuario, usuario_t *usuarioABloquear);

;RDI usuario
;RSI usuarioABloquear
bloquearUsuario:
    push rbp
    mov rbp,rsp
    push rbx
    push r12

    mov rbx,rdi ;usuario
    mov r12,rsi ;usuarioABloquear

    mov rdi,[rbx+USUARIO_BLOQUEADOS_OFFSET];cargo el puntero al array de bloqueados
    xor rsi,rsi ;limpio rsi
    mov esi, dword[rbx+USUARIO_CANT_BLOQUEADOS_OFFSET] ;cargo la cant de bloqueados
    mov [rdi+rsi*8],r12 ;agrego el usuario a bloquear en la ultima pos
    inc dword[rbx+USUARIO_CANT_BLOQUEADOS_OFFSET] ;actualizo bloqueados

    ;RDI-feed
    ;ESI id
    ;Borro publicaciones de usuarioABloquear en usuario
    mov rdi,[rbx+USUARIO_FEED_OFFSET];cargo el feed
    mov esi, dword[r12+USUARIO_ID_OFFSET]  ;cargo el id
    call borrar_publicaciones

    ;Borro publicaciones de usuario en usuarioABloquear
    mov rdi,[r12+USUARIO_FEED_OFFSET];cargo el feed
    mov esi, dword[rbx+USUARIO_ID_OFFSET]  ;cargo el id
    call borrar_publicaciones

    
    pop r12
    pop rbx
    pop rbp
    ret
