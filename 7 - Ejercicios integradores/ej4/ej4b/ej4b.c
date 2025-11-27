#include "ej4b.h"

#include <string.h>

// OPCIONAL: implementar en C
void invocar_habilidad(void* carta_generica, char* habilidad) {
	card_t* carta = carta_generica;

	//CASO 1:
	for(int i = 0; i < carta->__dir_entries; i++){
		//Conservo la habilidad que es contenida por el directorio:
		directory_entry_t current_ability = *(directory_entry_t*) (carta->__dir[i]); 

		char* name = current_ability.ability_name;
		int cmp = strcmp(habilidad, name);

		if(cmp == 0){ //Si tiene el mismo nombre:
			ability_function_t* function = current_ability.ability_ptr;
			function(carta); //Llamo a la funcion con la carta como parametro
			return;
		}
	}

	//CASO 2: quiero que suceda hasta que yo lo interrumpa
	while(true){
		carta = (card_t*) carta ->__archetype; //Actualizo el valor de carta con su arquetipo (de forma anidada)
		
		if(carta == NULL){
			return;
		}

		for(int i = 0; i < carta->__dir_entries; i++){
		//Conservo la habilidad que es contenida por el directorio:
		directory_entry_t current_ability = *(directory_entry_t*) (carta->__dir[i]); 

		char* name = current_ability.ability_name;
		int cmp = strcmp(habilidad, name);

		if(cmp == 0){ //Si tiene el mismo nombre:
			ability_function_t* function = current_ability.ability_ptr;
			function(carta); //Llamo a la funcion con la carta como parametro
			return;
		}
	}

	}
}
