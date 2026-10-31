#include "audio_sdl3mixer.h"
#include <SDL3/SDL.h>
#include <SDL3_mixer/SDL_mixer.h>
/* SDL3_mixer's own structures, for the one thing its API lacks: seeking an audio decoder (stream_seek). The vendored copy is pinned. */
#include "SDL_mixer_internal.h"
#include <math.h>

/* Voices are SDL3_mixer tracks: a clip's plays its audio, a stream's an audio stream the main thread fills from SDL3_mixer's decoder, a
   queue's the queue's audio stream, which the main thread fills with samples; a stream's and a queue's track are told to wait rather than
   stop when they run dry. Volume and pan are the track's cooked callback's: equal power for a mono voice, a balance for a stereo one,
   ramped linearly across each block from where the last ended, as SDL applies a gain change at once. */

#define RATE 44100
/* How far a download must have arrived past the decoder's reads before it decodes: a codec takes a short read for the end of the file. */
#define MARGIN (16 * 1024)
/* A stream keeps a second decoded ahead; a download's voice sounds once that much is decoded, a file's once a tenth of it is. */
#define AHEAD RATE
#define START_DOWNLOAD RATE
#define START_FILE (RATE / 10)
/* How long feed decodes for, a frame. */
#define BUDGET_NS 2000000

typedef struct download { int id, refs, released, ended; unsigned char *bytes; Sint64 total, avail; struct download *next; } download_t;
/* A decoder's view of a download: its read position. Its size is what has arrived, so a codec that asks for it at open (Ogg's, for the
   length) sees the end of what is there; seeking is within the whole file, its end the file's, as SDL3_mixer takes the length a decoder
   sees from a seek to the end (WAV's checks it against the samples' chunk) and a codec may seek past what has arrived, reading nothing. */
typedef struct { download_t *download; Sint64 position; } reader_t;
typedef struct clip { int id, channels; Sint64 frames; MIX_Audio *audio; struct clip *next; } clip_t;
/* A queue's samples in an audio stream, which SDL locks itself as the device's thread reads it: put is how many frames were ever added,
   voice the one playing it (0 for none). */
typedef struct queue { int id, channels, rate, voice; Sint64 put; SDL_AudioStream *stream; struct queue *next; } queue_t;
typedef struct voice {
    int id, clip, loop, paused, started, finished, decoded, channels;
    MIX_Track *track;
    char *path; download_t *download; reader_t *reader; MIX_AudioDecoder *decoder; SDL_AudioStream *input;
    /* A stream's: what it decodes to (its file's channels, up to 2, at RATE); the frame it was started or moved to; the frames decoded
       since; the frame the decoder's pass began at and the frames decoded in it; the file's frames at RATE, -1 until known. */
    SDL_AudioSpec spec; Sint64 origin, decoded_frames, pass_start, pass_frames, length;
    /* A queue's: the queue, and how many of its frames had been played when this voice started. */
    queue_t *queue; Sint64 base;
    /* The targets, set on the main thread under the mixer's lock; where the last block ended, the device thread's. */
    float volume, pan, heard_volume, heard_pan; int mixed;
    SDL_AtomicInt ended;
    struct voice *next;
} voice_t;

static MIX_Mixer *mixer;
static int initialized, device_open;
static clip_t *clips;
static queue_t *queues;
static voice_t *voices;
static download_t *downloads;
static int next_id = 1;
static const SDL_AudioSpec STEREO = {SDL_AUDIO_F32, 2, RATE};

static void unref(download_t *d) {
    if (--d->refs > 0 || !d->released) return;
    for (download_t **p = &downloads; *p; p = &(*p)->next) if (*p == d) { *p = d->next; break; }
    SDL_free(d->bytes); SDL_free(d);
}
static download_t *find_download(int id) { for (download_t *d = downloads; d; d = d->next) if (d->id == id) return d; return NULL; }
static clip_t *find_clip(int id) { for (clip_t *c = clips; c; c = c->next) if (c->id == id) return c; return NULL; }
static queue_t *find_queue(int id) { for (queue_t *q = queues; q; q = q->next) if (q->id == id) return q; return NULL; }
static voice_t *find_voice(int id) {
    if (id <= 0) return NULL;
    for (voice_t *v = voices; v; v = v->next) if (v->id == id && !SDL_GetAtomicInt(&v->ended)) return v;
    return NULL;
}

