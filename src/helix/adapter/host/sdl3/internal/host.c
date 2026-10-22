#include "host.h"
#include "surface.h"
#include "window.h"
#include <SDL3/SDL.h>
#include <stdio.h>
#if defined(__linux__)
#include <X11/Xlib.h>
#endif
#if defined(_WIN32)
#include <windows.h>
#include <dwmapi.h>
#endif

static SDL_Window *window;
static SDL_GLContext context;
/* gl: whether the window has a GL context the host swaps (the GL graphics adapter's), or none (SDL_GPU's, which presents for itself). */
static int samples=1,running,focused=1,gl=1;

/* The window's framebuffer for the GL graphics adapter (surface.h), and the window (window.h): sizes and positions are the OS's pixels,
   logical where it scales (Windows is told the program isn't DPI aware, as sokol's host tells it). */
int helix_surface_width(void){int w=0,h=0;SDL_GetWindowSizeInPixels(window,&w,&h);return w;}
int helix_surface_height(void){int w=0,h=0;SDL_GetWindowSizeInPixels(window,&w,&h);return h;}
int helix_surface_samples(void){return samples;}
void *helix_surface_window(void){return window;}

float helix_pixel_ratio(void){float d=SDL_GetWindowPixelDensity(window);return d>0?d:1;}
void helix_sdl3_quit(void){running=0;}
int helix_window_focused(void){return focused;}
void helix_window_set_title(const char*title){SDL_SetWindowTitle(window,title);}
int helix_window_width(void){int w=0,h=0;SDL_GetWindowSize(window,&w,&h);return w;}
int helix_window_height(void){int w=0,h=0;SDL_GetWindowSize(window,&w,&h);return h;}
void helix_window_set_size(int w,int h){SDL_SetWindowSize(window,w,h);}
/* Whether a move can work: not on Wayland, nor on X11 served by XWayland, where the compositor places windows and ignores a program's
   moves (sokol_app_utils asks X for the XWAYLAND extension the same way). */
int helix_window_can_move(void){
 const char *driver=SDL_GetCurrentVideoDriver();
 if(!driver)return 0;
 if(SDL_strcmp(driver,"wayland")==0)return 0;
#if defined(__linux__)
 if(SDL_strcmp(driver,"x11")==0){
  Display *display=(Display*)SDL_GetPointerProperty(SDL_GetWindowProperties(window),SDL_PROP_WINDOW_X11_DISPLAY_POINTER,NULL);
  int opcode,event,error;
  if(display&&XQueryExtension(display,"XWAYLAND",&opcode,&event,&error))return 0;
 }
#endif
 return 1;
}
int helix_window_x(void){int x=0,y=0;SDL_GetWindowPosition(window,&x,&y);return x;}
int helix_window_y(void){int x=0,y=0;SDL_GetWindowPosition(window,&x,&y);return y;}
void helix_window_set_position(int x,int y){SDL_SetWindowPosition(window,x,y);}
int helix_window_fullscreen(void){return (SDL_GetWindowFlags(window)&SDL_WINDOW_FULLSCREEN)!=0;}
/* Fullscreen on the window's display at the desktop's mode (SDL's default; no mode change). */
void helix_window_set_fullscreen(int on){SDL_SetWindowFullscreen(window,on!=0);}
int helix_window_visible(void){return (SDL_GetWindowFlags(window)&SDL_WINDOW_HIDDEN)==0;}
void helix_window_set_visible(int on){if(on)SDL_ShowWindow(window);else SDL_HideWindow(window);}

/* Displays by index in SDL's order of their IDs. */
static SDL_DisplayID display_id(int i){
 int n=0;SDL_DisplayID *ids=SDL_GetDisplays(&n),id=0;
 if(ids&&i>=0&&i<n)id=ids[i];
 SDL_free(ids);return id;
}
int helix_display_count(void){int n=0;SDL_DisplayID *ids=SDL_GetDisplays(&n);SDL_free(ids);return n>0?n:1;}
int helix_display_current(void){
 SDL_DisplayID current=SDL_GetDisplayForWindow(window);int n=0,found=0;SDL_DisplayID *ids=SDL_GetDisplays(&n);
 for(int i=0;ids&&i<n;i++)if(ids[i]==current)found=i;
 SDL_free(ids);return found;
}
/* Moves the window to the middle of display i (fullscreen, it moves there). */
void helix_display_set(int i){SDL_DisplayID id=display_id(i);if(id)SDL_SetWindowPosition(window,SDL_WINDOWPOS_CENTERED_DISPLAY(id),SDL_WINDOWPOS_CENTERED_DISPLAY(id));}
static SDL_Rect bounds(int i){SDL_Rect r={0,0,0,0};SDL_DisplayID id=display_id(i);if(id)SDL_GetDisplayBounds(id,&r);return r;}
int helix_display_x(int i){return bounds(i).x;}
int helix_display_y(int i){return bounds(i).y;}
int helix_display_width(int i){return bounds(i).w;}
int helix_display_height(int i){return bounds(i).h;}
const char*helix_display_name(int i){SDL_DisplayID id=display_id(i);const char*n=id?SDL_GetDisplayName(id):NULL;return n?n:"";}

