#include "audio.h"
#include "mixer.h"
#define SOKOL_AUDIO_IMPL
#include "sokol_audio.h"
#include "sokol_log.h"

/* The sokol_audio output: 44.1 kHz mono asked for, 512 frames a callback, the shared mixer stepping to whatever rate sokol gets. */
static int initialized;

static void callback(float *out, int frames, int channels) { helix_mixer_mix(out, frames, channels, saudio_sample_rate()); }

void helix_audio_setup(void) {
    if (initialized) return;
    saudio_setup(&(saudio_desc){ .sample_rate = 44100, .num_channels = 1,
        .buffer_frames = 512, .stream_cb = callback, .logger.func = slog_func });
    initialized = 1;
}
int helix_audio_available(void) { return initialized && saudio_isvalid(); }
int helix_audio_sample_rate(void) { return initialized ? saudio_sample_rate() : 0; }
int helix_audio_channels(void) { return initialized ? saudio_channels() : 0; }
void helix_audio_shutdown(void) {
    /* Join Sokol's callback thread before freeing mixer-owned samples. */
    if (initialized) { saudio_shutdown(); initialized = 0; }
    helix_mixer_release();
}
#ifdef HELIX_SERVICES_TEST
/* Only the deterministic dummy-backend test target exports this callback hook. */
void helix_audio_test_render(float *out, int frames, int channels) { callback(out, frames, channels); }
void helix_audio_test_setup(int rate) {
    saudio_setup(&(saudio_desc){.sample_rate=rate, .num_channels=1, .buffer_frames=512,
        .stream_cb=callback, .logger.func=slog_func}); initialized=1;
}
#endif
