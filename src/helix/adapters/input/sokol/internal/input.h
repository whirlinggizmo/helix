#ifndef HELIX_INPUT_H
#define HELIX_INPUT_H
#include <stdint.h>
#ifdef __cplusplus
extern "C" {
#endif
void hy_input_setup(void);void hy_input_shutdown(void);void hy_input_poll(void);void hy_input_consume(void);
void hy_input_key(int code,int down);void hy_input_pointer(float x,float y,int down);void hy_input_focus(int focused);
int hy_key(int code);int hy_key_pressed(int code);int hy_key_released(int code);int hy_focused(void);
float hy_pointer_x(void);float hy_pointer_y(void);int hy_pointer_down(void);int hy_pointer_pressed(void);int hy_pointer_released(void);
int hy_pad_available(void);int hy_pad_button(int button);float hy_pad_axis(int axis);
#ifdef __cplusplus
}
#endif
#endif
