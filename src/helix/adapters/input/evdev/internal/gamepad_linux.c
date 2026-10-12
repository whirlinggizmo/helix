#include "gamepad.h"
#include <dirent.h>
#include <errno.h>
#include <fcntl.h>
#include <limits.h>
#include <linux/input.h>
#include <stdio.h>
#include <string.h>
#include <sys/ioctl.h>
#include <time.h>
#include <unistd.h>

/* One evdev pad, Linux kernel-standard button/axis codes. No mapping database. */
#define WORD_BITS (sizeof(unsigned long) * CHAR_BIT)
#define WORDS(count) (((count) + WORD_BITS - 1) / WORD_BITS)
static int device = -1, dropped;
static double next_scan;
static unsigned long keys[WORDS(KEY_CNT)], axes[WORDS(ABS_CNT)];
static struct input_absinfo ranges[ABS_CNT];
static int bit(const unsigned long *bits, unsigned code) { return (int)((bits[code / WORD_BITS] >> (code % WORD_BITS)) & 1); }
static void set_bit(unsigned long *bits, unsigned code, int value) {
    const unsigned long mask = 1UL << (code % WORD_BITS);
    if (value) bits[code / WORD_BITS] |= mask; else bits[code / WORD_BITS] &= ~mask;
}
static double now(void) { struct timespec time; clock_gettime(CLOCK_MONOTONIC, &time); return time.tv_sec + time.tv_nsec * 1e-9; }
static void reset(void) {
    if (device >= 0) close(device);
    device = -1; dropped = 0;
    memset(keys, 0, sizeof keys); memset(axes, 0, sizeof axes); memset(ranges, 0, sizeof ranges);
}
static int snapshot(void) {
    if (ioctl(device, EVIOCGKEY(sizeof keys), keys) < 0) return 0;
    for (int code = 0; code < ABS_CNT; code++) if (bit(axes, code)) {
        if (ioctl(device, EVIOCGABS(code), &ranges[code]) < 0) return 0;
    }
    return 1;
}
void hy_gamepad_setup(void) { reset(); next_scan = 0; }
void hy_gamepad_shutdown(void) { reset(); }
static void discover(void) {
    DIR *directory = opendir("/dev/input");
    if (!directory) return;
    struct dirent *entry;
    while ((entry = readdir(directory))) {
        if (strncmp(entry->d_name, "event", 5)) continue;
        char path[sizeof entry->d_name + 16];
        snprintf(path, sizeof path, "/dev/input/%s", entry->d_name);
        const int candidate = open(path, O_RDONLY | O_NONBLOCK | O_CLOEXEC);
        if (candidate < 0) continue;
        unsigned long supported[WORDS(KEY_CNT)] = {0}, absolute[WORDS(ABS_CNT)] = {0};
        const int is_pad = ioctl(candidate, EVIOCGBIT(EV_KEY, sizeof supported), supported) >= 0 &&
            bit(supported, BTN_SOUTH) && bit(supported, BTN_EAST) &&
            ioctl(candidate, EVIOCGBIT(EV_ABS, sizeof absolute), absolute) >= 0 && bit(absolute, ABS_X) && bit(absolute, ABS_Y);
        if (!is_pad) { close(candidate); continue; }
        device = candidate; memcpy(axes, absolute, sizeof axes);
        if (snapshot()) break;
        reset();
    }
    closedir(directory);
}
void hy_gamepad_poll(void) {
    if (device < 0) {
        const double time = now();
        if (time < next_scan) return;
        next_scan = time + 2; discover();
        if (device < 0) return;
    }
    /* Bound work per render frame, preserving unread kernel events for next poll. */
    for (int batch = 0; batch < 16; batch++) {
        struct input_event events[16];
        const ssize_t bytes = read(device, events, sizeof events);
        if (bytes < 0 && errno == EINTR) continue;
        if (bytes < 0 && (errno == EAGAIN || errno == EWOULDBLOCK)) return;
        if (bytes <= 0 || bytes % sizeof events[0]) { reset(); return; }
        for (size_t i = 0; i < (size_t)bytes / sizeof events[0]; i++) {
            const struct input_event *event = &events[i];
            if (event->type == EV_SYN && event->code == SYN_DROPPED) { dropped = 1; continue; }
            if (dropped) {
                if (event->type == EV_SYN && event->code == SYN_REPORT) {
                    if (!snapshot()) { reset(); return; }
                    dropped = 0;
                }
                continue;
            }
            if (event->type == EV_KEY && event->code < KEY_CNT) set_bit(keys, event->code, event->value != 0);
            if (event->type == EV_ABS && event->code < ABS_CNT && bit(axes, event->code)) ranges[event->code].value = event->value;
        }
    }
}
int hy_gamepad_available(void) { return device >= 0; }
int hy_gamepad_button(int button) {
    static const unsigned codes[] = {BTN_SOUTH, BTN_EAST, BTN_TR, BTN_START, BTN_DPAD_UP, BTN_DPAD_DOWN, BTN_DPAD_LEFT, BTN_DPAD_RIGHT};
    if (device < 0 || button < 0 || button >= 8) return 0;
    if (bit(keys, codes[button])) return 1;
    if (button == 4 || button == 5) return bit(axes, ABS_HAT0Y) && (button == 4 ? ranges[ABS_HAT0Y].value < 0 : ranges[ABS_HAT0Y].value > 0);
    if (button == 6 || button == 7) return bit(axes, ABS_HAT0X) && (button == 6 ? ranges[ABS_HAT0X].value < 0 : ranges[ABS_HAT0X].value > 0);
    return 0;
}
float hy_gamepad_axis(int axis) {
    if (device < 0 || axis < 0 || axis > 2) return 0;
    int code = axis == 0 ? ABS_X : ABS_Y;
    if (axis == 2) {
        if (bit(axes, ABS_GAS)) code = ABS_GAS;
        else if (bit(axes, ABS_RZ) && bit(axes, ABS_RX) && bit(axes, ABS_RY)) code = ABS_RZ;
        else return 0; /* Generic Z/RZ stick layouts are ambiguous; avoid false thrust. */
    }
    const struct input_absinfo *range = &ranges[code];
    const double span = (double)range->maximum - range->minimum;
    if (!bit(axes, code) || span <= 0) return 0;
    double value = ((double)range->value - range->minimum) / span;
    if (value < 0) value = 0; if (value > 1) value = 1;
    return (float)(axis == 2 ? value : value * 2 - 1);
}
#ifdef HY_SERVICES_TEST
void hy_gamepad_test_connect(int fd) { reset(); device = fd; }
void hy_gamepad_test_range(int code, int minimum, int maximum, int value) {
    if (code < 0 || code >= ABS_CNT) return;
    set_bit(axes, code, 1); ranges[code] = (struct input_absinfo){.minimum=minimum, .maximum=maximum, .value=value};
}
#endif
