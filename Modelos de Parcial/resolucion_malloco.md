# Resolucion Ejercicio 1

Para poder añadir estas funciones a nuestro kernel, debemos implementar muchas cosas. Una de esas es una syscall para que una tarea con nivel de privilegio User
pueda pedir memoria. Esta activaria la interrupción en ASM mediante la instrucción int90. Por otro lado, también debemos otorgarle a la tarea la capacidad de liberar 
esa memoria. El método que usaremos es __void chau(virtaddr_t virt)__ y la tarea podrá utilizarlo mediante la instrucción int91. Para que esto funcione, debemos
añadir en idt.c las lineas:
```C
    IDTENTRY3(90); //Malloco
    IDTENTRY3(91); //Chau
```

Y en isr.asm este código:

# ISR (en ASM)
    ;Por la convencion que armé yo, si tengo que pasar algun parametro a la interrupción, se lo pasaré por el registro ecx
    isr90: ;Uso la 90 ya que cualquiera a partir de la 88 es Syscall
        pushad
        
        push ecx; Convencion -> Va por la pila
        call malloco
        add esp, 4

        mov [esp + OFFSET_EAX], eax; por convencion

        popad
        iret 

    isr91: ;CHAUUU 
        pushad

        push ecx;Aca esta mi dirección virtual
        call chau
        add esp, 4

        mov [esp + OFFSET_EAX], eax;

        popad
        iret


Obviamente, para que esto funcione en el archivo isr.asm debemos invocar a las funciones como extern 

Además, como dice la consigna, debemos mapear la memoria recien cuando se intenta acceder a la misma y, por otro lado, debemos cambiar el estado de la misma (a 2) para que luego sea desmapeada por el garbage collector

```C
    bool page_fault_handler(vaddr_t virt) {
	print("Atendiendo page fault...", 0, 0, C_FG_WHITE | C_BG_BLACK);
	if ( ON_DEMAND_MEM_START_VIRTUAL <= virt <= ON_DEMAND_MEM_END_VIRTUAL) {
		mmu_map_page(rcr3(), ON_DEMAND_MEM_START_VIRTUAL, ON_DEMAND_MEM_START_PHYSICAL, MMU_U | MMU_W | MMU_P);
		return 1; //(TRUE)
	} else if(esMemoriaReservada(virt)){
		uint32_t cr3 = rcr3();
		vaddr_t new_phys_page = mmu_next_free_user_page();
		zero_page(new_phys_page);
		mmu_map_page(cr3 >> 3, virt, new_phys_page, MMU_U | MMU_W | MMU_P);
		return 1; //(TRUE)
	} else if (!(esMemoriaReservada(virt))){ //En este caso, debo desalojar la tarea INMEDIATAMENTE
		reserva_por_tarea* id_tarea = dameReservas(current_task);
        uint8_t i;
		for (i = 0; i < MAX_TASKS; i++){
			if (by_malloco[i].task_id = id_tarea){
				for (uint8_t j = 0; j < reservas_size; j++){
					by_malloco[i].array_reservas[j].estado = 2;
				}
			}
		}
        current_task +=1;
		return sched_tasks[i-1].selector;(CASO ESPECIFICO)
	}
	return false; (FALSE = 0)
    // Chequeamos si el acceso fue dentro del area on-demand
    // En caso de que si, mapear la pagina
    }   
```
Faltaría ejecutar la siguiente tarea inmediatamente después de que la memoria virtual que recibe el page_fault_handler se de cuenta que no es parte de la memoria reservada...
Para eso deberia programar saltar a la proxima tarea inmediatamente con un código que ejecute un far jump en la interrupción solo en caso de que el valor de ecx sea 12

