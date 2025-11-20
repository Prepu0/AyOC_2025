#include "../ejs.h"

void bloquearUsuario(usuario_t *usuario, usuario_t *usuarioABloquear){
  uint32_t lastone = usuario->cantBloqueados;
  usuario->bloqueados[lastone] = usuarioABloquear;


  return;
}

void borrar_posts(feed_t* feed, usuario_t* usuario){
  
}
