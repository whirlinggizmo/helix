#ifndef HELIX_MIXER_H
#define HELIX_MIXER_H
/* What a native audio output gives the shared mixer (mixer.c): its callback mixes, and its shutdown releases the samples once the
   callback can no longer run. */
/** Mixes the playing voices into out: frames of channels interleaved floats at rate Hz, clamped to -1..1. On the output's thread. */
void helix_mixer_mix(float *out, int frames, int channels, int rate);
/** Frees every clip and voice; after the output has stopped calling helix_mixer_mix. */
void helix_mixer_release(void);
#endif