static Sint64 SDLCALL reader_size(void *u) { return ((reader_t *)u)->download->avail; }
static Sint64 SDLCALL reader_seek(void *u, Sint64 offset, SDL_IOWhence whence) {
    reader_t *r = u;
    const Sint64 to = whence == SDL_IO_SEEK_SET ? offset : whence == SDL_IO_SEEK_CUR ? r->position + offset : r->download->total + offset;
    if (to < 0 || to > r->download->total) { SDL_SetError("Seek past the file's end"); return -1; }
    return r->position = to;
}
static size_t SDLCALL reader_read(void *u, void *ptr, size_t size, SDL_IOStatus *status) {
    reader_t *r = u;
    Sint64 count = r->download->avail - r->position;
    if (count <= 0) { *status = SDL_IO_STATUS_EOF; return 0; }
    if ((Sint64)size < count) count = (Sint64)size;
    SDL_memcpy(ptr, r->download->bytes + r->position, (size_t)count);
    r->position += count;
    return (size_t)count;
}
static bool SDLCALL reader_close(void *u) { reader_t *r = u; unref(r->download); SDL_free(r); return true; }

/* A decoder over a download, its reader in *reader (freed with the decoder); NULL when the codec can't open what has arrived. */
static MIX_AudioDecoder *download_decoder(download_t *d, reader_t **reader) {
    reader_t *r = SDL_calloc(1, sizeof *r);
    if (!r) return NULL;
    r->download = d; d->refs++;
    SDL_IOStreamInterface io; SDL_INIT_INTERFACE(&io);
    io.size = reader_size; io.seek = reader_seek; io.read = reader_read; io.close = reader_close;
    SDL_IOStream *stream = SDL_OpenIO(&io, r);
    if (!stream) { reader_close(r); return NULL; }
    if (reader) *reader = r;
    return MIX_CreateAudioDecoder_IO(stream, true, 0);
}
/* A decoder's file length in seconds, or 0 when it doesn't know it. */
static double decoder_duration(MIX_AudioDecoder *decoder) {
    SDL_AudioSpec spec;
    const Sint64 frames = SDL_GetNumberProperty(MIX_GetAudioDecoderProperties(decoder), MIX_PROP_METADATA_DURATION_FRAMES_NUMBER, -1);
    return frames > 0 && MIX_GetAudioDecoderFormat(decoder, &spec) && spec.freq > 0 ? (double)frames / spec.freq : 0;
}
/* A new decoder for a stream's voice, from its start: its format and, the first time, its length taken from the file. */
static MIX_AudioDecoder *voice_decoder(voice_t *v) {
    v->reader = NULL; v->decoded = 0;
    MIX_AudioDecoder *decoder = v->path ? MIX_CreateAudioDecoder(v->path, 0) : download_decoder(v->download, &v->reader);
    SDL_AudioSpec spec;
    if (!decoder || !MIX_GetAudioDecoderFormat(decoder, &spec)) return decoder;
    v->spec.format = SDL_AUDIO_F32; v->spec.channels = spec.channels > 1 ? 2 : 1; v->spec.freq = RATE;
    if (v->length < 0) { const double seconds = decoder_duration(decoder); if (seconds > 0) v->length = (Sint64)(seconds * RATE + .5); }
    return decoder;
}

static void SDLCALL stopped(void *userdata, MIX_Track *track) { (void)track; SDL_SetAtomicInt(&((voice_t *)userdata)->ended, 1); }
/* Pans a stereo frame as Web Audio's StereoPannerNode pans a stereo input: at 0 unchanged; toward a side, the far channel is faded by
   equal power and its part faded out is mixed into the near one. */
