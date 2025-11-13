# Parejas
**Funciones a disposición:**

*   `task_id pareja_de_actual()`: si la tarea actual está en pareja devuelve el `task_id` de su pareja, o devuelve 0 si la tarea actual no está en pareja.
*   `bool es_lider(task_id tarea)`: indica si la tarea pasada por parámetro es lider o no.
*   `bool aceptando_pareja(task_id tarea)`: si la tarea pasada por parámetro está en un estado que le permita formar pareja devuelve 1, si no devuelve 0.
*   `void conformar_pareja(task_id tarea)`: informa al sistema que la tarea actual y la pasada por parámetro deben ser emparejadas. Al pasar `0` por parámetro, se indica al sistema que la tarea actual está disponible para ser emparejada.
*   `void romper_pareja()`: indica al sistema que la tarea actual ya no pertenece a su pareja actual. Si la tarea actual no estaba en pareja, no tiene efecto.

## Ejercicio 1

*   ### **Punto 1**

Para implementar las syscalls crear\_pareja, juntarse\_con y abandonar\_pareja, primero será necesario definir las funciones y estructuras correspondientes para invocarlas.

En primer lugar, por el hecho de que estas funciones son syscalls, será necesario modificar las entradas en la IDT, asignares a cada syscall un número de interrupción válido, digamos INT 66, INT 67 e INT 68. Para ello, en el archivo _idt.c_ usamos la macro IDT\_ENTRY3(número de interrupción) en la función idt\_init(), ingresándolas en la IDT con los permisos adecuados para ser llamadas por el usuario.  
Luego, hay que escribir los manejadores de interrupciones en el archivo _isr.asm_. A continuación, exhibo el código para cada uno de los manejadores.

> [!NOTE]
> Nota:  
> El caso de la ISR 67 es especial porque es una syscall que toma parámetros. Decidí que serán pasados por el registro EAX, y que el resultado de la syscall será devuelto también por el mismo registro.

**ISR 66**

```
global _isr66

_isr66:
    pushad

    call crear_pareja
    
    popad
    iret
```

**ISR 67**

```
global _isr67

_isr67: ; int id_tarea entra por eax
    pushad
    push eax

    call juntarse_con

    add esp, 4
    mov [esp + offset_EAX], eax ; guardo el resultado de juntarse_con en el lugar del eax que se recuperará 
    popad
    iret
```

**ISR\_68**

```
global _isr68

_isr68:
    pushad

    call abandonar_pareja

    popad
    iret
```

**En idt.c**

```csrc
void idt_init() {
...
// Syscalls
IDT_ENTRY3(66);
IDT_ENTRY3(67);
IDT_ENTRY3(68);
...
}
```

Finalmente, no hay que olvidarse de modificar _isr.h_ y agregar las definiciones:

```
void _isr66();
void _isr67();
void _isr68();
```

Una vez modificada la IDT y los manejadores de interrepciones, el siguiente paso es llavar a cabo la implementación de las funciones requeridas. Entonces, en un archivo aparte llamado _parejas.c_ definiré las funciones de la siguiente manera.

Pero antes de eso, es imperativo modificar las estructuras en _sched.c_ para que las funciones tengan a su disposición la información suficiente para cumplir sus porpósitos.

```csrc
typedef enum {
  TASK_SLOT_FREE,
  TASK_RUNNABLE,
  TASK_PAUSED,
  // Nuevo
  TASK_BUSCANDO,
  TASK_LIDER,
  TASK_SLAVE
} task_state_t;

/**
 * Estructura usada por el scheduler para guardar la información pertinente de
 * cada tarea.
 */
typedef struct {
  int16_t selector;
  task_state_t state;

  int8_t pareja_id; //La identidad de la parja si es que la tiene, si no, cero
} sched_entry_t;
```

> [!NOTE]
> Nota:  
> Hay que modificar el scheduler para que cuente TASK\_BUSCANDO como TASK\_PAUSED

