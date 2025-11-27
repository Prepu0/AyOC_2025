#include "../ejs.h"

void resolver_automaticamente(funcionCierraCasos_t* funcion, caso_t* arreglo_casos, caso_t* casos_a_revisar, int largo){
    caso_t* caso_actual;
    int largo2 = 0;
    for (int i = 0; i < largo; i++){
        caso_actual = &arreglo_casos[i];

        if(caso_actual->usuario->nivel != 0){
            uint16_t resfunc = funcion(caso_actual);
            if(resfunc == 1){
                caso_actual->estado = 1; //Cerrado favorablemente
            }else if(strncmp("CLT", caso_actual->categoria, 4) ==0 || strncmp("RBO", caso_actual->categoria, 4)==0){
                caso_actual->estado = 2;//Cerrado desfavorablemente
            }else{
                casos_a_revisar[largo2] = *(caso_t*) caso_actual;
                largo2++;
            }
        }else{
            casos_a_revisar[largo2] = *(caso_t*) caso_actual;
            largo2++;
        }
    }

}

