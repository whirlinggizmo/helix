// raylib 5.5's textures_bunnymark, spawning from run options instead of the mouse (count=N or ramp=1). The same as helix-raylib's Main.hx, for tools/compare/compare.py.
#include "raylib.h"
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <stdint.h>
#include <time.h>
#if defined(PLATFORM_WEB)
#include <emscripten/emscripten.h>
#define TARGET "page"
#else
#define TARGET "native-gl"
#endif

typedef struct Bunny {
    Vector2 position;
    Vector2 speed;
    Color color;
} Bunny;

static uint32_t seed = 2463534242u;
static int rnd(int min, int max) {
    uint32_t x = seed;
    x ^= x << 13; x ^= x >> 17; x ^= x << 5;
    seed = x;
    return min + (int)((x >> 8) % (uint32_t)(max - min + 1));
}

static Bunny *bunnies = NULL;
static int bunniesCount = 0, capacity = 0;
static Texture2D texBunny;
static int count = 1000, ramp = 0;
static int frame = -1, held = 0, done = 0;
static double last = 0, windowStart = 0, firstFrameMs = 0;
static double deltas[720];
static int ndeltas = 0;

static void spawn(int n) {
    if (bunniesCount + n > capacity) {
        capacity = (bunniesCount + n) * 2;
        bunnies = realloc(bunnies, capacity * sizeof(Bunny));
    }
    for (int i = 0; i < n; i++) {
        Bunny *b = &bunnies[bunniesCount++];
        b->position.x = (float)rnd(0, 800 - 32);
        b->position.y = (float)rnd(40, 450 - 32);
        b->speed.x = (float)rnd(-250, 250)/60.0f;
        b->speed.y = (float)rnd(-250, 250)/60.0f;
        int r = rnd(50, 240), g = rnd(80, 240), bl = rnd(100, 240);
        b->color = (Color){ r, g, bl, 255 };
    }
}

static double wallMs(void) {
#if defined(PLATFORM_WEB)
    return emscripten_get_now();
#else
    struct timespec t; clock_gettime(CLOCK_REALTIME, &t);
    return t.tv_sec*1000.0 + t.tv_nsec/1e6;
#endif
}

static int cmp(const void *a, const void *b) {
    double x = *(const double *)a, y = *(const double *)b;
    return x < y ? -1 : x > y ? 1 : 0;
}

static void UpdateDrawFrame(void) {
    if (done) return;
    double now = GetTime()*1000.0;
    if (frame < 0) spawn(count);
    else if (ndeltas < 720) deltas[ndeltas++] = now - last;
    else ndeltas++;
    last = now;
    frame++;

    for (int i = 0; i < bunniesCount; i++) {
        bunnies[i].position.x += bunnies[i].speed.x;
        bunnies[i].position.y += bunnies[i].speed.y;
        if (((bunnies[i].position.x + texBunny.width/2) > GetScreenWidth()) ||
            ((bunnies[i].position.x + texBunny.width/2) < 0)) bunnies[i].speed.x *= -1;
        if (((bunnies[i].position.y + texBunny.height/2) > GetScreenHeight()) ||
            ((bunnies[i].position.y + texBunny.height/2 - 40) < 0)) bunnies[i].speed.y *= -1;
    }

    BeginDrawing();
        ClearBackground(RAYWHITE);
        for (int i = 0; i < bunniesCount; i++)
            DrawTexture(texBunny, (int)bunnies[i].position.x, (int)bunnies[i].position.y, bunnies[i].color);
    EndDrawing();
    if (frame == 0) firstFrameMs = wallMs();

    if (!ramp) {
        if (ndeltas == 720) {
            double sorted[600], sum = 0;
            memcpy(sorted, deltas + 120, sizeof sorted);
            for (int i = 0; i < 600; i++) sum += sorted[i];
            qsort(sorted, 600, sizeof(double), cmp);
            double mean = sum/600;
            printf("{\"contender\":\"raylib-c\",\"target\":\"%s\",\"mode\":\"count\",\"count\":%d,\"mean_ms\":%.6f,\"median_ms\":%.6f,\"p95_ms\":%.6f,\"fps\":%.3f,\"first_frame_ms\":%.3f}\n",
                   TARGET, count, mean, sorted[300], sorted[570], 1000.0/mean, firstFrameMs);
            fflush(stdout);
            done = 1;
        }
    } else if (ndeltas >= 120 && (ndeltas - 120) % 60 == 0) {
        if (ndeltas > 120) {
            double fps = 60*1000.0/(now - windowStart);
            if (fps >= 59 && bunniesCount < 2000000) { held = bunniesCount; spawn(1000); }
            else {
                printf("{\"contender\":\"raylib-c\",\"target\":\"%s\",\"mode\":\"ramp\",\"ramp_max\":%d,\"last_fps\":%.3f,\"first_frame_ms\":%.3f}\n",
                       TARGET, held, fps, firstFrameMs);
                fflush(stdout);
                done = 1;
            }
        }
        windowStart = now;
    }
#if defined(PLATFORM_WEB)
    if (done) emscripten_cancel_main_loop();
#endif
}

int main(int argc, char **argv) {
#if defined(PLATFORM_WEB)
    char *q = emscripten_run_script_string("location.search");
    const char *c = strstr(q, "count="); if (c) count = atoi(c + 6);
    if (strstr(q, "ramp=1")) ramp = 1;
#else
    for (int i = 1; i < argc; i++) {
        if (!strncmp(argv[i], "--count=", 8)) count = atoi(argv[i] + 8);
        if (!strcmp(argv[i], "--ramp=1")) ramp = 1;
    }
#endif
    if (ramp) count = 1000;
    InitWindow(800, 450, "raylib [textures] example - bunnymark");
    texBunny = LoadTexture("resources/wabbit_alpha.png");
    // No SetTargetFPS and no FLAG_VSYNC_HINT: unpaced natively.
#if defined(PLATFORM_WEB)
    emscripten_set_main_loop(UpdateDrawFrame, 0, 1);
#else
    while (!done && !WindowShouldClose()) UpdateDrawFrame();
    free(bunnies);
    UnloadTexture(texBunny);
    CloseWindow();
#endif
    return 0;
}
