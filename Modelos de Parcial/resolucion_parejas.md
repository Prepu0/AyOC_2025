# Ejercicio 1

Para añadir estas nuevas funcionalidades al kernel, debemos hacer muchas modificaciones. Yo comenzaría modificando las estructuras relacionadas a las tareas... 

```C
    typedef struct {
  int16_t selector;
  task_state_t state;
  pareja_t pareja; //Aniado este struct
} sched_entry_t;

typedef enum { 
  TASK_SLOT_FREE,
  TASK_RUNNABLE,
  TASK_PAUSED,
  TASK_BLOCKED,
} task_state_t; 

typedef enum { //Añado estados para ver el estado CIVIL de la tarea :D
    TASK_MARRIED,
    TASK_NOT_MARRIED,
    TASK_SEARCHING,
    TASK_WAITING, //(To be unallocated...)
} task_civil_state_t

typedef struct{
    int id_media_naranja; //Es el task_id de la pareja. -1 indica que no tiene pareja
    bool es_lider; //Indica si la tarea es lider o no
    task_civil_state_t estado_civil;
    uint32_t* memoria_reservada; //Cada vez que reservo memoria la encolo ahi
    int cant_memoria; //Cuenta cuantas reservas se hicieron (cant de paginas)
}pareja_t
```

