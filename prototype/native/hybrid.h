#ifndef HYBRID_H
#define HYBRID_H
#include <stdint.h>
#ifdef __cplusplus
extern "C" {
#endif
int hy_codec_memory(const void *data,int bytes);
int hy_codec_file(const char *path);
double hy_codec_frames(int id);
int hy_codec_read(int id,void *destination,int frames);
int hy_codec_rewind(int id);
void hy_codec_close(int id);
const char *hy_codec_version(void);
void hy_run(void (*init)(void),void (*frame)(float),void (*cleanup)(void));
void hy_quit(void);int hy_width(void);int hy_height(void);int hy_key(int code);
void hy_setup(void);void hy_shutdown(void);const char *hy_renderer(void);
uint32_t hy_texture(int w,int h,const void *data,int bytes);
uint32_t hy_buffer(int capacity);uint32_t hy_pipeline(int alpha);
int hy_update(uint32_t buffer,const void *data,int bytes);
int hy_begin(int width,int height,int x,int y,int w,int h);
int hy_draw(uint32_t pipeline,uint32_t buffer,uint32_t texture,int vertices);
void hy_end(void);int hy_destroy(int kind,uint32_t handle);
void hy_capture(const char *path);
void hy_audio_setup(void);void hy_audio_shutdown(void);int hy_audio_clip(const void *data,int bytes);
int hy_audio_play(int clip,int loop,float volume);void hy_audio_stop(int voice);int hy_audio_destroy_clip(int clip);
int hy_audio_available(void);int hy_audio_played(void);int hy_audio_stopped(void);int hy_audio_loops(void);
int hy_audio_is_playing(int id);void hy_audio_pause(int id,int paused);void hy_audio_volume(int id,float volume);
int hy_audio_stream(float volume);int hy_audio_stream_queued(int id);int hy_audio_stream_push(int id,const void *data,int bytes,int eof);
int hy_audio_callbacks(void);int hy_audio_sample_rate(void);int hy_audio_channels(void);
void hy_input_setup(void);void hy_input_shutdown(void);void hy_input_poll(void);void hy_input_consume(void);
void hy_input_key(int code,int down);void hy_input_pointer(float x,float y,int down);void hy_input_focus(int focused);
int hy_key_pressed(int code);int hy_key_released(int code);int hy_focused(void);float hy_pixel_ratio(void);
float hy_pointer_x(void);float hy_pointer_y(void);int hy_pointer_down(void);int hy_pointer_pressed(void);int hy_pointer_released(void);
int hy_pad_available(void);int hy_pad_button(int button);float hy_pad_axis(int axis);
#ifdef __cplusplus
}
#endif
#endif
