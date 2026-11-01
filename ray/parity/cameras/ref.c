// raylib 5.5's own 3D-camera functions over the cases CameraBits.hx prints, as double bits, one line per case; each camera's first line
// its scale line, as CameraBits.hx prints it.
#include "raylib.h"
#include <stdio.h>
#include <string.h>
#include <stdint.h>
#include <math.h>
void CameraYaw(Camera *camera, float angle, bool rotateAroundTarget);
void CameraPitch(Camera *camera, float angle, bool lockView, bool rotateAroundTarget, bool rotateUp);
void CameraRoll(Camera *camera, float angle);
void CameraMoveForward(Camera *camera, float distance, bool moveInWorldPlane);
void CameraMoveUp(Camera *camera, float distance);
void CameraMoveRight(Camera *camera, float distance, bool moveInWorldPlane);
void CameraMoveToTarget(Camera *camera, float delta);

static void bits(double x) { uint64_t u; memcpy(&u, &x, 8); printf(" %016llX", (unsigned long long)u); }
static void put(const char *label, const float *v, int n) { printf("%s", label); for (int i = 0; i < n; i++) bits(v[i]); printf("\n"); }
static void cam(const char *label, Camera *c) {
    float v[9] = { c->position.x, c->position.y, c->position.z, c->target.x, c->target.y, c->target.z, c->up.x, c->up.y, c->up.z };
    put(label, v, 9);
}
static double positions[4][3] = { {0, 2, 4}, {10, -3, 7.5}, {0, 0, 0}, {-1e3, 50, 2e2} };
static double ups[5][3] = { {0, 1, 0}, {0, 0, 1}, {.3, .9, -.1}, {0, 0, 0}, {0, -2, 0} };
static double fovys[7][2] = { {45, 0}, {60, 0}, {0, 0}, {179, 0}, {1e-4, 0}, {10, 1}, {0, 1} };
static int sizes[2][2] = { {800, 450}, {640, 960} };
static double screens[5][2] = { {400, 225}, {0, 0}, {800, 450}, {13.5, -20}, {1e4, 3} };
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
        for (int ti = 0; ti < 5; ti++) for (int ui = 0; ui < 5; ui++) for (int fi = 0; fi < 7; fi++) {
            double *t = targets[ti], *u = ups[ui], *f = fovys[fi];
            int id = n++;
            Camera camera = make(p, t, u, f);
            printf("c%d scale %.17g %s\n", id, scale(p, t), degenerate(p, t, u, f) ? "degenerate" : "regular");
            Matrix m = GetCameraMatrix(camera);
            float mv[16] = { m.m0, m.m1, m.m2, m.m3, m.m4, m.m5, m.m6, m.m7, m.m8, m.m9, m.m10, m.m11, m.m12, m.m13, m.m14, m.m15 };
            sprintf(label, "c%d.matrix", id); put(label, mv, 16);
            for (int si = 0; si < 2; si++) {
                int w = sizes[si][0], h = sizes[si][1];
                const double *points[5] = { (double[]){0, 0, 0}, (double[]){1, 2, -3}, (double[]){100, -50, 25}, p, t };
                float out[60]; int k = 0;
                for (int q = 0; q < 5; q++) { Vector2 r = GetWorldToScreenEx(V(points[q]), camera, w, h); out[k++] = r.x; out[k++] = r.y; }
                sprintf(label, "c%d.w2s.%d", id, w); put(label, out, k);
                k = 0;
                for (int q = 0; q < 5; q++) {
                    Ray ray = GetScreenToWorldRayEx((Vector2){ (float)screens[q][0], (float)screens[q][1] }, camera, w, h);
                    out[k++] = ray.position.x; out[k++] = ray.position.y; out[k++] = ray.position.z;
                    out[k++] = ray.direction.x; out[k++] = ray.direction.y; out[k++] = ray.direction.z;
                }
                sprintf(label, "c%d.ray.%d", id, w); put(label, out, k);
            }
            if (f[0] != 60) continue;
            Camera c;
#define OP(name, body) do { c = make(p, t, u, f); body; sprintf(label, "c%d.%s", id, name); cam(label, &c); } while (0)
            OP("yaw.false", CameraYaw(&c, .3f, false));
            OP("yaw.true", CameraYaw(&c, .3f, true));
            const char *angles[3] = { "0.4", "-2", "3" }; float av[3] = { .4f, -2, 3 };
            const char *tf[2] = { "false", "true" };
            for (int a = 0; a < 3; a++) for (int l = 0; l < 2; l++) for (int r = 0; r < 2; r++) for (int up = 0; up < 2; up++) {
                char nm[64]; sprintf(nm, "pitch.%s.%s.%s.%s", angles[a], tf[l], tf[r], tf[up]);
                OP(nm, CameraPitch(&c, av[a], l, r, up));
            }
            OP("roll", CameraRoll(&c, .25f));
            for (int pl = 0; pl < 2; pl++) {
                char nm[64];
                sprintf(nm, "forward.%s", tf[pl]); OP(nm, CameraMoveForward(&c, 1.5f, pl));
                sprintf(nm, "right.%s", tf[pl]); OP(nm, CameraMoveRight(&c, -.7f, pl));
            }
            OP("up", CameraMoveUp(&c, .6f));
            OP("zoom.0.5", CameraMoveToTarget(&c, .5f));
            OP("zoom.-100", CameraMoveToTarget(&c, -100));
            OP("zoom.-3", CameraMoveToTarget(&c, -3));
            OP("pro", UpdateCameraPro(&c, (Vector3){ 1.5f, -.75f, .2f }, (Vector3){ -33, 12, 4 }, .5f));
            OP("pro50", for (int i = 0; i < 50; i++) UpdateCameraPro(&c, (Vector3){ .1f, .05f, .01f }, (Vector3){ 1.3f, -.7f, .2f }, .01f));
            OP("prolock", UpdateCameraPro(&c, (Vector3){ 0, 0, 0 }, (Vector3){ 0, -200, 0 }, 0); UpdateCameraPro(&c, (Vector3){ 0, 0, 0 }, (Vector3){ 10, 400, 15 }, 0));
        }
    }
    return 0;
}
