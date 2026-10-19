"""The audio example's second track, the one it crossfades to: a 16 s pad loop (C, A minor, F, G, 4 s each), synthesized and encoded as
Ogg/Vorbis into audio/music/ beside this file, where it's committed (DECISIONS 117): made only when it's missing (tools/example.py runs it
before copying the example's assets), or anew with --regenerate, which needs FFmpeg. Mono, so a pan is heard plainly."""
import array
import math
from pathlib import Path
import shutil
import subprocess
import sys
import wave

ROOT=Path(__file__).resolve().parents[3]
RATE=44100
# Each chord's notes in Hz, 4 s apiece: C major, A minor, F major, G major, around middle C.
CHORDS=[[130.81,261.63,329.63,392.00],[110.00,220.00,261.63,329.63],[87.31,174.61,220.00,261.63],[98.00,196.00,246.94,293.66]]

def pad():
    """The loop's samples, -1 to 1: each chord a few detuned sines under a raised-cosine swell that overlaps its neighbours by a second, wrapped
    around the end so the loop's seam is like any other change of chord."""
    span=4*RATE;frames=span*len(CHORDS);overlap=RATE;out=[0.]*frames
    for c,notes in enumerate(CHORDS):
        start=c*span-overlap//2;length=span+overlap
        for i in range(length):
            # Up over the overlap, held, down over the overlap.
            edge=min(i,length-1-i)/overlap
            gain=1. if edge>=1 else math.sin(edge*math.pi/2)**2
            t=i/RATE;s=0.
            for k,f in enumerate(notes):
                s+=(math.sin(2*math.pi*f*t)+.5*math.sin(2*math.pi*f*1.003*t)+.25*math.sin(2*math.pi*2*f*.998*t))/(1+.4*k)
            out[(start+i)%frames]+=gain*s
    peak=max(abs(v) for v in out)
    return [v/peak for v in out]

def generate(regenerate=False):
    """Writes audio/music/pad_loop.ogg beside this file when it's missing (or regenerate), its WAV source under build/generated/audio-music,
    and returns the example's assets folder."""
    out=Path(__file__).resolve().parent;music=out/'audio/music';source=ROOT/'build/generated/audio-music'
    if not regenerate and (music/'pad_loop.ogg').is_file():return out
    encoder=shutil.which('ffmpeg')
    if not encoder:raise RuntimeError('Install FFmpeg with the libvorbis encoder to make the audio example\'s pad loop')
    music.mkdir(parents=True,exist_ok=True);source.mkdir(parents=True,exist_ok=True)
    data=array.array('h',(round(v*.5*32767) for v in pad()))
    if sys.byteorder!='little':data.byteswap()
    with wave.open(str(source/'pad_loop.wav'),'wb') as wav:
        wav.setnchannels(1);wav.setsampwidth(2);wav.setframerate(RATE);wav.writeframes(data.tobytes())
    subprocess.run([encoder,'-v','error','-y','-bitexact','-i',str(source/'pad_loop.wav'),'-map_metadata','-1','-c:a','libvorbis','-q:a','3','-fflags','+bitexact',str(music/'pad_loop.ogg')],check=True)
    return out

if __name__=='__main__':print(generate('--regenerate' in sys.argv[1:]))