static void balance(float *frame, float pan) {
    const float half_pi = 1.57079632679489661923f, l = frame[0], r = frame[1];
    if (pan <= 0) { const float x = (pan + 1) * half_pi; frame[0] = l + r * cosf(x); frame[1] = r * sinf(x); }
    else { const float x = pan * half_pi; frame[0] = l * cosf(x); frame[1] = r + l * sinf(x); }
}
static void SDLCALL cooked(void *userdata, MIX_Track *track, const SDL_AudioSpec *spec, float *pcm, int samples) {
    (void)track;
    voice_t *v = userdata;
    const int channels = spec->channels, frames = channels > 0 ? samples / channels : 0;
    if (frames <= 0) return;
    const float volume0 = v->mixed ? v->heard_volume : v->volume, volume1 = v->volume;
    const float pan0 = v->mixed ? v->heard_pan : v->pan, pan1 = v->pan, quarter = 0.78539816339744830962f;
    v->mixed = 1; v->heard_volume = volume1; v->heard_pan = pan1;
    float left = cosf((pan1 + 1) * quarter), right = sinf((pan1 + 1) * quarter);
    for (int i = 0; i < frames; i++) {
        const float t = (float)(i + 1) / (float)frames, gain = volume0 + (volume1 - volume0) * t;
        float *frame = pcm + i * channels;
        if (channels == 1) { frame[0] *= gain; continue; }
        if (v->channels == 2) {
            balance(frame, pan0 == pan1 ? pan1 : pan0 + (pan1 - pan0) * t);
            for (int c = 0; c < channels; c++) frame[c] *= gain;
            continue;
        }
        if (pan0 != pan1) { const float angle = (pan0 + (pan1 - pan0) * t + 1) * quarter; left = cosf(angle); right = sinf(angle); }
        frame[0] *= gain * left; frame[1] *= gain * right;
        for (int c = 2; c < channels; c++) frame[c] *= gain;
    }
}

static voice_t *new_voice(float volume) {
    if (!mixer || !isfinite(volume) || volume < 0 || volume > 1) return NULL;
    MIX_Track *track = MIX_CreateTrack(mixer);
    if (!track) return NULL;
    voice_t *v = SDL_calloc(1, sizeof *v);
    if (!v) { MIX_DestroyTrack(track); return NULL; }
    v->id = next_id++; v->track = track; v->volume = volume; v->channels = 1; v->length = -1;
    MIX_SetTrackStoppedCallback(track, stopped, v);
    MIX_SetTrackCookedCallback(track, cooked, v);
    v->next = voices; voices = v;
    return v;
}
static void free_voice(voice_t *v) {
    if (v->queue && v->queue->voice == v->id) v->queue->voice = 0;
    MIX_DestroyTrack(v->track);
    if (v->decoder) MIX_DestroyAudioDecoder(v->decoder);
    if (v->input) SDL_DestroyAudioStream(v->input);
    if (v->download) unref(v->download);
    SDL_free(v->path); SDL_free(v);
}
/* Ends a voice; it's freed at the next feed. A queue's voice lets go of the queue's stream at once, so the queue may be played again or
   disposed. */
static void end_voice(voice_t *v) {
    if (v->started) MIX_StopTrack(v->track, 0);
    if (v->queue) { MIX_SetTrackAudioStream(v->track, NULL); if (v->queue->voice == v->id) v->queue->voice = 0; v->queue = NULL; }
    SDL_SetAtomicInt(&v->ended, 1);
}

