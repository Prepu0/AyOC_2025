extern malloc

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

; tuit_t **trendingTopic(usuario_t *usuario, uint8_t (*esTuitSobresaliente)(tuit_t *));
global trendingTopic

;uint64_t cantSobresalientes(usuario_t *usuario, uint8_t (*esTuitSobresaliente)(tuit_t *))

;RDI--> usuario
;RSI-->funcion
cantSobresalientes:
    push rbp
    mov rbp,rsp
    push rbx
    push r12
    push r13
    push r14
    push r15
    sub rsp,8
    
    mov rbx, rdi ;usuario
    mov r12,rsi  ;funcion

    mov r15,0 ; res=0

    mov r13, [rbx+USUARIO_FEED_OFFSET] ;cargo el feed
    mov r13, [r13+FEED_FIRST_OFFSET] ;cargo el primero

    ;mantengo en r13 la publicacion_t

    whileCS:
    cmp r13,0 ;si no tiene publicaciones termino
    je fin
    mov r14,[r13+PUBLICACION_VALUE_OFFSET] ;cargo el tweet
    ;mantengo en r14 el tuit

    mov eax, dword[rbx+USUARIO_ID_OFFSET]
    cmp dword[r14+TUIT_ID_AUTOR_OFFSET], eax ;chequeo si es suyo
    jne actCS

    ;chequeo si es sobresaliente
    mov rdi, r14
    call r12
    cmp rax,0
    je actCS

    inc r15

    actCS:
    mov r13,[r13+PUBLICACION_NEXT_OFFSET] ;cargo la siguiente
    jmp whileCS

    fin:
    mov rax,r15
    add rsp,8
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbx
    pop rbp
    ret


trendingTopic:
    push rbp
    mov rbp,rsp
    push rbx
    push r12
    push r13
    push r14
    push r15
    sub rsp, 24

    mov rbx,rdi ;usuario
    mov r12,rsi ;funcion

    call cantSobresalientes
    mov r13,rax ;guardo en r13 la cant de sobresalientes
    cmp r13,0
    jne armarArray
    mov r14,0
    jmp finTT

    armarArray:
    mov rdi,r13
    inc rdi
    imul rdi,8 ;long array = cantElems*puntero
    call malloc
    mov r14, rax ;guardo en r14 el puntero al array

    mov r15, [rbx+USUARIO_FEED_OFFSET] ;cargo el feed
    mov r15, [r15+FEED_FIRST_OFFSET] ;cargo el primero

    ;mantengo en r15 la publicacion actual

    mov qword[rbp-56],0 ;iterador res

    whileTT:
    cmp r15,0 ;si no tiene publicaciones termino
    je finTT
    mov rax,[r15+PUBLICACION_VALUE_OFFSET]
    mov [rbp-48],rax ;cargo el tweet
    ;mantengo en rbp-48 el tuit

    mov eax, dword[rbx+USUARIO_ID_OFFSET]
    mov rcx,[rbp-48] ;cargo el tweet
    cmp dword[rcx+TUIT_ID_AUTOR_OFFSET], eax ;chequeo si es suyo
    jne actTT

    ;chequeo si es sobresaliente
    mov rdi, rcx
    call r12
    cmp rax,0
    je actTT

    mov rdx,[rbp-56]
    mov rcx,[rbp-48] ;cargo el tweet
    mov [r14+rdx*8],rcx ;cargo el tweet en res
    inc qword[rbp-56]

    actTT:
    mov r15,[r15+PUBLICACION_NEXT_OFFSET] ;cargo la siguiente
    jmp whileTT

    finTT:
    cmp r14,0
    je empty
    mov rdx,[rbp-56]
    mov qword[r14+rdx*8],0 ;cargo el tweet en res
    empty:
    mov rax,r14

    add rsp,24
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbx
    pop rbp
    ret
