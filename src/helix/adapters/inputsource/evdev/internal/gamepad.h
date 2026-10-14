#ifndef HELIX_GAMEPAD_H
#define HELIX_GAMEPAD_H
#define HELIX_GAMEPADS 4
void helix_gamepad_setup(void);
void helix_gamepad_shutdown(void);
void helix_gamepad_poll(void);
int helix_gamepad_connected(int pad);
const char *helix_gamepad_name(int pad);
/* Buttons by W3C standard-gamepad index (0-5, 8-16); axes 0-3 the sticks (-1..1), 4 and 5 the left and right triggers (0..1). */
int helix_gamepad_button(int pad, int button);
float helix_gamepad_axis(int pad, int axis);
#ifdef HELIX_SERVICES_TEST
/* Owned nonblocking fd carrying Linux input_event records, not a physical pad. */
void helix_gamepad_test_connect(int pad, int fd);
void helix_gamepad_test_driver(int pad, int xpad, int right_on_z);
void helix_gamepad_test_range(int pad, int code, int minimum, int maximum, int value);
void helix_audio_test_render(float *out, int frames, int channels);
void helix_audio_test_setup(int rate);
#endif
#endif
