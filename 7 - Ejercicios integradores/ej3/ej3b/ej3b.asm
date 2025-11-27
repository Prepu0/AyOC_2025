extern strncmp
;########### SECCION DE DATOS
section .data
CLT: db "CLT", 0 ;Cada caracter es un byte (dB)
RBO: db "RBO", 0

;########### SECCION DE TEXTO (PROGRAMA)
section .text


; Completar las definiciones (serán revisadas por ABI enforcer):
USUARIO_ID_OFFSET EQU 0
USUARIO_NIVEL_OFFSET EQU 4
USUARIO_SIZE EQU 8

CASO_CATEGORIA_OFFSET EQU 0
CASO_ESTADO_OFFSET EQU 4
CASO_USUARIO_OFFSET EQU 8
CASO_SIZE EQU 16

SEGMENTACION_CASOS0_OFFSET EQU 0
SEGMENTACION_CASOS1_OFFSET EQU 8
SEGMENTACION_CASOS2_OFFSET EQU 16
SEGMENTACION_SIZE EQU 24

ESTADISTICAS_CLT_OFFSET EQU 0
ESTADISTICAS_RBO_OFFSET EQU 1
ESTADISTICAS_KSC_OFFSET EQU 2
ESTADISTICAS_KDT_OFFSET EQU 3
ESTADISTICAS_ESTADO0_OFFSET EQU 4
ESTADISTICAS_ESTADO1_OFFSET EQU 5
ESTADISTICAS_ESTADO2_OFFSET EQU 6
ESTADISTICAS_SIZE EQU 7

global resolver_automaticamente

;void resolver_automaticamente(funcionCierraCasos* funcion, caso_t* arreglo_casos, caso_t* casos_a_revisar, int largo)
resolver_automaticamente:
push rbp
mov rbp, rsp
push r12
push r13
push r14
push r15
push rbx
sub rsp,8; alineo la pila

;rdi = funcion
;rsi = arreglo_casos
;rdx = casos_a_revisar
;rcx = largo

mov r12, rdi;funcionCieraCasos* r12 = funcion
mov r13, rsi;caso_t* r13 = arreglo_casos
mov r14, rdx;caso_t* r14 = casos_a_revisar
mov r15, rcx;int r15 = largo

xor rbx, rbx ; int rbx = largo2

xor r8, r8; uso r8 como iterador
dec r8

.ciclo:
inc r8
cmp r8, r15
je .fin

mov r9, r13; caso_t* r9 = arr_casos
mov r10, r8; int r10 = i
imul r10, CASO_SIZE; int r10 = i*16
add r9, r10; ahora en r9 tengo la direccion de inicio de arreglo_casos[i]
;caso_t* r9 = arreglo_casos[i]

mov r10, QWORD[r9 + CASO_USUARIO_OFFSET]; usuario_t* r10 
mov r11d, DWORD[r10 + USUARIO_NIVEL_OFFSET]; uint32 r10d = nivel

;IF:
cmp r11d, 0
je .else 

push r9
push r8

mov rdi, r9
call r12

pop r8
pop r9

mov r10w, ax; uint16 r10w = resfunc;
cmp r10w, 1
jne .caso2

.caso1:
mov WORD[r9 + CASO_ESTADO_OFFSET], r10w
jmp .ciclo


.caso2:
push r9
push r8

mov rdi, CLT; char* rdi = "CLT"
mov rsi, r9 
add rsi, CASO_CATEGORIA_OFFSET
mov rdx, 4
call strncmp

pop r8
pop r9


cmp rax, 0
je .entrocaso2

push r9
push r8

mov rdi, RBO; char* rdi = "CLT"
mov rsi, r9 
add rsi, CASO_CATEGORIA_OFFSET
mov rdx, 4
call strncmp

pop r8
pop r9

cmp rax, 0
je .entrocaso2

jmp .caso3


.entrocaso2:
mov WORD[r9 + CASO_ESTADO_OFFSET], 2
jmp .ciclo

.caso3:

push r8
sub rsp,8

mov r8, rbx
imul r8, CASO_SIZE; largo2 * 16

mov r10, QWORD[r9]

mov QWORD[r14 + r8], r10

mov r10 , QWORD[r9 + CASO_USUARIO_OFFSET]; le sumo 8 a la direccion del struct y estoy en la parte alta (usuario_t*)

mov QWORD[r14 + r8 + 8], r10

add rsp, 8
pop r8

inc rbx; largo2 ++
jmp .ciclo



.else:

push r8
sub rsp,8

mov r8, rbx
imul r8, CASO_SIZE; largo2 * 16

mov r10, QWORD[r9]

mov QWORD[r14 + r8], r10

mov r10 , QWORD[r9 + CASO_USUARIO_OFFSET]; le sumo 8 a la direccion del struct y estoy en la parte alta (usuario_t*)

mov QWORD[r14 + r8 + 8], r10

add rsp, 8
pop r8

inc rbx; largo2 ++
jmp .ciclo


.fin:
add rsp, 8
pop rbx
pop r15
pop r14
pop r13
pop r12
pop rbp
ret
