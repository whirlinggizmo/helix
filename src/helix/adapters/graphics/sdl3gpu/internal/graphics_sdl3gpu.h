#ifndef HELIX_GRAPHICS_SDL3GPU_H
#define HELIX_GRAPHICS_SDL3GPU_H
#include <stdint.h>
/* SDL_GPU's own calls beside shared/graphics.h's. */
#ifdef __cplusplus
extern "C" {
#endif
/* Makes the device and claims the host's window (surface.h); 0 when SDL can't. */
int helix_sdl3gpu_setup(void);
/* Waits for the GPU, releases everything and the device. */
void helix_sdl3gpu_shutdown(void);
/* The dialect programs are given in: 0 SPIR-V, 1 MSL, 2 HLSL. */
int helix_sdl3gpu_shader_format(void);
/* The backend SDL chose ("vulkan", "direct3d12", "metal"). */
const char *helix_sdl3gpu_driver(void);
/* A program from its stages in that dialect (text NUL-terminated, its bytes without the NUL) and its layout. */
uint32_t helix_sdl3gpu_shader(const void *vs,int vs_bytes,const void *fs,int fs_bytes,const char *layout);
#ifdef __cplusplus
}
#endif
#endif
