#include "sdl3.h"
#include "surface.h"
#include <SDL3/SDL.h>
#include <stdio.h>
#if defined(_WIN32)
#include <windows.h>
#include <dwmapi.h>
#include <shlobj.h>
#else
#include <pwd.h>
#include <unistd.h>
#endif

static SDL_Window *window;
static SDL_GLContext context;
static int samples=1,focused=1,vsync=1;

/* GL's wait for the display. On Windows, where the compositor (DWM) shows the frame (windowed, and in SDL's fullscreen too, a borderless
   window at the desktop's mode), the swap interval is 0 and the swap waits on the compositor (DwmFlush), as GLFW does in a window: a GL
   driver may busy-wait inside a vsynced swap there (Intel's did, a whole core at 60 frames a second). Elsewhere the swap waits
   (interval 1). A window opened without vsync swaps at once (interval 0) and waits on nothing. */
static int compositor_waits;
static void swap_interval(void){
#if defined(_WIN32)
 BOOL composited=FALSE;
 compositor_waits=vsync&&SUCCEEDED(DwmIsCompositionEnabled(&composited))&&composited;
#endif
 SDL_GL_SetSwapInterval(compositor_waits||!vsync?0:1);
}

/* The window with a GL 4.1 core context (forward compatible, as macOS requires), 24-bit depth and 8-bit stencil, and the samples asked for:
   fewer when the GL can't make that many, down to none. */
static int open_gl(int sample_count){
 for(int n=sample_count>1?sample_count:1;;n/=2){
  SDL_GL_ResetAttributes();
  SDL_GL_SetAttribute(SDL_GL_CONTEXT_MAJOR_VERSION,4);SDL_GL_SetAttribute(SDL_GL_CONTEXT_MINOR_VERSION,1);
  SDL_GL_SetAttribute(SDL_GL_CONTEXT_PROFILE_MASK,SDL_GL_CONTEXT_PROFILE_CORE);SDL_GL_SetAttribute(SDL_GL_CONTEXT_FLAGS,SDL_GL_CONTEXT_FORWARD_COMPATIBLE_FLAG);
  SDL_GL_SetAttribute(SDL_GL_DOUBLEBUFFER,1);SDL_GL_SetAttribute(SDL_GL_DEPTH_SIZE,24);SDL_GL_SetAttribute(SDL_GL_STENCIL_SIZE,8);
  SDL_GL_SetAttribute(SDL_GL_MULTISAMPLEBUFFERS,n>1);SDL_GL_SetAttribute(SDL_GL_MULTISAMPLESAMPLES,n>1?n:0);
  window=SDL_CreateWindow("HeliX",800,600,SDL_WINDOW_OPENGL|SDL_WINDOW_RESIZABLE);
  if(window&&(context=SDL_GL_CreateContext(window))){samples=n;return 1;}
  fprintf(stderr,"HeliX SDL3: a GL 4.1 window with %d samples: %s\n",n,SDL_GetError());
  if(window){SDL_DestroyWindow(window);window=NULL;}
  if(n<=1)return 0;
 }
}

/* Opens the window, asking for sample_count samples a pixel (1: none), with a GL context made current (with_gl) or without one (SDL_GPU
   claims the window and makes its own multisampled textures). 0 when SDL or the window can't be had. Windows is told the program isn't DPI
   aware, so sizes are logical pixels. */
int helix_sdl3_open(int sample_count,int with_gl,int with_vsync){
 if(window)return 1;
 vsync=with_vsync!=0;
 SDL_SetHint("SDL_WINDOWS_DPI_AWARENESS","unaware");
 if(!SDL_Init(SDL_INIT_VIDEO)){fprintf(stderr,"HeliX SDL3: %s\n",SDL_GetError());return 0;}
 if(with_gl){
  if(!open_gl(sample_count)){SDL_Quit();return 0;}
  SDL_GL_MakeCurrent(window,context);
  swap_interval();
 }else{
  samples=sample_count>1?sample_count:1;
  if(!(window=SDL_CreateWindow("HeliX",800,600,SDL_WINDOW_RESIZABLE))){fprintf(stderr,"HeliX SDL3: %s\n",SDL_GetError());SDL_Quit();return 0;}
 }
 focused=1;
 return 1;
}
void helix_sdl3_close(void){
 if(!window)return;
 if(context)SDL_GL_DestroyContext(context);
 SDL_DestroyWindow(window);context=NULL;window=NULL;
 SDL_Quit();
}
void *helix_sdl3_window(void){return window;}
int helix_sdl3_is_open(void){return window!=NULL;}
int helix_sdl3_focused(void){return focused;}
void helix_sdl3_set_focused(int value){focused=value!=0;}
const char *helix_sdl3_platform(void){return SDL_GetPlatform();}
const char *helix_sdl3_getenv(const char *name){return SDL_getenv(name);}
const char *helix_sdl3_base_path(void){return SDL_GetBasePath();}
double helix_sdl3_time(void){return (double)SDL_GetTicksNS()/1e9;}

/* Names the program for SDL, which uses the name where the OS shows one (its audio mixer, a Wayland compositor): once, before any of
   SDL's subsystems starts, by whichever adapter starts one first. */
void helix_sdl3_name_app(const char *name){
 static int named;
 if(named)return;
 named=1;
 SDL_SetAppMetadata(name,NULL,NULL);
}

/* A directory the OS keeps for the user, asked of the OS when its environment variable is unset: 0 the home directory, 1 the roaming
   application data, 2 the local application data. On Windows its shell folders (SHGetFolderPathW, as SDL_GetPrefPath asks); elsewhere the
   home directory from the user database, and none for 1 and 2. UTF-8, valid until the next call; NULL when the OS has none. */
const char *helix_sdl3_os_directory(int which){
 static char path[4096];
#if defined(_WIN32)
 static const int folders[]={CSIDL_PROFILE,CSIDL_APPDATA,CSIDL_LOCAL_APPDATA};
 WCHAR wide[MAX_PATH];
 if(which<0||which>2||FAILED(SHGetFolderPathW(NULL,folders[which],NULL,0,wide)))return NULL;
 return WideCharToMultiByte(CP_UTF8,0,wide,-1,path,(int)sizeof path,NULL,NULL)>0?path:NULL;
#else
 struct passwd *entry;
 if(which!=0)return NULL;
 entry=getpwuid(getuid());
 if(!entry||!entry->pw_dir||!entry->pw_dir[0])return NULL;
 snprintf(path,sizeof path,"%s",entry->pw_dir);
 return path;
#endif
}

/* The window's framebuffer, for the graphics adapters (surface.h). */
int helix_surface_width(void){int w=0,h=0;if(window)SDL_GetWindowSizeInPixels(window,&w,&h);return w;}
int helix_surface_height(void){int w=0,h=0;if(window)SDL_GetWindowSizeInPixels(window,&w,&h);return h;}
int helix_surface_samples(void){return samples;}
int helix_surface_vsync(void){return vsync;}
void *helix_surface_window(void){return window;}
void helix_surface_present(void){
 if(!context)return;
 SDL_GL_SwapWindow(window);
#if defined(_WIN32)
 if(compositor_waits)DwmFlush();
#endif
}
