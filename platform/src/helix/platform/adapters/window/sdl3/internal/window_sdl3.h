#ifndef HELIX_WINDOW_SDL3_H
#define HELIX_WINDOW_SDL3_H
#ifdef __cplusplus
extern "C" {
#endif
/* The SDL3 window's own calls: its title, size and position in the OS's pixels (logical where it scales), fullscreen, visibility and the
   displays. The window itself is shared/sdl3's. Each request returns SDL's answer, 0 when it refused (helix_window_error says why); the
   window's events are counted as SDL queues them while watched, by kind. */
enum {HELIX_WINDOW_EVENT_SHOWN,HELIX_WINDOW_EVENT_HIDDEN,HELIX_WINDOW_EVENT_MOVED,HELIX_WINDOW_EVENT_RESIZED,HELIX_WINDOW_EVENT_MINIMIZED,
 HELIX_WINDOW_EVENT_MAXIMIZED,HELIX_WINDOW_EVENT_RESTORED,HELIX_WINDOW_EVENT_FOCUS_GAINED,HELIX_WINDOW_EVENT_DISPLAY_CHANGED,
 HELIX_WINDOW_EVENT_ENTER_FULLSCREEN,HELIX_WINDOW_EVENT_LEAVE_FULLSCREEN,HELIX_WINDOW_EVENT_KINDS};
void helix_window_watch(int on);int helix_window_event_count(int kind);const char *helix_window_error(void);
float helix_window_pixel_ratio(void);
void helix_window_set_title(const char*title);int helix_window_width(void);int helix_window_height(void);int helix_window_set_size(int w,int h);
int helix_window_can_move(void);int helix_window_x(void);int helix_window_y(void);int helix_window_set_position(int x,int y);
int helix_window_maximized(void);int helix_window_minimized(void);int helix_window_set_maximized(int on);int helix_window_set_minimized(int on);
int helix_window_raise(void);int helix_window_has_focus(void);void helix_window_set_icon(int w,int h,const void *rgba);float helix_window_opacity(void);int helix_window_set_opacity(float o);
int helix_window_set_minimum_size(int w,int h);int helix_window_set_maximum_size(int w,int h);float helix_display_refresh_rate(int i);
int helix_window_fullscreen(void);int helix_window_set_fullscreen(int on);int helix_window_visible(void);int helix_window_set_visible(int on);
int helix_display_count(void);int helix_display_current(void);int helix_display_set(int i);int helix_display_x(int i);int helix_display_y(int i);
int helix_display_width(int i);int helix_display_height(int i);const char*helix_display_name(int i);
#ifdef __cplusplus
}
#endif
#endif
