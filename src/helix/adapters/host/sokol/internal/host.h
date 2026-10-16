#ifndef HELIX_HOST_H
#define HELIX_HOST_H
#ifdef __cplusplus
extern "C" {
#endif
/* The sokol_app host: its window (window.h, surface.h) and frame loop. */
void helix_run(void (*init)(void),void (*frame)(void),void (*cleanup)(void),int sample_count);
void helix_quit(void);
#ifdef __cplusplus
}
#endif
#endif