```csrc
uint16_t sched_next_task(void) {
  // Buscamos la próxima tarea viva (comenzando en la actual)
  int8_t i;
  for (i = (current_task + 1); (i % MAX_TASKS) != current_task; i++) {
    // Si esta tarea está disponible la ejecutamos
    if (sched_tasks[i % MAX_TASKS].state == TASK_RUNNABLE || sched_tasks[i % MAX_TASKS].state == TASK_LIDER || sched_tasks[i % MAX_TASKS].state == TASK_SLAVE) {
      break;
    }
  }

  // Ajustamos i para que esté entre 0 y MAX_TASKS-1
  i = i % MAX_TASKS;

  // Si la tarea que encontramos es ejecutable entonces vamos a correrla.
  current_task = i;
  return sched_tasks[i].selector;

  // En el peor de los casos no hay ninguna tarea viva. Usemos la idle como
  // selector.
  return GDT_IDX_TASK_IDLE << 3;
}
```

Modifico el Page Fault Handler para que pueda asignar memoria dinámicamente a las tareas en parerja que lo requieran.

**page\_fault\_handler()**

```csrc
#define PAREJA_START 0xC0C00000
#define PAREJA_END   PAREJA_START + 0x1000 * 0x3FF // PAREJA_START + casi 4MB
#include "shared.h"
...
...
...
bool page_fault_handler(vaddr_t virt) {
	print("Atendiendo page fault...", 0, 0, C_FG_WHITE | C_BG_BLACK);
	// Tengo que conseguir la task ID.
	uint32_t cr3 = rcr3();
	int8_t current_task = ENVIRONMENT->task_id;
	
	if ( ON_DEMAND_MEM_START_VIRTUAL <= virt <= ON_DEMAND_MEM_END_VIRTUAL ) {
		mmu_map_page(cr3, ON_DEMAND_MEM_START_VIRTUAL, ON_DEMAND_MEM_START_PHYSICAL, MMU_U | MMU_W | MMU_P);
		return true;
	} else if ( !aceptandoPareja(current_task) && PAREJA_START <= virt <= PAREJA_END) { // Si no está aceptando pareja, es porque está en pareja, excepto que tenga un corazón enorme...
		// Tengo que ver cuál es primera entry ausente en la estructura de paginación a partir de PAREJA_START
		uint32_t primeraLibre = firstFreeParejaPage(cr3);
		if (!primeraLibre) return false;
		if (es_lider(current_task)) {
			mmu_map_page(cr3, primeraLibre, mmu_next_user_page(), MMU_U | MMU_W | MMU_P);
		} else {
			mmu_map_page(cr3, primeraLibre, mmu_next_user_page(), MMU_U | MMU_P);
		}
		zero_page(primeraLibre); // Llena la página de ceros.
		return true;
	}
	else return false; 
}

uint32_t firstFreeParejaPage(uint32_t cr3) {
	/*
	Devuelve la primera página que esté libre a partir de PAREJA_START. Si no hay páginas libres, devuelve cero.
	*/
	pd_entry_t* page_directory = (pd_entry_t*) (CR3_TO_PAGE_DIR(cr3));
	uint32_t pd_index = VIRT_PAGE_DIR(PAREJA_START);
	pd_entry_t* pde = &page_directory[pd_index];
	
	for (uint32_t i = PAREJA_START; i < PAREJAS_END; i += PAGE_SIZE) { // Me fijo en todas las páginas hasta que una esté libre
		pt_entry_t* pte = &pt_addr[VIRT_PAGE_TABLE(i)];
		if (!(pte->attrs & 1)) { // Si la página está ausente, devuelvo su dirección.
			return i;
		}
	}
	
	return 0; // Si no, devuelve cero.
}
```

**crear\_pareja()**

```csrc
void crear_pareja() {
	sched_entry_t* current_task_entry = &sched_tasks[ENVIRONMENT->task_id];
    if (current_task_entry->state == TASK_LIDER || current_task_entry->state == TASK_SLAVE) return;
    conformarPareja(0); // Avisa al kernel que está buscando pareja
    //La memoria se maneja sola
    
}
```

**juntarse\_con(lider\_id)**

