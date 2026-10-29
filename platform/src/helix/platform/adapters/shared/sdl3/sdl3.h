#ifndef HELIX_SDL3_H
#define HELIX_SDL3_H
#ifdef __cplusplus
extern "C" {
#endif
/* What SDL3's adapters share: the one window (with a GL context for the GL graphics adapter, or none for SDL_GPU's), whether it has the
   keyboard (seen by the events adapter, answered by the window adapter), the clock and the program's facts. */
int helix_sdl3_open(int sample_count,int with_gl);
void helix_sdl3_close(void);
void *helix_sdl3_window(void);
int helix_sdl3_is_open(void);
int helix_sdl3_focused(void);
void helix_sdl3_set_focused(int focused);
const char *helix_sdl3_platform(void);
const char *helix_sdl3_getenv(const char *name);
const char *helix_sdl3_base_path(void);
double helix_sdl3_time(void);
#ifdef __cplusplus
}
#endif
#endif
