/* SDL3's events adapters' C (platform: shared/sdl3/events_sdl3.c) against SDL's own events, with SDL's dummy video driver: with no device
   wanted, the first press alone arrives, then SDL drops the devices' events; with them wanted, events pushed through SDL come out of a poll
   as records in order, with the platform's codes; the window's focus, visibility and close arrive as events; and an SDL virtual gamepad,
   attached and detached while running, connects in a slot and reads as the W3C standard layout. A virtual
   gamepad uses SDL's identity mapping, so this checks the adapter's translation, not SDL's controller database or a real pad. */
#include "events_sdl3.h"
#include "sdl3.h"
#include <SDL3/SDL.h>
#include <math.h>
#include <stdio.h>
#include <stdlib.h>

static int checks;
#define CHECK(value) do { if (!(value)) { fprintf(stderr, "Failed at line %d\n", __LINE__); abort(); } checks++; } while (0)

/* The next record of the last poll is kind, code and value. */
static int next(int kind, int code, int value) {
    return helix_events_next() && helix_events_kind() == kind && helix_events_code() == code && helix_events_value() == value;
}
/* The virtual pad's slot, or -1: found by its name, as a real pad may be plugged in too. */
static int virtual_slot(void) {
    for (int i = 0; i < 4; i++) if (helix_pad_connected(i) && SDL_strcmp(helix_pad_name(i), "HeliX virtual pad") == 0) return i;
    return -1;
}
static void key(SDL_Scancode scancode, int down, int repeat) {
    SDL_Event e = {0};
    e.type = down ? SDL_EVENT_KEY_DOWN : SDL_EVENT_KEY_UP; e.key.scancode = scancode; e.key.down = down; e.key.repeat = repeat;
    SDL_PushEvent(&e);
}

