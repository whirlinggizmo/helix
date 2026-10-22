#ifndef HELIX_AUDIO_H
#define HELIX_AUDIO_H
#include <stdint.h>
#ifdef __cplusplus
extern "C" {
#endif
void helix_audio_setup(void);void helix_audio_shutdown(void);int helix_audio_clip(const void *data,int bytes);
int helix_audio_play(int clip,int loop,float volume);void helix_audio_stop(int voice);int helix_audio_destroy_clip(int clip);
int helix_audio_available(void);int helix_audio_played(void);int helix_audio_stopped(void);int helix_audio_loops(void);
int helix_audio_is_playing(int id);void helix_audio_pause(int id,int paused);void helix_audio_volume(int id,float volume);
void helix_audio_pitch(int id,float pitch);void helix_audio_pan(int id,float pan);
int helix_audio_stream(float volume);int helix_audio_stream_queued(int id);int helix_audio_stream_push(int id,const void *data,int bytes,int eof);
int helix_audio_callbacks(void);int helix_audio_sample_rate(void);int helix_audio_channels(void);
#ifdef __cplusplus
}
#endif
#endif
