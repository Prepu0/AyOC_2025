#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include "ej4a.h"

/**
 * Marca el ejercicio 1A como hecho (`true`) o pendiente (`false`).
 *
 * Funciones a implementar:
 *   - init_fantastruco_dir
 */
bool EJERCICIO_1A_HECHO = true;

// OPCIONAL: implementar en C
void init_fantastruco_dir(fantastruco_t* card) {
    char* name1 = "sleep";
    char* name2 = "wakeup";

    directory_entry_t* new_dir_sleep = create_dir_entry(name1, &(sleep)); //Creo el directorio que contiene la accion y el nombre sleep
    directory_entry_t* new_dir_wakeup = create_dir_entry(name2, &(wakeup)); //Creo el directorio que contiene la accion y el nombre wakeup

    directory_t directorio = (directory_t) malloc(2*8); //Creo el directorio con la cantidad de memoria que voy a necesitar
    //PREGUNTAR: Es lo mismo inicializarlo con malloc que hacer directory_t directorio[2]? 
    directorio[0] = new_dir_sleep;
    directorio[1] = new_dir_wakeup;

    card -> __dir_entries = 2;
    card -> __dir = directorio;
}

/**
 * Marca el ejercicio 1A como hecho (`true`) o pendiente (`false`).
 *
 * Funciones a implementar:
 *   - summon_fantastruco
 */
bool EJERCICIO_1B_HECHO = true;

// OPCIONAL: implementar en C
fantastruco_t* summon_fantastruco() {
    fantastruco_t* new_card = malloc(sizeof(fantastruco_t));
    new_card->face_up = 1;
    new_card->__archetype = NULL;
    init_fantastruco_dir(new_card);

    return new_card;
}
