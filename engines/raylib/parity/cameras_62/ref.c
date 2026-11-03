// raylib 6.2's rcamera CameraMoveForward and CameraMoveRight (6.2 #5458: the world's plane is the one square to the camera's up, so a
// Z-up or X-up camera moves on its ground) and UpdateCameraPro, which moves in that plane, over the cases CameraBits62.hx prints, as double
// bits, one line per case; each camera's first line its scale line, as CameraBits62.hx prints it.
#include "raylib.h"
#include <stdio.h>
#include <string.h>
#include <stdint.h>
#include <math.h>
void CameraMoveForward(Camera *camera, float distance, bool moveInWorldPlane);
void CameraMoveRight(Camera *camera, float distance, bool moveInWorldPlane);

static void bits(double x) { uint64_t u; memcpy(&u, &x, 8); printf(" %016llX", (unsigned long long)u); }
static void put(const char *label, const float *v, int n) { printf("%s", label); for (int i = 0; i < n; i++) bits(v[i]); printf("\n"); }
static void cam(const char *label, Camera *c) {
    float v[9] = { c->position.x, c->position.y, c->position.z, c->target.x, c->target.y, c->target.z, c->up.x, c->up.y, c->up.z };
    put(label, v, 9);
}
static double positions[4][3] = { {0, 2, 4}, {10, -3, 7.5}, {0, 0, 0}, {-1e3, 50, 2e2} };
static double ups[6][3] = { {0, 1, 0}, {0, 0, 1}, {.3, .9, -.1}, {0, 0, 0}, {0, -2, 0}, {1, 0, 0} };
static double fovys[7][2] = { {45, 0}, {60, 0}, {0, 0}, {179, 0}, {1e-4, 0}, {10, 1}, {0, 1} };
static Vector3 V(const double *a) { return (Vector3){ (float)a[0], (float)a[1], (float)a[2] }; }
// What a camera's differences are measured against: the scene's size, at least 1.
static double scale(const double *p, const double *t) {
    double s = 1;
    for (int i = 0; i < 3; i++) { if (fabs(p[i]) > s) s = fabs(p[i]); if (fabs(t[i]) > s) s = fabs(t[i]); }
    return s;
}
// A camera without a view: its target at its position, no up, up along the view, or a field of view of 0, 179 or 1e-4 degrees.
static int degenerate(const double *p, const double *t, const double *u, const double *f) {
    double v[3] = { t[0] - p[0], t[1] - p[1], t[2] - p[2] };
    double c[3] = { v[1] * u[2] - v[2] * u[1], v[2] * u[0] - v[0] * u[2], v[0] * u[1] - v[1] * u[0] };
    return (!v[0] && !v[1] && !v[2]) || (!u[0] && !u[1] && !u[2]) || (!c[0] && !c[1] && !c[2]) || f[0] == 0 || f[0] == 179 || f[0] == 1e-4;
}
static Camera make(const double *p, const double *t, const double *u, const double *f) {
    return (Camera){ V(p), V(t), V(u), (float)f[0], (int)f[1] };
}
int main(void) {
    SetTraceLogLevel(LOG_NONE);
    int n = 0;
    char label[128];
    for (int pi = 0; pi < 4; pi++) {
        double *p = positions[pi];
        double targets[5][3] = { {0, 0, 0}, {0, 2, 0}, {p[0], p[1], p[2]}, {p[0], p[1] - 5, p[2]}, {1.0 / 3, 2.0 / 7, -5} };
        for (int ti = 0; ti < 5; ti++) for (int ui = 0; ui < 6; ui++) for (int fi = 0; fi < 7; fi++) {
            double *t = targets[ti], *u = ups[ui], *f = fovys[fi];
            int id = n++;
            printf("c%d scale %.17g %s\n", id, scale(p, t), degenerate(p, t, u, f) ? "degenerate" : "regular");
            if (f[0] != 60) continue;
            Camera c;
#define OP(name, body) do { c = make(p, t, u, f); body; sprintf(label, "c%d.%s", id, name); cam(label, &c); } while (0)
            const char *tf[2] = { "false", "true" };
            for (int pl = 0; pl < 2; pl++) {
                char nm[64];
                sprintf(nm, "forward.%s", tf[pl]); OP(nm, CameraMoveForward(&c, 1.5f, pl));
                sprintf(nm, "right.%s", tf[pl]); OP(nm, CameraMoveRight(&c, -.7f, pl));
            }
            OP("pro", UpdateCameraPro(&c, (Vector3){ 1.5f, -.75f, .2f }, (Vector3){ -33, 12, 4 }, .5f));
            OP("pro50", for (int i = 0; i < 50; i++) UpdateCameraPro(&c, (Vector3){ .1f, .05f, .01f }, (Vector3){ 1.3f, -.7f, .2f }, .01f));
            OP("prolock", UpdateCameraPro(&c, (Vector3){ 0, 0, 0 }, (Vector3){ 0, -200, 0 }, 0); UpdateCameraPro(&c, (Vector3){ 0, 0, 0 }, (Vector3){ 10, 400, 15 }, 0));
        }
    }
    return 0;
}
