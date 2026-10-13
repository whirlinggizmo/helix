#include "gamepad.h"
#include <dirent.h>
#include <errno.h>
#include <fcntl.h>
#include <limits.h>
#include <linux/input.h>
#include <stdio.h>
#include <string.h>
#include <sys/ioctl.h>
#include <sys/stat.h>
#include <time.h>
#include <unistd.h>

/* Up to four evdev pads, Linux kernel-standard button/axis codes. No mapping database. */
#define WORD_BITS (sizeof(unsigned long) * CHAR_BIT)
#define WORDS(count) (((count) + WORD_BITS - 1) / WORD_BITS)
typedef struct {
    int device, dropped;
    int xpad;       /* the xpad driver: X and Y report BTN_NORTH's and BTN_WEST's codes, swapped from the kernel's gamepad spec */
    int right_on_z; /* no RX/RY: the right stick is on Z/RZ (generic HID pads) */
    dev_t node;
    char name[128];
    unsigned long keys[WORDS(KEY_CNT)], axes[WORDS(ABS_CNT)];
    struct input_absinfo ranges[ABS_CNT];
} pad_t;
static pad_t pads[HY_GAMEPADS];
static double next_scan;
static int bit(const unsigned long *bits, unsigned code) { return (int)((bits[code / WORD_BITS] >> (code % WORD_BITS)) & 1); }
static void set_bit(unsigned long *bits, unsigned code, int value) {
    const unsigned long mask = 1UL << (code % WORD_BITS);
    if (value) bits[code / WORD_BITS] |= mask; else bits[code / WORD_BITS] &= ~mask;
}
static double now(void) { struct timespec time; clock_gettime(CLOCK_MONOTONIC, &time); return time.tv_sec + time.tv_nsec * 1e-9; }
static void reset(pad_t *pad) {
    if (pad->device >= 0) close(pad->device);
    memset(pad, 0, sizeof *pad);
    pad->device = -1;
}
static int snapshot(pad_t *pad) {
    if (ioctl(pad->device, EVIOCGKEY(sizeof pad->keys), pad->keys) < 0) return 0;
    for (int code = 0; code < ABS_CNT; code++) if (bit(pad->axes, code)) {
        if (ioctl(pad->device, EVIOCGABS(code), &pad->ranges[code]) < 0) return 0;
    }
    return 1;
}
void hy_gamepad_setup(void) { for (int i = 0; i < HY_GAMEPADS; i++) { pads[i].device = -1; reset(&pads[i]); } next_scan = 0; }
void hy_gamepad_shutdown(void) { for (int i = 0; i < HY_GAMEPADS; i++) reset(&pads[i]); }
static int open_already(dev_t node) {
    for (int i = 0; i < HY_GAMEPADS; i++) if (pads[i].device >= 0 && pads[i].node == node) return 1;
    return 0;
}
/* Whether the event device's driver is driver (sysfs: /sys/class/input/<event>/device/device/driver). */
static int driver_is(const char *event_name, const char *driver) {
    char link[320], target[256];
    snprintf(link, sizeof link, "/sys/class/input/%s/device/device/driver", event_name);
    const ssize_t n = readlink(link, target, sizeof target - 1);
    if (n <= 0) return 0;
    target[n] = 0;
    const char *base = strrchr(target, '/');
    return strcmp(base ? base + 1 : target, driver) == 0;
}

