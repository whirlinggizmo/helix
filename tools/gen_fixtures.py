"""The test fixtures: a short tone as WAV, Ogg/Vorbis and Ogg/Opus, in tests/fixtures (the unit and services tests read them), and
encoder.json beside them, how they were encoded (the services report includes it); and stream.ogg, ten seconds of a tone in noise as Vorbis,
long enough (about 110 KiB) for the streaming test (tests/streaming) to play it while it downloads. They're committed, so every system decodes
the same bytes and no build needs FFmpeg (DECISIONS 117); generate() makes them only when one is missing, and --regenerate makes them anew
(both need FFmpeg).

The WAV is 16-bit mono 44,100 Hz, 0.12 s; the Opus copy is stereo 48 kHz, to exercise channel and rate handling. FFmpeg encodes them, bit-exact."""
import array
import json
import math
from pathlib import Path
import random
import shutil
import subprocess
import sys
import tempfile
import wave

ROOT=Path(__file__).resolve().parents[1]
OUT=ROOT/'tests/fixtures'

def generate(regenerate=False):
    """Writes tone.wav, tone.ogg, tone.opus and encoder.json when any is missing (or regenerate), stream.ogg when it's missing (or
    regenerate), and returns their folder."""
    if regenerate or not (OUT/'stream.ogg').is_file():stream()
    if not regenerate and all((OUT/name).is_file() for name in ('tone.wav','tone.ogg','tone.opus','encoder.json')):return OUT
    encoder=shutil.which('ffmpeg')
    if not encoder:raise RuntimeError('Install FFmpeg with the libvorbis and libopus encoders to make the test fixtures')
    OUT.mkdir(parents=True,exist_ok=True)
    rate=44100;n=round(rate*.12);data=array.array('h')
    for i in range(n):
        t=i/rate;data.append(round(math.sin(2*math.pi*(1000*t-2400*t*t))*(1-i/n)**2*.35*32767))
    if sys.byteorder!='little':data.byteswap()
    with wave.open(str(OUT/'tone.wav'),'wb') as wav:
        wav.setnchannels(1);wav.setsampwidth(2);wav.setframerate(rate);wav.writeframes(data.tobytes())
    common=[encoder,'-v','error','-y','-bitexact','-i',str(OUT/'tone.wav'),'-map_metadata','-1']
    subprocess.run(common+['-c:a','libvorbis','-q:a','3','-fflags','+bitexact',str(OUT/'tone.ogg')],check=True)
    subprocess.run(common+['-ar','48000','-ac','2','-c:a','libopus','-b:a','64000','-fflags','+bitexact',str(OUT/'tone.opus')],check=True)
    version=subprocess.check_output([encoder,'-version'],text=True,encoding='utf-8').splitlines()[0]
    (OUT/'encoder.json').write_text(json.dumps({'version':version,'vorbisQuality':3,'opusFixtureBitrate':64000,
        'deterministicFlags':['-bitexact','-map_metadata -1','-fflags +bitexact']},indent=2)+'\n',encoding='utf-8')
    return OUT

def stream():
    """Writes stream.ogg: ten seconds of 440 Hz in seeded noise, 16-bit mono 44,100 Hz, as Vorbis at quality 5 (the noise keeps it near
    110 KiB, more than the 64 KiB a download opens at)."""
    encoder=shutil.which('ffmpeg')
    if not encoder:raise RuntimeError('Install FFmpeg with the libvorbis encoder to make the test fixtures')
    OUT.mkdir(parents=True,exist_ok=True)
    rate=44100;noise=random.Random(7);data=array.array('h')
    for i in range(rate*10):
        data.append(round((math.sin(2*math.pi*440*i/rate)*.25+(noise.random()*2-1)*.15)*32767))
    if sys.byteorder!='little':data.byteswap()
    with tempfile.TemporaryDirectory() as folder:
        source=Path(folder)/'stream.wav'
        with wave.open(str(source),'wb') as wav:
            wav.setnchannels(1);wav.setsampwidth(2);wav.setframerate(rate);wav.writeframes(data.tobytes())
        subprocess.run([encoder,'-v','error','-y','-bitexact','-i',str(source),'-map_metadata','-1','-c:a','libvorbis','-q:a','5','-fflags','+bitexact',str(OUT/'stream.ogg')],check=True)

if __name__=='__main__':print(generate('--regenerate' in sys.argv[1:]))