La modificación seria la siguiente:
    global _isr14

    _isr14:
        pushad

        mov eax, cr2; CR2 guarda la dirección que causo el PF (fuente: https://wiki.osdev.org/Exceptions#Page_Fault)
        push eax
        call page_fault_handler

        cmp eax, 0
        je .serompe

        cmp eax, 12
        je .jfar

        add esp, 4 ; eax
        popad ; si se quiere acceder a una direccion entre 0x07000000 y 0x07000fff entonces debo mapear las direcciones virtuales a las fisicas

        add esp, 4 ; error code
        iret
        
        .serompe:
            call kernel_exception

        .jfar:
            mov word [sched_task_selector], ax
            jmp far [sched_task_offset]

        jmp $


# Resolucion Ejercicio 2

Otra cosa para implementar es añadir la tarea __garbage_collector__ al scheduler.
La idea de __garbage_collector__ es desmapear toda la memoria reservada que usan las tareas cuyo estado es 2. Una posible implementacion
de __garbage_collector__ es:
```C
    void garbage_collector(){
        while(true){
            for(uint8_t i = 0; i < (sizeof(by_malloco) / sizeof(reservas_por_tarea)); i++){
                for(uint8_t j = 0; j < by_malloco[i].reservas_size; j++){
                    reserva_t* current_alloc = &by_malloco[i].array_reservas[j];
                    if (current_alloc->estado == 2){ //Quiero desalojar toda la reserva de la memoria
                        for (uint8_t k = 0; k <  current_alloc.tamanio / 4096; k+=4096){
                            mmu_unmap_page(task_selector_to_CR3(sched_tasks[by_malloco[i].task_id]), current_alloc->virt + k);
                        }
                        current_alloc->estado = 3;
                    }
                }
            }
        }
    }

    uint32_t task_selector_to_CR3(uint16_t selector) {
        uint16_t index = selector >> 3; // Sacamos los atributos
        gdt_entry_t* taskDescriptor = &gdt[index]; // Indexamos en la gdt
        tss_t* tss = (tss_t*)((taskDescriptor->base_15_0) |
        (taskDescriptor->base_23_16 << 16) |
        (taskDescriptor->base_31_24 << 24));
        return tss->cr3;
    }
```
El método ya está completo... Lo único que me falta es completar el código para que la tarea se ejecute cada 100 ticks.
Para eso, voy a modificar la interrupción del clock para que cada vez que se ejecute, tenga un contador de ticks y cuando llegue a 100, ahí ejecutar la tarea.
Si quiero que esto funcione, debo añadir la tarea al scheduler, pero que sea un caso aparte... Que no se ejecute cuando la lista sea iterada hasta su ubicación, sino que sólo se ejecute cada 100 ticks. Para eso debo incrementar el valor de la macro MAX_TASKS (pero el scheduler no va a iterar hasta el último elemento que sería la tarea del garbage_collector). Además, crear la tarea con su TSS y su descriptor en la GDT, y por último añadirla al scheduler.

# En ASM
    ; COMPLETAR (Parte 2: Interrupciones): La rutina se encuentra escrita parcialmente. Completar la rutina
global _isr32
  
_isr32:
   pushad
	call pic_finish1
	
   	call next_clock

    call sched_next_task

    call nomorethan_100
  
    str cx
    cmp ax, cx
    je .fin
    
    mov word [sched_task_selector], ax
    jmp far [sched_task_offset]
    
    .fin:

    call tasks_tick

    call tasks_screen_update
    popad
    iret


# En C:
```C
    #define MAX_TASKS (2*2) + 1

    uint8_t garbage_ticks_counter = 0;

    typedef enum {
    TASK_A = 0,
    TASK_B = 1,
    TASK_C = 2,
    } tipo_e;

    static paddr_t task_code_start[3] = {
    [TASK_A] = TASK_A_CODE_START,
    [TASK_B] = TASK_B_CODE_START,
    [TASK_C] = &garbage_collector,
    };


    uint8_t nomorethan_100(){
        garbage_ticks_counter += 1;
        if(garbage_ticks_counter == 100){
            garbage_ticks_counter = 0; //Lo seteo en 0 devuelta
        }
    }

    tss_t tss_create_kernel_task(vaddr_t code_start) {
        vaddr_t stack = mmu_next_free_kernel_page();
        return (tss_t) {
        .cr3 = create_cr3_for_kernel_task(),
        .esp = stack + PAGE_SIZE,
        .ebp = stack + PAGE_SIZE,
        .eip = (vaddr_t)code_start,
        .cs = GDT_CODE_0_SEL,
        .ds = GDT_DATA_0_SEL,
        .es = GDT_DATA_0_SEL,
        .fs = GDT_DATA_0_SEL,
        .gs = GDT_DATA_0_SEL,
        .ss = GDT_DATA_0_SEL,
        .ss0 = GDT_DATA_0_SEL,
        .esp0 = stack + PAGE_SIZE,
        .eflags = EFLAGS_IF,
        };
    }

    paddr_t create_cr3_for_kernel_task() {
        // Inicializamos el directorio de paginas
        paddr_t task_page_dir = mmu_next_free_kernel_page();
        zero_page(task_page_dir);

        // Realizamos el identity mapping
        for (uint32_t i = 0; i < identity_mapping_end; i += PAGE_SIZE) { //No se qué deberia ir en identity_mapping_end... ¿1024 * PAGE_SIZE?
        mmu_map_page(task_page_dir,i, i, MMU_W);
        }
        return task_page_dir;
    }



    uint8_t garbage_index; //Creo la tarea y tengo el index del scheduler (Lo defino en tasks_init)

    //Para inicializar la tarea, nos faltaría añadirla a la funcion tasks_init:

    void tasks_init(void) {
        int8_t task_id;
        // Dibujamos la interfaz principal
        tasks_screen_draw();

        // Creamos las tareas de tipo A
        task_id = create_task(TASK_A);
        sched_enable_task(task_id);
        task_id = create_task(TASK_A);
        sched_enable_task(task_id);
        task_id = create_task(TASK_A);
        sched_enable_task(task_id);

        // Creamos las tareas de tipo B
        task_id = create_task(TASK_B);
        sched_enable_task(task_id);

        //Creamos las tareas de tipo C (garbage collector)
        garbage_index = create_task(TASK_C);
        sched_enable_task(garbake_index);
    }


    static int8_t create_task(tipo_e tipo) { //Copio create_task porque la modifico 
            size_t gdt_id;
            for (gdt_id = GDT_TSS_START; gdt_id < GDT_COUNT; gdt_id++) { // Busca la primera entry vaciá de la GDT, después del índice 12 
                if (gdt[gdt_id].p == 0) {
                break;
                }
            }
            kassert(gdt_id < GDT_COUNT, "No hay entradas disponibles en la GDT");
            // Pregunta: Por qué GDT_COUNT es 35?

            int8_t task_id = sched_add_task(gdt_id << 3); // El parámetro es un segment selector de TSS con los atributos.
            tss_tasks[task_id] = tss_create_kernel_task(task_code_start[tipo]); //LINEA CAMBIADA
            gdt[gdt_id] = tss_gdt_entry_for_task(&tss_tasks[task_id]);
            return task_id;
    }

    uint16_t sched_next_task(void) { //Modifico también este método, ya que solo llama a garbage collector en un caso en particular
    // Buscamos la próxima tarea viva (comenzando en la actual)
    int8_t i;
    for (i = (current_task + 1); (i % (MAX_TASKS - 1)) != current_task; i++) { //Es MAX_TASKS -1 porque no quiero que la ultima sea contada
        // Si esta tarea está disponible la ejecutamos
        if (sched_tasks[i % MAX_TASKS].state == TASK_RUNNABLE) {
        break;
        }
    }

    // Ajustamos i para que esté entre 0 y MAX_TASKS-1
    i = i % MAX_TASKS;

    if (garbage_ticks_counter == 100){
        i = garbage_index; //Es el unico caso en el que i puede tomar el valor de i talque sched_tasks[i].selector = garbage_selector
    }

    // Si la tarea que encontramos es ejecutable entonces vamos a correrla.
    if (sched_tasks[i].state == TASK_RUNNABLE) {
        current_task = i;
        return sched_tasks[i].selector;
    }

    // En el peor de los casos no hay ninguna tarea viva. Usemos la idle como
    // selector.
    return GDT_IDX_TASK_IDLE << 3;
    }
```

# Resolución Ejercicio 3

a)Indicar dónde podría estár definida la estructura que lleva registro de las reservas (5 puntos)
Estamos hablando de la siguiente estructura:
```C
    typedef struct {
        uint32_t task_id;
        reserva_t* array_reservas;
        uint32_t reservas_size;
    } reservas_por_tarea; 
```
La misma esta muy relacionada a las tareas y al manejo de memoria... Como se va a armar una lista de este tipo y será modificada por los métodos 
_malloco_ y _chau_ , creo que la estructura debe estar ubicada en el mismo archivo que aquellos métodos. Y yo como programador, ubicaría esos métodos en mmu.c.


