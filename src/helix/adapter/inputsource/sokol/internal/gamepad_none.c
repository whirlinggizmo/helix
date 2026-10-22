#include "gamepad.h"

/* Gamepads where HeliX reads none yet (macOS): none connected. None of the earlier frameworks read a pad there either. */

void helix_gamepad_setup(void) {}
void helix_gamepad_shutdown(void) {}
void helix_gamepad_poll(void) {}
int helix_gamepad_connected(int pad) { (void)pad; return 0; }
const char *helix_gamepad_name(int pad) { (void)pad; return ""; }
int helix_gamepad_button(int pad, int button) { (void)pad; (void)button; return 0; }
float helix_gamepad_axis(int pad, int axis) { (void)pad; (void)axis; return 0; }
