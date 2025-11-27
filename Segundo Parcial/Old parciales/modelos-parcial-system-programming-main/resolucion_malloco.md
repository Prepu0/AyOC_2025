# Resolucion Ejercicio 1

Para poder añadir estas funciones a nuestro kernel, debemos implementar muchas cosas. Una de esas es una syscall para que una tarea con nivel de privilegio User
pueda pedir memoria. Esta activaria la interrupción en ASM mediante la instrucción int90. Por otro lado, también debemos otorgarle a la tarea la capacidad de liberar 
esa memoria. El método que usaremos es __void chau(virtaddr_t virt)__ y la tarea podrá utilizarlo mediante la instrucción int91. Para que esto funcione, debemos
añadir en idt.c las lineas:

    IDTENTRY3(90); //Malloco
    IDTENTRY3(91); //Chau


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

# Resolucion Ejercicio 2

Otra cosa para implementar es añadir la tarea __garbage_collector__ al scheduler.
La idea de __garbage_collector__ es desmapear toda la memoria reservada que usan las tareas cuyo estado es 2. Una posible implementacion
de __garbage_collector__ es:

    void garbage_collector(){
        while(true){
            for(uint8_t i = 0; i < sizeof(by_malloco); i++){
                for(uint8_t j = 0; j < sizeof(by_malloco[i].reservas_size); j++){
                    reserva_t current_alloc by_malloco[i].array_reservas[j];
                    if (current_alloc.estado == 2){ //Quiero desalojar toda la reserva de la memoria
                        for (uint8_t k = 0; k <  current_alloc.tamanio / 4096; k++){
                            mmu_unmap_page(current_alloc.virt + (k * 4096));
                        }
                        current_alloc.estado = 3;
                    }
                }
            }
        }
    }

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


# Resolución Ejercicio 3

a)Indicar dónde podría estár definida la estructura que lleva registro de las reservas (5 puntos)
Estamos hablando de la siguiente estructura:

    typedef struct {
        uint32_t task_id;
        reserva_t* array_reservas;
        uint32_t reservas_size;
    } reservas_por_tarea; 

La misma esta muy relacionada a las tareas y al manejo de memoria... Como se va a armar una lista de este tipo y será modificada por los métodos 
_malloco_ y _chau_ , creo que la estructura debe estar ubicada en el mismo archivo que aquellos métodos. Y yo como programador, ubicaría esos métodos en mmu.c.


b)Dar una implementación para `malloco` (10 puntos)

Considerando:
- Como máximo, una tarea puede tener asignados hasta 4 MB de memoria total. Si intenta reservar más memoria, la syscall deberá devolver `NULL`.
- El área de memoria virtual reservable empieza en la dirección `0xA10C0000`
- Cada tarea puede pedir varias veces memoria, pero no puede reservar más de 4 MB en total.
- No hace falta contemplar los casos en que las reservas tienen tamaños que no son múltiplos de 4KB. Es decir, las reservas siempre van a ocupar una cantidad de páginas, y dos reservas distintas nunca comparten una misma página.

    
    static paddr_t next_free_kernel_page = 0xA10C0000; //Modifico el valor de la variable
    void* malloco(size_t size){
        uint32_t cr3 = rcr3(); //Voy a necesitar el PD de la tarea que llamó

        for(uint8_t i = 0; i < size ; i += PAGE_SIZE){
            
        }


    }

# Nuevas estructuras
Estas estructuras son parte de la memoria del kernel porque modifican memoria que utiliza el OS.
**C** 

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


Necesito armar un array del tipo reservas_por_tarea, donde alojaré todas las tareas que reciban su memoria a partir de la función malloco.

    reservas_por_tarea* by_malloco [MAX_TASKS] = {0}; Le agrego elementos cada vez que se usa malloc

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