/* SDL3_mixer stays initialized without a mixer, so clips are still made and files checked. */
int helix_audio_init(void) { return initialized || (initialized = MIX_Init()); }
int helix_audio_open(int device) {
    if (mixer) return 1;
    if (!helix_audio_init()) return 0;
    if (device) {
        SDL_SetHint(SDL_HINT_AUDIO_DEVICE_SAMPLE_FRAMES, "512");
        if (!SDL_InitSubSystem(SDL_INIT_AUDIO)) return 0;
        if (!(mixer = MIX_CreateMixerDevice(SDL_AUDIO_DEVICE_DEFAULT_PLAYBACK, &STEREO))) { SDL_QuitSubSystem(SDL_INIT_AUDIO); return 0; }
        device_open = 1;
    } else if (!(mixer = MIX_CreateMixer(&STEREO))) return 0;
    return 1;
}
int helix_audio_is_open(void) { return mixer != NULL; }
void helix_audio_close(void) {
    if (!initialized) return;
    while (voices) { voice_t *v = voices; voices = v->next; free_voice(v); }
    while (clips) { clip_t *c = clips; clips = c->next; MIX_DestroyAudio(c->audio); SDL_free(c); }
    while (queues) { queue_t *q = queues; queues = q->next; SDL_DestroyAudioStream(q->stream); SDL_free(q); }
    while (downloads) { download_t *d = downloads; downloads = d->next; SDL_free(d->bytes); SDL_free(d); }
    /* Disposing a device's mixer closes the device, which joins its thread: no callback runs after it returns. */
    if (mixer) { MIX_DestroyMixer(mixer); mixer = NULL; }
    if (device_open) { SDL_QuitSubSystem(SDL_INIT_AUDIO); device_open = 0; }
    MIX_Quit(); initialized = 0;
}
int helix_audio_generate(float *out, int frames) {
    if (!mixer || device_open || frames < 0) return -1;
    /* MIX_Generate answers how much it mixed from playing tracks; the buffer is filled either way. */
    return MIX_Generate(mixer, out, frames * 2 * (int)sizeof(float)) < 0 ? -1 : frames;
}

int helix_audio_clip(const void *samples, int frames, int channels) {
    if (!initialized || !samples || frames <= 0 || channels < 1 || channels > 2) return 0;
    clip_t *c = SDL_calloc(1, sizeof *c);
    if (!c) return 0;
    const SDL_AudioSpec spec = {SDL_AUDIO_F32, channels, RATE};
    if (!(c->audio = MIX_LoadRawAudio(mixer, samples, (size_t)frames * channels * sizeof(float), &spec))) { SDL_free(c); return 0; }
    c->id = next_id++; c->channels = channels; c->frames = frames; c->next = clips; clips = c;
    return c->id;
}
int helix_audio_dispose_clip(int clip) {
    for (clip_t **p = &clips; *p; p = &(*p)->next) if ((*p)->id == clip) {
        clip_t *c = *p;
        for (voice_t *v = voices; v; v = v->next) if (v->clip == clip) end_voice(v);
        *p = c->next; MIX_DestroyAudio(c->audio); SDL_free(c);
        return 1;
    }
    return 0;
}
int helix_audio_play_clip(int clip, int loop, float volume) {
    clip_t *c = find_clip(clip);
    if (!c) return -1;
    voice_t *v = new_voice(volume);
    if (!v) return 0;
    v->clip = clip; v->loop = loop != 0; v->channels = c->channels; v->length = c->frames;
    SDL_PropertiesID props = SDL_CreateProperties();
    SDL_SetNumberProperty(props, MIX_PROP_PLAY_LOOPS_NUMBER, loop ? -1 : 0);
    const bool playing = MIX_SetTrackAudio(v->track, c->audio) && MIX_PlayTrack(v->track, props);
    SDL_DestroyProperties(props);
    if (!playing) { SDL_SetAtomicInt(&v->ended, 1); return 0; }
    v->started = 1;
    return v->id;
}

int helix_audio_download(int total) {
    if (total < 0) return 0;
    download_t *d = SDL_calloc(1, sizeof *d);
    if (!d || !(d->bytes = SDL_malloc(total > 0 ? (size_t)total : 1))) { SDL_free(d); return 0; }
    d->id = next_id++; d->total = total; d->refs = 1; d->next = downloads; downloads = d;
    return d->id;
}
int helix_audio_download_add(int download, const unsigned char *bytes, int count) {
    download_t *d = find_download(download);
    if (!d || d->ended || count < 0 || count > d->total - d->avail) return 0;
    SDL_memcpy(d->bytes + d->avail, bytes, (size_t)count);
    d->avail += count;
    return 1;
}
void helix_audio_download_end(int download) { download_t *d = find_download(download); if (d) d->ended = 1; }
void helix_audio_download_release(int download) {
    download_t *d = find_download(download);
    if (d && !d->released) { d->released = 1; unref(d); }
}

