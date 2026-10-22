#include "audio.h"
#include "mixer.h"
#include <math.h>
#include "lock.h"
#include <stdlib.h>
#include <string.h>

/* The native audio adapters' mixer: 32 clips and 16 voices (a clip played, or a stream fed as it arrives) of 44.1 kHz mono floats, mixed
   on the output's thread into stereo (or mono, when the output has one channel) by whichever output the program links (sokol_audio's or
   SDL3's), which supplies setup, shutdown, available, sample rate and channels (audio.h). A voice's pitch multiplies its resampling step; its
   pan places it by equal power; a volume or pan change ramps linearly across the next callback, so one stepped once a frame doesn't click. */
typedef struct { int id, count; float *samples; } clip_t;
/* A stream voice's ring: 2 s at 44.1 kHz, so a frame thread stalled under that (a level load, a collection) feeds it in time. */
#define HELIX_STREAM_RING 88200
/* mixed: whether a callback has mixed it, so heard_volume and heard_pan (what the last callback ended at) are where its ramps start. */
typedef struct { int id, clip_id, loop, paused, head, count, eof, mixed; double position; float volume, pitch, pan, heard_volume, heard_pan; float *ring; } voice_t;
static clip_t clips[32];
static voice_t voices[16];
static helix_lock_t audio_lock = HELIX_LOCK_INIT;
static int next_clip = 1, next_voice = 1, played, stopped, callbacks;

static clip_t *find_clip(int id) {
    if (id <= 0) return NULL;
    for (int i = 0; i < 32; i++) if (clips[i].id == id) return &clips[i];
    return NULL;
}

/* A voice's ramps across one callback of frames: from what the last callback ended at (its targets for a voice not mixed yet) to its
   targets, with each end's equal-power gains (left = cos((pan + 1) pi/4), right = sin). */
typedef struct { float volume0, volume1, pan0, pan1, left0, right0, left1, right1; int panning; } ramp_t;
static ramp_t ramp_start(voice_t *voice) {
    ramp_t r = { voice->mixed ? voice->heard_volume : voice->volume, voice->volume, voice->mixed ? voice->heard_pan : voice->pan, voice->pan };
    const float quarter = 0.78539816339744830962f;
    r.left0 = cosf((r.pan0 + 1) * quarter); r.right0 = sinf((r.pan0 + 1) * quarter);
    r.left1 = cosf((r.pan1 + 1) * quarter); r.right1 = sinf((r.pan1 + 1) * quarter);
    r.panning = r.pan0 != r.pan1;
    voice->mixed = 1; voice->heard_volume = voice->volume; voice->heard_pan = voice->pan;
    return r;
}
/* Adds sample, the voice's at frame i of frames, into out: its volume ramped, then the mono sum, or the left and right by its pan. */
static void ramp_add(const ramp_t *r, float *out, int i, int frames, int channels, float sample) {
    const float t = (float)(i + 1) / (float)frames;
    sample *= r->volume0 + (r->volume1 - r->volume0) * t;
    if (channels == 1) { out[i] += sample; return; }
    float left, right;
    if (r->panning) {
        const float angle = (r->pan0 + (r->pan1 - r->pan0) * t + 1) * 0.78539816339744830962f;
        left = cosf(angle); right = sinf(angle);
    } else { left = r->left1; right = r->right1; }
    out[i * channels] += sample * left; out[i * channels + 1] += sample * right;
}

