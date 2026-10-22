#ifndef HELIX_WINDOW_H
#define HELIX_WINDOW_H
/* The desktop window a native host gives (sokol_app's or SDL's; one host a program): its title, size and position in the OS's pixels
   (logical where it scales), focus, fullscreen, visibility and displays. NativeWindow reaches these through WindowBridge. */
#ifdef __cplusplus
extern "C" {
#endif
float helix_pixel_ratio(void);
void helix_window_set_title(const char*title);int helix_window_width(void);int helix_window_height(void);void helix_window_set_size(int w,int h);
int helix_window_can_move(void);int helix_window_x(void);int helix_window_y(void);void helix_window_set_position(int x,int y);
int helix_window_focused(void);int helix_window_fullscreen(void);void helix_window_set_fullscreen(int on);int helix_window_visible(void);void helix_window_set_visible(int on);
int helix_display_count(void);int helix_display_current(void);void helix_display_set(int i);int helix_display_x(int i);int helix_display_y(int i);int helix_display_width(int i);int helix_display_height(int i);const char*helix_display_name(int i);
#ifdef __cplusplus
}
#endif
#endif
