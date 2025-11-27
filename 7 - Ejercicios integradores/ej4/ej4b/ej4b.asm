extern strcmp
global invocar_habilidad

; Completar las definiciones o borrarlas (en este ejercicio NO serán revisadas por el ABI enforcer)
DIRENTRY_NAME_OFFSET EQU 0
DIRENTRY_PTR_OFFSET EQU 16
DIRENTRY_SIZE EQU 24

FANTASTRUCO_DIR_OFFSET EQU 0
FANTASTRUCO_ENTRIES_OFFSET EQU 8
FANTASTRUCO_ARCHETYPE_OFFSET EQU 16
FANTASTRUCO_FACEUP_OFFSET EQU 24
FANTASTRUCO_SIZE EQU 32

section .rodata
; Acá se pueden poner todas las máscaras y datos que necesiten para el ejercicio

section .text

; void invocar_habilidad(void* carta, char* habilidad);
invocar_habilidad:
	; Te recomendamos llenar una tablita acá con cada parámetro y su
	; ubicación según la convención de llamada. Prestá atención a qué
	; valores son de 64 bits y qué valores son de 32 bits o 8 bits.
	;
	; r/m64 = void*    card ; Vale asumir que card siempre es al menos un card_t*
	; r/m64 = char*    habilidad
	; rdi = carta
	; rsi = habilidad

	push rbp
	mov rbp, rsp; prologo

	push rbx
	push r12
	push r13
	push r14

	mov rbx, rdi ; rbx = carta
	mov r12, rsi ; r12 = habilidad
	; PRESERVO VALORES PASADOS POR PARAMETRO

	mov r13, [rbx + FANTASTRUCO_ENTRIES_OFFSET]; uint16_t r13 = carta->__dir_entries
	mov r14, [rbx + FANTASTRUCO_DIR_OFFSET]; directory_t r14 = carta-> directorio

	;En vez de usar un iterador, recorro el ciclo hasta que r13 == 0
	;Ahora estaria arrancando desde el final y termino en el primer elto. de la lista
.ciclo1:
	dec r13
	cmp r13, 0
	jl .finciclo1; if r13 < 0

	mov r9, [r14 + r13*8]; directory_entry_t r9 = carta-> dir[i]

	push r9 ; preservo el valor de r9 en la pila para no perderlo con call strcmp
	sub rsp,8

	mov rdi, r12 ; char* rdi =  habilidad
	mov rsi, r9; char* rsi = carta->dir[i].ability_name
	call strcmp

	add rsp, 8 
	pop r9; restauro el valor de r9

	cmp rax, 0 ; Si strcmp me devolvio cero...
	jne .ciclo1
	
	mov rdi, rbx;card* rdi = carta
	call [r9 + DIRENTRY_PTR_OFFSET]
	jmp .fin


.finciclo1:

	mov rbx, [rbx + FANTASTRUCO_ARCHETYPE_OFFSET]; card* rbx = carta ->__archetype

	cmp rbx, 0 ; if rbx == NULL
	je .fin ; termino el programa



	mov r13, [rbx + FANTASTRUCO_ENTRIES_OFFSET]; uint16_t r13 = carta->__dir_entries
	mov r14, [rbx + FANTASTRUCO_DIR_OFFSET]; directory_t r14 = carta-> directorio

.ciclo2:
	dec r13
	cmp r13, 0
	jl .finciclo1; if r13 < 0

	mov r9, [r14 + r13*8]; directory_entry_t r9 = carta-> dir[i]

	push r9 ; preservo el valor de r9 en la pila para no perderlo con call strcmp
	sub rsp,8

	mov rdi, r12 ; char* rdi =  habilidad
	mov rsi, r9; char* rsi = carta->dir[i].ability_name
	call strcmp

	add rsp, 8 
	pop r9; restauro el valor de r9

	cmp rax, 0 ; Si strcmp me devolvio cero...
	jne .ciclo1
	
	mov rdi, rbx;card* rdi = carta
	call [r9 + DIRENTRY_PTR_OFFSET]
	jmp .fin


.fin:
	pop r14
	pop r13
	pop r12
	pop rbx
	pop rbp

	ret ;No te olvides el ret!
