#include "gamepad.h"
#include <stdio.h>
#include <string.h>
#ifndef WIN32_LEAN_AND_MEAN
#define WIN32_LEAN_AND_MEAN
#endif
#include <windows.h>

/* Gamepads on Windows through XInput (wgrender-c's, as libwgf carried it): the four slots XInput numbers, so a pad's number is XInput's.
 * XInput is loaded at run time, from whichever of its DLLs the system has, so the program needs none of them to start. Its documented
 * XInputGetState leaves out the Guide button; XInputGetStateEx, which the DLLs export by ordinal 100 only, reports it, so that is used where
 * there is one, as SDL does. Asking about an empty slot is slow, so an empty one is asked again only every two seconds. */

#define EMPTY_CHECK_MS 2000
#define GET_STATE_EX_ORDINAL 100
#define GUIDE_MASK 0x0400

/* XInput's own types: xinput.h isn't in every toolchain. */
typedef struct {
    WORD buttons;
    BYTE left_trigger, right_trigger;
    SHORT lx, ly, rx, ry;
} xinput_gamepad_t;
typedef struct {
    DWORD packet;
    xinput_gamepad_t gamepad;
} xinput_state_t;
typedef DWORD(WINAPI *xinput_get_state_fn)(DWORD, xinput_state_t *);

typedef struct {
    int connected;
    char name[32];
    xinput_gamepad_t state;
} pad_t;

static HMODULE xinput;
static xinput_get_state_fn get_state;
static pad_t pads[HELIX_GAMEPADS];
static DWORD next_empty_check[HELIX_GAMEPADS];

void helix_gamepad_setup(void) {
    static const char *dlls[] = {"xinput1_4.dll", "xinput1_3.dll", "xinput9_1_0.dll"};
    for (int i = 0; i < 3 && xinput == NULL; i++) xinput = LoadLibraryA(dlls[i]);
    if (xinput != NULL) {
        FARPROC found = GetProcAddress(xinput, (LPCSTR)(ULONG_PTR)GET_STATE_EX_ORDINAL);
        if (found == NULL) found = GetProcAddress(xinput, "XInputGetState");
        /* A function pointer of another type. */
        memcpy(&get_state, &found, sizeof get_state);
    }
    memset(pads, 0, sizeof pads);
    memset(next_empty_check, 0, sizeof next_empty_check);
}

void helix_gamepad_shutdown(void) {
    if (xinput != NULL) FreeLibrary(xinput);
    xinput = NULL;
    get_state = NULL;
    memset(pads, 0, sizeof pads);
}

void helix_gamepad_poll(void) {
    if (get_state == NULL) return;
    const DWORD now = GetTickCount();
    for (int i = 0; i < HELIX_GAMEPADS; i++) {
        xinput_state_t state;
        if (!pads[i].connected && (LONG)(now - next_empty_check[i]) < 0) continue;
        if (get_state((DWORD)i, &state) != ERROR_SUCCESS) {
            memset(&pads[i], 0, sizeof pads[i]);
            next_empty_check[i] = now + EMPTY_CHECK_MS;
            continue;
        }
        pads[i].connected = 1;
        snprintf(pads[i].name, sizeof pads[i].name, "XInput controller %d", i + 1);
        pads[i].state = state.gamepad;
    }
}

static const pad_t *get(int pad) { return pad >= 0 && pad < HELIX_GAMEPADS && pads[pad].connected ? &pads[pad] : NULL; }

int helix_gamepad_connected(int pad) { return get(pad) != NULL; }

const char *helix_gamepad_name(int pad) {
    const pad_t *p = get(pad);
    return p ? p->name : "";
}

int helix_gamepad_button(int pad, int button) {
    /* W3C standard order; 6 and 7, the triggers, are read from their axes. */
    static const WORD masks[17] = {0x1000, 0x2000, 0x4000, 0x8000, 0x0100, 0x0200, 0, 0, 0x0020, 0x0010,
        0x0040, 0x0080, 0x0001, 0x0002, 0x0004, 0x0008, GUIDE_MASK};
    const pad_t *p = get(pad);
    if (!p || button < 0 || button >= 17) return 0;
    if (button == 6 || button == 7) return helix_gamepad_axis(pad, button == 6 ? 4 : 5) > 0.5f;
    return (p->state.buttons & masks[button]) != 0;
}

/* A stick's value, -1..1 (its range runs one further below than above). */
static float stick(SHORT value) {
    const float v = value / 32767.0f;
    return v < -1 ? -1 : v;
}

float helix_gamepad_axis(int pad, int axis) {
    const pad_t *p = get(pad);
    if (!p) return 0;
    /* XInput's sticks run up positive; the W3C layout's down. */
    switch (axis) {
        case 0: return stick(p->state.lx);
        case 1: return -stick(p->state.ly);
        case 2: return stick(p->state.rx);
        case 3: return -stick(p->state.ry);
        case 4: return p->state.left_trigger / 255.0f;
        case 5: return p->state.right_trigger / 255.0f;
        default: return 0;
    }
}