/* The channels a decoder plays: 1 or 2, more mixed down to 2 (voice_decoder); 0 when there is no decoder or format. */
static int decoder_channels(MIX_AudioDecoder *decoder) {
    SDL_AudioSpec spec;
    const int channels = decoder && MIX_GetAudioDecoderFormat(decoder, &spec) ? (spec.channels > 1 ? 2 : spec.channels) : 0;
    if (decoder) MIX_DestroyAudioDecoder(decoder);
    return channels;
}
int helix_audio_check_file(const char *path) {
    return initialized && path ? decoder_channels(MIX_CreateAudioDecoder(path, 0)) : 0;
}
int helix_audio_check_download(int download) {
    download_t *d = find_download(download);
    return d && initialized ? decoder_channels(download_decoder(d, NULL)) : 0;
}

double helix_audio_file_duration(const char *path) {
    MIX_AudioDecoder *decoder = initialized && path ? MIX_CreateAudioDecoder(path, 0) : NULL;
    if (!decoder) return 0;
    const double seconds = decoder_duration(decoder);
    MIX_DestroyAudioDecoder(decoder);
    return seconds;
}
double helix_audio_download_duration(int download) {
    download_t *d = find_download(download);
    if (!d || !initialized || !d->ended || d->avail != d->total) return 0;
    MIX_AudioDecoder *decoder = download_decoder(d, NULL);
    if (!decoder) return 0;
    const double seconds = decoder_duration(decoder);
    MIX_DestroyAudioDecoder(decoder);
    return seconds;
}

static int play_stream(voice_t *v, int loop) {
    v->loop = loop != 0;
    if (!(v->decoder = voice_decoder(v)) || !(v->input = SDL_CreateAudioStream(&v->spec, &v->spec)) || !MIX_SetTrackAudioStream(v->track, v->input)) {
        SDL_SetAtomicInt(&v->ended, 1);
        return 0;
    }
    v->channels = v->spec.channels;
    return v->id;
}
int helix_audio_play_file(const char *path, int loop, float volume) {
    voice_t *v = path ? new_voice(volume) : NULL;
    if (!v) return 0;
    if (!(v->path = SDL_strdup(path))) { SDL_SetAtomicInt(&v->ended, 1); return 0; }
    return play_stream(v, loop);
}
int helix_audio_play_download(int download, int loop, float volume) {
    download_t *d = find_download(download);
    voice_t *v = d ? new_voice(volume) : NULL;
    if (!v) return 0;
    v->download = d; d->refs++;
    return play_stream(v, loop);
}

/* Decodes a stream's voice up to a second ahead within the frame's budget, starts it once decoded far enough, and ends it once decoded to its
   end and heard. */
static void feed_voice(voice_t *v, Uint64 start) {
    float buffer[4096];
    const int frame_bytes = v->spec.channels * (int)sizeof(float);
    while (!v->finished && SDL_GetAudioStreamQueued(v->input) < AHEAD * frame_bytes && SDL_GetTicksNS() - start < BUDGET_NS) {
        download_t *d = v->download;
        if (d && !d->ended && d->avail - (v->reader ? v->reader->position : 0) < MARGIN) break;
        const int got = MIX_DecodeAudio(v->decoder, buffer, sizeof buffer / frame_bytes * frame_bytes, &v->spec);
        if (got < 0) { end_voice(v); return; }
        if (got > 0) {
            SDL_PutAudioStreamData(v->input, buffer, got);
            v->decoded = 1; v->decoded_frames += got / frame_bytes; v->pass_frames += got / frame_bytes;
            continue;
        }
        /* A read past what has arrived: wait for more. */
        if (d && !d->ended) break;
        /* Decoded to the end: the file's length is now known, if it wasn't. */
        if (v->length < 0 && v->decoded) v->length = v->pass_start + v->pass_frames;
        if (v->loop && v->decoded) {
            MIX_DestroyAudioDecoder(v->decoder);
            v->pass_start = v->pass_frames = 0;
            if ((v->decoder = voice_decoder(v))) continue;
            end_voice(v);
            return;
        }
        SDL_FlushAudioStream(v->input);
        v->finished = 1;
    }
    const int queued = SDL_GetAudioStreamQueued(v->input) / frame_bytes;
    if (!v->started && (v->finished || queued >= (v->download ? START_DOWNLOAD : START_FILE))) {
        SDL_PropertiesID props = SDL_CreateProperties();
        SDL_SetBooleanProperty(props, MIX_PROP_PLAY_HALT_WHEN_EXHAUSTED_BOOLEAN, false);
        const bool playing = MIX_PlayTrack(v->track, props);
        SDL_DestroyProperties(props);
        if (!playing) { end_voice(v); return; }
        v->started = 1;
        if (v->paused) MIX_PauseTrack(v->track);
    }
    if (v->finished && v->started && queued == 0) end_voice(v);
}
void helix_audio_feed(void) {
    const Uint64 start = SDL_GetTicksNS();
    for (voice_t **p = &voices; *p;) {
        voice_t *v = *p;
        if (SDL_GetAtomicInt(&v->ended)) { *p = v->next; free_voice(v); continue; }
        if (v->input) feed_voice(v, start);
        p = &v->next;
    }
}

