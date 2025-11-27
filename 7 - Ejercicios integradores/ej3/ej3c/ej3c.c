#include "../ejs.h"

estadisticas_t* calcular_estadisticas(caso_t* arreglo_casos, int largo, uint32_t usuario_id){
    estadisticas_t* res = calloc(1, sizeof(segmentacion_t)); //Memoria inicializada en 0

    if(usuario_id != 0){
        for(int i = 0; i < largo; i++){
            caso_t caso_actual = arreglo_casos[i];

            if(caso_actual.usuario->id == usuario_id){
                if(strncmp(caso_actual.categoria, "CLT",4) == 0){
                    res->cantidad_CLT++;
                }
                if(strncmp(caso_actual.categoria, "RBO",4) == 0){
                    res->cantidad_RBO++;
                }
                if(strncmp(caso_actual.categoria, "KSC",4) == 0){
                    res->cantidad_KSC++;
                }
                if(strncmp(caso_actual.categoria, "KDT",4) == 0){
                    res->cantidad_KDT++;
                }

                if(caso_actual.estado == 0) res->cantidad_estado_0++;
                if(caso_actual.estado == 1) res->cantidad_estado_1++;
                if(caso_actual.estado == 2) res->cantidad_estado_2++;

            }
        }
    }else{
        for(int i = 0; i < largo; i++){
            caso_t caso_actual = arreglo_casos[i];
            if(strncmp(caso_actual.categoria, "CLT",4) == 0){
                res->cantidad_CLT++;
            }
            if(strncmp(caso_actual.categoria, "RBO",4) == 0){
                res->cantidad_RBO++;
            }
            if(strncmp(caso_actual.categoria, "KSC",4) == 0){
                res->cantidad_KSC++;
            }
            if(strncmp(caso_actual.categoria, "KDT",4) == 0){
                res->cantidad_KDT++;
            }

            if(caso_actual.estado == 0) res->cantidad_estado_0++;
            if(caso_actual.estado == 1) res->cantidad_estado_1++;
            if(caso_actual.estado == 2) res->cantidad_estado_2++;

        }
    }
    return res;
}