int main(void) {
    SDL_SetHint(SDL_HINT_VIDEO_DRIVER, "dummy");
    CHECK(helix_sdl3_open(1, 0));
    helix_events_setup();
    helix_events_poll();
    while (helix_events_next()) {}

    /* No device wanted: SDL delivers only what the first press needs, a key's or a mouse button's press or a finger's lift; a key's press
       is the first press, alone, once, and then SDL delivers none of them. */
    CHECK(SDL_EventEnabled(SDL_EVENT_KEY_DOWN) && SDL_EventEnabled(SDL_EVENT_MOUSE_BUTTON_DOWN) && SDL_EventEnabled(SDL_EVENT_FINGER_UP));
    CHECK(!SDL_EventEnabled(SDL_EVENT_KEY_UP) && !SDL_EventEnabled(SDL_EVENT_MOUSE_MOTION) && !SDL_EventEnabled(SDL_EVENT_FINGER_DOWN));
    key(SDL_SCANCODE_A, 1, 0); key(SDL_SCANCODE_A, 0, 0);
    helix_events_poll();
    CHECK(next(HELIX_EVENTS_UNLOCKED, 0, 0)); CHECK(!helix_events_next());
    CHECK(!SDL_EventEnabled(SDL_EVENT_KEY_DOWN) && !SDL_EventEnabled(SDL_EVENT_MOUSE_BUTTON_DOWN) && !SDL_EventEnabled(SDL_EVENT_FINGER_UP));
    key(SDL_SCANCODE_B, 1, 0);
    helix_events_poll(); CHECK(!helix_events_next());

    helix_events_want(HELIX_EVENTS_KEYBOARD | HELIX_EVENTS_MOUSE | HELIX_EVENTS_TOUCH, 1);
    helix_events_poll(); CHECK(!helix_events_next());
    CHECK(SDL_EventEnabled(SDL_EVENT_KEY_UP) && SDL_EventEnabled(SDL_EVENT_MOUSE_MOTION) && SDL_EventEnabled(SDL_EVENT_FINGER_DOWN));
    SDL_Event e = {0};

    /* Keys by physical position, as Key's numbers; right-hand modifiers as the left-hand ones; a repeat says so; a key `Key` doesn't name
       isn't reported. */
    key(SDL_SCANCODE_A, 1, 0); key(SDL_SCANCODE_A, 1, 1); key(SDL_SCANCODE_A, 0, 0); key(SDL_SCANCODE_RCTRL, 1, 0); key(SDL_SCANCODE_MUTE, 1, 0);
    key(SDL_SCANCODE_KP_ENTER, 1, 0); key(SDL_SCANCODE_NONUSBACKSLASH, 1, 0); key(SDL_SCANCODE_APPLICATION, 1, 0);
    helix_events_poll();
    CHECK(next(HELIX_EVENTS_KEY_DOWN, 65, 0)); CHECK(next(HELIX_EVENTS_KEY_DOWN, 65, 1)); CHECK(next(HELIX_EVENTS_KEY_UP, 65, 0));
    CHECK(next(HELIX_EVENTS_KEY_DOWN, 341, 0)); CHECK(next(HELIX_EVENTS_KEY_DOWN, 335, 0)); CHECK(next(HELIX_EVENTS_KEY_DOWN, 161, 0));
    CHECK(next(HELIX_EVENTS_KEY_DOWN, 348, 0)); CHECK(!helix_events_next());

    /* Text as code points, control characters dropped. */
    e = (SDL_Event){0};
    e.type = SDL_EVENT_TEXT_INPUT; e.text.text = "a\xc3\xa9\x01\xe2\x82\xac"; SDL_PushEvent(&e);
    helix_events_poll();
    CHECK(next(HELIX_EVENTS_TEXT, 'a', 0)); CHECK(next(HELIX_EVENTS_TEXT, 0xe9, 0)); CHECK(next(HELIX_EVENTS_TEXT, 0x20ac, 0));
    CHECK(!helix_events_next());

    /* Mouse buttons (left 0, right 1, middle 2), where they happened; a pointer made of touch is dropped. */
    e = (SDL_Event){0}; e.type = SDL_EVENT_MOUSE_BUTTON_DOWN; e.button.button = SDL_BUTTON_RIGHT; e.button.down = true; e.button.x = 20; e.button.y = 30;
    SDL_PushEvent(&e);
    e.button.button = SDL_BUTTON_MIDDLE; SDL_PushEvent(&e);
    e.button.which = SDL_TOUCH_MOUSEID; SDL_PushEvent(&e);
    e = (SDL_Event){0}; e.type = SDL_EVENT_MOUSE_MOTION; e.motion.x = 5; e.motion.y = 6; SDL_PushEvent(&e);
    e = (SDL_Event){0}; e.type = SDL_EVENT_MOUSE_WHEEL; e.wheel.x = 1; e.wheel.y = -2; SDL_PushEvent(&e);
    e = (SDL_Event){0}; e.type = SDL_EVENT_WINDOW_MOUSE_LEAVE; SDL_PushEvent(&e);
    helix_events_poll();
    CHECK(next(HELIX_EVENTS_MOUSE_DOWN, 1, 0) && helix_events_x() == 20 && helix_events_y() == 30);
    CHECK(next(HELIX_EVENTS_MOUSE_DOWN, 2, 0));
    CHECK(next(HELIX_EVENTS_MOUSE_MOVE, 0, 0) && helix_events_x() == 5 && helix_events_y() == 6);
    CHECK(next(HELIX_EVENTS_WHEEL, 0, 0) && helix_events_x() == 1 && helix_events_y() == -2);
    CHECK(next(HELIX_EVENTS_MOUSE_LEAVE, 0, 0)); CHECK(!helix_events_next());

    /* Fingers by a small number while down, freed when up: down, down, and a canceled touch lifted. */
    e = (SDL_Event){0}; e.type = SDL_EVENT_FINGER_DOWN; e.tfinger.fingerID = 0x1234567890ull; SDL_PushEvent(&e);
    e.tfinger.fingerID = 77; SDL_PushEvent(&e);
    e.type = SDL_EVENT_FINGER_MOTION; SDL_PushEvent(&e);
    e.type = SDL_EVENT_FINGER_CANCELED; e.tfinger.fingerID = 0x1234567890ull; SDL_PushEvent(&e);
    helix_events_poll();
    CHECK(next(HELIX_EVENTS_TOUCH_DOWN, 0, 0)); CHECK(next(HELIX_EVENTS_TOUCH_DOWN, 1, 0)); CHECK(next(HELIX_EVENTS_TOUCH_MOVE, 1, 0));
    CHECK(next(HELIX_EVENTS_TOUCH_UP, 0, 0)); CHECK(!helix_events_next());

    /* The window: focus (kept where the window adapter reads it), visibility, size, a close asked for; the program decides about it. */
    e = (SDL_Event){0}; e.type = SDL_EVENT_WINDOW_FOCUS_LOST; SDL_PushEvent(&e);
    e.type = SDL_EVENT_WINDOW_MINIMIZED; SDL_PushEvent(&e);
    e.type = SDL_EVENT_WINDOW_RESTORED; SDL_PushEvent(&e);
    e.type = SDL_EVENT_WINDOW_PIXEL_SIZE_CHANGED; e.window.data1 = 640; e.window.data2 = 360; SDL_PushEvent(&e);
    e.type = SDL_EVENT_WINDOW_CLOSE_REQUESTED; SDL_PushEvent(&e);
    helix_events_poll();
    CHECK(next(HELIX_EVENTS_FOCUS_LOST, 0, 0) && !helix_sdl3_focused()); CHECK(next(HELIX_EVENTS_HIDDEN, 0, 0)); CHECK(next(HELIX_EVENTS_SHOWN, 0, 0));
    CHECK(next(HELIX_EVENTS_RESIZED, 640, 360)); CHECK(next(HELIX_EVENTS_CLOSE_REQUESTED, 0, 0)); CHECK(helix_sdl3_is_open());
    e = (SDL_Event){0}; e.type = SDL_EVENT_WINDOW_FOCUS_GAINED; SDL_PushEvent(&e);
    helix_events_poll(); CHECK(next(HELIX_EVENTS_FOCUS_GAINED, 0, 0) && helix_sdl3_focused());

    /* A virtual gamepad, attached while running: it connects in a free slot at the next poll, once the gamepads are wanted. */
    helix_events_want(HELIX_EVENTS_GAMEPADS, 1);
    helix_events_poll(); CHECK(virtual_slot() < 0);
    SDL_VirtualJoystickDesc desc; SDL_INIT_INTERFACE(&desc);
    desc.type = SDL_JOYSTICK_TYPE_GAMEPAD; desc.naxes = SDL_GAMEPAD_AXIS_COUNT; desc.nbuttons = SDL_GAMEPAD_BUTTON_COUNT; desc.name = "HeliX virtual pad";
    SDL_JoystickID id = SDL_AttachVirtualJoystick(&desc); CHECK(id != 0);
    SDL_Joystick *stick = SDL_OpenJoystick(id); CHECK(stick != NULL);
    helix_events_poll();
    const int pad = virtual_slot(); CHECK(pad >= 0);
    int connected = 0; while (helix_events_next()) if (helix_events_kind() == HELIX_EVENTS_PAD_CONNECTED && helix_events_code() == pad) connected = 1;
    CHECK(connected);
    /* Each W3C button from SDL's: face buttons by position, shoulders, back and start, stick clicks, the pad, guide. */
    static const int w3c[] = {0, 1, 2, 3, 4, 5, 8, 9, 10, 11, 12, 13, 14, 15, 16};
    static const SDL_GamepadButton sdl[] = {SDL_GAMEPAD_BUTTON_SOUTH, SDL_GAMEPAD_BUTTON_EAST, SDL_GAMEPAD_BUTTON_WEST, SDL_GAMEPAD_BUTTON_NORTH,
        SDL_GAMEPAD_BUTTON_LEFT_SHOULDER, SDL_GAMEPAD_BUTTON_RIGHT_SHOULDER, SDL_GAMEPAD_BUTTON_BACK, SDL_GAMEPAD_BUTTON_START,
        SDL_GAMEPAD_BUTTON_LEFT_STICK, SDL_GAMEPAD_BUTTON_RIGHT_STICK, SDL_GAMEPAD_BUTTON_DPAD_UP, SDL_GAMEPAD_BUTTON_DPAD_DOWN,
        SDL_GAMEPAD_BUTTON_DPAD_LEFT, SDL_GAMEPAD_BUTTON_DPAD_RIGHT, SDL_GAMEPAD_BUTTON_GUIDE};
    /* Each read as state, and arriving as a record going down and another going up. */
    for (int i = 0; i < 15; i++) {
        SDL_SetJoystickVirtualButton(stick, sdl[i], true); SDL_UpdateJoysticks(); helix_events_poll();
        for (int b = 0; b < 17; b++) CHECK(helix_pad_button(pad, b) == (b == w3c[i]));
        CHECK(next(HELIX_EVENTS_PAD_BUTTON_DOWN, pad, w3c[i]));
        SDL_SetJoystickVirtualButton(stick, sdl[i], false); SDL_UpdateJoysticks();
        /* SDL holds back Guide's release until a quarter second after its press, then sends it at a later update. */
        if (sdl[i] == SDL_GAMEPAD_BUTTON_GUIDE) { SDL_Delay(300); SDL_UpdateJoysticks(); }
        helix_events_poll();
        CHECK(next(HELIX_EVENTS_PAD_BUTTON_UP, pad, w3c[i]));
    }
    /* Pressed and let go between two polls: both records, in order, though the state reads up. */
    SDL_SetJoystickVirtualButton(stick, SDL_GAMEPAD_BUTTON_SOUTH, true); SDL_UpdateJoysticks();
    SDL_SetJoystickVirtualButton(stick, SDL_GAMEPAD_BUTTON_SOUTH, false); SDL_UpdateJoysticks(); helix_events_poll();
    CHECK(next(HELIX_EVENTS_PAD_BUTTON_DOWN, pad, 0) && next(HELIX_EVENTS_PAD_BUTTON_UP, pad, 0) && !helix_pad_button(pad, 0));
    /* Sticks -1..1, down and right positive; triggers 0..1, and pressed past a half as buttons 6 and 7. */
    SDL_SetJoystickVirtualAxis(stick, SDL_GAMEPAD_AXIS_LEFTY, SDL_JOYSTICK_AXIS_MAX);
    SDL_SetJoystickVirtualAxis(stick, SDL_GAMEPAD_AXIS_RIGHTX, SDL_JOYSTICK_AXIS_MIN);
    SDL_SetJoystickVirtualAxis(stick, SDL_GAMEPAD_AXIS_RIGHT_TRIGGER, SDL_JOYSTICK_AXIS_MAX);
    SDL_UpdateJoysticks(); helix_events_poll();
    CHECK(helix_pad_axis(pad, 1) == 1 && helix_pad_axis(pad, 2) == -1 && helix_pad_axis(pad, 0) == 0);
    CHECK(fabsf(helix_pad_axis(pad, 5) - 1) < 1e-4f && helix_pad_button(pad, 7) && !helix_pad_button(pad, 6));
    CHECK(next(HELIX_EVENTS_PAD_BUTTON_DOWN, pad, 7));
    SDL_SetJoystickVirtualAxis(stick, SDL_GAMEPAD_AXIS_RIGHT_TRIGGER, SDL_JOYSTICK_AXIS_MIN); SDL_UpdateJoysticks();
    CHECK(helix_pad_axis(pad, 5) == 0 && !helix_pad_button(pad, 7));
    helix_events_poll();
    CHECK(next(HELIX_EVENTS_PAD_BUTTON_UP, pad, 7));
    /* Detached while running: its slot empties, and says so, at the next poll. */
    SDL_CloseJoystick(stick); SDL_DetachVirtualJoystick(id); helix_events_poll();
    int disconnected = 0; while (helix_events_next()) if (helix_events_kind() == HELIX_EVENTS_PAD_DISCONNECTED && helix_events_code() == pad) disconnected = 1;
    CHECK(disconnected);
    CHECK(virtual_slot() < 0 && !helix_pad_connected(pad) && !helix_pad_button(pad, 0) && helix_pad_axis(pad, 1) == 0 && helix_pad_name(pad)[0] == 0);

    /* Text input is started on the window only while text entry is on. */
    SDL_Window *window = (SDL_Window*)helix_sdl3_window();
    CHECK(!SDL_TextInputActive(window));
    helix_events_set_text(1); CHECK(SDL_TextInputActive(window));
    helix_events_set_text(0); CHECK(!SDL_TextInputActive(window));
    helix_events_set_text(1); CHECK(SDL_TextInputActive(window));
    /* The keyboard no longer wanted stops text input; its keys are dropped again. */
    helix_events_want(HELIX_EVENTS_KEYBOARD, 0); CHECK(!SDL_TextInputActive(window));
    helix_events_poll(); CHECK(!SDL_EventEnabled(SDL_EVENT_KEY_DOWN) && SDL_EventEnabled(SDL_EVENT_MOUSE_BUTTON_DOWN));

    helix_events_dispose();
    helix_sdl3_close();
    printf("{\"passed\":true,\"checks\":%d,\"controller\":\"SDL virtual gamepad through SDL's identity mapping; no controller-database or physical-controller claim\"}\n", checks);
    return 0;
}
