# raudio: sound

[Back to the library](README.md)


```haxe
static function InitAudioDevice():Void
static function CloseAudioDevice():Void
static function IsAudioDeviceReady():Bool
static function SetMasterVolume(volume:Float):Void
static function GetMasterVolume():Float
static function IsWaveValid(wave:Wave):Bool
static function UnloadWave(wave:Wave):Void
static function WaveCopy(wave:Wave):Wave
static function WaveCrop(wave:Wave, initFrame:Int, finalFrame:Int):Void
static function WaveFormat(wave:Wave, sampleRate:Int, sampleSize:Int, channels:Int):Void
static function LoadWaveSamples(wave:Wave):Array<Float>
static function UnloadWaveSamples(samples:Array<Float>):Void
static function LoadSoundFromWave(wave:Wave):Sound
static function LoadSoundAlias(source:Sound):Sound
static function UnloadSound(sound:Sound):Void
static function UnloadSoundAlias(alias:Sound):Void
static function IsSoundValid(sound:Sound):Bool
static function UpdateSound(sound:Sound, data:haxe.io.Bytes, sampleCount:Int):Void
static function PlaySound(sound:Sound):Void
static function StopSound(sound:Sound):Void
static function PauseSound(sound:Sound):Void
static function ResumeSound(sound:Sound):Void
static function IsSoundPlaying(sound:Sound):Bool
static function SetSoundVolume(sound:Sound, volume:Float):Void
static function SetSoundPitch(sound:Sound, pitch:Float):Void
static function SetSoundPan(sound:Sound, pan:Float):Void
static function LoadMusicStreamFromMemory(fileType:String, data:haxe.io.Bytes, dataSize:Int):Music
static function IsMusicValid(music:Music):Bool
static function UnloadMusicStream(music:Music):Void
static function PlayMusicStream(music:Music):Void
static function IsMusicStreamPlaying(music:Music):Bool
static function UpdateMusicStream(music:Music):Void
static function StopMusicStream(music:Music):Void
static function PauseMusicStream(music:Music):Void
static function ResumeMusicStream(music:Music):Void
static function SeekMusicStream(music:Music, position:Float):Void
static function SetMusicVolume(music:Music, volume:Float):Void
static function SetMusicPitch(music:Music, pitch:Float):Void
static function SetMusicPan(music:Music, pan:Float):Void
static function GetMusicTimeLength(music:Music):Float
static function GetMusicTimePlayed(music:Music):Float
static function LoadAudioStream(sampleRate:Int, sampleSize:Int, channels:Int):AudioStream
static function IsAudioStreamValid(stream:AudioStream):Bool
static function UnloadAudioStream(stream:AudioStream):Void
static function UpdateAudioStream(stream:AudioStream, data:haxe.io.Bytes, frameCount:Int):Void
static function IsAudioStreamProcessed(stream:AudioStream):Bool
static function PlayAudioStream(stream:AudioStream):Void
static function PauseAudioStream(stream:AudioStream):Void
static function ResumeAudioStream(stream:AudioStream):Void
static function IsAudioStreamPlaying(stream:AudioStream):Bool
static function StopAudioStream(stream:AudioStream):Void
static function SetAudioStreamVolume(stream:AudioStream, volume:Float):Void
static function SetAudioStreamPitch(stream:AudioStream, pitch:Float):Void
static function SetAudioStreamPan(stream:AudioStream, pan:Float):Void
static function SetAudioStreamBufferSizeDefault(size:Int):Void
static function SetAudioStreamCallback(stream:AudioStream, callback:Null<(bufferData:haxe.io.Bytes, frames:Int) -> Void>):Void
static macro function ExportWave(wave:Wave, fileName:String):Bool
static macro function ExportWaveAsCode(wave:Wave, fileName:String):Bool
static macro function LoadSound(fileName:String):Sound
static macro function LoadMusicStream(fileName:String):Music
```

- `InitAudioDevice`: Opens the audio output, with helix-services' `Audio` over it.
  Sound may wait to play until a first key press, click or tap.

  Does nothing when the output is already open.
- `CloseAudioDevice`: Closes the audio output, stopping and unloading every sound.
  Does nothing when the output isn't open.
