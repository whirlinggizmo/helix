#ifndef HELIX_GRAPHICS_H
#define HELIX_GRAPHICS_H
#include <stdint.h>
/* The graphics calls every native graphics adapter's C implements (sokol_gfx's, SDL_GPU's), which NativeGraphics makes IGraphics of through
   GraphicsDeviceBridge. Handles are nonzero; 0 from a maker, or from an int-returning call, means it refused. Each adapter's own header adds
   its setup, shutdown and program making, which differ in what they take. */
#ifdef __cplusplus
extern "C" {
#endif
uint32_t helix_texture(int w,int h,const void *data,int bytes,int levels,int format);int helix_can_sample(int format);int helix_msaa_samples(void);int helix_max_msaa_samples(void);uint32_t helix_cube_texture(int size,const void *data,int bytes,int levels,int format);uint32_t helix_data_texture(int w,int h);int helix_update_data(uint32_t texture,const void *data,int bytes);
uint32_t helix_buffer(int capacity);uint32_t helix_static_buffer(const void *data,int bytes,int index);uint32_t helix_pipeline(const int *desc,int count);
int helix_update(uint32_t buffer,const void *data,int bytes);uint32_t helix_target(int w,int h);uint32_t helix_shadow_map(int size,int layers);int helix_begin_shadow(uint32_t map,int layer);int helix_begin_target(uint32_t target,uint32_t color);int helix_end_target(void);
int helix_begin(int width,int height,uint32_t color);int helix_viewport(int x,int y,int w,int h);
int helix_draw(uint32_t pipeline,const uint32_t *buffers,int buffer_count,uint32_t indices,int first,int count,int first_instance,int instance_count,
 const uint32_t *textures,const int *samplings,int texture_count,const void *uniforms,int uniform_bytes);
void helix_end(void);int helix_destroy(int kind,uint32_t handle);
int helix_scissor(int x,int y,int w,int h,int on);int helix_read_width(uint32_t target);int helix_read_height(uint32_t target);int helix_read_pixels(uint32_t target,unsigned char *out);
#ifdef __cplusplus
}
#endif
#endif
