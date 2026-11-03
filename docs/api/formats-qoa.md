# helix.formats.qoa

[Back to the index](README.md)

## QoaFile

*class* in [`libs/formats/src/helix/formats/qoa/QoaFile.hx`](../../libs/formats/src/helix/formats/qoa/QoaFile.hx), `import helix.formats.qoa.QoaFile;`

Represents the sound read from a QOA file ("Quite OK Audio"): its rate, channels and 16-bit samples.

Reading is qoa.h's `qoa_decode` (raylib 5.5's copy), ported, so its samples are those raylib's `LoadWave` gives, bit for bit. A file whose frames end early, or stop being valid, gives the frames read until then, as qoa.h does. A streamed file (its frame count 0) isn't read, as qoa.h doesn't read one.

```haxe
var qoa = QoaFile.read(bytes);
trace(qoa.sampleRate, qoa.channelCount, qoa.frameCount / qoa.sampleRate);
var samples = qoa.samples; // raylib's Wave: sampleSize 16
```

```haxe
static function read(data:haxe.io.Bytes):QoaFile
final sampleRate:Int
final channelCount:Int
final frameCount:Int
final samples:haxe.io.Bytes
```

- `read`: Reads a QOA file.
  - `data`: The file.
  - returns: The sound.
  - throws `String`: It isn't a QOA file qoa.h reads: it is under 16 bytes, its magic is wrong, or its frame count, channels or rate is 0.
- `sampleRate`: Gets the frames a second, 1 to 16777215.
- `channelCount`: Gets the number of channels a frame has, 1 to 255: 1 is mono, 2 stereo.
- `frameCount`: Gets the frames read, a sample for each channel.
- `samples`: Gets the samples: `frameCount` frames, each a sample for each channel in turn, 16-bit signed and little-endian.
