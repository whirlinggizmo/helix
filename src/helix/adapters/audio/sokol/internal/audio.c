#include "audio.h"
#include <math.h>
#include "lock.h"
#include <stdlib.h>
#include <string.h>
#define SOKOL_AUDIO_IMPL
#include "sokol_audio.h"
#include "sokol_log.h"

/* This prototype links Linux. Other native targets need their lock/link adapter. */
typedef struct { int id, count; float *samples; } clip_t;
typedef struct { int id, clip_id, loop, paused, head, count, eof; double position; float volume; float *ring; } voice_t;
static clip_t clips[32];
static voice_t voices[16];
static helix_lock_t audio_lock = HELIX_LOCK_INIT;
static int next_clip = 1, next_voice = 1, played, stopped, initialized, callbacks;

static clip_t *find_clip(int id) {
    if (id <= 0) return NULL;
    for (int i = 0; i < 32; i++) if (clips[i].id == id) return &clips[i];
    return NULL;
}

static void audio_callback(float *out, int frames, int channels) {
    memset(out, 0, (size_t)frames * channels * sizeof(float));
    helix_lock(&audio_lock);
    callbacks++;
    /* Clips use 44100Hz; account for the actual output rate negotiated by Sokol. */
    const int rate = saudio_sample_rate();
    const double step = rate > 0 ? 44100.0 / rate : 1.0;
    for (int v = 0; v < 16; v++) if (voices[v].id) {
        voice_t *voice = &voices[v];
        if (voice->paused) continue;
        if (voice->ring) {
            for(int i=0;i<frames;i++){
                if(voice->count==0){if(voice->eof){free(voice->ring);memset(voice,0,sizeof *voice);}break;}
                int next=(voice->head+1)%8192;
                float a=voice->ring[voice->head], b=voice->count>1?voice->ring[next]:a;
                float sample=(a+(b-a)*(float)voice->position)*voice->volume;
                for(int c=0;c<channels;c++)out[i*channels+c]+=sample;
                voice->position+=step;int used=(int)voice->position;if(used>voice->count)used=voice->count;
                voice->head=(voice->head+used)%8192;voice->count-=used;voice->position-=used;
            }
            continue;
        }
        clip_t *clip = find_clip(voice->clip_id);
        if (!clip) { memset(voice, 0, sizeof *voice); continue; }
        for (int i = 0; i < frames; i++) {
            if (voice->position >= clip->count) {
                if (voice->loop) voice->position = fmod(voice->position, clip->count);
                else { memset(voice, 0, sizeof *voice); break; }
            }
            const int at = (int)voice->position;
            const int next = at + 1 < clip->count ? at + 1 : voice->loop ? 0 : at;
            const float fraction = (float)(voice->position - at);
            const float sample = (clip->samples[at] + (clip->samples[next] - clip->samples[at]) * fraction) * voice->volume;
            for (int channel = 0; channel < channels; channel++) out[i * channels + channel] += sample;
            voice->position += step;
        }
    }
    helix_unlock(&audio_lock);
    for (int i = 0; i < frames * channels; i++) out[i] = fmaxf(-1, fminf(1, out[i]));
}

