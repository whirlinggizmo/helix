#include "input.h"
#include "gamepad.h"

/* The sokol input source: its events come from the sokol host (host.c pushes them); gamepads from the OS's own adapter (evdev on Linux,
   XInput on Windows, none on macOS). */
void helix_input_setup(void){helix_gamepad_setup();}
void helix_input_shutdown(void){helix_gamepad_shutdown();}
void helix_input_poll(void){helix_gamepad_poll();}
