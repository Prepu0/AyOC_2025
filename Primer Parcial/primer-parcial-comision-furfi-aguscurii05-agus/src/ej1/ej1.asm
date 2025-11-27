extern malloc
extern strcpy

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


;void agregar_feed(tuit_t* tweet, feed_t* feed)
agregar_feed:
    push rbp
    mov rbp,rsp
    push rbx
    push r12

    mov rbx,rdi ;tweet
    mov r12,rsi ;feed

    mov rdi,PUBLICACION_SIZE
    call malloc
    mov rdi,rax ;puntero a la nueva publicacion
    mov [rdi+PUBLICACION_VALUE_OFFSET],rbx ;guardo el tweet
    mov rsi, [r12] ;cargo la publicacion
    mov [rdi+PUBLICACION_NEXT_OFFSET], rsi;guardo el siguiente

    mov [r12], rdi ;cargo el nuevo tweet inicial
    
    pop r12
    pop rbx
    pop rbp
    ret



; tuit_t *publicar(char *mensaje, usuario_t *usuario);
global publicar

;RDI -mensaje
;RSI -usuario
publicar:
    push rbp
    mov rbp,rsp
    push rbx
    push r12
    push r13
    push r14
    push r15
    sub rsp,8

    mov rbx,rdi ;mensaje
    mov r12,rsi ;usuario

    mov rdi,TUIT_SIZE
    call malloc
    mov r13,rax ;puntero al nuevo tweet

    mov rdi,r13
    mov rsi,rbx
    call strcpy ;seteo el mensaje

    mov word [r13+TUIT_RETUITS_OFFSET],0    ;seteo retuits=0
    mov word [r13+TUIT_FAVORITOS_OFFSET],0  ;seteo favoritos=0
    mov edi, dword [r12+USUARIO_ID_OFFSET]  ;cargo el id en esi
    mov [r13+TUIT_ID_AUTOR_OFFSET], edi     ;seteo el id

    mov rdi,r13                         ;cargo el tweet
    mov rsi,[r12+USUARIO_FEED_OFFSET]   ;cargo el feed
    call agregar_feed

    ;Ahora tengo que agregarselo a los seguidores

    mov r14,[r12+USUARIO_SEGUIDORES_OFFSET] ;cargo la lista de usuarios
    mov r15d,0

    cmp dword[r12+USUARIO_CANT_SEGUIDORES_OFFSET], 0
    je fin

    while:
    cmp r15d,[r12+USUARIO_CANT_SEGUIDORES_OFFSET]
    je fin

    mov rdi, r13         ;cargo el tweet
    mov rsi, [r14+r15*8] ;cargo el usuario
    mov rsi, [rsi+USUARIO_FEED_OFFSET] ;cargo el feed
    call agregar_feed

    inc r15
    jmp while
    
    fin:
    add rsp,8
    mov rax,r13
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbx
    pop rbp
    ret
