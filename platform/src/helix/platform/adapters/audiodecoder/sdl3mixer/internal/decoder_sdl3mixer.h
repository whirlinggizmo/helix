#ifndef HELIX_DECODER_SDL3MIXER_H
#define HELIX_DECODER_SDL3MIXER_H
/* Whole-file audio decoding over SDL3_mixer's decoder, on any thread. */
#ifdef __cplusplus
extern "C" {
#endif
/* Initializes SDL3_mixer for decoding; on the main thread, once. 1 when it is. */
int helix_decoder_init(void);
/* Decodes bytes of an encoded file into mono 44100 Hz floats: what it made, or NULL with the reason in helix_decoder_error. */
void *helix_decoder_decode(const void *data, int bytes);
/* The number of frames a result holds. */
int helix_decoder_frames(void *result);
/* Copies a result's frames into into (4 bytes each) and frees it. */
void helix_decoder_take(void *result, void *into);
/* Why the last decode on this thread failed. */
const char *helix_decoder_error(void);
#ifdef __cplusplus
}
#endif
#endif