/* GL's wait for the display. On Windows, where the compositor (DWM) shows the frame (windowed, and in SDL's fullscreen too, a borderless
   window at the desktop's mode), the host waits on the compositor (DwmFlush) with the swap interval 0, as GLFW does in a window: a GL driver
   may busy-wait inside a vsynced swap there (Intel's did, a whole core at 60 frames a second; NVIDIA's has been reported to; sokol_app's
   FIXME names the case). Measured on an Intel UHD 630: a core windowed and fullscreen before, 3 to 5% after, 60 frames a second both ways.
   Elsewhere the swap waits (interval 1). */
static int compositor_waits;
static void swap_interval(void){
#if defined(_WIN32)
 BOOL composited=FALSE;
 compositor_waits=SUCCEEDED(DwmIsCompositionEnabled(&composited))&&composited;
#endif
 SDL_GL_SetSwapInterval(compositor_waits?0:1);
}
static void swap(void){
 SDL_GL_SwapWindow(window);
#if defined(_WIN32)
 if(compositor_waits)DwmFlush();
#endif
}

/* The window with a GL 4.1 core context (forward compatible, as macOS requires), 24-bit depth and 8-bit stencil, and the samples asked for:
   fewer when the GL can't make that many, down to none. */
static int open_window(int sample_count){
 for(int n=sample_count>1?sample_count:1;;n/=2){
  SDL_GL_ResetAttributes();
  SDL_GL_SetAttribute(SDL_GL_CONTEXT_MAJOR_VERSION,4);SDL_GL_SetAttribute(SDL_GL_CONTEXT_MINOR_VERSION,1);
  SDL_GL_SetAttribute(SDL_GL_CONTEXT_PROFILE_MASK,SDL_GL_CONTEXT_PROFILE_CORE);SDL_GL_SetAttribute(SDL_GL_CONTEXT_FLAGS,SDL_GL_CONTEXT_FORWARD_COMPATIBLE_FLAG);
  SDL_GL_SetAttribute(SDL_GL_DOUBLEBUFFER,1);SDL_GL_SetAttribute(SDL_GL_DEPTH_SIZE,24);SDL_GL_SetAttribute(SDL_GL_STENCIL_SIZE,8);
  SDL_GL_SetAttribute(SDL_GL_MULTISAMPLEBUFFERS,n>1);SDL_GL_SetAttribute(SDL_GL_MULTISAMPLESAMPLES,n>1?n:0);
  window=SDL_CreateWindow("HeliX Haxe",800,600,SDL_WINDOW_OPENGL|SDL_WINDOW_RESIZABLE);
  if(window&&(context=SDL_GL_CreateContext(window))){samples=n;return 1;}
  fprintf(stderr,"HeliX SDL3 host: a GL 4.1 window with %d samples: %s\n",n,SDL_GetError());
  if(window){SDL_DestroyWindow(window);window=NULL;}
  if(n<=1)return 0;
 }
}

/* Opens the window, asking for sample_count samples a pixel (1: none), with a GL context (with_gl) or without (for SDL_GPU, which makes its
   own multisampled textures), and runs its loop: each frame SDL's events (the input and audio adapters watch them for themselves), then the
   frame, then the swap (with GL; SDL_GPU presents as the frame ends), until quit or the window is closed. The window can be resized by
   the user, as sokol's can. */
void helix_sdl3_run(void (*init)(void),void (*frame)(void),void (*cleanup)(void),int sample_count,int with_gl){
 /* Windows scales the window as it does sokol's (high_dpi off), so sizes stay logical pixels on both native hosts. */
 SDL_SetHint("SDL_WINDOWS_DPI_AWARENESS","unaware");
 if(!SDL_Init(SDL_INIT_VIDEO)){fprintf(stderr,"HeliX SDL3 host: %s\n",SDL_GetError());return;}
 gl=with_gl!=0;
 if(gl){
  if(!open_window(sample_count)){SDL_Quit();return;}
  SDL_GL_MakeCurrent(window,context);
  swap_interval();
 }else{
  samples=sample_count>1?sample_count:1;
  if(!(window=SDL_CreateWindow("HeliX Haxe",800,600,SDL_WINDOW_RESIZABLE))){fprintf(stderr,"HeliX SDL3 host: %s\n",SDL_GetError());SDL_Quit();return;}
 }
 running=1;
 init();
 while(running){
  SDL_Event e;
  while(SDL_PollEvent(&e)){
   switch(e.type){
    case SDL_EVENT_QUIT:case SDL_EVENT_WINDOW_CLOSE_REQUESTED:running=0;break;
    case SDL_EVENT_WINDOW_FOCUS_LOST:case SDL_EVENT_WINDOW_MINIMIZED:case SDL_EVENT_WINDOW_HIDDEN:focused=0;break;
    case SDL_EVENT_WINDOW_FOCUS_GAINED:case SDL_EVENT_WINDOW_RESTORED:focused=1;break;
    default:break;
   }
  }
  if(!running)break;
  frame();
  if(gl)swap();
  /* Minimized, a swap may not wait for the display: don't spin. */
  if(SDL_GetWindowFlags(window)&SDL_WINDOW_MINIMIZED)SDL_Delay(16);
 }
 cleanup();
 if(context)SDL_GL_DestroyContext(context);
 SDL_DestroyWindow(window);context=NULL;window=NULL;
 SDL_Quit();
}
