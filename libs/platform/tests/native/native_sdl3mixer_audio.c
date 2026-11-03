/* The native audio adapter's C (adapters/audio/sdl3mixer/internal) rendered with no device (helix_audio_generate): clips, voices, pan, pitch,
   the volume and pan ramps, stereo clips and streams balanced, positions read and moved, streams' lengths, streams from a file and from a
   download arriving slowly or stopping, looping, queues fed, run dry and fed again, and a render thread racing the main one. No
   audible-output claim. */
#include "audio_sdl3mixer.h"
#include <SDL3/SDL.h>
#include <math.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

static int checks;
#define CHECK(value) do { if (!(value)) { fprintf(stderr, "Failed at line %d\n", __LINE__); abort(); } checks++; } while (0)
#define NEAR(a, b) (fabsf((a) - (b)) < 1e-5f)
static const float QUARTER = 0.78539816339744830962f;

/* A 16-bit 44100 Hz WAV of frames frames, mono at value, or stereo at value on the left and right on the right. */
static unsigned char *wav_of(int frames, int stereo, float value, float right, int *length) {
    const unsigned short channels = stereo ? 2 : 1, align = 2 * channels, pcm = 1, bits = 16;
    *length = 44 + frames * align;
    unsigned char *w = calloc(1, (size_t)*length);
    const unsigned int sizes[2] = {(unsigned)*length - 8, (unsigned)frames * align};
    memcpy(w, "RIFF", 4); memcpy(w + 4, &sizes[0], 4); memcpy(w + 8, "WAVEfmt ", 8);
    const unsigned int fmt = 16, rate = 44100, bytes = 44100u * align;
    memcpy(w + 16, &fmt, 4); memcpy(w + 20, &pcm, 2); memcpy(w + 22, &channels, 2); memcpy(w + 24, &rate, 4); memcpy(w + 28, &bytes, 4);
    memcpy(w + 32, &align, 2); memcpy(w + 34, &bits, 2); memcpy(w + 36, "data", 4); memcpy(w + 40, &sizes[1], 4);
    for (int i = 0; i < frames; i++)
        for (int c = 0; c < channels; c++) { const short s = (short)((c ? right : value) * 32767); memcpy(w + 44 + (i * channels + c) * 2, &s, 2); }
    return w;
}
static unsigned char *wav(int frames, float value, int *length) { return wav_of(frames, 0, value, 0, length); }
static void write_file(const char *path, const unsigned char *bytes, int length) {
    SDL_IOStream *io = SDL_IOFromFile(path, "wb"); CHECK(io && SDL_WriteIO(io, bytes, (size_t)length) == (size_t)length); SDL_CloseIO(io);
}
/* Renders frames a frame (735) at a time, feeding first; the last block's first frame in last (left, right). */
static void render(int frames, float *last) {
    static float block[735 * 2];
    for (int done = 0; done < frames; done += 735) {
        const int count = frames - done < 735 ? frames - done : 735;
        helix_audio_feed();
        CHECK(helix_audio_generate(block, count) == count);
    }
    if (last) { last[0] = block[0]; last[1] = block[1]; }
}

/* Frames whose left channel is heard, out of frames rendered a frame (735) at a time, feeding first; stops early once voice has ended. */
static int heard(int voice, int frames) {
    static float out[735 * 2];
    int count = 0;
    for (int done = 0; done < frames; done += 735) {
        helix_audio_feed();
        CHECK(helix_audio_generate(out, 735) == 735);
        for (int i = 0; i < 735; i++) if (out[2 * i] != 0) count++;
        if (!helix_audio_is_playing(voice)) break;
    }
    return count;
}

static volatile int racing = 1;
static int SDLCALL render_thread(void *unused) {
    (void)unused;
    float out[256];
    while (racing) {
        helix_audio_generate(out, 128);
        for (int i = 0; i < 256; i++) if (!isfinite(out[i]) || out[i] < -2 || out[i] > 2) abort();
        SDL_DelayNS(100000); /* As a device's thread waits between blocks; without it the thread starves the main one of the mixer's lock. */
    }
    return 0;
}