En cuanto a código en C, mis modificaciones serían las siguientes:
```c
void crear_pareja(){
    sched_entry_t* tarea_actual = &sched_tasks[current_task]; //Guardamos la tarea
    if(tarea_actual->pareja.estado_civil == TASK_MARRIED) return; //Si ya tiene pareja => no hago nada
    else{
        tarea_actual->state = TASK_PAUSED; //Debo cambiar el criterio del scheduler

        tarea_actual->pareja.estado_civil = TASK_SEARCHING;
        tarea_actual->pareja.es_lider = true;
    }
}

//Para que esto funcione, debo modificar el scheduler para que nunca ejecute
//una tarea que su estado civil es BUSCANDO

void sched_enable_task(int8_t task_id) {
  kassert(task_id >= 0 && task_id < MAX_TASKS, "Invalid task_id");

  if(sched_tasks[task_id].pareja.estado_civil == TASK_SEARCHING || sched_tasks[task_id].state == TASK_BLOCKED) return;
  else sched_tasks[task_id].state = TASK_RUNNABLE;
}//De esta forma, solo se habilita una tarea si no esta BUSCANDO (estado marcado por crear_pareja()) ni esta BLOQUEADA (estado marcado por juntarse_con())

int8_t sched_add_task(uint16_t selector) {
  kassert(selector != 0, "No se puede agregar el selector nulo");
  
  // Todas las tareas van a comenzar con el mismo estado:
  pareja_t iniciando = {
    .id_media_naranja = -1,
    .es_lider = 0,
    .estado_civil = TASK_NOT_MARRIED,
    .memoria_reservada = {0}, //La inicializo en 0
    .cant_memoria = 0,
  };
 
 // Se busca el primer slot libre para agregar la tarea
  for (int8_t i = 0; i < MAX_TASKS; i++) {
    if (sched_tasks[i].state == TASK_SLOT_FREE) { // Como sched_tasks está inicializado con ceros y TASK_SLOT_FREE equivale a cero, en un principio todos los slots están libres.
      sched_tasks[i] = (sched_entry_t) {
        .selector = selector,
      	.state = TASK_PAUSED,
        .pareja = iniciando,
      };
      return i;
    }
  }
  kassert(false, "No task slots available");
}

int juntarse_con(int id_tarea){
    sched_entry_t* tarea_lider = &sched_tasks[id_tarea];
    if(tarea_lider->pareja.estado_civil != TASK_SEARCHING) return 1; //Tanto si la tarea ya esta en pareja como si NO esta BUSCANDO... Entonces devuelvo 1
    else{ //Si la tarea esta BUSCANDO (es lider) => se conforma la pareja
        tarea_lider->pareja.es_lider = true; //Ya que nunca se aclara si ya es lider, por las dudas lo seteo asi

        conformar_pareja(id_tarea); //Este metodo setea todo para que se conforme la pareja

        //Luego el acceso a memoria lo debe atender el Page Fault
        return 0
    }
}

void conformar_pareja(task_id tarea){
    sched_entry_t* actual = sched_tasks[current_task];
    if (tarea == 0){
        actual->pareja.estado_civil = TASK_SEARCHING;
        return;
    }
    //Actualizo la tarea actual
    actual->pareja.estado_civil = TASK_MARRIED;
    actual->pareja.id_media_naranja = tarea;

    //Actualizo la tarea pasada por parametro
    sched_entry_t* theother = sched_tasks[tarea];
    theother->pareja.estado_civil = TASK_MARRIED;
    actual->pareja.id_media_naranja = current_task;

    //Asumo que la tarea que ya es lider esta definida como tal y le cambio el estado
    if(actual->pareja.es_lider){
        actual->state=TASK_RUNNABLE;
    }else{
        theohter->state=TASK_RUNNABLE
    }
    return;
}


void abandonar_pareja(){
    sched_entry_t* tarea_actual = &sched_tasks[current_task];
    if(tarea_actual->pareja.estado_civil != TASK_MARRIED) return; //A quien va a abandonar si no esta en pareja? 

    else if(!(es_lider(current_task))){
        for(int i = 0; i < tarea_actual->pareja->cant_memoria; i++){
            vaddr_t desmapear = tarea_actual->pareja.memoria_reservada[i];
            mmu_unmap_page(rcr3(), desmapear);
        }//Desmapeo toda la memoria que tenia la tarea
        ;
        romper_pareja();

        sched_entry_t pareja_lider = sched_tasks[tarea_actual->pareja.id_media_naranja];

        if(pareja_lider->pareja.estado_civil == TASK_WAITING){//En este caso... la tarea lider estaba esperando a que abandone la pareja la otra tarea
            for(int i = 0; i < pareja_lider->pareja->cant_memoria; i++){
                vaddr_t desmapear = pareja_lider->pareja.memoria_reservada[i];
                uint32_t cr3_lider = task_selector_to_CR3(pareja_lider.selector);
                mmu_unmap_page(cr3_lider, desmapear); //Libero toda su memoria
            }           
            pareja_lider->state = TASK_RUNNABLE; //Es ejecutable
            pareja_lider->pareja.estado_civil = TASK_NOT_MARRIED; //No tiene pareja
            pareja_lider->pareja.es_lider = false;
            pareja_lider->pareja.cant_memoria = 0; //Ya no tiene memoria mapeada
            pareja_lider->pareja.memoria_reservada = {0}; //Ya no tiene memoria mapeada
        }else{ //Si la tarea NO-lider abandona pero la lider no lo hace...
            pareja_lider->pareja.id_media_naranja = -1; //Solo la desvinculo de la pareja, pero mantiene el es_lider y el estado_civil
        }
    }else{//Si la tarea esta en pareja y es su lider...
        if(tarea_actual->pareja.id_media_naranja == -1){ //Unico caso en el que pasa esto es cuando la pareja abandono
            for(int i = 0; i < tarea_actual->pareja->cant_memoria; i++){
            vaddr_t desmapear = tarea_actual->pareja.memoria_reservada[i];
            mmu_unmap_page(rcr3(), desmapear);
            }
        romper_pareja();
        }
    }
}

void romper_pareja(){
    sched_entry_t* actual = &sched_tasks[current_task];
    sched_entry_t* parejade = &sched_tasks[actual->pareja.id_media_naranja]
    if(actual->pareja.estado_civil != TASK_MARRIED) return; //Si la tarea actual no tiene pareja entonces no hago nada
    if(!(es_lider(current_task))){
        actual->pareja.estado_civil = TASK_NOT_MARRIED;
        actual->pareja.id_media_naranja = -1;
        actual->pareja.cant_memoria = 0;
        actual->pareja.memoria_reservada = {0};
        
    }else{ //Si la tarea actual es lider...
        if(parejade->pareja.estado_civil == TASK_MARRIED && parejade->pareja.id_media_naranja == current_task){ //Si la pareja SIGUE casada y con la tarea actual
            actual->pareja.estado_civil = TASK_WAITING; //Entonces solo le cambio el estado y cuando la otra decida liberamos todo
            actual->state = TASK_BLOCKED;//Podria ser PAUSED pero de esta manera no estoy permitiendo que sched_enable_task le cambie el estado
        }else{//Reseteo el estado del elemento
            actual->pareja.estado_civil = TASK_NOT_MARRIED;
            actual->pareja.es_lider = false;
            actual->pareja.cant_memoria = 0;
            actual->pareja.memoria_reservada = {0};
        }//Este caso en particular SOLO sucede cuando la tarea actual es lider y la otra tarea la abandono
    }   
}

task_id pareja_de_actual(){
    sched_entry_t* actual = &sched_tasks[current_task];
    if(actual->pareja.estado_civil != TASK_MARRIED) return;
    return actual->pareja.id_media_naranja;
}

bool es_lider(task_id tarea){
    return sched_tasks[tarea].pareja.es_lider == true;
}

bool aceptando_pareja(task_id tarea){
    int estado_civil_tarea = sched_tasks[tarea].estado_civil;
    if(estado_civil_tarea == TASK_NOT_MARRIED || estado_civil_tarea == TASK_SEARCHING) return 1;
    return 0;
}

//Creo este metodo para conseguir el cr3 de las tareas
uint32_t task_selector_to_CR3(uint16_t selector) {
    uint16_t index = selector >> 3; // Sacamos los atributos
    gdt_entry_t* taskDescriptor = &gdt[index]; // Indexamos en la gdt
    tss_t* tss = (tss_t*)((taskDescriptor->base_15_0) |
    (taskDescriptor->base_23_16 << 16) |
    (taskDescriptor->base_31_24 << 24));
    return tss->cr3;
}
```


