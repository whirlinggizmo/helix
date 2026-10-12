#ifndef HY_GAMEPAD_H
#define HY_GAMEPAD_H
void hy_gamepad_setup(void);
void hy_gamepad_shutdown(void);
void hy_gamepad_poll(void);
int hy_gamepad_available(void);
int hy_gamepad_button(int button);
float hy_gamepad_axis(int axis);
#ifdef HY_SERVICES_TEST
/* Owned nonblocking fd carrying Linux input_event records, not a physical pad. */
void hy_gamepad_test_connect(int fd);
void hy_gamepad_test_range(int code, int minimum, int maximum, int value);
void hy_audio_test_render(float *out, int frames, int channels);
void hy_audio_test_setup(int rate);
#endif
#endif
