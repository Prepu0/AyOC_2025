#include "../ejs.h"

// Función auxiliar para contar casos por nivel
int contar_casos_por_nivel(caso_t* arreglo_casos, int largo, int nivel) {
    int res = 0;
    for(int i = 0; i < largo; i++){
        if(arreglo_casos[i].usuario->nivel == nivel) res++;
    }
    return res;
}


segmentacion_t* segmentar_casos(caso_t* arreglo_casos, int largo) {
    segmentacion_t* res = (segmentacion_t*) malloc(sizeof(segmentacion_t));

    int cant_0 = contar_casos_por_nivel(arreglo_casos, largo, 0);

    //Super importante: Devolver NULL si no hay casos, ya que malloc(0) puede dar direcciones ERRONEAS
    caso_t* list_0 = NULL;
    if(cant_0 > 0){
        list_0 = (caso_t*) malloc(cant_0 * sizeof(caso_t));
    }
    int i_0 = 0;

    for(int i = 0; i < largo;i++){
        caso_t caso_actual = arreglo_casos[i];

        if(caso_actual.usuario->nivel == 0){
            list_0[i_0] = caso_actual;
            i_0++;
        }
    }

    res->casos_nivel_0 = list_0;


    int cant_1 = contar_casos_por_nivel(arreglo_casos, largo, 1);

    //Super importante: Devolver NULL si no hay casos, ya que malloc(0) puede dar direcciones ERRONEAS
    caso_t* list_1 = NULL;
    if( cant_1 >0){
        list_1 = (caso_t*) malloc(cant_1 * sizeof(caso_t));
    }

    int i_1 = 0;

    for(int i = 0; i < largo;i++){
        caso_t caso_actual = arreglo_casos[i];

        if(caso_actual.usuario->nivel == 1){
            list_1[i_1] = caso_actual;
            i_1++;
        }
    }
    res->casos_nivel_1 = list_1;


    int cant_2 = contar_casos_por_nivel(arreglo_casos, largo, 2);
    caso_t* list_2 = NULL;
    if( cant_2 > 0){
        list_2 = (caso_t*) malloc(cant_2 * sizeof(caso_t));
    }
    int i_2 = 0;

    for(int i = 0; i < largo;i++){
        caso_t caso_actual = arreglo_casos[i];

        if(caso_actual.usuario->nivel == 2){
            list_2[i_2] = caso_actual;
            i_2++;
        }
    }
    res->casos_nivel_2 = list_2;
    

    return res;
}



