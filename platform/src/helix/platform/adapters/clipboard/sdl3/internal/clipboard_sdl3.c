#include "clipboard_sdl3.h"
#include <SDL3/SDL.h>
#include <stdlib.h>
#include <string.h>

/* The text last read, kept until the next read: SDL hands over a copy the caller frees. */
static char *text;
const char*helix_clipboard_text(void){SDL_free(text);text=SDL_GetClipboardText();return text?text:"";}
int helix_clipboard_set_text(const char*t){return SDL_SetClipboardText(t?t:"");}

/* The image last read, its size asked for first and then copied out. */
static void *image;static size_t image_size;
int helix_clipboard_image_size(void){
 SDL_free(image);image=NULL;image_size=0;
 if(!SDL_HasClipboardData("image/png"))return 0;
 image=SDL_GetClipboardData("image/png",&image_size);
 if(!image||image_size>0x7fffffff){SDL_free(image);image=NULL;image_size=0;}
 return (int)image_size;
}
void helix_clipboard_image_copy(void*out){if(image)memcpy(out,image,image_size);SDL_free(image);image=NULL;image_size=0;}

/* An image put on the clipboard: SDL asks for its bytes when another program pastes, and frees it once the clipboard holds something
   else. */
typedef struct{size_t size;unsigned char data[];} blob;
static const void *SDLCALL provide(void*user,const char*mime,size_t*size){
 blob*b=user;if(mime&&!strcmp(mime,"image/png")){*size=b->size;return b->data;}
 *size=0;return NULL;
}
static void SDLCALL release(void*user){free(user);}
int helix_clipboard_set_image(const void*png,int size){
 if(!png||size<=0)return 0;
 blob*b=malloc(sizeof(blob)+(size_t)size);if(!b)return 0;
 b->size=(size_t)size;memcpy(b->data,png,(size_t)size);
 const char*mimes[]={"image/png"};
 return SDL_SetClipboardData(provide,release,b,mimes,1);
}
void helix_clipboard_dispose(void){SDL_free(text);text=NULL;SDL_free(image);image=NULL;image_size=0;}