void helix_mixer_mix(float *out, int frames, int channels, int rate) {
    memset(out, 0, (size_t)frames * channels * sizeof(float));
    helix_lock(&audio_lock);
    callbacks++;
    /* Clips are 44.1 kHz; stepped to the output's rate, times each voice's pitch. */
    const double base = rate > 0 ? 44100.0 / rate : 1.0;
    for (int v = 0; v < 16; v++) if (voices[v].id) {
        voice_t *voice = &voices[v];
        if (voice->paused) continue;
        const double step = base * voice->pitch;
        if (voice->ring) {
            const ramp_t r = ramp_start(voice);
            for(int i=0;i<frames;i++){
                if(voice->count==0){if(voice->eof){free(voice->ring);memset(voice,0,sizeof *voice);}break;}
                int next=(voice->head+1)%HELIX_STREAM_RING;
                float a=voice->ring[voice->head], b=voice->count>1?voice->ring[next]:a;
                ramp_add(&r,out,i,frames,channels,a+(b-a)*(float)voice->position);
                voice->position+=step;int used=(int)voice->position;if(used>voice->count)used=voice->count;
                voice->head=(voice->head+used)%HELIX_STREAM_RING;voice->count-=used;voice->position-=used;
            }
            continue;
        }
        clip_t *clip = find_clip(voice->clip_id);
        if (!clip) { memset(voice, 0, sizeof *voice); continue; }
        const ramp_t r = ramp_start(voice);
        for (int i = 0; i < frames; i++) {
            if (voice->position >= clip->count) {
                if (voice->loop) voice->position = fmod(voice->position, clip->count);
                else { memset(voice, 0, sizeof *voice); break; }
            }
            const int at = (int)voice->position;
            const int next = at + 1 < clip->count ? at + 1 : voice->loop ? 0 : at;
            const float fraction = (float)(voice->position - at);
            ramp_add(&r, out, i, frames, channels, clip->samples[at] + (clip->samples[next] - clip->samples[at]) * fraction);
            voice->position += step;
        }
    }
    helix_unlock(&audio_lock);
    for (int i = 0; i < frames * channels; i++) out[i] = fmaxf(-1, fminf(1, out[i]));
}

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
        id = next_voice++; voices[i] = (voice_t){.id=id, .clip_id=clip_id, .loop=loop!=0, .volume=volume, .pitch=1}; played++; break;
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
int helix_audio_loops(void) {
    helix_lock(&audio_lock);
    int count = 0;
    for (int i = 0; i < 16; i++) if (voices[i].id && voices[i].loop) count++;
    helix_unlock(&audio_lock);
    return count;
}

void helix_mixer_release(void) {
    for (int i = 0; i < 32; i++) { free(clips[i].samples); memset(&clips[i], 0, sizeof clips[i]); }
    for(int i=0;i<16;i++)free(voices[i].ring);
    memset(voices, 0, sizeof voices);
}

int helix_audio_is_playing(int id) {helix_lock(&audio_lock);int found=0;for(int i=0;i<16;i++)if(id&&voices[i].id==id)found=1;helix_unlock(&audio_lock);return found;}
void helix_audio_pause(int id,int paused) {helix_lock(&audio_lock);for(int i=0;i<16;i++)if(id&&voices[i].id==id)voices[i].paused=paused!=0;helix_unlock(&audio_lock);}
void helix_audio_volume(int id,float volume) {if(!isfinite(volume)||volume<0||volume>1)return;helix_lock(&audio_lock);for(int i=0;i<16;i++)if(id&&voices[i].id==id)voices[i].volume=volume;helix_unlock(&audio_lock);}
void helix_audio_pitch(int id,float pitch) {if(!isfinite(pitch)||pitch<.25f||pitch>4)return;helix_lock(&audio_lock);for(int i=0;i<16;i++)if(id&&voices[i].id==id)voices[i].pitch=pitch;helix_unlock(&audio_lock);}
void helix_audio_pan(int id,float pan) {if(!isfinite(pan)||pan<-1||pan>1)return;helix_lock(&audio_lock);for(int i=0;i<16;i++)if(id&&voices[i].id==id)voices[i].pan=pan;helix_unlock(&audio_lock);}
int helix_audio_stream(float volume) {
 if(!isfinite(volume)||volume<0||volume>1)return 0;
 helix_lock(&audio_lock);int id=0;
 if(helix_audio_available())for(int i=0;i<16;i++)if(!voices[i].id){float *ring=calloc(HELIX_STREAM_RING,sizeof(float));if(ring){id=next_voice++;voices[i]=(voice_t){.id=id,.volume=volume,.pitch=1,.ring=ring};played++;}break;}
 helix_unlock(&audio_lock);return id;
}
int helix_audio_stream_queued(int id) {helix_lock(&audio_lock);int count=-1;for(int i=0;i<16;i++)if(id&&voices[i].id==id&&voices[i].ring)count=voices[i].count;helix_unlock(&audio_lock);return count;}
int helix_audio_stream_push(int id,const void *data,int bytes,int eof) {
 if(bytes<0||bytes%4||(!data&&bytes))return -1;const float *samples=data;
 for(int i=0;i<bytes/4;i++)if(!isfinite(samples[i])||samples[i]<-1||samples[i]>1)return -1;
 helix_lock(&audio_lock);int accepted=-1;
 for(int i=0;i<16;i++)if(id&&voices[i].id==id&&voices[i].ring){voice_t *v=&voices[i];accepted=bytes/4;if(accepted>HELIX_STREAM_RING-v->count)accepted=HELIX_STREAM_RING-v->count;for(int n=0;n<accepted;n++)v->ring[(v->head+v->count+n)%HELIX_STREAM_RING]=samples[n];v->count+=accepted;if(eof&&accepted==bytes/4)v->eof=1;break;}
 helix_unlock(&audio_lock);return accepted;
}