b)Dar una implementación para `malloco` (10 puntos)

Considerando:
- Como máximo, una tarea puede tener asignados hasta 4 MB de memoria total. Si intenta reservar más memoria, la syscall deberá devolver `NULL`.
- El área de memoria virtual reservable empieza en la dirección `0xA10C0000`
- Cada tarea puede pedir varias veces memoria, pero no puede reservar más de 4 MB en total.
- No hace falta contemplar los casos en que las reservas tienen tamaños que no son múltiplos de 4KB. Es decir, las reservas siempre van a ocupar una cantidad de páginas, y dos reservas distintas nunca comparten una misma página.

Para implementar malloco, creo una variable que comienza teniendo el valor 0xA10C0000 y va incrementando a medida que se va reservando la memoria. Esta variable se actualiza a medida que se reserva memoria y ese valor siempre sera el que devuelve la funcion malloco (a excepcion cuando la tarea quiere reservar mas de 4MB)

```C
        static vaddr_t next_malloco_free_page = 0xA10C0000;
        void* malloco(size_t size){
            reservas_por_tarea_t* reservas = dameReservas(current_task);
            reserva_t* current_array_reservas = reservas->array_reservas;

            void* res = (void*) next_malloco_free_page;

            //Ahora quiero calcular que la memoria reservada de esa tarea no sea mayor a 4MB
            uint32_t total_memory = 0;
            for(uint8_t i = 0; i < reservas->reservas_size; i ++){
                total_memory += reservas->array_reservas[i].tamanio;
            }
            if (total_memory + size >= 4096*4096) return NULL; //Ya que 4096 * 4096 = 4MB

            //Ahora quiero reservar la memoria:
            reserva_t new_reserve = {
                .virt = next_malloco_free_page,
                .tamanio = size,
                .estado = 1
            };

            reservas -> array_reservas[reservas_size] = new_reserve; //Encolo el elemento
            reservas -> reservas_size ++; // Le sumo uno a la cantidad de elementos que tiene la lista

            next_malloco_free_page += (vaddr_t) size;
            return next_malloco_free_page - (vaddr_t) size;

        }
```

