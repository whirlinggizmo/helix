#include "audio_sdl3mixer.h"
#include <SDL3/SDL.h>
#include <SDL3_mixer/SDL_mixer.h>
#include <math.h>

/* Voices are SDL3_mixer tracks: a clip's plays its audio, a stream's an audio stream the main thread fills from SDL3_mixer's decoder, the
   track told to wait rather than stop when it runs dry. Volume and pan are the track's cooked callback's: equal power, ramped linearly across
   each block from where the last ended, as SDL applies a gain change at once. */

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
typedef struct clip { int id; MIX_Audio *audio; struct clip *next; } clip_t;
typedef struct voice {
    int id, clip, loop, paused, started, finished, decoded;
    MIX_Track *track;
    char *path; download_t *download; reader_t *reader; MIX_AudioDecoder *decoder; SDL_AudioStream *input;
    /* The targets, set on the main thread under the mixer's lock; where the last block ended, the device thread's. */
    float volume, pan, heard_volume, heard_pan; int mixed;
    SDL_AtomicInt ended;
    struct voice *next;
} voice_t;

static MIX_Mixer *mixer;
static int initialized, device_open;
static clip_t *clips;
static voice_t *voices;
static download_t *downloads;
static int next_id = 1;
static const SDL_AudioSpec MONO = {SDL_AUDIO_F32, 1, RATE};
static const SDL_AudioSpec STEREO = {SDL_AUDIO_F32, 2, RATE};

static void unref(download_t *d) {
    if (--d->refs > 0 || !d->released) return;
    for (download_t **p = &downloads; *p; p = &(*p)->next) if (*p == d) { *p = d->next; break; }
    SDL_free(d->bytes); SDL_free(d);
}
static download_t *find_download(int id) { for (download_t *d = downloads; d; d = d->next) if (d->id == id) return d; return NULL; }
static clip_t *find_clip(int id) { for (clip_t *c = clips; c; c = c->next) if (c->id == id) return c; return NULL; }
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
static MIX_AudioDecoder *voice_decoder(voice_t *v) {
    v->reader = NULL; v->decoded = 0;
    return v->path ? MIX_CreateAudioDecoder(v->path, 0) : download_decoder(v->download, &v->reader);
}

static void SDLCALL stopped(void *userdata, MIX_Track *track) { (void)track; SDL_SetAtomicInt(&((voice_t *)userdata)->ended, 1); }
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
    v->id = next_id++; v->track = track; v->volume = volume;
    MIX_SetTrackStoppedCallback(track, stopped, v);
    MIX_SetTrackCookedCallback(track, cooked, v);
    v->next = voices; voices = v;
    return v;
}
static void free_voice(voice_t *v) {
    MIX_DestroyTrack(v->track);
    if (v->decoder) MIX_DestroyAudioDecoder(v->decoder);
    if (v->input) SDL_DestroyAudioStream(v->input);
    if (v->download) unref(v->download);
    SDL_free(v->path); SDL_free(v);
}
/* Ends a voice; it's freed at the next feed. */
static void end_voice(voice_t *v) {
    if (v->started) MIX_StopTrack(v->track, 0);
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

int helix_audio_clip(const void *samples, int count) {
    if (!initialized || !samples || count <= 0) return 0;
    clip_t *c = SDL_calloc(1, sizeof *c);
    if (!c) return 0;
    if (!(c->audio = MIX_LoadRawAudio(mixer, samples, (size_t)count * sizeof(float), &MONO))) { SDL_free(c); return 0; }
    c->id = next_id++; c->next = clips; clips = c;
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
    v->clip = clip; v->loop = loop != 0;
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

int helix_audio_check_file(const char *path) {
    if (!initialized || !path) return 0;
    MIX_AudioDecoder *decoder = MIX_CreateAudioDecoder(path, 0);
    if (decoder) MIX_DestroyAudioDecoder(decoder);
    return decoder != NULL;
}
int helix_audio_check_download(int download) {
    download_t *d = find_download(download);
    if (!d || !initialized) return 0;
    MIX_AudioDecoder *decoder = download_decoder(d, NULL);
    if (decoder) MIX_DestroyAudioDecoder(decoder);
    return decoder != NULL;
}

static int play_stream(voice_t *v, int loop) {
    v->loop = loop != 0;
    if (!(v->decoder = voice_decoder(v)) || !(v->input = SDL_CreateAudioStream(&MONO, &MONO)) || !MIX_SetTrackAudioStream(v->track, v->input)) {
        SDL_SetAtomicInt(&v->ended, 1);
        return 0;
    }
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
    while (!v->finished && SDL_GetAudioStreamQueued(v->input) < AHEAD * (int)sizeof(float) && SDL_GetTicksNS() - start < BUDGET_NS) {
        download_t *d = v->download;
        if (d && !d->ended && d->avail - (v->reader ? v->reader->position : 0) < MARGIN) break;
        const int got = MIX_DecodeAudio(v->decoder, buffer, sizeof buffer, &MONO);
        if (got < 0) { end_voice(v); return; }
        if (got > 0) { SDL_PutAudioStreamData(v->input, buffer, got); v->decoded = 1; continue; }
        /* A read past what has arrived: wait for more. */
        if (d && !d->ended) break;
        if (v->loop && v->decoded) {
            MIX_DestroyAudioDecoder(v->decoder);
            if ((v->decoder = voice_decoder(v))) continue;
            end_voice(v);
            return;
        }
        SDL_FlushAudioStream(v->input);
        v->finished = 1;
    }
    const int queued = SDL_GetAudioStreamQueued(v->input) / (int)sizeof(float);
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

void helix_audio_stop(int voice) { voice_t *v = find_voice(voice); if (v) end_voice(v); }
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
int helix_audio_is_sounding(int voice) { voice_t *v = find_voice(voice); return v && v->started; }
