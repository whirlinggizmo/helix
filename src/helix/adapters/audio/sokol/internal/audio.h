#ifndef HELIX_AUDIO_H
#define HELIX_AUDIO_H
#include <stdint.h>
#ifdef __cplusplus
extern "C" {
#endif
void hy_audio_setup(void);void hy_audio_shutdown(void);int hy_audio_clip(const void *data,int bytes);
int hy_audio_play(int clip,int loop,float volume);void hy_audio_stop(int voice);int hy_audio_destroy_clip(int clip);
int hy_audio_available(void);int hy_audio_played(void);int hy_audio_stopped(void);int hy_audio_loops(void);
int hy_audio_is_playing(int id);void hy_audio_pause(int id,int paused);void hy_audio_volume(int id,float volume);
int hy_audio_stream(float volume);int hy_audio_stream_queued(int id);int hy_audio_stream_push(int id,const void *data,int bytes,int eof);
int hy_audio_callbacks(void);int hy_audio_sample_rate(void);int hy_audio_channels(void);
#ifdef __cplusplus
}
#endif
#endif