- `IsAudioDeviceReady`: Returns whether the audio output is open.
  - returns: True after `InitAudioDevice`, where the platform has an output.
- `SetMasterVolume`: Sets the volume of every sound.
  - `volume`: 0 (silent) to 1.

  Ignored before `InitAudioDevice`.
- `GetMasterVolume`: Returns the volume of every sound.
  - returns: 0 (silent) to 1, or 1 before `InitAudioDevice`.
- `IsWaveValid`: Returns whether a wave holds samples.
  - `wave`: The wave.
  - returns: True when it has data, frames, a rate, a sample size and channels.
- `UnloadWave`: Frees a wave's samples, leaving its `data` null.
  - `wave`: The wave.
- `WaveCopy`: Returns a copy of a wave, with samples of its own.
  - `wave`: The wave.
  - returns: The copy.
- `WaveCrop`: Crops a wave to a range of its frames, from `initFrame` up to `finalFrame`, not including it.
  - `wave`: The wave, changed in place.
  - `initFrame`: The first frame kept.
  - `finalFrame`: The frame after the last one kept, at most `frameCount`.

  A range outside the wave, or an empty one, changes nothing and logs a warning.
- `WaveFormat`: Converts a wave's samples to another rate, sample size and channel count, as raylib's does through miniaudio.
  - `wave`: The wave, changed in place.
  - `sampleRate`: The frames a second.
  - `sampleSize`: The bits a sample takes: 8, 16 or 32.
  - `channels`: The number of channels.

  The conversion:

  - turns integers to floats and back without dithering. - mixes channels by miniaudio's standard speaker layouts. - changes the rate by miniaudio's linear resampler, low-pass filtered.

  A wave that can't be converted is unchanged, and a warning is logged.
- `LoadWaveSamples`: Returns a wave's samples as numbers from -1 to 1, as raylib's does.
  - `wave`: The wave.
  - returns: `frameCount * channels` samples, interleaved.

  Each sample size maps as:

  - 8-bit: less 128, over 128. - 16-bit: over 32768. - 32-bit: unchanged. - any other size: 0.
- `UnloadWaveSamples`: Frees samples `LoadWaveSamples` returned.
  - `samples`: The samples.

  Does nothing, as there is nothing to free.
- `LoadSoundFromWave`: Returns a sound made from a wave, ready to play at once.
  - `wave`: The wave. It is unchanged, and may be unloaded after.
  - returns: The sound, or one that isn't valid (`IsSoundValid`) when the wave has no samples or can't be converted.

  `InitAudioDevice` must come first.

  The samples are converted to 32-bit floats at 44100 Hz. A wave with 1 or 2 channels keeps them, and one with more is mixed to 2.
- `LoadSoundAlias`: Returns an alias that plays another sound's samples with its own volume, pitch, pan and voice, as raylib's does.
  - `source`: The sound whose samples it plays.
  - returns: The alias, or one that isn't valid when the source isn't loaded.

  Takes no memory for samples of its own. Holds a reference to its source's samples, so it plays on after the source is unloaded; they're freed when the last held reference, a load or an alias, is released.
- `UnloadSound`: Frees a sound, stopping it.
  - `sound`: The sound.

  Releases the sound's reference to its samples; they're freed when the last held reference, a load or an alias, is released:

  - a sound loaded from a file: its load's reference to the file's decoded sound. - a sound made from a wave: its own reference to its samples. - an alias: as `UnloadSoundAlias` releases it.

  Its aliases play on.
- `UnloadSoundAlias`: Frees an alias, stopping it, and releases its reference to its source's samples. They're freed when it held the last.
  - `alias`: The alias.
- `IsSoundValid`: Returns whether a sound is loaded.
  - `sound`: The sound.
  - returns: True once it is decoded or made, until it is unloaded.
- `UpdateSound`: Writes new samples over the start of a sound and stops it, as raylib's does.
  - `sound`: The sound, or one of its aliases.
  - `data`: 32-bit float samples at 44100 Hz in the sound's channels (a wave's channels, when 1 or 2), interleaved.
  - `sampleCount`: How many frames to write, at most the sound's `frameCount`. The frames after them keep their samples; for a sound loaded from a file, whose samples aren't held, they are silent.

  The sound's length is unchanged. Its aliases play the new samples.