void helix_audio_stop(int voice) {
    voice_t *v = find_voice(voice);
    if (!v) return;
    queue_t *q = v->queue;
    end_voice(v);
    /* A queue's voice stopped drops what it hadn't played. */
    if (q) SDL_ClearAudioStream(q->stream);
}
void helix_audio_pause(int voice, int paused) {
    voice_t *v = find_voice(voice);
    if (!v || v->paused == (paused != 0)) return;
    v->paused = paused != 0;
    if (v->started) { if (v->paused) MIX_PauseTrack(v->track); else MIX_ResumeTrack(v->track); }
}
int helix_audio_set_volume(int voice, float volume) {
    voice_t *v = find_voice(voice);
    if (!v || !isfinite(volume) || volume < 0 || volume > 1) return 0;
    MIX_LockMixer(mixer); v->volume = volume; MIX_UnlockMixer(mixer);
    return 1;
}
int helix_audio_set_pitch(int voice, float pitch) {
    voice_t *v = find_voice(voice);
    if (!v || !isfinite(pitch) || pitch < .25f || pitch > 4) return 0;
    return MIX_SetTrackFrequencyRatio(v->track, pitch);
}
int helix_audio_set_pan(int voice, float pan) {
    voice_t *v = find_voice(voice);
    if (!v || !isfinite(pan) || pan < -1 || pan > 1) return 0;
    MIX_LockMixer(mixer); v->pan = pan; MIX_UnlockMixer(mixer);
    return 1;
}
int helix_audio_is_playing(int voice) { return find_voice(voice) != NULL; }

/* Frames of a stream's voice queued for its track and not yet taken. */
static Sint64 stream_queued(voice_t *v) { return SDL_GetAudioStreamQueued(v->input) / (v->spec.channels * (int)sizeof(float)); }
/* Frames of a queue taken by its track since its voice started. */
static Sint64 queue_played(voice_t *v) {
    queue_t *q = v->queue;
    SDL_LockAudioStream(q->stream);
    const Sint64 played = q->put - SDL_GetAudioStreamQueued(q->stream) / (q->channels * (int)sizeof(float));
    SDL_UnlockAudioStream(q->stream);
    return played - v->base;
}
double helix_audio_position(int voice) {
    voice_t *v = find_voice(voice);
    if (!v) return 0;
    if (v->queue) return (double)queue_played(v) / v->queue->rate;
    if (!v->input) { const Sint64 frames = MIX_GetTrackPlaybackPosition(v->track); return frames > 0 ? (double)frames / RATE : 0; }
    Sint64 frames = v->origin + v->decoded_frames - stream_queued(v);
    if (frames < 0) frames = 0;
    if (v->length > 0) frames = v->loop ? frames % v->length : SDL_min(frames, v->length);
    return (double)frames / RATE;
}
/* Moves a stream's decoder to frame (at RATE) through SDL3_mixer's own decoder seek, which its API doesn't offer, and drops what was
   decoded ahead. */