```csrc
void juntarse_con(lider_id) {
	task_id_t current_task_id = ENVIRONMENT->task_id;
	sched_entry_t* current_task_entry = &sched_tasks[current_task_id];
    if (!aceptando_tarea(current_task_id) || !aceptando_tarea(lider_id)) return 1;
    conformar_pareja(lider_id);
    // La memoria se maneja sola
    return 0;
}
```

**abandonar\_pareja()**

```csrc
void abandonar_pareja() {
	uint8_t current_task_id = ENVIRONMENT->task_id;
	sched_entry_t* current_task_entry = &sched_tasks[current_task_id]; // Los datos de la tarea actual
	uint32_t cr3 = rcr3(); // El cr3 de la tarea actual
	
	if (!(pareja_de_actual())) return;
	sched_entry_t* pareja_entry = &sched_tasks[pareja_de_actual()]; // Busca a su pareja
	
    if (current_task_entry->state == TASK_SLAVE) { // Si la tarea es una esclava...
    	// Si su pareja ya no se considera en pareja (era el líder), la despausa.
    	if (pareja_entry->pareja_id != current_task_id) pareja_entry->state = TASK_RUNNABLE;
    } else if (current_task_entry->state == TASK_LIDER) {
    	// Si es el líder, simplemente se va de la pareja y queda pausada hasta que la otra se vaya también.
    	// Except que la otra ya se haya ido, en cuyo caso no abandona la pareja y sigue corriendo
    	if (pareja_entry->pareja_id == current_task_id) current_task_entry->state = TASK_PAUSED; // Si todavía tiene esclavo, la pausa hasta que el esclavo se de cuenta y se escape.
    }
    
    romper_pareja(); // Sale de la pareja si es que estaba, si no, no hace nada.
    desmapear_pareja(cr3); //Desmapeo memoria si es que estaba mapeada
}
```

**despamear\_pareja(cr3)**

```csrc
void desmapear_pareja(uint32_t cr3) {
	for (uint32_t i = PAREJA_START; i < PAREJA_END; i += PAGE_SIZE)
		mmu_unmap_page(cr3, i);
}
```

*   ### **Punto 2**

**conformar\_pareja()**

```csrc
void conformar_pareja(task_id_t tarea_id) {
	task_id_t current_task_id = ENVIRONMENT->task_id;
	sched_entry_t* current_task_entry = &sched_tasks[current_task_id];
	sched_entry_t* task_entry = &sched_tasks[tarea_id];
	
	if (!aceptando_pareja(current_task_id)) return; // Si la tarea que llamó la función no acepta pareja, no hacer nada.
	
	if (!tarea_id) { // Si el parámetro es 0, entonces la que llamó empieza a buscar
		current_task_entry->state = TASK_BUSCANDO;
	}
	else if (task_entry.state == TASK_BUSCANDO) { // Si la tarea pasada por parámetro efectivamente está buscando, empareja
		tarea_id->state = TASK_LIDER;
		tarea_id->pareja_id = tarea_id;
		current_task_entry->state = TASK_SLAVE;
		current_task_entry->pareja_id = lider_id;
	}
}
```

**romper\_pareja()**

```
void romper_pareja() {
	task_id_t current_task_id = ENVIRONMENT->task_id;
	sched_entry_t* current_task_entry = &sched_tasks[current_task_id];
	current_task_entry->pareja_id = 0; //Si la tarea no tenía pareja, su pareja_id ya estaba en 0, por lo que da igual.
	
}
```

*   ### **Punto 3**

**pareja\_de\_actual()**

```
void pareja_de_actual() {
	task_id_t current_task_id = ENVIRONMENT->task_id;
	sched_entry_t* current_task_entry = &sched_tasks[current_task_id];
	task_id_t pareja = current_task_entry->pareja_id;
	return pareja;
}
```

**es\_lider()**

```
bool es_lider() {
	task_id_t current_task_id = ENVIRONMENT->task_id;
	sched_entry_t* current_task_entry = &sched_tasks[current_task_id];
	task_id_t estado = current_task_entry->state;
	return estado == TASK_LIDER;
}
```