- `PlaySound`: Plays a sound from its start, restarting it when it is already playing.
  - `sound`: The sound.

  A sound still decoding starts once decoded, once for each play asked for meanwhile.

  Ignored before `InitAudioDevice`, and once the sound is unloaded.
- `StopSound`: Stops a sound.
  - `sound`: The sound.
- `PauseSound`: Pauses a sound where it is.
  - `sound`: The sound.
- `ResumeSound`: Resumes a paused sound.
  - `sound`: The sound.
- `IsSoundPlaying`: Returns whether a sound is playing.
  - `sound`: The sound.
  - returns: True while it plays. False while it is paused, as raylib's is.
- `SetSoundVolume`: Sets a sound's volume, for the play under way and the next.
  - `sound`: The sound.
  - `volume`: 0 (silent) to 1.
- `SetSoundPitch`: Sets a sound's pitch, for the play under way and the next, speeding or slowing the sound with it.
  - `sound`: The sound.
  - `pitch`: 1 for as recorded, 2 an octave up.

  The pitch is absolute, whatever was set before, so 1 sets the sound back to as recorded.

  Clamped to 0.25 to 4, the platform's range.
- `SetSoundPan`: Sets where a sound is heard, for the play under way and the next.
  - `sound`: The sound.
  - `pan`: 0 for left, 0.5 the middle, 1 for right.

  The range is raylib 5.5's, 0 to 1 with 0.5 the middle and 1 the right.
- `LoadMusicStreamFromMemory`: Returns music opened from a file's bytes, to be played as it is read.
  - `fileType`: The file's extension, such as ".ogg": Ogg Vorbis, MP3 or WAV.
  - `data`: The file's bytes; they are kept until the music is unloaded.
  - `dataSize`: How many of them.
  - returns: The music.

  `InitAudioDevice` must come first.

  A FLAC file (".flac" or ".FLAC") is refused, as raylib 5.5's default build leaves FLAC out. The music is invalid, and "STREAM: Data format not supported" is logged.
- `IsMusicValid`: Returns whether music is open, or still opening.
  - `music`: The music.
  - returns: False once its file couldn't be opened, or once it is unloaded.
- `UnloadMusicStream`: Stops music and closes it.
  - `music`: The music.
- `PlayMusicStream`: Plays music from its start, or from where `SeekMusicStream` moved it, looping while its `looping` is true.
  - `music`: The music.

  Music still opening starts once it opens.
- `IsMusicStreamPlaying`: Returns whether music is playing, or will once it opens.
  - `music`: The music.
  - returns: True while it plays. False while it is paused, as raylib's is.
- `UpdateMusicStream`: Does nothing, as the stream feeds itself.
  - `music`: The music.

  Music that doesn't loop is heard to its last sample, and stops then.
- `StopMusicStream`: Stops music, so its next play starts from its beginning.
  - `music`: The music.
- `PauseMusicStream`: Pauses music where it is.
  - `music`: The music.
- `ResumeMusicStream`: Resumes paused music.
  - `music`: The music.
- `SeekMusicStream`: Moves music to a position.
  - `music`: The music.
  - `position`: The position, in seconds from its start, clamped to 0 or more.

  Music not playing starts there when next played.

  Music streamed from a server moves only as far as the server's range requests reach.
- `SetMusicVolume`: Sets music's volume.
  - `music`: The music.
  - `volume`: 0 (silent) to 1.
- `SetMusicPitch`: Sets music's pitch, absolute whatever was set before, as `SetSoundPitch` sets a sound's.
  - `music`: The music.
  - `pitch`: 1 for as recorded.

  Clamped to 0.25 to 4.
- `SetMusicPan`: Sets where music is heard, in `SetSoundPan`'s range, with 1 the right.
  - `music`: The music.
  - `pan`: 0 for left, 0.5 the middle, 1 for right.
- `GetMusicTimeLength`: Returns music's length (helix-services' `Sound.duration`).
  - `music`: The music.
  - returns: The length, in seconds, or 0 while it isn't known.

  Known once the music opens from a file. A server's file's length is known once its start and its last 64 KiB have arrived.
