#ifndef HELIX_SDL3_HOST_H
#define HELIX_SDL3_HOST_H
#ifdef __cplusplus
extern "C" {
#endif
/* The SDL3 host: one window with a GL 4.1 core context (window.h, surface.h) and the frame loop. */
void helix_sdl3_run(void (*init)(void),void (*frame)(void),void (*cleanup)(void),int sample_count);
void helix_sdl3_quit(void);
#ifdef __cplusplus
}
#endif
#endif
