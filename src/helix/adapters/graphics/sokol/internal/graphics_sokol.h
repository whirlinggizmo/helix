#ifndef HELIX_GRAPHICS_SOKOL_H
#define HELIX_GRAPHICS_SOKOL_H
#include <stdint.h>
/* sokol_gfx's own calls beside shared/graphics.h's: setting up on the host's GL context, shutting down, and programs from GLSL 410. */
#ifdef __cplusplus
extern "C" {
#endif
void helix_setup(void);void helix_shutdown(void);
uint32_t helix_shader(const char *vs,const char *fs,const char *layout);
#ifdef __cplusplus
}
#endif
#endif
