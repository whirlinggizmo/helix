/* The native audio adapter's C on the default playback device: a tenth of a second of silence played, and ended by the device's thread
   mixing it through. Silence only; no audible-output claim. Exits 2 where there's no device. */
#include "audio_sdl3mixer.h"
#include <SDL3/SDL.h>
#include <stdio.h>

int main(void) {
    if (!helix_audio_open(1)) { printf("{\"passed\":false,\"reason\":\"no audio device\"}\n"); return 2; }
    static float silence[4410];
    const int clip = helix_audio_clip(silence, 4410, 1), voice = clip ? helix_audio_play_clip(clip, 0, 1) : 0;
    const Uint64 start = SDL_GetTicks();
    while (voice > 0 && helix_audio_is_playing(voice) && SDL_GetTicks() - start < 2000) SDL_Delay(10);
    const int ended = voice > 0 && !helix_audio_is_playing(voice);
    const Uint64 took = SDL_GetTicks() - start;
    helix_audio_close();
    printf("{\"passed\":%s,\"backend\":\"SDL3_mixer\",\"milliseconds\":%d,\"audio\":\"Silence only; no audible-output claim\"}\n",
        ended ? "true" : "false", (int)took);
    return ended ? 0 : 3;
}