int main(void) {
    CHECK(helix_audio_open(0) && helix_audio_is_open());
    float out[64];
    /* A clip is a copy; an unknown clip refuses. */
    float pcm[4] = {.1f, -.1f, .2f, -.2f};
    const int clip = helix_audio_clip(pcm, 4, 1); CHECK(clip > 0); pcm[0] = NAN;
    CHECK(helix_audio_play_clip(0, 0, .5f) == -1 && helix_audio_dispose_clip(0) == 0 && helix_audio_play_clip(clip, 0, 2) == 0);
    /* Hard left, the volume as set: the left channel is the clip times it, the right silent; looping wraps. */
    int voice = helix_audio_play_clip(clip, 1, .5f); CHECK(voice > 0 && helix_audio_set_pan(voice, -1));
    CHECK(helix_audio_generate(out, 8) == 8);
    CHECK(NEAR(out[0], .05f) && NEAR(out[2], -.05f) && NEAR(out[8], .05f) && NEAR(out[1], 0) && NEAR(out[9], 0));
    helix_audio_stop(voice); CHECK(!helix_audio_is_playing(voice) && !helix_audio_set_volume(voice, 1));
    helix_audio_stop(voice);
    helix_audio_feed(); helix_audio_generate(out, 8); CHECK(out[0] == 0 && out[7] == 0);
    /* Once through: it ends, and says so. */
    voice = helix_audio_play_clip(clip, 0, 1); CHECK(voice > 0 && helix_audio_set_pan(voice, -1));
    helix_audio_generate(out, 8); CHECK(NEAR(out[4], .2f) && out[8] == 0 && !helix_audio_is_playing(voice));
    /* Pan and volume ramp across a block, from where the last ended. */
    float half[64]; for (int i = 0; i < 64; i++) half[i] = .5f;
    const int halves = helix_audio_clip(half, 64, 1); CHECK(halves > 0);
    voice = helix_audio_play_clip(halves, 1, 1); helix_audio_set_pan(voice, -1); helix_audio_generate(out, 8);
    for (int i = 0; i < 8; i++) CHECK(NEAR(out[2 * i], .5f) && NEAR(out[2 * i + 1], 0));
    helix_audio_set_pan(voice, 0); helix_audio_generate(out, 8);
    CHECK(NEAR(out[14], .5f * cosf(QUARTER)) && NEAR(out[15], out[14])); /* The middle by equal power, by the block's end. */
    CHECK(out[1] > 0 && out[1] < out[15]);                                /* Ramped across it. */
    helix_audio_set_pan(voice, -1); helix_audio_generate(out, 8);
    helix_audio_set_volume(voice, .5f); helix_audio_generate(out, 4);
    CHECK(NEAR(out[0], .5f * .875f) && NEAR(out[6], .25f));               /* Volume ramps linearly. */
    CHECK(!helix_audio_set_pitch(voice, 8) && !helix_audio_set_pan(voice, 2) && !helix_audio_set_volume(voice, -1)); /* Out of range: refused. */
    /* Paused: silent and still playing; resumed: heard again. */
    helix_audio_pause(voice, 1); helix_audio_generate(out, 8); CHECK(out[0] == 0 && helix_audio_is_playing(voice));
    helix_audio_pause(voice, 0); helix_audio_generate(out, 8); CHECK(out[0] != 0);
    helix_audio_stop(voice);
    /* Pitch 2 plays a clip in half the frames. */
    float longer[4410]; for (int i = 0; i < 4410; i++) longer[i] = .5f;
    const int tenth = helix_audio_clip(longer, 4410, 1);
    for (int pitch = 1; pitch <= 2; pitch++) {
        voice = helix_audio_play_clip(tenth, 0, 1); CHECK(helix_audio_set_pitch(voice, (float)pitch));
        const int count = heard(voice, 44100);
        CHECK(abs(count - 4410 / pitch) < 64 && !helix_audio_is_playing(voice));
    }
    /* A clip's position: how far it has played, moved while playing, and past the end ending it. */
    voice = helix_audio_play_clip(tenth, 0, 1); render(2205, NULL);
    CHECK(fabs(helix_audio_position(voice) - .05) < .002);
    CHECK(helix_audio_set_position(voice, .08) && fabs(helix_audio_position(voice) - .08) < .002);
    render(441, NULL); CHECK(fabs(helix_audio_position(voice) - .09) < .002);
    CHECK(!helix_audio_set_position(voice, -1) && helix_audio_set_position(voice, 1) && !helix_audio_is_playing(voice));
    CHECK(helix_audio_position(voice) == 0 && !helix_audio_set_position(voice, 0));
    /* A looping clip's position wraps. */
    voice = helix_audio_play_clip(tenth, 1, 1); render(4410 + 2205, NULL);
    CHECK(fabs(helix_audio_position(voice) - .05) < .002);
    helix_audio_stop(voice);
    /* A stereo clip: each side its own channel in the middle; toward a side, the far channel mixed into the near one. */
    float pair[128]; for (int i = 0; i < 64; i++) { pair[2 * i] = .5f; pair[2 * i + 1] = -.25f; }
    const int stereo = helix_audio_clip(pair, 64, 2); CHECK(stereo > 0 && helix_audio_clip(pair, 64, 3) == 0);
    voice = helix_audio_play_clip(stereo, 1, 1); helix_audio_generate(out, 8);
    CHECK(NEAR(out[0], .5f) && NEAR(out[1], -.25f) && NEAR(out[14], .5f) && NEAR(out[15], -.25f));
    helix_audio_stop(voice);
    voice = helix_audio_play_clip(stereo, 1, 1); helix_audio_set_pan(voice, -1); helix_audio_generate(out, 8);
    CHECK(NEAR(out[0], .25f) && NEAR(out[1], 0)); helix_audio_stop(voice);
    voice = helix_audio_play_clip(stereo, 1, 1); helix_audio_set_pan(voice, 1); helix_audio_generate(out, 8);
    CHECK(NEAR(out[0], 0) && NEAR(out[1], .25f));
    helix_audio_set_pan(voice, .5f); helix_audio_generate(out, 8);
    CHECK(NEAR(out[14], .5f * cosf(QUARTER)) && NEAR(out[15], -.25f + .5f * sinf(QUARTER)));
    helix_audio_stop(voice); helix_audio_feed();
    CHECK(helix_audio_dispose_clip(stereo) == 1);
    /* Disposing a clip stops its voices. */
    voice = helix_audio_play_clip(halves, 1, 1); CHECK(helix_audio_dispose_clip(halves) == 1 && !helix_audio_is_playing(voice) && helix_audio_dispose_clip(halves) == 0);

    /* A stream from a file plays the whole of it once. */
    int length; unsigned char *file = wav(22050, .5f, &length);
    const char *path = "build/native-tests/native_sdl3mixer_audio.wav";
    write_file(path, file, length);
    CHECK(helix_audio_check_file(path) && !helix_audio_check_file("build/native-tests/missing.wav"));
    CHECK(fabs(helix_audio_file_duration(path) - .5) < 1e-6 && helix_audio_file_duration("build/native-tests/missing.wav") == 0);
    voice = helix_audio_play_file(path, 0, 1); CHECK(voice > 0);
    int count = heard(voice, 44100 * 2); CHECK(abs(count - 22050) < 64 && !helix_audio_is_playing(voice));
    /* Looping: still playing after twice its length. */
    voice = helix_audio_play_file(path, 1, 1);
    count = heard(voice, 44100); CHECK(count > 44100 - 2000 && helix_audio_is_playing(voice));
    helix_audio_stop(voice); helix_audio_feed();
    /* A stream's position: how far its track has taken it, moved, wrapping when it loops, and past the end ending it. */
    voice = helix_audio_play_file(path, 1, 1); render(735 * 15, NULL);
    CHECK(fabs(helix_audio_position(voice) - .25) < .01);
    CHECK(helix_audio_set_position(voice, .4) && fabs(helix_audio_position(voice) - .4) < .01);
    render(735 * 9, NULL); CHECK(fabs(helix_audio_position(voice) - .05) < .01); /* .4 + .15, wrapped at .5. */
    helix_audio_pause(voice, 1); render(735 * 6, NULL); CHECK(fabs(helix_audio_position(voice) - .05) < .01);
    CHECK(helix_audio_set_position(voice, .2) && fabs(helix_audio_position(voice) - .2) < .01);
    helix_audio_pause(voice, 0); render(735 * 3, NULL); CHECK(fabs(helix_audio_position(voice) - .25) < .01);
    helix_audio_stop(voice);
    voice = helix_audio_play_file(path, 0, 1); render(735, NULL);
    CHECK(helix_audio_set_position(voice, 2) && !helix_audio_is_playing(voice));
    helix_audio_feed();
    /* A stereo file streams in stereo, its pan a balance. */
    const char *pair_path = "build/native-tests/native_sdl3mixer_audio_stereo.wav";
    free(file); file = wav_of(22050, 1, .5f, -.5f, &length); write_file(pair_path, file, length);
    CHECK(fabs(helix_audio_file_duration(pair_path) - .5) < 1e-6);
    voice = helix_audio_play_file(pair_path, 0, 1); float last[2]; render(735 * 4, last);
    CHECK(fabs(last[0] - .5f) < 1e-3 && fabs(last[1] + .5f) < 1e-3);
    helix_audio_set_pan(voice, 1); render(735 * 2, last); CHECK(fabs(last[0]) < 1e-3 && fabs(last[1]) < 1e-3); /* -.5 + .5 */
    helix_audio_stop(voice); helix_audio_feed();
    SDL_RemovePath(pair_path);
    /* A download arriving at twice the rate it plays: opened at 16 KiB, sounding before its last byte, played whole. */
    free(file); file = wav(44100 * 2, .5f, &length);
    int download = helix_audio_download(length), arrived = 0, sounding = -1, frame = 0;
    CHECK(download > 0 && !helix_audio_check_download(download));
    voice = 0;
    count = 0;
    for (; frame < 60 * 10; frame++) {
        const int part = arrived + 2940 * 2 > length ? length - arrived : 2940 * 2;
        if (part > 0) { CHECK(helix_audio_download_add(download, file + arrived, part)); arrived += part; if (arrived == length) helix_audio_download_end(download); }
        if (!voice && arrived >= 16 * 1024) { CHECK(helix_audio_check_download(download)); voice = helix_audio_play_download(download, 0, 1); CHECK(voice > 0); }
        helix_audio_feed();
        static float block[735 * 2];
        helix_audio_generate(block, 735);
        for (int i = 0; i < 735; i++) if (block[2 * i] != 0) { count++; if (sounding < 0) sounding = frame; }
        if (voice && !helix_audio_is_playing(voice)) break;
        if (arrived < length) CHECK(helix_audio_download_duration(download) == 0); /* Unknown until it has all arrived. */
    }
    CHECK(!helix_audio_download_add(download, file, 1));
    CHECK(fabs(helix_audio_download_duration(download) - 2) < 1e-6);
    CHECK(sounding >= 0 && sounding * 2940 * 2 < length && abs(count - 44100 * 2) < 64);
    helix_audio_download_release(download);
    /* A download that stops: what arrived plays, then the voice ends. */
    download = helix_audio_download(length);
    CHECK(helix_audio_download_add(download, file, 44 + 44100)); helix_audio_download_end(download);
    voice = helix_audio_play_download(download, 0, 1); helix_audio_download_release(download);
    count = heard(voice, 44100 * 3); CHECK(abs(count - 22050) < 64 && !helix_audio_is_playing(voice));
    free(file);
    SDL_RemovePath(path);

    /* A queue fed half a second plays it at its own rate, the frames queued falling; dry, it plays on silent and resumes when fed. */
    const int queue = helix_audio_queue(2, 22050); CHECK(queue > 0 && !helix_audio_queue(3, 22050) && !helix_audio_queue(1, 100));
    static float fed[11025 * 2]; for (int i = 0; i < 11025; i++) { fed[2 * i] = .5f; fed[2 * i + 1] = .25f; }
    CHECK(helix_audio_queue_samples(queue, fed, (int)sizeof fed) && helix_audio_queued_frames(queue) == 11025);
    CHECK(!helix_audio_queue_samples(0, fed, 8) && helix_audio_queued_frames(0) == -1 && helix_audio_play_queue(0, 1) == -1);
    voice = helix_audio_play_queue(queue, 1); CHECK(voice > 0);
    render(735 * 15, last);
    int queued = helix_audio_queued_frames(queue);
    CHECK(abs(queued - 5512) < 600 && fabs(last[0] - .5f) < 1e-3 && fabs(last[1] - .25f) < 1e-3);
    CHECK(fabs(helix_audio_position(voice) - .25) < .03 && !helix_audio_set_position(voice, 0));
    render(735 * 30, last);
    CHECK(helix_audio_queued_frames(queue) == 0 && helix_audio_is_playing(voice) && last[0] == 0 && fabs(helix_audio_position(voice) - .5) < 1e-6);
    CHECK(helix_audio_queue_samples(queue, fed, (int)sizeof fed)); render(735 * 2, last);
    CHECK(fabs(last[0] - .5f) < 1e-3 && helix_audio_queued_frames(queue) < 11025);
    /* Played again: the earlier voice ends, the samples kept; stopped: what was queued is dropped. */
    queued = helix_audio_queued_frames(queue);
    const int again = helix_audio_play_queue(queue, 1);
    CHECK(again > 0 && !helix_audio_is_playing(voice) && helix_audio_queued_frames(queue) == queued && helix_audio_position(again) == 0);
    helix_audio_stop(again); CHECK(helix_audio_queued_frames(queue) == 0 && !helix_audio_is_playing(again));
    voice = helix_audio_play_queue(queue, 1);
    CHECK(helix_audio_dispose_queue(queue) == 1 && !helix_audio_is_playing(voice) && helix_audio_dispose_queue(queue) == 0);
    helix_audio_feed();

    /* The device's thread mixes while the main one plays, changes and stops voices. */
    SDL_Thread *thread = SDL_CreateThread(render_thread, "render", NULL); CHECK(thread != NULL);
    for (int i = 0; i < 2000; i++) {
        const int id = helix_audio_play_clip(clip, 1, .5f);
        helix_audio_set_volume(id, (float)(i % 10) / 10); helix_audio_set_pan(id, (float)(i % 3) - 1);
        if (i % 2) helix_audio_stop(id);
        helix_audio_feed();
    }
    racing = 0; SDL_WaitThread(thread, NULL);
    CHECK(helix_audio_dispose_clip(clip) == 1 && helix_audio_play_clip(clip, 0, .5f) == -1);
    helix_audio_close(); CHECK(!helix_audio_is_open() && helix_audio_play_clip(tenth, 0, 1) == -1);
    printf("{\"passed\":true,\"checks\":%d,\"audio\":\"The SDL3_mixer output rendered with no device: clips, voices, pan, pitch, ramps, stereo balance, positions read and moved, lengths, streams from a file and a download, looping, queues, a racing render thread; no audible-output claim\"}\n", checks);
    return 0;
}
