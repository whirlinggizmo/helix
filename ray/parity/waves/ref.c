// raylib 5.5's waves, printed for tools/ray_parity.py: each file LoadWave reads (WAV, Ogg Vorbis, MP3, QOA) and one it refuses (FLAC),
// its frames, rate, sample size and channels, then its samples 32 a line, each as a double (a 16-bit sample over 32768) printed as
// hxcpp prints one; and a file read by LoadWaveFromMemory under a type in mixed case, which raylib refuses.
#include "raylib.h"
#include <stdio.h>

static void print(const char *name, Wave w) {
    printf("%s wave %u %u %u %u\n", name, w.frameCount, w.sampleRate, w.sampleSize, w.channels);
    if (w.data == NULL) return;
    unsigned int count = w.frameCount * w.channels;
    for (unsigned int i = 0; i < count; i++) {
        double v = w.sampleSize == 32 ? (double)((float *)w.data)[i] : ((short *)w.data)[i] / 32768.0;
        if (i % 32 == 0) printf("%s s", name);
        printf(" %.15g", v);
        if (i % 32 == 31 || i == count - 1) printf("\n");
    }
}

static void load(const char *name, const char *file) {
    Wave w = LoadWave(file);
    print(name, w);
    UnloadWave(w);
}

int main(void) {
    SetTraceLogLevel(LOG_NONE);
    load("wav22_u8", "tone22_u8.wav");
    load("wav22_s24", "tone22_s24.wav");
    load("ogg48_mono", "tone48_mono.ogg");
    load("ogg44_stereo", "tone44_stereo.ogg");
    load("mp3_lame", "tone32_lame.mp3");
    load("mp3_plain", "tone32_plain.mp3");
    load("qoa44_stereo", "tone44_stereo.qoa");
    load("flac48", "tone48.flac");
    int size = 0;
    unsigned char *data = LoadFileData("tone48_mono.ogg", &size);
    Wave mixed = LoadWaveFromMemory(".Ogg", data, size);
    print("ogg_mixed_case", mixed);
    UnloadWave(mixed);
    UnloadFileData(data);
    data = LoadFileData("tone44_stereo.qoa", &size);
    Wave chosen = LoadWaveFromMemory(".qoa", data, size);
    print("qoa_run_time", chosen);
    UnloadWave(chosen);
    UnloadFileData(data);
    return 0;
}
