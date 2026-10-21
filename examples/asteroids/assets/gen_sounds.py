"""Asteroids' eight original sounds, synthesized and encoded as Ogg/Vorbis into audio/sfx/ beside this file, where they're committed (DECISIONS 117):
made only when one is missing (tools/example.py runs it before copying the example's assets), or anew with --regenerate, which needs FFmpeg."""
import array
import math
from pathlib import Path
import random
import shutil
import subprocess
import sys
import wave

ROOT=Path(__file__).resolve().parents[3]
NAMES=['start','fire','bang_large','bang_medium','bang_small','extra_life','game_over','thrust-v4']

def thrust_loop(rate,frames):
    """Periodic filtered noise with audible midrange and supporting motor tones."""
    overlap=round(.04*rate)
    rng=random.Random(737);noise=[rng.uniform(-1,1) for _ in range(frames+overlap)]
    def smooth(span):
        # Circular windows keep the loop seam an ordinary adjacent-sample step.
        total=sum(noise[-span:]);result=[]
        for i in range(len(noise)):
            total+=noise[i]-noise[(i-span)%len(noise)];result.append(total/span)
        return result
    short,body,low,rumble=[smooth(span) for span in [10,39,118,235]]
    filtered=[1.5*(short[i]-low[i])+.6*(body[i]-rumble[i]) for i in range(len(noise))]
    # Equal-power head/tail blend avoids a level dip in this uncorrelated noise.
    loop=filtered[overlap:]
    for i in range(overlap):
        angle=(i/(overlap-1))*math.pi/2
        loop[frames-overlap+i]=loop[frames-overlap+i]*math.cos(angle)+filtered[i]*math.sin(angle)
    # Integer-cycle tones stay continuous over two seconds. No repeating gain pulse.
    return [loop[i]+.25*math.sin(2*math.pi*133*i/rate)+
            .15*math.sin(2*math.pi*266*i/rate) for i in range(frames)]

def generate(regenerate=False):
    """Writes the sounds as Ogg/Vorbis into audio/sfx/ beside this file when any is missing (or regenerate), the WAV sources under
    build/generated/asteroids/wav, and returns the example's assets directory."""
    out=Path(__file__).resolve().parent;sounds=out/'audio/sfx';source=ROOT/'build/generated/asteroids/wav'
    if not regenerate and all((sounds/(name+'.ogg')).is_file() for name in NAMES):return out
    sounds.mkdir(parents=True,exist_ok=True);source.mkdir(parents=True,exist_ok=True)
    encoder=shutil.which('ffmpeg')
    if not encoder:raise RuntimeError('Install FFmpeg with the libvorbis encoder to make the Asteroids sounds')
    lengths=[.28,.12,.42,.27,.16,.42,.65,2.0]
    for kind,name in enumerate(NAMES):
        rate=44100;n=round(rate*lengths[kind]);data=array.array('h');rng=random.Random(730+kind)
        engine=thrust_loop(rate,n) if name=='thrust-v4' else None
        for i in range(n):
            t=i/rate;p=i/n
            if name=='fire':sample=math.sin(2*math.pi*(1000*t-2400*t*t))*(1-p)**2
            elif name.startswith('bang_'):sample=(rng.uniform(-1,1)*.65+math.sin(2*math.pi*(45+kind*25)*t)*.35)*(1-p)**3
            elif engine is not None:sample=engine[i]
            else:
                note=int(p*4);freq=([262,330,392,523] if name=='start' else [523,659,784,1047] if name=='extra_life' else [392,330,262,196])[min(note,3)]
                sample=math.sin(2*math.pi*freq*t)*min(1,t*80)*(1-p)
            data.append(round(max(-1,min(1,sample))*.35*32767))
        if sys.byteorder!='little':data.byteswap()
        with wave.open(str(source/(name+'.wav')),'wb') as wav:
            wav.setnchannels(1);wav.setsampwidth(2);wav.setframerate(rate);wav.writeframes(data.tobytes())
        subprocess.run([encoder,'-v','error','-y','-bitexact','-i',str(source/(name+'.wav')),'-map_metadata','-1','-c:a','libvorbis','-q:a','3','-fflags','+bitexact',str(sounds/(name+'.ogg'))],check=True)
    return out

if __name__=='__main__':print(generate('--regenerate' in sys.argv[1:]))
