#include "audio.h"
#include "mixer.h"
#include <SDL3/SDL.h>

/* The SDL3 output: an audio stream of 44.1 kHz stereo floats into the default playback device, which SDL converts to the device's format and
   rate; its callback mixes what the device asks for. 512 frames a buffer are asked for, as sokol's output asks (SDL may give another). */
static SDL_AudioStream *stream;

static void SDLCALL callback(void *userdata, SDL_AudioStream *s, int additional, int total) {
    (void)userdata; (void)total;
    float buffer[1024 * 2];
    const int frame = 2 * (int)sizeof(float);
    while (additional > 0) {
        /* Whole frames, at least one: SDL asks in bytes. */
        int frames = (additional + frame - 1) / frame;
        if (frames > 1024) frames = 1024;
        helix_mixer_mix(buffer, frames, 2, 44100);
        SDL_PutAudioStreamData(s, buffer, frames * frame);
        additional -= frames * frame;
    }
}

void helix_audio_setup(void) {
    if (stream) return;
    SDL_SetHint(SDL_HINT_AUDIO_DEVICE_SAMPLE_FRAMES, "512");
    if (!SDL_InitSubSystem(SDL_INIT_AUDIO)) return;
    const SDL_AudioSpec spec = {SDL_AUDIO_F32, 2, 44100};
    stream = SDL_OpenAudioDeviceStream(SDL_AUDIO_DEVICE_DEFAULT_PLAYBACK, &spec, callback, NULL);
    if (!stream) { SDL_QuitSubSystem(SDL_INIT_AUDIO); return; }
    /* A device stream starts paused. */
    SDL_ResumeAudioStreamDevice(stream);
}
int helix_audio_available(void) { return stream != NULL; }
/* The mixer's rate and channels: the stream's side, which SDL converts to the device's. */
int helix_audio_sample_rate(void) { return stream ? 44100 : 0; }
int helix_audio_channels(void) { return stream ? 2 : 0; }
void helix_audio_shutdown(void) {
    /* Destroying a device stream closes its device, which joins the device's thread (SDL_audio.c's ClosePhysicalAudioDevice): no callback
       runs after it returns. */
    if (stream) { SDL_DestroyAudioStream(stream); stream = NULL; SDL_QuitSubSystem(SDL_INIT_AUDIO); }
    helix_mixer_release();
}
