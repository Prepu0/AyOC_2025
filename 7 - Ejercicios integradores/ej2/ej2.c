#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include "ej2.h"

/**
 * Marca el ejercicio 1A como hecho (`true`) o pendiente (`false`).
 *
 * Funciones a implementar:
 *   - es_indice_ordenado
 */
bool EJERCICIO_2A_HECHO = false;

/**
 * Marca el ejercicio 1B como hecho (`true`) o pendiente (`false`).
 *
 * Funciones a implementar:
 *   - contarCombustibleAsignado
 */
bool EJERCICIO_2B_HECHO = true;

/**
 * Marca el ejercicio 1B como hecho (`true`) o pendiente (`false`).
 *
 * Funciones a implementar:
 *   - modificarUnidad
 */
bool EJERCICIO_2C_HECHO = true;

/**
 * OPCIONAL: implementar en C
 */
void optimizar(mapa_t mapa, attackunit_t* compartida, uint32_t (*fun_hash)(attackunit_t*)) {
    uint32_t shared_hash = fun_hash(compartida);
    compartida->references=0;
    for(int i = 0; i<255; i++){
        for(int j = 0; j < 255; j++){
            attackunit_t* actual = mapa[i][j];

            if(actual == 0) continue;; //No debo tomar punteros a null

            uint32_t actual_hash = fun_hash(actual);
            if(actual_hash == shared_hash){
                compartida->references++;
                mapa[i][j] = compartida;

                if(actual == compartida) continue; //Contemplo el caso en el que ya fue optimizado

                if(actual->references > 1){//Si la cant de refs es 1 directamente libero la memoria
                    actual->references--;
                }else{ 
                    free(actual);
                }   
            }
        }
    }
}

/**
 * OPCIONAL: implementar en C
 */
uint32_t contarCombustibleAsignado(mapa_t mapa, uint16_t (*fun_combustible)(char*)) {
    uint32_t res =0;
    for(int i = 0; i < 255; i++){
        for(int j = 0; j < 255; j++){
            attackunit_t* actual = mapa[i][j];

            if(actual == 0) continue;

            uint16_t corresponde = fun_combustible(actual->clase);

            //Calculo cuanto de la reserva utiilzo el jugador
            uint16_t diferencia = actual->combustible - corresponde;

            if(actual->references > 1){//O sea, tiene >= 2 referencias
                //Debo crear un nuevo attackunit
                actual->references--;
                attackunit_t* new = malloc(sizeof(attackunit_t));

                //void* memcpy( void* dest, const void* src, std::size_t count );
                memcpy(new, actual, sizeof(attackunit_t));
                new->references = 1;
                mapa[i][j] = new;
            }
            mapa[i][j]->combustible = corresponde;
            res += diferencia;
        }
    }
    return res;
}

/**
 * OPCIONAL: implementar en C
 */
void modificarUnidad(mapa_t mapa, uint8_t x, uint8_t y, void (*fun_modificar)(attackunit_t*)) {
    if(mapa[x][y] == 0) return;
    attackunit_t* new = mapa[x][y];
    if(new->references > 1){
        new->references--;
        new = malloc(sizeof(attackunit_t));

        //void* memcpy( void* dest, const void* src, std::size_t count );
        memcpy(new, mapa[x][y], sizeof(attackunit_t));
        new->references = 1;

    }
    mapa[x][y] = new;
    fun_modificar(new);
    
}