Respecto a la `memoria`, solamente debo mapear la memoria a demanda, es decir que debo modificar la funcion a la que llama la rutina de PAGE FAULT (#14):

```C
bool page_fault_handler(vaddr_t virt) {
	print("Atendiendo page fault...", 0, 0, C_FG_WHITE | C_BG_BLACK);
	if ( ON_DEMAND_MEM_START_VIRTUAL <= virt <= ON_DEMAND_MEM_END_VIRTUAL) {
		mmu_map_page(rcr3(), ON_DEMAND_MEM_START_VIRTUAL, ON_DEMAND_MEM_START_PHYSICAL, MMU_U | MMU_W | MMU_P);
		return true;
	} else if(0xC0C00000 <= virt < 0XC0C00000 + (0x400000)){
        sched_entry_t* tarea_actual = &sched_tasks[current_task];
        sched_entry_t* tarea_otra = &sched_tasks[tarea_actual.pareja.id_media_naranja]

        if (tarea_actual->pareja.estado_civil != TASK_MARRIED) return false; //SOLO se mapea la memoria si la tarea tiene pareja

        uint32_t cr3 = rcr3(); //Consigo el cr3 de la tarea ACTUAL
        if(tarea_actual->pareja.es_lider == true){
            uint32_t cr3_lid = cr3;

            uint32_t cr3_NOT_lid = task_selector_to_CR3(sched_tasks[tarea_actual->pareja.id_media_naranja].selector); //cr3_NOT_lid es el cr3 de la otra tarea
        }else{
            uint32_t cr3_lid = task_selector_to_CR3(sched_tasks[tarea_actual->pareja.id_media_naranja].selector);

            uint32_t cr3_NOT_lid = cr3;
        }

        paddr_t new_shared_page = mmu_next_free_user_page();
        mmu_map_page(cr3_lid, virt, new_shared_page, MMU_U | MMU_W | MMU_P);
        mmu_map_page(cr3_NOT_lid, virt, new_shared_page , MMU_U | MMU_P);

        tarea_actual->pareja.cant_memoria ++;
        tarea_actual->pareja.memoria_reservada[tarea_actual->pareja.cant_memoria - 1] = virt;

        tarea_otra->pareja.cant_memoria ++;
        tarea_otra->pareja.memoria_reservada[tarea_otra->pareja.cant_memoria - 1] = virt;


        zero_page(virt);
        return true;
    }
	return false; 
}
```
Teniendo en cuenta que mi rutina isr14 es asi:

```asm
global _isr14

_isr14:
    pushad

    mov eax, cr2; CR2 guarda la dirección que causo el PF (fuente: https://wiki.osdev.org/Exceptions#Page_Fault)
    push eax
    call page_fault_handler

    cmp eax, 0
    je .serompe

    add esp, 4 ; eax
    popad ; si se quiere acceder a una direccion entre 0x07000000 y 0x07000fff entonces debo mapear las direcciones virtuales a las fisicas

    add esp, 4 ; error code
    iret
    
    .serompe:
        call kernel_exception
	jmp $
```
`Aclaracion:` Al modificar el sistema de paginacion de alguna tarea, ya sea con mmu_map_page() o mmu_unmap_page(), no ejecuto el flush de la TLB porque ya esta implementado en las funciones de mapeo de mi TP
# SYSCALLS

Sabemos que una Syscall es una rutina de atención que puede ser accedida por código y tareas con privilegio nivel 3 (User). Las mismas estan asociadas a un vector de interrupcion con el cual luego se indexa en la IDT y se busca el gate descriptor de la interrupcion. El numero que puede tomar este vector va desde el 48 hasta el 255, que son los reservador para interrupciones de software.
Para que las syscalls funcionen, debo añadir las mismas en la IDT con sus atributos correspondientes:
```C
    #define IDT_ENTRY3(numero)                                                     \
    idt[numero] = (idt_entry_t) {                                                \
    .offset_31_16 = HIGH_16_BITS(&_isr##numero),                               \
    .offset_15_0 = LOW_16_BITS(&_isr##numero),                                 \
    .segsel = GDT_CODE_0_SEL,                                                  \
    .type = D + interrupt_type,                                                \
    .dpl = 3,                                                                  \
    .present = 1                                                               \
  }
void idt_init() {
  // Excepciones
  IDT_ENTRY0(0);
  IDT_ENTRY0(1);
  IDT_ENTRY0(2);
  IDT_ENTRY0(3);
  IDT_ENTRY0(4);
  IDT_ENTRY0(5);
  IDT_ENTRY0(6);
  IDT_ENTRY0(7);
  IDT_ENTRY0(8);
  IDT_ENTRY0(9);
  IDT_ENTRY0(10);
  IDT_ENTRY0(11);
  IDT_ENTRY0(12);
  IDT_ENTRY0(13);
  IDT_ENTRY0(14);
  IDT_ENTRY0(15);
  IDT_ENTRY0(16);
  IDT_ENTRY0(17);
  IDT_ENTRY0(18);
  IDT_ENTRY0(19);
  IDT_ENTRY0(20);


  IDT_ENTRY0(32);
  IDT_ENTRY0(33);

  IDT_ENTRY3(70); //Syscall para crear_pareja()
  IDT_ENTRY3(71); //Syscall para juntarse_con(id_tarea)
  IDT_ENTRY3(72); //Syscall para abandonar_pareja()
  IDT_ENTRY3(88);
  IDT_ENTRY3(98);
}

```
Luego de añadir las syscalls a la IDT, debo programar las rutinas que serán llamadas a partir de la tabla.

# ASM

**ISR70**
```
global _isr70

_isr70:

    pushad

    call crear_pareja
    call fue_bloqueada

    cmp 0, ax; ax vale 0 si fue_bloqueada returnea false
    je .fin

    call sched_next_task

    mov WORD [sched_task_selector], ax
    jmp far [sched_task_offset]

    .fin:
        popad
        iret
```
La funcion `bool fue_bloqueada()` es una funcion auxiliar que consulta el estado de la tarea actual. Si la misma esta BLOCKED es porque no esta en pareja y esta esperando a ser elegida. Con esta implementacion, si la tarea queda bloqueada entonces inmediatamente salto a la proxima tarea.
```c
    bool fue_bloqueada(){
        sched_entry_t* actual = &sched_tasks[current_task];
        if(actual->state == TASK_BLOCKED) return true;
        return false; //Solo llega a este caso si la tarea no esta blocked
    }

```

**ISR71**

Como no existe una convencion para este caso (Yo al ser el programador de la tarea) se que el task_id se lo paso a juntarse_con mediante el registro ecx

```asm
global _isr71

_isr71:

    pushad

    push ecx
    call juntarse_con

    add esp, 4; para sacar ecx
    mov [rsp + OFFSET_EAX], eax; Guardo el valor de eax donde la funcion luego lo recuperara

    popad
    iret
```
`Pequeña explicacion:` Cuando una tarea llama a una syscall y la misma debe devolverle un valor hay que hacer unas modificaciones para que la tarea efectivamente reciba ese valor, ya que el popad restaura todos los valores de proposito general como estaban previo a la syscall. Teniendo esto en cuenta, debemos modificar el valor de EAX (Decidido por convencion) en la pila, para que al restaurar los valores de la misma, la tarea pueda leer el valor que necesita.


**ISR72**

```asm
global _isr72

_isr72:

    pushad

    call abandonar_pareja

    popad
    iret
```

# Parte 2
Como esta funcion debe estar implementada en codigo nivel 0, considero que debe existir dentro de codigo de ese privilegio. Por lo tanto, yo decido implementarla en mmu.c.
```c
uint32_t uso_de_memoria_de_las_parejas(){
    uint32_t totalmem = 0;

    for(int i = 0; i < MAX_TASKS; i++){
        sched_entry_t tarea_actual = sched_tasks[i];
        if(tarea_actual.pareja.es_lider){
            totalmem += (tarea_actual.pareja.cant_memoria) * 4096; //Asumo que totalmem tiene que devolver la cant de memoria en bytes
        }
    return totalmem;
    }

} //Esto estara corriendo, por ejemplo, en el PF Handler
```