c)Dar una implementación para `chau` (10 puntos)

Considerando:
- Si se pasa un puntero que no fue asignado por la syscall `malloco`, el comportamiento de la syscall `chau` es indefinido.
- Si se pasa un puntero que ya fue liberado, la syscall `chau` no hará nada.
- Si se pasa un puntero que pertenece a un bloque reservado pero no es la dirección más baja, el comportamiento de la syscall `chau` es indefinido.
- Si la tarea continúa usando la memoria una vez liberada, el comportamiento del sistema es indefinido.
- No nos preocuparemos por reciclar la memoria liberada, bastará con liberarla

Para este metodo, mi plan es iterar toda la lista de reservas_por_tarea y en cada elemento verificar si la direccion virtual alocada en el mismo es igual a la que me pasan por parametro
```C
    void chau(virtaddr_t virt){
        for(uint8_t i = 0; i < (uint8_t) (sizeof(by_malloco) / sizeof(reservas_por_tarea)); i++){
            reservas_por_tarea* actual_task = &by_malloco[i];
            for(uint8_t j = 0; j < actual_task->reservas_size; j++){
                if(actual_task->array_reservas[j].virt == virt){
                    actual_task->array_reservas[j]->estado =2;
                    return;
                }
            }
        }
    }
```
# Nuevas estructuras
Estas estructuras son parte de la memoria del kernel porque modifican memoria que utiliza el OS.
**C** 
```C
        typedef struct {
            uint32_t task_id;
            reserva_t* array_reservas;
            uint32_t reservas_size;
        } reservas_por_tarea; 


        typedef struct {
            uint32_t virt; //direccion virtual donde comienza el bloque reservado
            uint32_t tamanio; //tamaño del bloque en bytes
            uint8_t estado; //0 si la casilla está libre, 1 si la reserva está activa, 2 si la reserva está marcada para liberar, 3 si la reserva ya fue liberada
        } reserva_t; 


//Necesito armar un array del tipo reservas_por_tarea, donde alojaré todas las tareas que reciban su memoria a partir de la función malloco.

    static reservas_por_tarea by_malloco[MAX_TASKS] = {0}; Le agrego elementos cada vez que se usa malloc

    bool esMemoriaReservada(virtaddr_t virt){
        for(uint8_t i = 0; i < MAX_TASKS; i++){
            reservas_por_tarea current_task = by_malloco[i];
            for(uint8_t j = 0; j < sizeof(current_task.array_reservas) / 12; j++){ //Divido por 12 ya que es el tamaño de cada elemento y quiero iterar de a uno.
                if(current_task.array_reservas[j].estado == 1 || current_task.array_reservas[j].estado == 2) 
                    return true;
            }
        }
        return false; //Si no encontré 
    }

    reservas_por_tarea* dameReservas(int task_id){
        for(uint8_t i = 0; i < MAX_TASKS; i++){
            if(by_malloco[i].task_id == task_id) return &by_malloco[i];
            else return null;
        }
    }

Bien hecho, no se donde aplicarlo todavia:

Para eso, debemos  añadirla al scheduler y hacer el mapeo en memoria. Esta función tiene sentido que sólo sea ejecutable por código con privilegio nivel 0 

    MAX_TASKS += 1; //Debo actualizar la macro

    sched_entry_t gcollector = {
        .selector = &garbage_collector,
        .state = TASK_PAUSED,
    };

    sched_entry_t* sched_tasks[sizeof(sched_tasks)/sizeof(sched_entry) - 1] = gcollector;
