#ifndef HELIX_GRAPHICS_H
#define HELIX_GRAPHICS_H
#include <stdint.h>
#ifdef __cplusplus
extern "C" {
#endif
void helix_setup(void);void helix_shutdown(void);const char *helix_renderer(void);
uint32_t helix_texture(int w,int h,const void *data,int bytes,int levels,int format);int helix_can_sample(int format);
uint32_t helix_buffer(int capacity);uint32_t helix_static_buffer(const void *data,int bytes,int index);uint32_t helix_pipeline(int kind,int alpha);
int helix_update(uint32_t buffer,const void *data,int bytes);uint32_t helix_target(int w,int h);int helix_begin_target(uint32_t target,uint32_t color);int helix_end_target(void);
int helix_begin(int width,int height,uint32_t color);int helix_viewport(int x,int y,int w,int h);
int helix_draw(uint32_t pipeline,uint32_t buffer,uint32_t texture,int sampling,int vertices,int first_vertex,const void *uniforms,int uniform_bytes);
int helix_draw_mesh(uint32_t pipeline,uint32_t vertices,uint32_t indices,int index_count,uint32_t instances,int first_instance,int instance_count,uint32_t texture,
 int texture_sampling,uint32_t normal,int normal_sampling,const void *vs,int vs_bytes,const void *fs,int fs_bytes);
void helix_end(void);int helix_destroy(int kind,uint32_t handle);
void helix_capture(const char *path);const char *helix_graphics_audit(void);double helix_peak_rss(void);int helix_vertex_reserved(void);
#ifdef __cplusplus
}
#endif
#endif
