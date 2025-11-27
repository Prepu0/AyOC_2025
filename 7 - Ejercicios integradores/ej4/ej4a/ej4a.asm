extern malloc
extern sleep
extern wakeup
extern create_dir_entry

section .rodata
; Acá se pueden poner todas las máscaras y datos que necesiten para el ejercicio
sleep_name: DB "sleep", 0
wakeup_name: DB "wakeup", 0

section .text
; Marca un ejercicio como aún no completado (esto hace que no corran sus tests)
FALSE EQU 0
; Marca un ejercicio como hecho
TRUE  EQU 1

; Marca el ejercicio 1A como hecho (`true`) o pendiente (`false`).
;
; Funciones a implementar:
;   - init_fantastruco_dir
global EJERCICIO_1A_HECHO
EJERCICIO_1A_HECHO: db TRUE ; Cambiar por `TRUE` para correr los tests.

; Marca el ejercicio 1B como hecho (`true`) o pendiente (`false`).
;
; Funciones a implementar:
;   - summon_fantastruco
global EJERCICIO_1B_HECHO
EJERCICIO_1B_HECHO: db TRUE ; Cambiar por `TRUE` para correr los tests.

;########### ESTOS SON LOS OFFSETS Y TAMAÑO DE LOS STRUCTS
; Completar las definiciones (serán revisadas por ABI enforcer):
DIRENTRY_NAME_OFFSET EQU 0
DIRENTRY_PTR_OFFSET EQU 16
DIRENTRY_SIZE EQU 24

FANTASTRUCO_DIR_OFFSET EQU 0
FANTASTRUCO_ENTRIES_OFFSET EQU 8
FANTASTRUCO_ARCHETYPE_OFFSET EQU 16
FANTASTRUCO_FACEUP_OFFSET EQU 24
FANTASTRUCO_SIZE EQU 32

; void init_fantastruco_dir(fantastruco_t* card);

global init_fantastruco_dir

section .text
init_fantastruco_dir:
	; Te recomendamos llenar una tablita acá con cada parámetro y su
	; ubicación según la convención de llamada. Prestá atención a qué
	; valores son de 64 bits y qué valores son de 32 bits o 8 bits.
	;
	; r/m64 = fantastruco_t*     card
	push rbp
	mov rbp, rsp; prologo

	push r12
	push r13
	push r14
	sub rsp, 8; alineo la pila

	mov r12, rdi; cargo el valor de *card en r12

	xor rdi, rdi; limpio rdi
	mov rdi, sleep_name; cargo la label en rdi
	mov rsi, sleep; cargo la direccion de la funcion en rsi

	call create_dir_entry

	mov r13, rax; conservo el valor de new_dir_sleep

	xor rdi, rdi
	mov rdi, wakeup_name
	mov rsi, wakeup

	call create_dir_entry

	mov r14, rax; conservo el valor de new_dir_wakeup

	xor rdi, rdi
	add rdi, 16

	call malloc

	mov [rax], r13
	mov [rax + 8], r14

	mov QWORD[r12 + FANTASTRUCO_DIR_OFFSET], rax; cargo la direccion que contiene el arranque del directorio
	mov DWORD[r12 + FANTASTRUCO_ENTRIES_OFFSET], 2; cargo la cant de entrys que tiene directorio

	add rsp, 8
	pop r14
	pop r13
	pop r12

	pop rbp
	ret ;No te olvides el ret!

; fantastruco_t* summon_fantastruco();
global summon_fantastruco
summon_fantastruco:
	; Esta función no recibe parámetros
	push rbp
	mov rbp, rsp; prologo
	push r12
	sub rsp, 8; alineo la pila

	xor rdi, rdi; limpio el registro
	add rdi, FANTASTRUCO_SIZE
	call malloc

	; rax = direccion de mi nuevo fantastruco

	mov BYTE[rax + FANTASTRUCO_FACEUP_OFFSET], 1
	mov QWORD[rax + FANTASTRUCO_ARCHETYPE_OFFSET], 0x00000000

	mov r12, rax; conservo la direccion de memoria
	mov rdi, rax
	call init_fantastruco_dir

	mov rax, r12; restablezco la dir de memoria a rax para devolverla segun convencion PERO con los datos cambiados ;)

	add rsp, 8
	pop r12
	pop rbp

	ret ;No te olvides el ret!
