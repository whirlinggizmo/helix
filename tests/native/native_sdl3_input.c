/* The SDL3 input source's C (inputsource/sdl3/internal/input_sdl3.c) against SDL's own events, with no window: events pushed through SDL
   reach the shared queue as HeliX's codes, and an SDL virtual gamepad, attached and detached while running, reads as the W3C standard
   layout. A virtual gamepad uses SDL's identity mapping, so this checks HeliX's translation, not SDL's controller database or a real pad. */
#include "input.h"
#include "gamepad.h"
#include <SDL3/SDL.h>
#include <math.h>
#include <stdio.h>
#include <stdlib.h>

static int checks;
#define CHECK(value) do { if (!(value)) { fprintf(stderr, "Failed at line %d\n", __LINE__); abort(); } checks++; } while (0)

/* The next queued event is type, code and value. */
static int next(int type, int code, int value) {
    return helix_input_next() && helix_event_type() == type && helix_event_code() == code && helix_event_value() == value;
}
/* The virtual pad's slot, or -1: found by its name, as a real pad may be plugged in too. */
static int virtual_slot(void) {
    for (int i = 0; i < helix_pad_slots(); i++) if (helix_pad_connected(i) && SDL_strcmp(helix_pad_name(i), "HeliX virtual pad") == 0) return i;
    return -1;
}
static void key(SDL_Scancode scancode, int down) {
    SDL_Event e = {0};
    e.type = down ? SDL_EVENT_KEY_DOWN : SDL_EVENT_KEY_UP; e.key.scancode = scancode; e.key.down = down;
    SDL_PushEvent(&e);
}

