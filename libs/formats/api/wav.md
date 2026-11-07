# helix.formats.wav

[Back to the library](README.md)

## WavEncoding

*abstract* in [`libs/formats/src/helix/formats/wav/WavEncoding.hx`](../src/helix/formats/wav/WavEncoding.hx), `import helix.formats.wav.WavEncoding;`

Specifies how a WAV file's samples are stored.

- `WavEncoding.Pcm`: Integers: 8 bits unsigned, centered on 128; 16, 24, 32 or more bits signed.
- `WavEncoding.FloatingPoint`: IEEE floating point, 32 or 64 bits, from -1 to 1.
- `WavEncoding.ALaw`: G.711 A-law, a byte a sample.
- `WavEncoding.MuLaw`: G.711 mu-law, a byte a sample.

## WavFile

*class* in [`libs/formats/src/helix/formats/wav/WavFile.hx`](../src/helix/formats/wav/WavFile.hx), `import helix.formats.wav.WavFile;`

Represents the sound read from a WAV file: its rate, channels, sample size and samples; and provides writing one.

Reading is dr_wav 0.13.16's (raylib 5.5's copy), ported: a RIFF WAVE file of integer, floating-point, A-law or mu-law samples, its format given plainly or as `WAVE_FORMAT_EXTENSIBLE`. Chunks before the samples that it doesn't need are skipped; those after them are never read. `toInt16` converts the samples as raylib's `LoadWave` does, and `toFloat32` as its music streams of 32-bit files do. Writing is raylib's `ExportWave`, byte for byte.

```haxe
var wav = WavFile.read(bytes);
trace(wav.sampleRate, wav.channelCount, wav.frameCount / wav.sampleRate);
var samples = wav.toInt16(); // raylib's Wave: sampleSize 16
var file = WavFile.write(wav.sampleRate, wav.channelCount, 16, wav.frameCount, samples);
```

```haxe
static function read(data:haxe.io.Bytes):WavFile
static function write(sampleRate:Int, channelCount:Int, sampleSize:Int, frameCount:Int, samples:haxe.io.Bytes):haxe.io.Bytes
final sampleRate:Int
final channelCount:Int
final sampleSize:Int
final encoding:WavEncoding
final frameCount:Int
final samples:haxe.io.Bytes
function toInt16():haxe.io.Bytes
function toFloat32():haxe.io.Bytes
```

- `read`: Reads a WAV file.
  - `data`: The file.
  - returns: The sound, its samples as the file stores them.
  - throws `String`: It isn't a WAV file this reads: it has no RIFF WAVE header (RIFX, RF64, Wave64 and AIFF aren't read), no format or data chunk, a format out of range, or samples stored some other way (ADPCM and compressed encodings aren't read).

  The frames are those whole in the data chunk; a data chunk whose size is 0 or 0xFFFFFFFF, as a streamed file leaves it, runs to the file's end, and one larger than the file stops at its end. A `fact` chunk is skipped, as dr_wav skips it for these encodings.
- `write`: Writes samples as a WAV file, byte for byte as raylib's `ExportWave` writes a `Wave` (dr_wav's writer).
  - `sampleRate`: The frames a second.
  - `channelCount`: The channels a frame has.
  - `sampleSize`: The bits a sample takes: 8, 16, 24 or 32.
  - `frameCount`: The frames to write, a sample for each channel.
  - `samples`: The samples, a sample for each channel in turn, `sampleSize / 8` bytes each, little-endian.
  - returns: The WAV file.
  - throws `String`: The rate is under 1, the channels are outside 1 to 65535, the sample size isn't 8, 16, 24 or 32, the frame count is negative, or there are fewer samples than it needs.

  8, 16 and 24 bits are integer samples (format 1, 8 bits unsigned), and 32 bits floating point (format 3), as raylib's `Wave` takes them. The file is a 16-byte format chunk and the data chunk, padded to an even size; it has no `fact` chunk. Bytes past the samples are ignored.
- `sampleRate`: Gets the frames a second, 1 to 384000.
- `channelCount`: Gets the number of channels a frame has, 1 to 256: 1 is mono, 2 stereo.
- `sampleSize`: Gets the bits a sample takes in `samples`: 8, 16, 24, 32 or more for `Pcm`, 32 or 64 for `FloatingPoint`, 8 for `ALaw` and `MuLaw`. A file whose samples have bits not a multiple of 8 (12 in 16, say) gives the size they are stored in.
- `encoding`: Gets how the samples are stored.
- `frameCount`: Gets the frames, a sample for each channel.
- `samples`: Gets the samples as the file stores them: `frameCount` frames, each a sample for each channel in turn, each `sampleSize / 8` bytes, little-endian.
- `toInt16`: Returns the samples as 16-bit signed integers, as raylib's `LoadWave` gives a WAV file's (dr_wav's `drwav_read_pcm_frames_s16`).
  - returns: `frameCount` frames, a sample for each channel in turn, 2 bytes each, little-endian.

  8-bit samples are moved to signed and widened; wider integers keep their top 16 bits; floating point is clamped to -1 to 1 and scaled to -32768 to 32767; A-law and mu-law are expanded by G.711's tables.
- `toFloat32`: Returns the samples as 32-bit floating point, -1 to 1, as raylib's music streams read a 32-bit WAV file (dr_wav's `drwav_read_pcm_frames_f32`).
  - returns: `frameCount` frames, a sample for each channel in turn, 4 bytes each, little-endian.

  Integers are divided by their range (8-bit samples by 127.5, after moving to signed); A-law and mu-law are expanded to 16 bits first; 64-bit floating point is rounded to 32 bits.
