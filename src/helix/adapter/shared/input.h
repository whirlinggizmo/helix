#ifndef HELIX_INPUT_H
#define HELIX_INPUT_H
#include <stdint.h>
#ifdef __cplusplus
extern "C" {
#endif
/* The native window's events, queued as they arrive and drained once a frame by NativeInputSource, which reports them to the shared
   InputRouter: key codes are Key's numbers, positions framebuffer pixels, mouse buttons MouseButton's. helix_input_setup, _shutdown and
   _poll are the input adapter's own (its gamepads, and SDL's event watch), as is _set_text: typed text asked for (SDL's text input, started
   on the window) or let go; sokol's window types either way, so its adapter does nothing. */
enum {HELIX_EVENT_KEY=1,HELIX_EVENT_CHAR,HELIX_EVENT_MOUSE_BUTTON,HELIX_EVENT_MOUSE_MOVE,HELIX_EVENT_WHEEL,HELIX_EVENT_TOUCH,HELIX_EVENT_FOCUS,HELIX_EVENT_MOUSE_LEAVE};
void helix_input_setup(void);void helix_input_shutdown(void);void helix_input_poll(void);void helix_input_set_text(int on);
void helix_input_push(int type,int code,int value,float x,float y);
int helix_input_next(void);int helix_event_type(void);int helix_event_code(void);int helix_event_value(void);float helix_event_x(void);float helix_event_y(void);
int helix_pad_slots(void);
int helix_pad_connected(int pad);const char*helix_pad_name(int pad);int helix_pad_button(int pad,int button);float helix_pad_axis(int pad,int axis);
#ifdef __cplusplus
}
#endif
#endif
