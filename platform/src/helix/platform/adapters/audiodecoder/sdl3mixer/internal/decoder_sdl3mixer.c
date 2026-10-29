#include "decoder_sdl3mixer.h"
#include <SDL3/SDL.h>
#include <SDL3_mixer/SDL_mixer.h>

typedef struct { int frames; float *samples; } result_t;

int helix_decoder_init(void) { return MIX_Init(); }

void *helix_decoder_decode(const void *data, int bytes) {
    const SDL_AudioSpec mono = {SDL_AUDIO_F32, 1, 44100};
    SDL_IOStream *io = data && bytes > 0 ? SDL_IOFromConstMem(data, (size_t)bytes) : NULL;
    if (!io) { SDL_SetError("No audio to decode"); return NULL; }
    MIX_AudioDecoder *decoder = MIX_CreateAudioDecoder_IO(io, true, 0);
    if (!decoder) return NULL;
    result_t *result = SDL_calloc(1, sizeof *result);
    int room = 0, failed = result == NULL;
    while (!failed) {
        if (room - result->frames < 4096) {
            room = room ? room * 2 : 65536;
            float *grown = SDL_realloc(result->samples, (size_t)room * sizeof(float));
            if (!grown) { failed = 1; break; }
            result->samples = grown;
        }
        const int got = MIX_DecodeAudio(decoder, result->samples + result->frames, (room - result->frames) * (int)sizeof(float), &mono);
        if (got < 0) failed = 1;
        else if (got == 0) break;
        else result->frames += got / (int)sizeof(float);
    }
    MIX_DestroyAudioDecoder(decoder);
    if (!failed && result->frames == 0) { SDL_SetError("Empty decoded audio"); failed = 1; }
    if (failed) { if (result) SDL_free(result->samples); SDL_free(result); return NULL; }
    return result;
}
int helix_decoder_frames(void *result) { return ((result_t *)result)->frames; }
void helix_decoder_take(void *result, void *into) {
    result_t *r = result;
    SDL_memcpy(into, r->samples, (size_t)r->frames * sizeof(float));
    SDL_free(r->samples); SDL_free(r);
}
const char *helix_decoder_error(void) { return SDL_GetError(); }
