#ifndef HELIX_EVENTS_SDL3_H
#define HELIX_EVENTS_SDL3_H
#ifdef __cplusplus
extern "C" {
#endif
/* SDL3's events for one poll, read one record at a time: a kind, a code (a key, a character, a button, a finger, a slot, a width), a value
   (a repeat, a height) and a position. */
enum {HELIX_EVENTS_KEY_DOWN=1,HELIX_EVENTS_KEY_UP,HELIX_EVENTS_TEXT,HELIX_EVENTS_MOUSE_DOWN,HELIX_EVENTS_MOUSE_UP,HELIX_EVENTS_MOUSE_MOVE,
 HELIX_EVENTS_MOUSE_LEAVE,HELIX_EVENTS_WHEEL,HELIX_EVENTS_TOUCH_DOWN,HELIX_EVENTS_TOUCH_MOVE,HELIX_EVENTS_TOUCH_UP,HELIX_EVENTS_PAD_CONNECTED,
 HELIX_EVENTS_PAD_DISCONNECTED,HELIX_EVENTS_RESIZED,HELIX_EVENTS_FOCUS_GAINED,HELIX_EVENTS_FOCUS_LOST,HELIX_EVENTS_SHOWN,HELIX_EVENTS_HIDDEN,
 HELIX_EVENTS_CLOSE_REQUESTED,HELIX_EVENTS_PAD_BUTTON_DOWN,HELIX_EVENTS_PAD_BUTTON_UP,HELIX_EVENTS_UNLOCKED,HELIX_EVENTS_FILES_DROPPED};
/* The devices whose events are wanted, each added by its adapter: what isn't wanted isn't listened to. */
enum {HELIX_EVENTS_KEYBOARD=1,HELIX_EVENTS_MOUSE=2,HELIX_EVENTS_TOUCH=4,HELIX_EVENTS_GAMEPADS=8};
void helix_events_setup(void);void helix_events_dispose(void);void helix_events_poll(void);void helix_events_wait(int milliseconds);
void helix_events_set_text(int on);void helix_events_want(int device,int on);
int helix_events_next(void);int helix_events_kind(void);int helix_events_code(void);int helix_events_value(void);float helix_events_x(void);float helix_events_y(void);
/* The mouse's cursor and lock (Sdl3MouseAdapter): its shape is CursorShape's number; the lock is SDL's relative mouse mode. */
void helix_mouse_set_cursor_visible(int on);int helix_mouse_cursor_visible(void);void helix_mouse_set_cursor_shape(int shape);
int helix_mouse_set_locked(int on);int helix_mouse_locked(void);int helix_mouse_warp(float x,float y);void helix_mouse_dispose(void);
int helix_pad_rumble(int pad,float low,float high,int milliseconds);int helix_pad_add_mappings(const char *mappings);
int helix_pad_connected(int pad);const char*helix_pad_name(int pad);int helix_pad_button(int pad,int button);float helix_pad_axis(int pad,int axis);
#ifdef __cplusplus
}
#endif
#endif
