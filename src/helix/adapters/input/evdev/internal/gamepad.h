#ifndef HY_GAMEPAD_H
#define HY_GAMEPAD_H
#define HY_GAMEPADS 4
void hy_gamepad_setup(void);
void hy_gamepad_shutdown(void);
void hy_gamepad_poll(void);
int hy_gamepad_connected(int pad);
const char *hy_gamepad_name(int pad);
/* Buttons by W3C standard-gamepad index (0-5, 8-16); axes 0-3 the sticks (-1..1), 4 and 5 the left and right triggers (0..1). */
int hy_gamepad_button(int pad, int button);
float hy_gamepad_axis(int pad, int axis);
#ifdef HY_SERVICES_TEST
/* Owned nonblocking fd carrying Linux input_event records, not a physical pad. */
void hy_gamepad_test_connect(int pad, int fd);
void hy_gamepad_test_driver(int pad, int xpad, int right_on_z);
void hy_gamepad_test_range(int pad, int code, int minimum, int maximum, int value);
void hy_audio_test_render(float *out, int frames, int channels);
void hy_audio_test_setup(int rate);
#endif
#endif