void helix_audio_setup(void) {
    if (initialized) return;
    saudio_setup(&(saudio_desc){ .sample_rate = 44100, .num_channels = 1,
        .buffer_frames = 512, .stream_cb = audio_callback, .logger.func = slog_func });
    initialized = 1;
}
int helix_audio_available(void) { return initialized && saudio_isvalid(); }
int helix_audio_clip(const void *data, int bytes) {
    if (!data || bytes <= 0 || bytes % 4) return 0;
    float *copy = malloc((size_t)bytes);
    if (!copy) return 0;
    memcpy(copy, data, (size_t)bytes);
    for (int i = 0; i < bytes / 4; i++) if (!isfinite(copy[i]) || copy[i] < -1 || copy[i] > 1) { free(copy); return 0; }
    helix_lock(&audio_lock);
    int id = 0;
    for (int i = 0; i < 32; i++) if (!clips[i].id) { id = next_clip++; clips[i] = (clip_t){id, bytes / 4, copy}; break; }
    helix_unlock(&audio_lock);
    if (!id) free(copy);
    return id;
}
int helix_audio_play(int clip_id, int loop, float volume) {
    if (!isfinite(volume) || volume < 0 || volume > 1) return -1;
    helix_lock(&audio_lock);
    if (!find_clip(clip_id)) { helix_unlock(&audio_lock); return -1; }
    int id = 0;
    if (helix_audio_available()) for (int i = 0; i < 16; i++) if (!voices[i].id) {
        id = next_voice++; voices[i] = (voice_t){.id=id, .clip_id=clip_id, .loop=loop!=0, .volume=volume}; played++; break;
    }
    helix_unlock(&audio_lock);
    return id;
}
void helix_audio_stop(int id) {
    helix_lock(&audio_lock);
    for (int i = 0; i < 16; i++) if (id && voices[i].id == id) { free(voices[i].ring); memset(&voices[i], 0, sizeof voices[i]); stopped++; }
    helix_unlock(&audio_lock);
}
int helix_audio_destroy_clip(int id) {
    helix_lock(&audio_lock);
    clip_t *clip = find_clip(id);
    if (!clip) { helix_unlock(&audio_lock); return 0; }
    for (int i = 0; i < 16; i++) if (voices[i].clip_id == id) memset(&voices[i], 0, sizeof voices[i]);
    free(clip->samples); memset(clip, 0, sizeof *clip);
    helix_unlock(&audio_lock);
    return 1;
}
int helix_audio_played(void) { return played; }
int helix_audio_stopped(void) { return stopped; }
int helix_audio_callbacks(void) {
    helix_lock(&audio_lock); const int count=callbacks; helix_unlock(&audio_lock); return count;
}
int helix_audio_sample_rate(void) { return initialized ? saudio_sample_rate() : 0; }
int helix_audio_channels(void) { return initialized ? saudio_channels() : 0; }
int helix_audio_loops(void) {
    helix_lock(&audio_lock);
    int count = 0;
    for (int i = 0; i < 16; i++) if (voices[i].id && voices[i].loop) count++;
    helix_unlock(&audio_lock);
    return count;
}
void helix_audio_shutdown(void) {
    /* Join Sokol's callback thread before freeing mixer-owned samples. */
    if (initialized) { saudio_shutdown(); initialized = 0; }
    for (int i = 0; i < 32; i++) { free(clips[i].samples); memset(&clips[i], 0, sizeof clips[i]); }
    for(int i=0;i<16;i++)free(voices[i].ring);
    memset(voices, 0, sizeof voices);
}
#ifdef HELIX_SERVICES_TEST
/* Only the deterministic dummy-backend test target exports this callback hook. */
void helix_audio_test_render(float *out, int frames, int channels) { audio_callback(out, frames, channels); }
void helix_audio_test_setup(int rate) {
    saudio_setup(&(saudio_desc){.sample_rate=rate, .num_channels=1, .buffer_frames=512,
        .stream_cb=audio_callback, .logger.func=slog_func}); initialized=1;
}
#endif

int helix_audio_is_playing(int id) {helix_lock(&audio_lock);int found=0;for(int i=0;i<16;i++)if(id&&voices[i].id==id)found=1;helix_unlock(&audio_lock);return found;}
void helix_audio_pause(int id,int paused) {helix_lock(&audio_lock);for(int i=0;i<16;i++)if(id&&voices[i].id==id)voices[i].paused=paused!=0;helix_unlock(&audio_lock);}
void helix_audio_volume(int id,float volume) {if(!isfinite(volume)||volume<0||volume>1)return;helix_lock(&audio_lock);for(int i=0;i<16;i++)if(id&&voices[i].id==id)voices[i].volume=volume;helix_unlock(&audio_lock);}
int helix_audio_stream(float volume) {
 if(!isfinite(volume)||volume<0||volume>1)return 0;
 helix_lock(&audio_lock);int id=0;
 if(helix_audio_available())for(int i=0;i<16;i++)if(!voices[i].id){float *ring=calloc(8192,sizeof(float));if(ring){id=next_voice++;voices[i]=(voice_t){.id=id,.volume=volume,.ring=ring};played++;}break;}
 helix_unlock(&audio_lock);return id;
}
int helix_audio_stream_queued(int id) {helix_lock(&audio_lock);int count=-1;for(int i=0;i<16;i++)if(id&&voices[i].id==id&&voices[i].ring)count=voices[i].count;helix_unlock(&audio_lock);return count;}
int helix_audio_stream_push(int id,const void *data,int bytes,int eof) {
 if(bytes<0||bytes%4||(!data&&bytes))return -1;const float *samples=data;
 for(int i=0;i<bytes/4;i++)if(!isfinite(samples[i])||samples[i]<-1||samples[i]>1)return -1;
 helix_lock(&audio_lock);int accepted=-1;
 for(int i=0;i<16;i++)if(id&&voices[i].id==id&&voices[i].ring){voice_t *v=&voices[i];accepted=bytes/4;if(accepted>8192-v->count)accepted=8192-v->count;for(int n=0;n<accepted;n++)v->ring[(v->head+v->count+n)%8192]=samples[n];v->count+=accepted;if(eof&&accepted==bytes/4)v->eof=1;break;}
 helix_unlock(&audio_lock);return accepted;
}