- `GetMusicTimePlayed`: Returns how far music has played, back to 0 at each loop, as raylib's does.
  - `music`: The music.
  - returns: The position, in seconds from its start.

  Holds while paused. Is 0 once stopped, or once played to its end without looping, and starts from 0 when played again.
- `LoadAudioStream`: Returns a stream that plays samples the program makes as it goes, each buffer as `UpdateAudioStream` gives it.
  - `sampleRate`: The frames a second, 8000 to 96000.
  - `sampleSize`: The bits a sample takes: 8 (unsigned), 16 (signed) or 32 (float).
  - `channels`: The number of channels, 1 or 2.
  - returns: The stream, or one that isn't valid (`IsAudioStreamValid`) when it can't be made.

  `InitAudioDevice` must come first.

  Played through helix-services' `SampleQueue`, which the platform resamples.
- `IsAudioStreamValid`: Returns whether a stream is open.
  - `stream`: The stream.
  - returns: True when it has its queue, a rate, a sample size and channels.
- `UnloadAudioStream`: Closes a stream, stopping it.
  - `stream`: The stream.
- `UpdateAudioStream`: Gives a stream its next buffer of samples, as raylib's does, filling the rest of the buffer with silence.
  - `stream`: The stream.
  - `data`: The samples in the stream's sample size and channels, interleaved.
  - `frameCount`: How many frames.

  Taken only once a buffer has been heard (`IsAudioStreamProcessed`), and only up to a buffer's frames (`SetAudioStreamBufferSizeDefault`). Otherwise nothing is taken, and a warning is logged.
- `IsAudioStreamProcessed`: Returns whether a stream has room for another buffer, as raylib's double buffer has one free.
  - `stream`: The stream.
  - returns: True while it holds no more than one buffer not yet heard, when `UpdateAudioStream` would take samples.
- `PlayAudioStream`: Plays a stream: what it holds, and what it is given after.
  - `stream`: The stream.

  A stream with a callback (`SetAudioStreamCallback`) is filled by it at once.
- `PauseAudioStream`: Pauses a stream where it is.
  - `stream`: The stream.
- `ResumeAudioStream`: Resumes a paused stream.
  - `stream`: The stream.
- `IsAudioStreamPlaying`: Returns whether a stream is playing.
  - `stream`: The stream.
  - returns: True while it plays, even when it has run out of samples. False while it is paused, as raylib's is.
- `StopAudioStream`: Stops a stream, dropping the samples it hasn't played.
  - `stream`: The stream.
- `SetAudioStreamVolume`: Sets a stream's volume.
  - `stream`: The stream.
  - `volume`: 0 (silent) to 1.
- `SetAudioStreamPitch`: Sets a stream's pitch, absolute whatever was set before, as `SetSoundPitch` sets a sound's.
  - `stream`: The stream.
  - `pitch`: 1 for as given.

  Clamped to 0.25 to 4.
- `SetAudioStreamPan`: Sets where a stream is heard, in `SetSoundPan`'s range, with 1 the right.
  - `stream`: The stream.
  - `pan`: 0 for left, 0.5 the middle, 1 for right.
- `SetAudioStreamBufferSizeDefault`: Sets the frames in each of a stream's two buffers, for the streams opened after.
  - `size`: The frames.

  0 restores raylib's default, a 30th of a second at 44100 Hz (1470 frames).