/* Fill free slots with pads not yet open: a device with south and east buttons and an X/Y stick. */
static void discover(void) {
#ifdef HY_SERVICES_TEST
    return; /* Tests feed pads through pipes; a real pad on the machine must not take a slot. */
#endif
    DIR *directory = opendir("/dev/input");
    if (!directory) return;
    struct dirent *entry;
    while ((entry = readdir(directory))) {
        int slot = -1;
        for (int i = 0; i < HY_GAMEPADS && slot < 0; i++) if (pads[i].device < 0) slot = i;
        if (slot < 0) break;
        if (strncmp(entry->d_name, "event", 5)) continue;
        char path[sizeof entry->d_name + 16];
        snprintf(path, sizeof path, "/dev/input/%s", entry->d_name);
        struct stat info;
        if (stat(path, &info) < 0 || open_already(info.st_rdev)) continue;
        const int candidate = open(path, O_RDONLY | O_NONBLOCK | O_CLOEXEC);
        if (candidate < 0) continue;
        unsigned long supported[WORDS(KEY_CNT)] = {0}, absolute[WORDS(ABS_CNT)] = {0};
        const int is_pad = ioctl(candidate, EVIOCGBIT(EV_KEY, sizeof supported), supported) >= 0 &&
            bit(supported, BTN_SOUTH) && bit(supported, BTN_EAST) &&
            ioctl(candidate, EVIOCGBIT(EV_ABS, sizeof absolute), absolute) >= 0 && bit(absolute, ABS_X) && bit(absolute, ABS_Y);
        if (!is_pad) { close(candidate); continue; }
        pad_t *pad = &pads[slot];
        pad->device = candidate; pad->node = info.st_rdev; memcpy(pad->axes, absolute, sizeof pad->axes);
        pad->xpad = driver_is(entry->d_name, "xpad");
        pad->right_on_z = !bit(absolute, ABS_RX) && bit(absolute, ABS_Z) && bit(absolute, ABS_RZ);
        if (ioctl(candidate, EVIOCGNAME(sizeof pad->name), pad->name) < 0) snprintf(pad->name, sizeof pad->name, "gamepad");
        pad->name[sizeof pad->name - 1] = 0;
        if (!snapshot(pad)) reset(pad);
    }
    closedir(directory);
}
static void read_pad(pad_t *pad) {
    /* Bound work per render frame, preserving unread kernel events for next poll. */
    for (int batch = 0; batch < 16; batch++) {
        struct input_event events[16];
        const ssize_t bytes = read(pad->device, events, sizeof events);
        if (bytes < 0 && errno == EINTR) continue;
        if (bytes < 0 && (errno == EAGAIN || errno == EWOULDBLOCK)) return;
        if (bytes <= 0 || bytes % sizeof events[0]) { reset(pad); return; }
        for (size_t i = 0; i < (size_t)bytes / sizeof events[0]; i++) {
            const struct input_event *event = &events[i];
            if (event->type == EV_SYN && event->code == SYN_DROPPED) { pad->dropped = 1; continue; }
            if (pad->dropped) {
                if (event->type == EV_SYN && event->code == SYN_REPORT) {
                    if (!snapshot(pad)) { reset(pad); return; }
                    pad->dropped = 0;
                }
                continue;
            }
            if (event->type == EV_KEY && event->code < KEY_CNT) set_bit(pad->keys, event->code, event->value != 0);
            if (event->type == EV_ABS && event->code < ABS_CNT && bit(pad->axes, event->code)) pad->ranges[event->code].value = event->value;
        }
    }
}
void hy_gamepad_poll(void) {
    int open_count = 0;
    for (int i = 0; i < HY_GAMEPADS; i++) if (pads[i].device >= 0) open_count++;
    if (open_count < HY_GAMEPADS) {
        const double time = now();
        if (time >= next_scan) { next_scan = time + 2; discover(); }
    }
    for (int i = 0; i < HY_GAMEPADS; i++) if (pads[i].device >= 0) read_pad(&pads[i]);
}
static pad_t *get(int pad) { return pad >= 0 && pad < HY_GAMEPADS && pads[pad].device >= 0 ? &pads[pad] : NULL; }
int hy_gamepad_connected(int pad) { return get(pad) != NULL; }
const char *hy_gamepad_name(int pad) { pad_t *p = get(pad); return p ? p->name : ""; }
static int hat(const pad_t *pad, int code, int negative) {
    return bit(pad->axes, code) && (negative ? pad->ranges[code].value < 0 : pad->ranges[code].value > 0);
}
int hy_gamepad_button(int pad, int button) {
    /* W3C standard order, by the kernel's gamepad spec (BTN_WEST the left face button, BTN_NORTH the top); the xpad driver
       reports Xbox X and Y with the two codes swapped. */
    static const unsigned codes[17] = {BTN_SOUTH, BTN_EAST, BTN_WEST, BTN_NORTH, BTN_TL, BTN_TR, BTN_TL2, BTN_TR2, BTN_SELECT, BTN_START,
        BTN_THUMBL, BTN_THUMBR, BTN_DPAD_UP, BTN_DPAD_DOWN, BTN_DPAD_LEFT, BTN_DPAD_RIGHT, BTN_MODE};
    const pad_t *p = get(pad);
    if (!p || button < 0 || button >= 17 || !codes[button]) return 0;
    unsigned code = codes[button];
    if (p->xpad && (button == 2 || button == 3)) code = button == 2 ? BTN_NORTH : BTN_WEST;
    if (bit(p->keys, code)) return 1;
    /* The triggers are buttons too, as the W3C layout's 6 and 7: pressed past half way on a pad with analog triggers. */
    if (button == 6 || button == 7) return hy_gamepad_axis(pad, button == 6 ? 4 : 5) > 0.5f;
    if (button == 12 || button == 13) return hat(p, ABS_HAT0Y, button == 12);
    if (button == 14 || button == 15) return hat(p, ABS_HAT0X, button == 14);
    return 0;
}
static float normalized(const pad_t *pad, int code, int signed_range) {
    const struct input_absinfo *range = &pad->ranges[code];
    const double span = (double)range->maximum - range->minimum;
    if (!bit(pad->axes, code) || span <= 0) return 0;
    double value = ((double)range->value - range->minimum) / span;
    if (value < 0) value = 0; if (value > 1) value = 1;
    return (float)(signed_range ? value * 2 - 1 : value);
}
float hy_gamepad_axis(int pad, int axis) {
    const pad_t *p = get(pad);
    if (!p || axis < 0 || axis > 5) return 0;
    /* The right stick on RX/RY, or on Z/RZ where a generic HID pad has no RX/RY (right_on_z). Analog triggers on ABS_BRAKE/ABS_GAS,
       else on Z/RZ; a pad with only digital triggers reads 0 here, and its triggers as buttons 6 and 7. */
    const int dual = bit(p->axes, ABS_RX) && bit(p->axes, ABS_RY);
    switch (axis) {
        case 0: return normalized(p, ABS_X, 1);
        case 1: return normalized(p, ABS_Y, 1);
        case 2: return dual ? normalized(p, ABS_RX, 1) : p->right_on_z ? normalized(p, ABS_Z, 1) : 0;
        case 3: return dual ? normalized(p, ABS_RY, 1) : p->right_on_z ? normalized(p, ABS_RZ, 1) : 0;
        case 4:
            if (bit(p->axes, ABS_BRAKE)) return normalized(p, ABS_BRAKE, 0);
            return !p->right_on_z && bit(p->axes, ABS_Z) ? normalized(p, ABS_Z, 0) : 0;
        default:
            if (bit(p->axes, ABS_GAS)) return normalized(p, ABS_GAS, 0);
            return !p->right_on_z && bit(p->axes, ABS_RZ) ? normalized(p, ABS_RZ, 0) : 0;
    }
}
#ifdef HY_SERVICES_TEST
void hy_gamepad_test_driver(int pad, int xpad, int right_on_z) { pads[pad].xpad = xpad; pads[pad].right_on_z = right_on_z; }
void hy_gamepad_test_connect(int pad, int fd) { reset(&pads[pad]); pads[pad].device = fd; pads[pad].node = (dev_t)(pad + 1); snprintf(pads[pad].name, sizeof pads[pad].name, "test pad %d", pad); }
void hy_gamepad_test_range(int pad, int code, int minimum, int maximum, int value) {
    if (code < 0 || code >= ABS_CNT) return;
    set_bit(pads[pad].axes, code, 1); pads[pad].ranges[code] = (struct input_absinfo){.minimum=minimum, .maximum=maximum, .value=value};
}
#endif