static int stream_seek(voice_t *v, Sint64 frame) {
    MIX_AudioDecoder *decoder = v->decoder;
    if (!decoder) return 0;
    const Uint64 to = (Uint64)((double)frame * decoder->audio->spec.freq / RATE);
    if (!decoder->audio->decoder->seek(decoder->track_userdata, to)) return 0;
    SDL_ClearAudioStream(decoder->stream);
    SDL_ClearAudioStream(v->input);
    v->origin = v->pass_start = frame; v->decoded_frames = v->pass_frames = 0; v->finished = 0;
    return 1;
}
int helix_audio_set_position(int voice, double seconds) {
    voice_t *v = find_voice(voice);
    if (!v || v->queue || !isfinite(seconds) || seconds < 0) return 0;
    Sint64 frame = (Sint64)(seconds * RATE + .5);
    if (v->length > 0 && frame >= v->length) {
        if (!v->loop) { end_voice(v); return 1; }
        frame = 0;
    }
    return v->input ? stream_seek(v, frame) : MIX_SetTrackPlaybackPosition(v->track, frame);
}

int helix_audio_queue(int channels, int rate) {
    if (!initialized || channels < 1 || channels > 2 || rate < 8000 || rate > 96000) return 0;
    queue_t *q = SDL_calloc(1, sizeof *q);
    if (!q) return 0;
    const SDL_AudioSpec spec = {SDL_AUDIO_F32, channels, rate};
    if (!(q->stream = SDL_CreateAudioStream(&spec, &spec))) { SDL_free(q); return 0; }
    q->id = next_id++; q->channels = channels; q->rate = rate; q->next = queues; queues = q;
    return q->id;
}
int helix_audio_queue_samples(int queue, const void *samples, int bytes) {
    queue_t *q = find_queue(queue);
    if (!q) return 0;
    const int frames = bytes / (q->channels * (int)sizeof(float));
    if (frames <= 0 || !samples) return 1;
    /* SDL's stream takes its own lock; put is the main thread's. */
    if (!SDL_PutAudioStreamData(q->stream, samples, frames * q->channels * (int)sizeof(float))) return 0;
    q->put += frames;
    return 1;
}
int helix_audio_queued_frames(int queue) {
    queue_t *q = find_queue(queue);
    return q ? SDL_GetAudioStreamQueued(q->stream) / (q->channels * (int)sizeof(float)) : -1;
}
int helix_audio_dispose_queue(int queue) {
    for (queue_t **p = &queues; *p; p = &(*p)->next) if ((*p)->id == queue) {
        queue_t *q = *p;
        voice_t *v = find_voice(q->voice);
        if (v) end_voice(v);
        *p = q->next; SDL_DestroyAudioStream(q->stream); SDL_free(q);
        return 1;
    }
    return 0;
}
int helix_audio_play_queue(int queue, float volume) {
    queue_t *q = find_queue(queue);
    if (!q) return -1;
    voice_t *earlier = find_voice(q->voice);
    if (earlier) end_voice(earlier);
    voice_t *v = new_voice(volume);
    if (!v) return 0;
    v->channels = q->channels;
    SDL_PropertiesID props = SDL_CreateProperties();
    SDL_SetBooleanProperty(props, MIX_PROP_PLAY_HALT_WHEN_EXHAUSTED_BOOLEAN, false);
    const bool playing = MIX_SetTrackAudioStream(v->track, q->stream) && MIX_PlayTrack(v->track, props);
    SDL_DestroyProperties(props);
    if (!playing) { MIX_SetTrackAudioStream(v->track, NULL); SDL_SetAtomicInt(&v->ended, 1); return 0; }
    v->queue = q; v->started = 1; q->voice = v->id;
    v->base = q->put - SDL_GetAudioStreamQueued(q->stream) / (q->channels * (int)sizeof(float));
    return v->id;
}
int helix_audio_is_sounding(int voice) { voice_t *v = find_voice(voice); return v && v->started; }