**aceptando\_pareja()**

```
bool aceptando_pareja(task_id_t tarea_id) {
	sched_entry_t* task_entry = &sched_tasks[tarea_id]; 
    if (task_entry->state == TASK_LIDER || task_entry->state == TASK_SLAVE) return 0;
	return 1;
}
```

* * *

## **Ejercicio 2**

```csrc
typedef struct {
	sched_entry_t p1;
	sched_entry_t p2;
} pareja_t;

uint32_t uso_de_memoria_de_las_parejas() {
	/*
	Creo una variable llamada uint32_t suma_de_memoria = 0;.
	Primero tengo que hacer una conjunto de tuplas (structs) de las parejas, donde sus elementos son de la forma (p1, p2).
		- Defino el tipo Pareja como un struct con campos p1 y p2.
		- Creo una copia de sched_tasks con la cual trabajar. También creo el array de tipo Pareja ingeniosamente llamado "parejas".
		- Luego loopeo sobre la copia de sched_tasks. Por cada elemento, si tiene pareja, la busco y los saco a ambos del array.
		  Creo un struct que los guarde y los sumo a Parejas. Repito este proceso hasta llegar al final del array.
	Luego, por cada pareja, armo el conjunto de páginas páginas presentes a partir de C0C0 y los 4MBs siguientes que tengan mapeadas.
		- Creo el array de uint32_t "paginas".
		- Primero loopeo sobre la estructura de paginación del líder a partir de 0xC0C0, y cada entrie presente la sumo al array paginas.
		- Luego repito el proceso con el esclavo, pero antes de meter una dirección a páginas chequeo aún no pertenezca.
		- Repito para cada pareja.
	Luego, por cada conjunto, calculo su largo y lo multiplico por 0x1000. Sumo el resultado a suma_de_memoria.
	Una vez que terminé con todas las parejas, devuelvo suma_de_memoria.
	*/
	
	
	uint32_t suma_de_memoria = 0;
	sched_entry_t sched_copy[MAX_TASKS] = copy_array(sched_tasks); // Asumo que existe copy_array
	int8_t copy_index = 0;
	pareja_t parejas[MAX_TASKS] = {0}; // Sé que podría haber menos parejas que MAX_TASKS, pero esto sirve.
	
	for (int8_t i = 0; i < MAX_TASKS; i++) {
		sched_entry_t* actual = &sched_tasks[i];
		if (actual->state == TASK_LIDER || actual->state == TASK_SLAVE) {
			task_id_t pareja_id = actual->pareja_id;
			if (pareja_id) {
				parejas[copy_index] = { .p1 = *actual, .p2 = sched_tasks[pareja_id] }; // Esto es como inicializar una struct con todos 0.
				eliminar(&sched_copy, sched_tasks[pareja_id]); // Asunmo que eliminar(arr, elem) existe
			}
			else { parejas[copy_index] = { .p1 = *actual, .p2 = (sched_entry_t*){0} }; }
			eliminar(&sched_copy, *actual);
			copy_index++;
		}
	}
	// En este punto, finalmente, tengo mi conjunto.
	
	for (int8_t i = 0; i < MAX_TASKS; i++) {
		pareja_t pareja = &parejas[i];
		if (!pareja->p1) break; // Esto quiere decir que no hay más parejas en la lista, pues la manera en que lo hice implica que p1 no pede ser nunca cero
		uint32_t* paginas_p1 = encontrar_paginas_COCO(pareja->p1); 
		//Asumo que definí esta función (no es difícil) que encuentra las páginas presentes después de PAREJAS_START y devulelve un puntero a un array con sus direcciones.
		// Se que esto es imposible en C sin malloc, pero uno se podría imaginar que en vez de usar esta función escribiríamos el código y listo, pero no tengo tiempo para ello.
		uint32_t* paginas_p2 = encontrar_paginas_COCO(pareja->p2);
		
		// Bueno sigue pero no me da...
	}
	
	
}
```