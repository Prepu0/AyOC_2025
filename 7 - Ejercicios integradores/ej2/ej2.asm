extern malloc
extern free

section .rodata
; Acá se pueden poner todas las máscaras y datos que necesiten para el ejercicio

section .text
; Marca un ejercicio como aún no completado (esto hace que no corran sus tests)
FALSE EQU 0
; Marca un ejercicio como hecho
TRUE  EQU 1

; Marca el ejercicio 1A como hecho (`true`) o pendiente (`false`).
;
; Funciones a implementar:
;   - optimizar
global EJERCICIO_2A_HECHO
EJERCICIO_2A_HECHO: db TRUE ; Cambiar por `TRUE` para correr los tests.

; Marca el ejercicio 1B como hecho (`true`) o pendiente (`false`).
;
; Funciones a implementar:
;   - contarCombustibleAsignado
global EJERCICIO_2B_HECHO
EJERCICIO_2B_HECHO: db FALSE ; Cambiar por `TRUE` para correr los tests.

; Marca el ejercicio 1C como hecho (`true`) o pendiente (`false`).
;
; Funciones a implementar:
;   - modificarUnidad
global EJERCICIO_2C_HECHO
EJERCICIO_2C_HECHO: db FALSE ; Cambiar por `TRUE` para correr los tests.

;########### ESTOS SON LOS OFFSETS Y TAMAÑO DE LOS STRUCTS
; Completar las definiciones (serán revisadas por ABI enforcer):
ATTACKUNIT_CLASE EQU 0
ATTACKUNIT_COMBUSTIBLE EQU 12
ATTACKUNIT_REFERENCES EQU 14
ATTACKUNIT_SIZE EQU 16

global optimizar
optimizar:
	; Te recomendamos llenar una tablita acá con cada parámetro y su
	; ubicación según la convención de llamada. Prestá atención a qué
	; valores son de 64 bits y qué valores son de 32 bits o 8 bits.
	;
	; r/m64 = mapa_t           mapa
	; r/m64 = attackunit_t*    compartida
	; r/m64 = uint32_t*        fun_hash(attackunit_t*)
	push rbp
	mov rbp, rsp
	push r12
	push r13
	push r14
	push r15
	push rbx
	sub rsp, 8; alineo la pila y dejo un espacio para pushear

	mov r12,rdi; mapa_t r12
	mov r13, rsi; attackunit* r13 = compartida
	mov r14, rdx; uint32_t r14 = fun_hash

	mov rdi, r13
	call r14

	mov r15d, eax; uint32_t eax = fun_hash(compartida)

	mov BYTE[r13 + ATTACKUNIT_REFERENCES], 0

	xor r8, r8
	dec r8; uso r8 de iterador

	.ciclo:
	inc r8
	cmp r8, 65025; = 255*255
	jge .fin 

	mov rbx, QWORD[r12 + r8*8]; attackunit_t* rbx = mapa[i]

	cmp rbx, 0
	je .ciclo

	push r8
	sub rsp, 8

	mov rdi, rbx
	call r14

	add rsp, 8
	pop r8

	;uint32_t eax = fun_hash(actual)
	cmp eax, r15d; IF actual_hash = shared_hash
	jne .ciclo

	inc BYTE[r13 + ATTACKUNIT_REFERENCES]

	mov QWORD[r12 + r8*8], r13; actualizo el mapa

	cmp rbx, r13; IF (actual == compartida)
	je .ciclo; => SIGO EL CICLO

	cmp BYTE[rbx + ATTACKUNIT_REFERENCES], 1
	jle .else

	dec BYTE[rbx + ATTACKUNIT_REFERENCES]
	jmp .ciclo

	.else:
	push r8; SUPER IMPORTANTE: PRESERVAR SIEMPRE LOS NO-VOLATILES
	sub rsp, 8

	mov rdi, rbx
	call free

	add rsp, 8
	pop r8

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

global contarCombustibleAsignado
contarCombustibleAsignado:
	; r/m64 = mapa_t           mapa
	; r/m64 = uint16_t*        fun_combustible(char*)
	ret

global modificarUnidad
modificarUnidad:
	; r/m64 = mapa_t           mapa
	; r/m8  = uint8_t          x
	; r/m8  = uint8_t          y
	; r/m64 = void*            fun_modificar(attackunit_t*)
	ret
