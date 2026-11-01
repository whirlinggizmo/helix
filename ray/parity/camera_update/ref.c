// raylib 5.5's rcamera UpdateCamera over the frames in frames.txt, its input functions stubbed with them, each frame 1/60 s; a Z-up
// start is camera_update_62's.
#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include "raylib.h"
static int keys[512], prevKeys[512], buttons[8], pad; static float mouseX, mouseY, prevX, prevY, wheel, axes[8];
Vector2 GetMouseDelta(void) { return (Vector2){ mouseX - prevX, mouseY - prevY }; }
float GetMouseWheelMove(void) { return wheel; }
bool IsKeyDown(int k) { return keys[k]; }
bool IsKeyPressed(int k) { return keys[k] && !prevKeys[k]; }
bool IsMouseButtonDown(int b) { return buttons[b]; }
bool IsGamepadAvailable(int g) { return g == 0 && pad; }
float GetGamepadAxisMovement(int g, int a) { return g == 0 && pad ? axes[a] : 0; }
float GetFrameTime(void) { return 1.0f / 60; }
#define RL_CULL_DISTANCE_NEAR 0.01
#define RL_CULL_DISTANCE_FAR 1000.0
#define RAYMATH_STATIC_INLINE
#define RCAMERA_IMPLEMENTATION
#include "rcamera.h"
int main(void) {
    char lines[64][128]; int n = 0; FILE *f = fopen("frames.txt", "r");
    while (fgets(lines[n], 128, f)) { lines[n][strcspn(lines[n], "\n")] = 0; if (lines[n][0]) n++; }
    int modes[5] = { CAMERA_FREE, CAMERA_FIRST_PERSON, CAMERA_THIRD_PERSON, CAMERA_ORBITAL, CAMERA_CUSTOM };
    float starts[2][3][3] = { { {0, 2, 4}, {0, 2, 0}, {0, 1, 0} }, { {3, -1, 2}, {-1, .5f, -4}, {.2f, .9f, .1f} } };
    for (int s = 0; s < 2; s++) for (int m = 0; m < 5; m++) {
        Camera c = { { starts[s][0][0], starts[s][0][1], starts[s][0][2] }, { starts[s][1][0], starts[s][1][1], starts[s][1][2] },
            { starts[s][2][0], starts[s][2][1], starts[s][2][2] }, 60, CAMERA_PERSPECTIVE };
        memset(keys, 0, sizeof keys); mouseX = mouseY = 0;
        for (int round = 0; round < 2; round++) for (int i = 0; i < n; i++) {
            char line[128]; strcpy(line, lines[i]); char *t = strtok(line, " ");
            memcpy(prevKeys, keys, sizeof keys); memset(keys, 0, sizeof keys); memset(buttons, 0, sizeof buttons);
            prevX = mouseX; prevY = mouseY; wheel = 0; pad = 0; memset(axes, 0, sizeof axes);
            if (!strcmp(t, "mouse") || !strcmp(t, "pan")) { int p = !strcmp(t, "pan"); mouseX += atof(strtok(0, " ")); mouseY += atof(strtok(0, " ")); if (p) buttons[MOUSE_BUTTON_MIDDLE] = 1; }
            else if (!strcmp(t, "keys") || !strcmp(t, "press")) { char *k; while ((k = strtok(0, " "))) keys[atoi(k)] = 1; }
            else if (!strcmp(t, "wheel")) wheel = atof(strtok(0, " "));
            else if (!strcmp(t, "pad")) { pad = 1; axes[GAMEPAD_AXIS_RIGHT_X] = atof(strtok(0, " ")); axes[GAMEPAD_AXIS_RIGHT_Y] = atof(strtok(0, " "));
                axes[GAMEPAD_AXIS_LEFT_Y] = atof(strtok(0, " ")); axes[GAMEPAD_AXIS_LEFT_X] = atof(strtok(0, " ")); }
            UpdateCamera(&c, modes[m]);
            printf("s%d.m%d.r%d.f%d %.9g %.9g %.9g %.9g %.9g %.9g %.9g %.9g %.9g\n", s, modes[m], round, i, c.position.x, c.position.y, c.position.z,
                c.target.x, c.target.y, c.target.z, c.up.x, c.up.y, c.up.z);
        }
    }
    return 0;
}
