#ifndef HELIX_GRAPHICS_H
#define HELIX_GRAPHICS_H
#include <stdint.h>
#ifdef __cplusplus
extern "C" {
#endif
void hy_setup(void);void hy_shutdown(void);const char *hy_renderer(void);
uint32_t hy_texture(int w,int h,const void *data,int bytes);
uint32_t hy_buffer(int capacity);uint32_t hy_pipeline(int alpha);
int hy_update(uint32_t buffer,const void *data,int bytes);
int hy_begin(int width,int height,int x,int y,int w,int h);
int hy_draw(uint32_t pipeline,uint32_t buffer,uint32_t texture,int vertices,int first_vertex);
void hy_end(void);int hy_destroy(int kind,uint32_t handle);
void hy_capture(const char *path);const char *hy_graphics_audit(void);double hy_peak_rss(void);int hy_vertex_reserved(void);
#ifdef __cplusplus
}
#endif
#endif
