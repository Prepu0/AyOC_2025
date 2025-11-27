extern malloc

;########### SECCION DE DATOS
section .data

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

;segmentacion_t* segmentar_casos(caso_t* arreglo_casos, int largo)
global segmentar_casos
segmentar_casos:
push rbp
mov rbp, rsp
push r12
push r13
push r14
push r15
push rbx
sub rsp, 8; alineo la pila

mov r12, rdi; caso_t* r12 = arreglo_cassos
mov r13, rsi; int r13 = largo


xor rdi, rdi
add rdi, SEGMENTACION_SIZE
call malloc
mov r14, rax; segmentacinon_t* r14 = res

.caso0:
mov rdi, r12
mov rsi, r13
xor rdx, rdx
call contar_casos_por_nivel

mov r15, rax; int r15 = cant_0
xor rbx, rbx; caso_t* list_0 = NULL

cmp r15, 0; if cant_0 == 0
jle .actualizo_res_caso0

imul r15, CASO_SIZE
mov rdi, r15
call malloc

mov rbx, rax; actualizo el valor de list_0

;cant_0 ya no lo uso asi que puedo limpiar r15
xor r15, r15; int r15 = i_0

; Preparo ciclo0

xor r8, r8
dec r8; uso r8 de iterador

.ciclo0:
inc r8
cmp r8, r13
je .actualizo_res_caso0

push r8; pusheo para poder usarlo
sub rsp, 8; alineo

imul r8, CASO_SIZE

mov r9, QWORD[r12 + r8]; Guardo en r9 la parte baja del struct
mov r10, QWORD[r12 + r8 + CASO_USUARIO_OFFSET]; Guardo en r10 la parte alta del struct (usuario_t*)

add rsp, 8
pop r8

mov r11d, DWORD[r10 + USUARIO_NIVEL_OFFSET]
cmp r11d, 0
jne .ciclo0 ;Si no son iguales vuelvo a ciclo
; Si son iguales debo encolar el caso_t

mov r11, r15
imul r11, CASO_SIZE; int r11 = i_0 * 16

mov QWORD[rbx + r11], r9
mov QWORD[rbx + r11 + CASO_USUARIO_OFFSET], r10
inc r15; i_0++

jmp .ciclo0

.actualizo_res_caso0:
mov QWORD[r14 + SEGMENTACION_CASOS0_OFFSET], rbx; cargo list_0 en res


.caso1:
mov rdi, r12
mov rsi, r13
xor rdx, rdx
inc edx ;nivel = 1
call contar_casos_por_nivel

mov r15, rax; int r15 = cant_1
xor rbx, rbx; caso_t* list_1 = NULL

cmp r15, 0
je .actualizo_res_caso1

imul r15, CASO_SIZE
mov rdi, r15
call malloc

mov rbx, rax; actualizo el valor de list_1

;cant_1 ya no lo uso asi que puedo limpiar r15
xor r15, r15; int r15 = i_1

; Preparo ciclo1

xor r8, r8
dec r8; uso r8 de iterador

.ciclo1:
inc r8
cmp r8, r13
jge .actualizo_res_caso1

push r8; pusheo para poder usarlo
sub rsp, 8; alineo

imul r8, CASO_SIZE

mov r9, QWORD[r12 + r8]; Guardo en r9 la parte baja del struct
mov r10, QWORD[r12 + r8 + CASO_USUARIO_OFFSET]; Guardo en r10 la parte alta del struct (usuario_t*)

add rsp, 8
pop r8

mov r11d, DWORD[r10 + USUARIO_NIVEL_OFFSET]
cmp r11d, 1
jne .ciclo1 ;Si no son iguales vuelvo a ciclo
; Si son iguales debo encolar el caso_t

mov r11, r15
imul r11, CASO_SIZE; int r11 = i_1 * 16

mov QWORD[rbx + r11], r9
mov QWORD[rbx + r11 + CASO_USUARIO_OFFSET], r10
inc r15; i_1++

jmp .ciclo1

.actualizo_res_caso1:
mov QWORD[r14 + SEGMENTACION_CASOS1_OFFSET], rbx; cargo list_1 en res


.caso2:
mov rdi, r12
mov rsi, r13
xor rdx, rdx
add edx, 2 ;nivel = 2
call contar_casos_por_nivel

mov r15, rax; int r15 = cant_2
xor rbx, rbx; caso_t* list_2 = NULL

cmp r15, 0
je .actualizo_res_caso2

imul r15, CASO_SIZE
mov rdi, r15
call malloc

mov rbx, rax; actualizo el valor de list_2

;cant_2 ya no lo uso asi que puedo limpiar r15
xor r15, r15; int r15 = i_2

; Preparo ciclo2

xor r8, r8
dec r8; uso r8 de iterador

.ciclo2:
inc r8
cmp r8, r13
jge .actualizo_res_caso2

push r8; pusheo para poder usarlo
sub rsp, 8; alineo

imul r8, CASO_SIZE

mov r9, QWORD[r12 + r8]; Guardo en r9 la parte baja del struct
mov r10, QWORD[r12 + r8 + CASO_USUARIO_OFFSET]; Guardo en r10 la parte alta del struct (usuario_t*)

add rsp, 8
pop r8

mov r11d, DWORD[r10 + USUARIO_NIVEL_OFFSET]
cmp r11d, 2
jne .ciclo2 ;Si no son iguales vuelvo a ciclo
; Si son iguales debo encolar el caso_t

mov r11, r15
imul r11, CASO_SIZE; int r11 = i_2 * 16

mov QWORD[rbx + r11], r9
mov QWORD[rbx + r11 + CASO_USUARIO_OFFSET], r10
inc r15; i_2++

jmp .ciclo2

.actualizo_res_caso2:
mov QWORD[r14 + SEGMENTACION_CASOS2_OFFSET], rbx; cargo list_2 en res


.fin:

mov rax, r14

add rsp, 8
pop rbx
pop r15
pop r14
pop r13
pop r12
pop rbp

ret

;int contar_casos_por_nivel(caso_t* arreglo_casos, int largo, int nivel)
global contar_casos_por_nivel
contar_casos_por_nivel:

push rbp
mov rbp, rsp; preparo el stack frame
push r12
push r13


; caso_t* rdi = arreglo_casos
; int rsi = largo
; int edx = nivel
xor rax, rax; preparo el registro de respuestas

xor r12, r12
sub r12, CASO_SIZE

xor r8, r8
dec r8

.ciclo:
add r12, CASO_SIZE

inc r8
cmp r8, rsi
je .fin

;caso_t pesa 16 bytes, o sea que deberia usar dos registros para almacenarlo entero
; PERO yo solo quiero el usuario, asi que unicamente tomare la parte alta del struct

;De este modo estoy tomando el usuario
mov r13, QWORD[rdi + r12 + CASO_USUARIO_OFFSET]; caso_t r13 =  arreglo_casos[i].usuario

mov r13d, DWORD[r13 + USUARIO_NIVEL_OFFSET]; uint32_t r13 = arreglo_casos[i]->usuario->nivel

cmp edx, r13d
jne .ciclo

inc rax
jmp .ciclo


.fin:

pop r13
pop r12
pop rbp

ret