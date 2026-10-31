#ifndef HELIX_AUDIO_SDL3MIXER_H
#define HELIX_AUDIO_SDL3MIXER_H
/* The native audio output over SDL3_mixer: clips, voices, streams decoded on the main thread as they're read, downloads arriving, and
   queues of samples fed as they play.
   Every call is the main thread's; SDL3_mixer mixes on the device's thread. Ids are positive; 0 is none. */
#ifdef __cplusplus
extern "C" {
#endif
/* Initializes SDL3_mixer without a mixer: clips are made and files checked, nothing plays. 1 when initialized. */
int helix_audio_init(void);
/* Initializes and opens the mixer: on the default playback device when device is 1, or with no device when 0, mixed only by
   helix_audio_generate (tests). 1 when open. */
int helix_audio_open(int device);
/* Whether the mixer is open. */
int helix_audio_is_open(void);
/* Stops every voice, frees everything, closes the mixer and its device, and quits SDL3_mixer; no mixing happens after it returns. */
void helix_audio_close(void);
/* Mixes frames of stereo 44100 Hz floats into out, for a mixer opened with no device; the frames mixed, or -1. */
int helix_audio_generate(float *out, int frames);

/* A clip of frames 44100 Hz frames of channels (1 or 2) interleaved floats, copied; 0 when it can't be made. */
int helix_audio_clip(const void *samples, int frames, int channels);
/* Stops a clip's voices and frees it; 0 for an unknown clip. */
int helix_audio_dispose_clip(int clip);
/* Starts a clip; its voice, 0 when it can't start, -1 for an unknown clip. */
int helix_audio_play_clip(int clip, int loop, float volume);

/* A download's bytes in C: room for total bytes, none arrived. */
int helix_audio_download(int total);
/* Appends count bytes after what has arrived; 0 past its length or for an unknown download. */
int helix_audio_download_add(int download, const unsigned char *bytes, int count);
/* Says nothing more will arrive: the whole file, or what came before it failed. */
void helix_audio_download_end(int download);
/* Lets the download go; it's freed once no voice reads it. */
void helix_audio_download_release(int download);

/* Whether the codec opens the file at path. */
int helix_audio_check_file(const char *path);
/* Whether the codec opens what has arrived of a download. */
int helix_audio_check_download(int download);
/* The file's length at path in seconds, or 0 when its codec doesn't know it. */
double helix_audio_file_duration(const char *path);
/* A download's length in seconds once it has all arrived, or 0 before then or when its codec doesn't know it. */
double helix_audio_download_duration(int download);
/* Starts the file at path streaming; its voice, or 0. */
int helix_audio_play_file(const char *path, int loop, float volume);
/* Starts a download streaming; its voice, or 0. */
int helix_audio_play_download(int download, int loop, float volume);
/* A queue of channels (1 or 2) at rate (8000 to 96000) frames a second; 0 when it can't be made. */
int helix_audio_queue(int channels, int rate);
/* Appends the whole frames in bytes of the queue's interleaved floats, copied; 0 for an unknown queue. */
int helix_audio_queue_samples(int queue, const void *samples, int bytes);
/* The frames a queue holds that its voice hasn't taken; -1 for an unknown queue. */
int helix_audio_queued_frames(int queue);
/* Stops a queue's voice and frees it; 0 for an unknown queue. */
int helix_audio_dispose_queue(int queue);
/* Starts a queue playing, stopping its earlier voice; its voice, 0 when it can't start, -1 for an unknown queue. It plays on, silent,
   when the queue runs dry. */
int helix_audio_play_queue(int queue, float volume);
/* Feeds the streamed voices for up to 2 ms, starts those decoded far enough, ends those decoded to their end, and frees ended voices. */
void helix_audio_feed(void);

/* Stops a voice; a queue's drops what it hadn't played. */
void helix_audio_stop(int voice);
void helix_audio_pause(int voice, int paused);
int helix_audio_set_volume(int voice, float volume);
int helix_audio_set_pitch(int voice, float pitch);
int helix_audio_set_pan(int voice, float pan);
int helix_audio_is_playing(int voice);
/* How far a voice has played in seconds, from its start and wrapping at each loop; 0 for an unknown voice. */
double helix_audio_position(int voice);
/* Moves a clip's or a stream's voice to seconds, ending one that doesn't loop at or past its end; 0 when it can't. */
int helix_audio_set_position(int voice, double seconds);
/* Whether a voice is sounding: started, a stream once decoded far enough (for checks). */
int helix_audio_is_sounding(int voice);
#ifdef __cplusplus
}
#endif
#endif
