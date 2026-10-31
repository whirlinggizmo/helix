#ifndef HELIX_DECODER_SDL3MIXER_H
#define HELIX_DECODER_SDL3MIXER_H
/* Whole-file audio decoding over SDL3_mixer's decoder, on any thread. */
#ifdef __cplusplus
extern "C" {
#endif
/* Initializes SDL3_mixer for decoding; on the main thread, once. 1 when it is. */
int helix_decoder_init(void);
/* Decodes bytes of an encoded file into 44100 Hz floats, mono or stereo interleaved as the file has it (more channels mixed down to
   stereo): what it made, or NULL with the reason in helix_decoder_error. */
void *helix_decoder_decode(const void *data, int bytes);
/* The number of floats a result holds, whole frames. */
int helix_decoder_count(void *result);
/* The channels a result holds, 1 or 2. */
int helix_decoder_channels(void *result);
/* Copies a result's floats into into (4 bytes each) and frees it. */
void helix_decoder_take(void *result, void *into);
/* Why the last decode on this thread failed. */
const char *helix_decoder_error(void);
#ifdef __cplusplus
}
#endif
#endif
