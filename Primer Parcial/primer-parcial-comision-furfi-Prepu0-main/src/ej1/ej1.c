#include "../ejs.h"
#include <string.h>
#include <stdlib.h>


// Función principal: publicar un tuit
tuit_t *publicar(char *mensaje, usuario_t *user) {
  tuit_t* newtuit = malloc(sizeof(tuit_t));
  strcpy(newtuit->mensaje, mensaje); //Copio el mensaje a mi tuit

  uint32_t iduser = user -> id;
  newtuit->id_autor = iduser;//Asigno id_user a mi tuit

  feed_t* user_feed = user->feed;
  tuitafeed(newtuit, user_feed);

  //Ahora mi tuit esta en el feed de mi usuario

  uint32_t cantfollowers = user->cantSeguidores;
  usuario_t** arrfollowers = user->seguidores;
  if (cantfollowers>0){  
    for(int i = 0; i < (int) cantfollowers; i++){
      usuario_t* seguidor = arrfollowers[i];
      feed_t* feed_seguidor = seguidor->feed;
    
      tuitafeed(newtuit, feed_seguidor);
    }
  }
  return newtuit;
}


//Funcion auxiliar: crear tuit y pegarlo al principio del feed
void tuitafeed(tuit_t* tuit, feed_t* feed){
  publicacion_t* newpost = malloc(sizeof(publicacion_t));
  newpost->value = tuit; //Añado a mi nueva publicacion un puntero al tuit
  newpost->next =NULL; //El siguiente es NULL
  
  if (feed->first == NULL){//Si no tiene primer tuit => le asigno un primer tuit y next =NULL
    feed->first =newpost; 
  }else{//Si tiene un primer tuit entonces lo cargo en el siguiente
    publicacion_t* valor = feed->first;
    newpost->next = valor;
    feed->first=newpost;
  }
    // newpost->next = tuit;
    // newpost -> next = nextpost; 
  
}
