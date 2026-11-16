// The frame stats for raylib C, linked by score_frames.py beside the entrant's code and stock raylib 5.5, which it leaves as shipped:
// with -Wl,--wrap=EndDrawing -Wl,--wrap=WindowShouldClose, the program's calls reach these, which call raylib's own (__real_).
// RAYLIB_FRAME_STATS=W,N records frames W + 1 to N, each from one EndDrawing to the next as helix-raylib's frame stats time them,
// prints frame_stats and a JSON object as helix-raylib's hook does, without the draws, and then WindowShouldClose returns true.
#include <stdio.h>
#include <stdlib.h>
#include <stdbool.h>

double GetTime(void);
void __real_EndDrawing(void);
bool __real_WindowShouldClose(void);

static int from = -1, to = 0, frame = 0, count = 0;
static double last = -1, *times = NULL;
static bool done = false;

static int slowestFirst(const void *a, const void *b)
{
    double x = *(const double *)a, y = *(const double *)b;
    return (x < y) - (x > y);
}

void __wrap_EndDrawing(void)
{
    if (from < 0)
    {
        const char *given = getenv("RAYLIB_FRAME_STATS");
        from = 0;
        if (given != NULL) sscanf(given, "%d,%d", &from, &to);
        if (to > from) times = calloc(to - from, sizeof(double));
        else to = 0;
    }
    if (to > 0 && !done)
    {
        double now = GetTime();
        frame++;
        if (frame > from && last >= 0) times[count++] = now - last;
        last = now;
        if (frame == to)
        {
            double sum = 0;
            for (int i = 0; i < count; i++) sum += times[i];
            qsort(times, count, sizeof(double), slowestFirst);
            int k = (count + 19)/20;
            printf("frame_stats {\"frames\":%d,\"fps\":%.17g,\"meanFrameTime\":%.17g,\"p95FrameTime\":%.17g,\"slowestFrameTime\":%.17g}\n",
                   count, (sum > 0)? count/sum : 0, (count > 0)? sum/count : 0, (k > 0)? times[k - 1] : 0, (count > 0)? times[0] : 0);
            fflush(stdout);
            done = true;
        }
    }
    __real_EndDrawing();
}

bool __wrap_WindowShouldClose(void)
{
    return done || __real_WindowShouldClose();
}