- `SetAudioStreamCallback`: Sets the callback a stream asks for its samples, or removes it.
  - `stream`: The stream.
  - `callback`: Receives a buffer to fill, in the stream's sample size and channels, and its frames; null for none.

  While the stream plays, the callback is called with a buffer's frames to fill until the stream holds two buffers ahead of what is heard.

  Called on the main thread as each frame ends (`EndDrawing`'s poll), and once as the stream starts to play. raylib calls it on its audio thread.

  A frame long enough to empty both buffers is heard as a gap.

  Ignored for a stream that isn't open.
- `ExportWave`: Writes a wave to a sound file, as `ExportWaveAsync` writes it, and returns once it is written. See `ExportWaveAsCode` for writing a C header.
  - `wave`: The wave.
  - `fileName`: The file; its extension chooses the format.
  - returns: Whether it was written. Why it wasn't is logged.
- `ExportWaveAsCode`: Writes a wave as a C header, as `ExportWaveAsCodeAsync` writes it, and returns once it is written. See `ExportWave` for writing a sound file.
  - `wave`: The wave.
  - `fileName`: The file; its name, upper case, names the defines and the array.
  - returns: Whether it was written. Why it wasn't is logged.
- `LoadSound`: Loads a sound file, as `LoadSoundAsync` loads it, and returns the sound once it is decoded, ready to play at once. See `LoadMusicStream` for playing a file as it is read.
  - `fileName`: The file, as the program names it.
  - returns: The sound, or one that isn't valid (`IsSoundValid`) when it couldn't be loaded. Why it couldn't is logged.

  `InitAudioDevice` must come first.
- `LoadMusicStream`: Opens a music file, as `LoadMusicStreamAsync` opens it, and returns the music once enough of the file has arrived to start.
  - `fileName`: The file, as the program names it, such as "assets/theme.ogg".
  - returns: The music, or one that isn't valid (`IsMusicValid`) when it couldn't be opened. Why it couldn't is logged.

  `InitAudioDevice` must come first.


```haxe
static function LoadSoundAsync(fileName:String, loaded:Sound -> Void, ?failed:String -> Void):Void
static function LoadMusicStreamAsync(fileName:String, loaded:Music -> Void, ?failed:String -> Void):Void
static function ExportWaveAsync(wave:Wave, fileName:String, ?done:() -> Void, ?failed:String -> Void):Void
static function ExportWaveAsCodeAsync(wave:Wave, fileName:String, ?done:() -> Void, ?failed:String -> Void):Void
```

- `LoadSoundAsync`: Asynchronously loads and decodes a sound file, ready to play at once, replacing raylib's `LoadSound`. See `LoadMusicStreamAsync` for playing a file as it is read.
  - `fileName`: The file, as the program names it.
  - `loaded`: Receives the sound.
  - `failed`: Optional. Receives why it couldn't be loaded; when omitted, it is logged.

  `InitAudioDevice` must come first.

  A file loaded again shares its first load's decoded sound.
- `LoadMusicStreamAsync`: Asynchronously opens a music file to be played as it is read, replacing raylib's `LoadMusicStream`. See `LoadSoundAsync` for decoding a file whole first.
  - `fileName`: The file, as the program names it, such as "assets/theme.ogg".
  - `loaded`: Receives the music, ready to play, once enough of the file has arrived to start.
  - `failed`: Optional. Receives why it couldn't be opened; when omitted, it is logged.

  `InitAudioDevice` must come first.

  A FLAC file is refused, as raylib 5.5's default build leaves FLAC out.

  Never loaded whole: it is read as it plays (helix-services' `Audio.stream`).
- `ExportWaveAsync`: Asynchronously writes a wave to a sound file, replacing raylib's `ExportWave`. See `ExportWaveAsCodeAsync` for writing a C header.
  - `wave`: The wave.
  - `fileName`: The file; its extension chooses the format.
  - `done`: Optional. Called once the file is written, or once it is refused, at a later poll.
  - `failed`: Optional. Receives why it wasn't, such as a wave with no samples or another extension; when omitted, it is logged.

  The extension chooses the format:

  - ".wav": 8, 16 and 24-bit samples as integers, 32-bit as floats, as raylib's dr_wav writes them. - ".raw": the samples unchanged.

  A ".qoa" file is refused, though raylib writes one.

  The file is written and kept by `SaveFileDataAsync`.
- `ExportWaveAsCodeAsync`: Asynchronously writes a wave as a C header, replacing raylib's `ExportWaveAsCode`. See `ExportWaveAsync` for writing a sound file.
  - `wave`: The wave.
  - `fileName`: The file; its name, upper case, names the defines and the array.
  - `done`: Optional. Called once the file is written, or once it is refused, at a later poll.
  - `failed`: Optional. Receives why it wasn't; when omitted, it is logged.

  The header holds:

  - the frame count, sample rate, sample size and channel count, as defines. - the samples, as an array of floats with 4 places for 32-bit samples, else of bytes, 20 a line.

  The file is written by `SaveFileTextAsync`.
