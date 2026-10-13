#ifndef HELIX_GRAPHICS_H
#define HELIX_GRAPHICS_H
#include <stdint.h>
#ifdef __cplusplus
extern "C" {
#endif
void helix_setup(void);void helix_shutdown(void);const char *helix_renderer(void);
uint32_t helix_texture(int w,int h,const void *data,int bytes,int levels,int linear);
void helix_clear_color(uint32_t color);
uint32_t helix_buffer(int capacity);uint32_t helix_pipeline(int alpha);
int helix_update(uint32_t buffer,const void *data,int bytes);
int helix_begin(int width,int height,int x,int y,int w,int h);
int helix_draw(uint32_t pipeline,uint32_t buffer,uint32_t texture,int vertices,int first_vertex);
void helix_end(void);int helix_destroy(int kind,uint32_t handle);
void helix_capture(const char *path);const char *helix_graphics_audit(void);double helix_peak_rss(void);int helix_vertex_reserved(void);
#ifdef __cplusplus
}
#endif
#endif
