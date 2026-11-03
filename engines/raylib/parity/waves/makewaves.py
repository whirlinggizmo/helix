"""Writes the waves suite's sound files into the directory its command line names, from one tone (two sines and a little noise, made
the same each run): WAV at 22050 Hz in 8 bits mono and 24 bits stereo (Python's wave module), Ogg Vorbis at 48000 Hz mono and 44100 Hz
stereo, MP3 at 32000 Hz with its LAME tag and without, and FLAC (ffmpeg), and QOA (raylib 5.5's qoa.h, compiled with cc). The files are
kept in the repository beside this script, as the harness compiles them in; this is how they were made.

    python3 makewaves.py OUT_DIR RAYLIB_SRC"""
import math
import struct
import subprocess
import sys
import tempfile
import wave
from pathlib import Path

out, raylib = Path(sys.argv[1]), Path(sys.argv[2])
out.mkdir(parents=True, exist_ok=True)


def tone(rate, seconds, channels):
    """Interleaved samples in -1..1: 440 Hz and 1250 Hz sines, the right channel a fifth up, and a little noise from an LCG; faded out
    over 5 ms and then 20 ms of silence, as a sound file usually ends (Chromium's Vorbis decoder ends a stream early, measured by tens of
    frames, where helix-raylib gives silence)."""
    seed, samples, frames = 12345, [], int(rate * seconds)
    for i in range(frames):
        t = i / rate
        gain = max(0.0, min(1.0, (frames - rate * 0.02 - i) / (rate * 0.005)))
        for c in range(channels):
            seed = (seed * 1103515245 + 12345) & 0x7FFFFFFF
            f = 440 * (1.5 if c else 1)
            samples.append(gain * (0.45 * math.sin(2 * math.pi * f * t) + 0.25 * math.sin(2 * math.pi * 1250 * t) + 0.02 * (seed / 0x7FFFFFFF - 0.5)))
    return samples


def write_wav(path, rate, channels, width, samples):
    with wave.open(str(path), 'wb') as w:
        w.setnchannels(channels)
        w.setsampwidth(width)
        w.setframerate(rate)
        if width == 1:
            w.writeframes(bytes(max(0, min(255, round(128 + s * 127))) for s in samples))
        else:
            scale = (1 << (8 * width - 1)) - 1
            w.writeframes(b''.join(struct.pack('<i', round(s * scale))[:width] for s in samples))


write_wav(out / 'tone22_u8.wav', 22050, 1, 1, tone(22050, 0.1, 1))
write_wav(out / 'tone22_s24.wav', 22050, 2, 3, tone(22050, 0.1, 2))
with tempfile.TemporaryDirectory() as tmp:
    tmp = Path(tmp)
    for name, rate, channels in (('m48', 48000, 1), ('s44', 44100, 2), ('m32', 32000, 1), ('s32', 32000, 2)):
        write_wav(tmp / f'{name}.wav', rate, channels, 2, tone(rate, 0.25, channels))

    def ffmpeg(source, target, *codec):
        subprocess.run(['ffmpeg', '-v', 'error', '-y', '-i', str(tmp / source), '-map_metadata', '-1', '-fflags', '+bitexact', *codec, str(out / target)], check=True)

    ffmpeg('m48.wav', 'tone48_mono.ogg', '-c:a', 'libvorbis', '-q:a', '2')
    ffmpeg('s44.wav', 'tone44_stereo.ogg', '-c:a', 'libvorbis', '-q:a', '2')
    ffmpeg('s32.wav', 'tone32_lame.mp3', '-c:a', 'libmp3lame', '-b:a', '64k', '-id3v2_version', '0')
    ffmpeg('m32.wav', 'tone32_plain.mp3', '-c:a', 'libmp3lame', '-b:a', '48k', '-id3v2_version', '0', '-write_xing', '0')
    ffmpeg('m48.wav', 'tone48.flac', '-t', '0.02', '-c:a', 'flac')
    # QOA: qoa.h's encoder over 44100 Hz stereo 16-bit samples.
    write_wav(tmp / 'q.wav', 44100, 2, 2, tone(44100, 0.2, 2))
    with wave.open(str(tmp / 'q.wav'), 'rb') as w:
        (tmp / 'q.raw').write_bytes(w.readframes(w.getnframes()))
    (tmp / 'qoa.c').write_text('''#define QOA_IMPLEMENTATION
#include "external/qoa.h"
#include <stdio.h>
int main(int argc, char **argv) {
    static short samples[44100 * 2];
    FILE *f = fopen(argv[1], "rb");
    unsigned int n = (unsigned int)fread(samples, 2, 44100 * 2, f);
    fclose(f);
    qoa_desc q = {.channels = 2, .samplerate = 44100, .samples = n / 2};
    return qoa_write(argv[2], samples, &q) ? 0 : 1;
}
''')
    subprocess.run(['cc', '-O2', '-I', str(raylib), str(tmp / 'qoa.c'), '-o', str(tmp / 'qoa')], check=True)
    subprocess.run([str(tmp / 'qoa'), str(tmp / 'q.raw'), str(out / 'tone44_stereo.qoa')], check=True)
