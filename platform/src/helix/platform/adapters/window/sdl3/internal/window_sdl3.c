#include "window_sdl3.h"
#include "sdl3.h"
#include <SDL3/SDL.h>
#if defined(__linux__)
#include <X11/Xlib.h>
#endif

#define WINDOW ((SDL_Window*)helix_sdl3_window())

float helix_window_pixel_ratio(void){float d=WINDOW?SDL_GetWindowPixelDensity(WINDOW):1;return d>0?d:1;}
void helix_window_set_title(const char*title){SDL_SetWindowTitle(WINDOW,title);}
int helix_window_width(void){int w=0,h=0;SDL_GetWindowSize(WINDOW,&w,&h);return w;}
int helix_window_height(void){int w=0,h=0;SDL_GetWindowSize(WINDOW,&w,&h);return h;}
void helix_window_set_size(int w,int h){SDL_SetWindowSize(WINDOW,w,h);}
/* Whether a move can work: not on Wayland, nor on X11 served by XWayland, where the compositor places windows and ignores a program's
   moves (asked of X as the XWAYLAND extension). */
int helix_window_can_move(void){
 const char *driver=SDL_GetCurrentVideoDriver();
 if(!driver)return 0;
 if(SDL_strcmp(driver,"wayland")==0)return 0;
#if defined(__linux__)
 if(SDL_strcmp(driver,"x11")==0){
  Display *display=(Display*)SDL_GetPointerProperty(SDL_GetWindowProperties(WINDOW),SDL_PROP_WINDOW_X11_DISPLAY_POINTER,NULL);
  int opcode,event,error;
  if(display&&XQueryExtension(display,"XWAYLAND",&opcode,&event,&error))return 0;
 }
#endif
 return 1;
}
int helix_window_x(void){int x=0,y=0;SDL_GetWindowPosition(WINDOW,&x,&y);return x;}
int helix_window_y(void){int x=0,y=0;SDL_GetWindowPosition(WINDOW,&x,&y);return y;}
void helix_window_set_position(int x,int y){SDL_SetWindowPosition(WINDOW,x,y);}
int helix_window_fullscreen(void){return (SDL_GetWindowFlags(WINDOW)&SDL_WINDOW_FULLSCREEN)!=0;}
/* Fullscreen on the window's display at the desktop's mode (SDL's default; no mode change). */
void helix_window_set_fullscreen(int on){SDL_SetWindowFullscreen(WINDOW,on!=0);}
int helix_window_visible(void){return (SDL_GetWindowFlags(WINDOW)&SDL_WINDOW_HIDDEN)==0;}
void helix_window_set_visible(int on){if(on)SDL_ShowWindow(WINDOW);else SDL_HideWindow(WINDOW);}

/* Displays by index in SDL's order of their IDs. */
static SDL_DisplayID display_id(int i){
 int n=0;SDL_DisplayID *ids=SDL_GetDisplays(&n),id=0;
 if(ids&&i>=0&&i<n)id=ids[i];
 SDL_free(ids);return id;
}
int helix_display_count(void){int n=0;SDL_DisplayID *ids=SDL_GetDisplays(&n);SDL_free(ids);return n>0?n:1;}
int helix_display_current(void){
 SDL_DisplayID current=SDL_GetDisplayForWindow(WINDOW);int n=0,found=0;SDL_DisplayID *ids=SDL_GetDisplays(&n);
 for(int i=0;ids&&i<n;i++)if(ids[i]==current)found=i;
 SDL_free(ids);return found;
}
/* Moves the window to the middle of display i (fullscreen, it moves there). */
void helix_display_set(int i){SDL_DisplayID id=display_id(i);if(id)SDL_SetWindowPosition(WINDOW,SDL_WINDOWPOS_CENTERED_DISPLAY(id),SDL_WINDOWPOS_CENTERED_DISPLAY(id));}
static SDL_Rect bounds(int i){SDL_Rect r={0,0,0,0};SDL_DisplayID id=display_id(i);if(id)SDL_GetDisplayBounds(id,&r);return r;}
int helix_display_x(int i){return bounds(i).x;}
int helix_display_y(int i){return bounds(i).y;}
int helix_display_width(int i){return bounds(i).w;}
int helix_display_height(int i){return bounds(i).h;}
int helix_window_maximized(void){return (SDL_GetWindowFlags(WINDOW)&SDL_WINDOW_MAXIMIZED)!=0;}
int helix_window_minimized(void){return (SDL_GetWindowFlags(WINDOW)&SDL_WINDOW_MINIMIZED)!=0;}
void helix_window_set_maximized(int on){if(on)SDL_MaximizeWindow(WINDOW);else SDL_RestoreWindow(WINDOW);}
void helix_window_set_minimized(int on){if(on)SDL_MinimizeWindow(WINDOW);else SDL_RestoreWindow(WINDOW);}
void helix_window_raise(void){SDL_RaiseWindow(WINDOW);}
/* The icon from RGBA8, rows top first: SDL copies the surface's pixels, so it is freed at once. */
void helix_window_set_icon(int w,int h,const void *rgba){
 SDL_Surface *s=SDL_CreateSurfaceFrom(w,h,SDL_PIXELFORMAT_RGBA32,(void*)rgba,w*4);
 if(s){SDL_SetWindowIcon(WINDOW,s);SDL_DestroySurface(s);}
}
float helix_window_opacity(void){float o=SDL_GetWindowOpacity(WINDOW);return o<0?1:o;}
int helix_window_set_opacity(float o){return SDL_SetWindowOpacity(WINDOW,o<0?0:o>1?1:o);}
int helix_window_set_minimum_size(int w,int h){return SDL_SetWindowMinimumSize(WINDOW,w,h);}
int helix_window_set_maximum_size(int w,int h){return SDL_SetWindowMaximumSize(WINDOW,w,h);}
float helix_display_refresh_rate(int i){
 SDL_DisplayID id=display_id(i);const SDL_DisplayMode *m=id?SDL_GetCurrentDisplayMode(id):NULL;return m?m->refresh_rate:0;
}
const char*helix_display_name(int i){SDL_DisplayID id=display_id(i);const char*n=id?SDL_GetDisplayName(id):NULL;return n?n:"";}
