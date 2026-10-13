#ifndef HELIX_INPUT_H
#define HELIX_INPUT_H
#include <stdint.h>
#ifdef __cplusplus
extern "C" {
#endif
/* Sokol's events, queued as they arrive and drained once a frame by the Haxe adapter, which applies them to its InputState. */
enum {HY_EVENT_KEY=1,HY_EVENT_CHAR,HY_EVENT_MOUSE_BUTTON,HY_EVENT_MOUSE_MOVE,HY_EVENT_WHEEL,HY_EVENT_TOUCH,HY_EVENT_FOCUS};
void hy_input_setup(void);void hy_input_shutdown(void);void hy_input_poll(void);
void hy_input_push(int type,int code,int value,float x,float y);
int hy_input_next(void);int hy_event_type(void);int hy_event_code(void);int hy_event_value(void);float hy_event_x(void);float hy_event_y(void);
int hy_focused(void);
int hy_pad_connected(int pad);const char*hy_pad_name(int pad);int hy_pad_button(int pad,int button);float hy_pad_axis(int pad,int axis);
#ifdef __cplusplus
}
#endif
#endif
