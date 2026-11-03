#include "decoder_sdl3mixer.h"
#include <SDL3/SDL.h>
#include <SDL3_mixer/SDL_mixer.h>

/* What a decode made: count floats of channels interleaved. */
typedef struct { int count, channels; float *samples; } result_t;

int helix_decoder_init(void) { return MIX_Init(); }

void *helix_decoder_decode(const void *data, int bytes, int rate) {
    SDL_IOStream *io = data && bytes > 0 ? SDL_IOFromConstMem(data, (size_t)bytes) : NULL;
    if (!io) { SDL_SetError("No audio to decode"); return NULL; }
    MIX_AudioDecoder *decoder = MIX_CreateAudioDecoder_IO(io, true, 0);
    if (!decoder) return NULL;
    /* The file's channels, more mixed down to stereo by SDL's channel conversion, at rate, resampled to it. */
    SDL_AudioSpec spec = {SDL_AUDIO_F32, 1, 44100};
    if (!MIX_GetAudioDecoderFormat(decoder, &spec)) { MIX_DestroyAudioDecoder(decoder); return NULL; }
    const SDL_AudioSpec out = {SDL_AUDIO_F32, spec.channels > 1 ? 2 : 1, rate};
    result_t *result = SDL_calloc(1, sizeof *result);
    int room = 0, failed = result == NULL;
    if (result) result->channels = out.channels;
    while (!failed) {
        if (room - result->count < 4096) {
            room = room ? room * 2 : 65536;
            float *grown = SDL_realloc(result->samples, (size_t)room * sizeof(float));
            if (!grown) { failed = 1; break; }
            result->samples = grown;
        }
        const int room_frames = (room - result->count) / out.channels;
        const int got = MIX_DecodeAudio(decoder, result->samples + result->count, room_frames * out.channels * (int)sizeof(float), &out);
        if (got < 0) failed = 1;
        else if (got == 0) break;
        else result->count += got / (int)sizeof(float);
    }
    MIX_DestroyAudioDecoder(decoder);
    if (!failed && result->count < out.channels) { SDL_SetError("Empty decoded audio"); failed = 1; }
    if (failed) { if (result) SDL_free(result->samples); SDL_free(result); return NULL; }
    return result;
}
int helix_decoder_count(void *result) { result_t *r = result; return r->count / r->channels * r->channels; }
int helix_decoder_channels(void *result) { return ((result_t *)result)->channels; }
void helix_decoder_take(void *result, void *into) {
    result_t *r = result;
    SDL_memcpy(into, r->samples, (size_t)helix_decoder_count(r) * sizeof(float));
    SDL_free(r->samples); SDL_free(r);
}
const char *helix_decoder_error(void) { return SDL_GetError(); }
