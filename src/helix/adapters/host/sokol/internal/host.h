#ifndef HELIX_HOST_H
#define HELIX_HOST_H
#include <stdint.h>
#ifdef __cplusplus
extern "C" {
#endif
void hy_run(void (*init)(void),void (*frame)(float),void (*cleanup)(void));
void hy_quit(void);int hy_width(void);int hy_height(void);float hy_pixel_ratio(void);
void hy_window_set_title(const char*title);int hy_window_width(void);int hy_window_height(void);void hy_window_set_size(int w,int h);
int hy_window_can_move(void);int hy_window_x(void);int hy_window_y(void);void hy_window_set_position(int x,int y);
int hy_window_fullscreen(void);void hy_window_set_fullscreen(int on);int hy_window_visible(void);void hy_window_set_visible(int on);
int hy_display_count(void);int hy_display_current(void);void hy_display_set(int i);int hy_display_x(int i);int hy_display_y(int i);int hy_display_width(int i);int hy_display_height(int i);const char*hy_display_name(int i);
#ifdef __cplusplus
}
#endif
#endif
