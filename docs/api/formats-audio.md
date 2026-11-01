# helix.formats.audio

[Back to the index](README.md)

## AudioHeader

*class* in [`formats/src/helix/formats/audio/AudioHeader.hx`](../../formats/src/helix/formats/audio/AudioHeader.hx), `import helix.formats.audio.AudioHeader;`

Provides reading a sound file's length and channels from its first bytes, and for some kinds its last, without decoding it.

It reads WAV, Ogg (Vorbis, Opus, FLAC and Speex), FLAC and MP3 (MPEG audio layers I to III). Given the whole file, it reads the start alone; given part of it, the first 64 KiB is enough for all but an MP3 whose tags are larger, and Ogg's length needs the last bytes too, where the last page is.

```haxe
var seconds = AudioHeader.readDuration(first64k, last64k, fileSize);
var channels = AudioHeader.readChannelCount(first64k);
```

```haxe
static function readDuration(start:haxe.io.Bytes, ?end:haxe.io.Bytes, size:Int):Float
static function readChannelCount(start:haxe.io.Bytes):Int
```

- `readDuration`: Returns a sound file's length in seconds.
  - `start`: The file's first bytes, as many as there are or as are read; 64 KiB is enough for most files.
  - `end`: Optional. The file's last bytes, up to 64 KiB; Ogg needs them, MP3 reads an ID3v1 tag from them. When omitted and `start` is the whole file, `start` is read for both.
  - `size`: The file's size, in bytes.
  - returns: The length, in seconds, or 0 when it can't tell: an unknown kind, too few bytes, or a file that doesn't record it.

  WAV: the data chunk's frames over the rate; for a compressed encoding, the `fact` chunk's frames, or the data's size over its bytes a second. A data chunk whose size is 0 or 0xFFFFFFFF, as a streamed file leaves it, runs to the file's end. Ogg: the last page's position over the rate, less Opus's pre-skip; the first stream's pages alone are read, each checked by its CRC. FLAC: STREAMINFO's frames over its rate; 0 when it doesn't record them. MP3: ID3v2 tags are skipped; the frames a Xing, Info or VBRI header records; otherwise an estimate, the bytes after the tags (and before an ID3v1 tag, when `end` is provided) over the first frame's bitrate, exact for a file of one bitrate and off for one whose bitrate varies.
- `readChannelCount`: Returns how many channels a sound file has.
  - `start`: The file's first bytes, as many as there are or as are read; 64 KiB is enough for most files.
  - returns: The channels, or 0 when it can't tell: an unknown kind or too few bytes.

  WAV: its `fmt ` chunk's. Ogg: the first stream's header's. FLAC: STREAMINFO's. MP3: the first frame's mode, 1 for mono and 2 otherwise.