int main(void) {
    SDL_SetHint(SDL_HINT_VIDEO_DRIVER, "dummy");
    if (!SDL_Init(SDL_INIT_EVENTS)) { fprintf(stderr, "SDL_Init: %s\n", SDL_GetError()); return 1; }
    helix_input_setup();

    /* Keys by physical position, as Key's numbers; right-hand modifiers keep theirs; a key HeliX doesn't name isn't queued. */
    key(SDL_SCANCODE_A, 1); key(SDL_SCANCODE_A, 0); key(SDL_SCANCODE_RCTRL, 1); key(SDL_SCANCODE_MUTE, 1); key(SDL_SCANCODE_KP_ENTER, 1);
    key(SDL_SCANCODE_NONUSBACKSLASH, 1); key(SDL_SCANCODE_APPLICATION, 1);
    CHECK(next(HELIX_EVENT_KEY, 65, 1)); CHECK(next(HELIX_EVENT_KEY, 65, 0)); CHECK(next(HELIX_EVENT_KEY, 345, 1));
    CHECK(next(HELIX_EVENT_KEY, 335, 1)); CHECK(next(HELIX_EVENT_KEY, 161, 1)); CHECK(next(HELIX_EVENT_KEY, 348, 1));
    CHECK(!helix_input_next());

    /* Text as code points, control characters dropped. */
    SDL_Event e = {0};
    e.type = SDL_EVENT_TEXT_INPUT; e.text.text = "a\xc3\xa9\x01\xe2\x82\xac"; SDL_PushEvent(&e);
    CHECK(next(HELIX_EVENT_CHAR, 'a', 0)); CHECK(next(HELIX_EVENT_CHAR, 0xe9, 0)); CHECK(next(HELIX_EVENT_CHAR, 0x20ac, 0));
    CHECK(!helix_input_next());

    /* Mouse buttons as MouseButton's (left 0, right 1, middle 2), where they happened; a pointer made of touch is dropped. */
    e = (SDL_Event){0}; e.type = SDL_EVENT_MOUSE_BUTTON_DOWN; e.button.button = SDL_BUTTON_RIGHT; e.button.down = true; e.button.x = 20; e.button.y = 30;
    SDL_PushEvent(&e);
    CHECK(next(HELIX_EVENT_MOUSE_BUTTON, 1, 1) && helix_event_x() == 20 && helix_event_y() == 30);
    e.button.button = SDL_BUTTON_MIDDLE; SDL_PushEvent(&e); CHECK(next(HELIX_EVENT_MOUSE_BUTTON, 2, 1));
    e.button.which = SDL_TOUCH_MOUSEID; SDL_PushEvent(&e); CHECK(!helix_input_next());
    e = (SDL_Event){0}; e.type = SDL_EVENT_MOUSE_MOTION; e.motion.x = 5; e.motion.y = 6; SDL_PushEvent(&e);
    CHECK(next(HELIX_EVENT_MOUSE_MOVE, 0, 0) && helix_event_x() == 5 && helix_event_y() == 6);
    e = (SDL_Event){0}; e.type = SDL_EVENT_MOUSE_WHEEL; e.wheel.x = 1; e.wheel.y = -2; SDL_PushEvent(&e);
    CHECK(next(HELIX_EVENT_WHEEL, 0, 0) && helix_event_x() == 1 && helix_event_y() == -2);
    e = (SDL_Event){0}; e.type = SDL_EVENT_WINDOW_MOUSE_LEAVE; SDL_PushEvent(&e); CHECK(next(HELIX_EVENT_MOUSE_LEAVE, 0, 0));

    /* Fingers by a small number while down, freed when up; a canceled touch ends it. */
    e = (SDL_Event){0}; e.type = SDL_EVENT_FINGER_DOWN; e.tfinger.fingerID = 0x1234567890ull; SDL_PushEvent(&e);
    e.tfinger.fingerID = 77; SDL_PushEvent(&e);
    e.type = SDL_EVENT_FINGER_CANCELED; e.tfinger.fingerID = 0x1234567890ull; SDL_PushEvent(&e);
    CHECK(next(HELIX_EVENT_TOUCH, 0, 1)); CHECK(next(HELIX_EVENT_TOUCH, 1, 1)); CHECK(next(HELIX_EVENT_TOUCH, 0, 0));

    /* Focus. */
    e = (SDL_Event){0}; e.type = SDL_EVENT_WINDOW_FOCUS_LOST; SDL_PushEvent(&e); CHECK(next(HELIX_EVENT_FOCUS, 0, 0));
    e.type = SDL_EVENT_WINDOW_FOCUS_GAINED; SDL_PushEvent(&e); CHECK(next(HELIX_EVENT_FOCUS, 0, 1));
    CHECK(!helix_input_next());

    /* A virtual gamepad, attached while running: it fills a free slot at the next poll. */
    helix_input_poll(); CHECK(virtual_slot() < 0);
    SDL_VirtualJoystickDesc desc; SDL_INIT_INTERFACE(&desc);
    desc.type = SDL_JOYSTICK_TYPE_GAMEPAD; desc.naxes = SDL_GAMEPAD_AXIS_COUNT; desc.nbuttons = SDL_GAMEPAD_BUTTON_COUNT; desc.name = "HeliX virtual pad";
    SDL_JoystickID id = SDL_AttachVirtualJoystick(&desc); CHECK(id != 0);
    SDL_Joystick *stick = SDL_OpenJoystick(id); CHECK(stick != NULL);
    SDL_PumpEvents(); helix_input_poll();
    const int pad = virtual_slot(); CHECK(pad >= 0);
    /* Each W3C button from SDL's: face buttons by position, shoulders, back and start, stick clicks, the pad, guide. */
    static const int w3c[] = {0, 1, 2, 3, 4, 5, 8, 9, 10, 11, 12, 13, 14, 15, 16};
    static const SDL_GamepadButton sdl[] = {SDL_GAMEPAD_BUTTON_SOUTH, SDL_GAMEPAD_BUTTON_EAST, SDL_GAMEPAD_BUTTON_WEST, SDL_GAMEPAD_BUTTON_NORTH,
        SDL_GAMEPAD_BUTTON_LEFT_SHOULDER, SDL_GAMEPAD_BUTTON_RIGHT_SHOULDER, SDL_GAMEPAD_BUTTON_BACK, SDL_GAMEPAD_BUTTON_START,
        SDL_GAMEPAD_BUTTON_LEFT_STICK, SDL_GAMEPAD_BUTTON_RIGHT_STICK, SDL_GAMEPAD_BUTTON_DPAD_UP, SDL_GAMEPAD_BUTTON_DPAD_DOWN,
        SDL_GAMEPAD_BUTTON_DPAD_LEFT, SDL_GAMEPAD_BUTTON_DPAD_RIGHT, SDL_GAMEPAD_BUTTON_GUIDE};
    for (int i = 0; i < 15; i++) {
        SDL_SetJoystickVirtualButton(stick, sdl[i], true); SDL_UpdateJoysticks(); helix_input_poll();
        for (int b = 0; b < 17; b++) CHECK(helix_pad_button(pad, b) == (b == w3c[i]));
        SDL_SetJoystickVirtualButton(stick, sdl[i], false); SDL_UpdateJoysticks();
    }
    /* Sticks -1..1, down and right positive; triggers 0..1, and pressed past a half as buttons 6 and 7. */
    SDL_SetJoystickVirtualAxis(stick, SDL_GAMEPAD_AXIS_LEFTY, SDL_JOYSTICK_AXIS_MAX);
    SDL_SetJoystickVirtualAxis(stick, SDL_GAMEPAD_AXIS_RIGHTX, SDL_JOYSTICK_AXIS_MIN);
    SDL_SetJoystickVirtualAxis(stick, SDL_GAMEPAD_AXIS_RIGHT_TRIGGER, SDL_JOYSTICK_AXIS_MAX);
    SDL_UpdateJoysticks(); helix_input_poll();
    CHECK(helix_pad_axis(pad, 1) == 1 && helix_pad_axis(pad, 2) == -1 && helix_pad_axis(pad, 0) == 0);
    CHECK(fabsf(helix_pad_axis(pad, 5) - 1) < 1e-4f && helix_pad_button(pad, 7) && !helix_pad_button(pad, 6));
    SDL_SetJoystickVirtualAxis(stick, SDL_GAMEPAD_AXIS_RIGHT_TRIGGER, SDL_JOYSTICK_AXIS_MIN); SDL_UpdateJoysticks();
    CHECK(helix_pad_axis(pad, 5) == 0 && !helix_pad_button(pad, 7));
    /* Detached while running: its slot empties at the next poll. */
    SDL_CloseJoystick(stick); SDL_DetachVirtualJoystick(id); SDL_PumpEvents(); helix_input_poll();
    CHECK(virtual_slot() < 0 && !helix_pad_connected(pad) && !helix_pad_button(pad, 0) && helix_pad_axis(pad, 1) == 0 && helix_pad_name(pad)[0] == 0);

    /* Text input is started on the window only while text entry is on (asked before the window exists, it starts once there is one). */
    CHECK(SDL_InitSubSystem(SDL_INIT_VIDEO));
    helix_input_set_text(1);
    SDL_Window *window = SDL_CreateWindow("text", 64, 64, SDL_WINDOW_HIDDEN); CHECK(window != NULL);
    CHECK(!SDL_TextInputActive(window));
    helix_input_poll(); CHECK(SDL_TextInputActive(window));
    helix_input_set_text(0); helix_input_poll(); CHECK(!SDL_TextInputActive(window));
    helix_input_set_text(1); helix_input_poll(); CHECK(SDL_TextInputActive(window));
    SDL_DestroyWindow(window);

    helix_input_shutdown();
    SDL_Quit();
    printf("{\"passed\":true,\"checks\":%d,\"controller\":\"SDL virtual gamepad through SDL's identity mapping; no controller-database or physical-controller claim\"}\n", checks);
    return 0;
}
