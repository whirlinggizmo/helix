# helix.services.audio

[Back to the index](README.md)

## Analyser

*class* in [`libs/services/src/helix/services/audio/Analyser.hx`](../../libs/services/src/helix/services/audio/Analyser.hx), `import helix.services.audio.Analyser;`

Represents a reading of what a group plays (`AudioEffects.addAnalyser`), for a level meter or a visualizer, until it is removed.

It reads what was heard at the last `AudioEffects.poll`. Natively that is up to one output block late.

```haxe
var group(default, null):Group
var frameCount(default, null):Int
var framesPassed(get, never):Float
function getSamples(into:haxe.io.Bytes):Int
function getSpectrum(into:haxe.io.Bytes):Int
function getLevel():Float
function remove():Void
```

- `group`: Gets the group it reads.
- `frameCount`: Gets how many of the latest frames it keeps.
- `framesPassed`: Gets how many frames it has read since it was added, so a reader can tell which of the latest are new since its last read.
- `getSamples`: Copies the latest frames heard.
  - `into`: Receives the frames as 32-bit floats, -1 to 1, stereo interleaved, left first, the oldest first. Its length sets how many, up to `frameCount`.
  - returns: The frames copied, fewer than asked until enough have played.
- `getSpectrum`: Measures the latest frames heard by frequency, as Web Audio's `AnalyserNode` does.
  - `into`: Receives the bands as 32-bit floats in decibels, from 0 Hz up to half the output's rate, evenly spaced. Its length sets how many, up to half of `frameCount`.
  - returns: The bands written.
- `getLevel`: Returns how loud the latest frames were, for a level meter.
  - returns: Their root mean square across both channels, 0 (silent) to 1.
- `remove`: Removes it from its group. Its members change nothing after.

## Audio

*class* in [`libs/services/src/helix/services/audio/Audio.hx`](../../libs/services/src/helix/services/audio/Audio.hx), `import helix.services.audio.Audio;`, implements `IPollable`

Provides sounds by path, played as voices in groups whose volumes and fades apply to every voice in them.

A sound is loaded in one of two ways. `load` decodes it whole, for short sounds played often. `stream` plays it as it is read, for music and other long sounds. `createSound` makes one from samples, and `createSampleQueue` a queue that plays samples as they are added. Every group is under `master`.

The program calls `poll` once a frame, which steps the fades and releases voices that ended. A fade runs on real time from when it starts, whether or not anything is heard yet. In a page, sound starts with the player's first key, click or tap (`IAudio.running`), so a fade started before then may already have ended.

```haxe
var effects = audio.createGroup();
var music = audio.createGroup();
audio.load("jump.wav", sound -> jump = sound);
audio.stream("music.ogg", sound -> audio.play(sound, music, true, 0).fadeTo(0.5, 2));
audio.play(jump, effects);
audio.master.muted = true;
```

```haxe
function new(output:IAudio, decoder:IAudioDecoder, assets:Assets, system:ISystem)
var master(default, null):Group
function createGroup(?parent:Group):Group
function load(path:String, loaded:Sound -> Void, ?failed:String -> Void):() -> Void
function stream(path:String, opened:Sound -> Void, ?failed:String -> Void):() -> Void
function createSound(samples:haxe.io.Bytes, channelCount:Int):Sound
function createSampleQueue(channelCount:Int, sampleRate:Int):SampleQueue
function play(sound:Sound, ?group:Group, ?loop:Bool = false, ?volume:Float = 1.):Voice
function unload(sound:Sound):Void
function poll():Void
function dispose():Void
```

- `new`: Creates the audio over the platform's output, with `master` as its only group.
  - `output`: The platform's sound output.
  - `decoder`: The platform's decoder, for sounds loaded whole.
  - `assets`: The assets that sounds are found in by path.
  - `system`: The platform's system, whose monotonic time (`getTime`) times the fades.
- `master`: Gets the group that every other group is under. Its volume and `muted` apply to every voice.
- `createGroup`: Creates a group, such as music or effects, with its own volume.
  - `parent`: Optional. The group it is under. Defaults to `master`.
  - returns: The group, at volume 1.
- `load`: Loads a sound whole, so it plays at once each time.
  - `path`: The file's path in `Assets`. The file is WAV, Ogg Vorbis, MP3 or FLAC.
  - `loaded`: Receives the sound.
  - `failed`: Optional. Receives why the sound can't be loaded or decoded. When omitted, the failure is logged with the path.
  - returns: The abort: nothing is called after it.

  The file is read through `Assets.load`, decoded, and held as samples.
- `stream`: Opens a sound to be played as it is read, never held whole.
  - `path`: The file's path in `Assets`.
  - `opened`: Receives the sound, once enough of it has arrived to start.
  - `failed`: Optional. Receives why the sound can't be found or opened. When omitted, the failure is logged with the path.
  - returns: The abort: nothing is called after it.

  The file is found through `Assets.locate`. A file system's file is read where it is. A server's file is read from its kept copy, or played as it downloads while the copy is kept.
- `createSound`: Makes a sound from samples, held whole as a loaded sound is.
  - `samples`: 32-bit float PCM at 44100 Hz, -1 to 1, interleaved when stereo: the platform's clip format (`IAudio.createClip`).
  - `channelCount`: The channels, 1 (mono) or 2 (stereo).
  - returns: The sound, its path "".
  - throws `String`: When channelCount isn't 1 or 2, or the samples hold no whole frame.

  The samples are copied. A partial frame at the end is ignored.
- `createSampleQueue`: Creates a queue, which plays samples as they are added to it, at its own rate.
  - `channelCount`: The channels, 1 (mono) or 2 (stereo).
  - `sampleRate`: The samples' rate in frames a second, 8000 to 96000; the platform resamples them.
  - returns: The queue, holding nothing.
  - throws `String`: When channelCount or sampleRate is out of range.
- `play`: Starts a sound playing.
  - `sound`: The sound, from `load` or `stream`.
  - `group`: Optional. The group it plays in. Defaults to `master`.
  - `loop`: Optional. True to play it again from the start each time it ends. Defaults to false.
  - `volume`: Optional. The voice's own volume, 0 to 1, before its groups' volumes apply. Defaults to 1.
  - returns: The voice, which changes or stops the sound.
  - throws `String`: When the sound is null or unloaded.
- `unload`: Unloads a sound. Its voices stop, and the memory or file that holds it is released.
  - `sound`: The sound.

  Does nothing for a sound already unloaded.
- `poll`: Steps the fades to the current time and releases the voices that ended.
  Call it once a frame.
- `dispose`: Stops every voice, unloads every sound and disposes every queue.
  Call it before disposing the output, decoder and `Assets` it was given.

## AudioEffects

*class* in [`libs/services/src/helix/services/audio/AudioEffects.hx`](../../libs/services/src/helix/services/audio/AudioEffects.hx), `import helix.services.audio.AudioEffects;`, implements `IPollable`

Provides effects on what groups play, such as a low pass on the music while the game is paused, and reads what a group plays, for a level meter or a visualizer.

A group's effects apply to every voice in it and in the groups under it. A voice in `music`, under `master`, is heard through music's effects and then master's. Each group's effects run in the order they were added. A program constructs it only when it uses effects, so one that doesn't carries none of it. Voices already playing when it is constructed are moved into their groups' effects.

The program calls `poll` once a frame, which steps the fades and delivers what the analysers kept.

```haxe
var effects = new AudioEffects(audio, new WebAudioEffectsAdapter(output));
var muffle = effects.add(music, LowPass(22050, 0.71));
muffle.fadeTo(LowPass(800, 0.71), 0.3); // paused
var meter = effects.addAnalyser(audio.master, 1024);
var level = meter.getLevel();
```

```haxe
function new(audio:Audio, effects:IAudioEffects)
function add(group:Group, effect:AudioEffect):Effect
function addAnalyser(group:Group, frameCount:Int):Analyser
function poll():Void
function dispose():Void
```

- `new`: Creates the effects over the platform's, for an audio's groups.
  - `audio`: The audio whose groups get effects.
  - `effects`: The platform's effects, over the same output as `audio`.
- `add`: Adds an effect at the end of a group's effects.
  - `group`: The group.
  - `effect`: The effect and its settings.
  - returns: The effect.
  - throws `String`: When a setting is outside its range.
- `addAnalyser`: Adds an analyser at the end of a group's effects, which reads what the group plays there.
  - `group`: The group.
  - `frameCount`: How many of the latest frames it keeps, a power of two from 32 to 32768. 1024 is about a frame's worth at 60 Hz.
  - returns: The analyser.
  - throws `String`: When the frame count isn't a power of two from 32 to 32768.
- `poll`: Steps the effects' fades and delivers what the analysers kept. The program calls it once a frame.
- `dispose`: Removes every effect and analyser. Every voice is heard without effects again.

## Effect

*class* in [`libs/services/src/helix/services/audio/Effect.hx`](../../libs/services/src/helix/services/audio/Effect.hx), `import helix.services.audio.Effect;`

Represents an effect on what a group plays (`AudioEffects.add`), until it is removed.

```haxe
var group(default, null):Group
var settings(default, set):AudioEffect
var bypassed(default, set):Bool
function fadeTo(settings:AudioEffect, seconds:Float, ?done:() -> Void):Void
function remove():Void
```

- `group`: Gets the group whose voices it changes.
- `settings`: Gets or sets the effect's settings, of the same kind as when it was added. A change is ramped over a few milliseconds, so one made each frame doesn't click. Setting it ends a fade.
  - throws `String`: When set to another kind, or a setting outside its range.
- `bypassed`: Gets or sets a value indicating whether it is off, letting what plays through unchanged while keeping its place and settings. Defaults to false.
- `fadeTo`: Moves its settings to others over some real time. Frequencies move evenly in octaves, and every other setting in a straight line.
  - `settings`: The settings to end at, of the same kind.
  - `seconds`: The fade's length, in real seconds. 0 or less sets them at once.
  - `done`: Optional. Called once they are reached, unless another fade or set settings end the fade first.
  - throws `String`: For another kind, or a setting outside its range.
- `remove`: Removes it from its group. Its members change nothing after.

## Group

*class* in [`libs/services/src/helix/services/audio/Group.hx`](../../libs/services/src/helix/services/audio/Group.hx), `import helix.services.audio.Group;`

Represents voices whose volume is set together, such as the music or the effects (`Audio.createGroup`).

A voice is heard at its own volume times the volume of its group and of each group above it. It is silent while any of those groups is muted.

```haxe
var parent(default, null):Null<Group>
var volume(default, set):Float
var muted:Bool
function fadeTo(volume:Float, seconds:Float, ?done:() -> Void):Void
```

- `parent`: Gets the group this one is under, or null for `Audio.master`.
- `volume`: Gets or sets the group's volume, 0 to 1. Defaults to 1. Setting it ends a fade.
- `muted`: Gets or sets a value indicating whether the group's voices are silent. Defaults to false. Their volumes are unchanged.
- `fadeTo`: Fades the group's volume to another over some real time, on a curve the ear hears as even (in decibels).
  - `volume`: The volume to end at, 0 to 1.
  - `seconds`: The fade's length, in real seconds. 0 or less sets the volume at once.
  - `done`: Optional. Called once the volume is reached, unless another fade or a set volume ends the fade first.

## SampleQueue

*class* in [`libs/services/src/helix/services/audio/SampleQueue.hx`](../../libs/services/src/helix/services/audio/SampleQueue.hx), `import helix.services.audio.SampleQueue;`

Represents samples played as they are added (`Audio.createSampleQueue`), for sound a program makes as it goes.

Samples added ahead of what is heard play back to back without a gap. A queue that runs out keeps playing, silent, and goes on when more are added. It has one voice at a time, which plays in a group like any other: its group's volume, mute and fades apply.

```haxe
var queue = audio.createSampleQueue(1, 22050);
queue.queueSamples(tone);
var voice = queue.play(effects);
// each frame, while fewer than a buffer's frames wait:
if (queue.queuedFrameCount < 4096)
queue.queueSamples(more());
```

```haxe
function queueSamples(samples:haxe.io.Bytes):Void
var queuedFrameCount(get, never):Int
function play(?group:Group, ?volume:Float = 1.):Voice
function dispose():Void
```

- `queueSamples`: Adds samples to the end of the queue.
  - `samples`: 32-bit float PCM at the queue's rate, -1 to 1, interleaved when stereo.
  - throws `String`: When the queue is disposed.

  They are copied. Samples added while the queue has no voice wait for `play`. A partial frame at the end is ignored.
- `queuedFrameCount`: Gets how many frames the queue holds that haven't been heard yet; 0 once it is disposed.
- `play`: Starts the queue playing what it holds and what is added to it.
  - `group`: Optional. The group it plays in. Defaults to `Audio.master`.
  - `volume`: Optional. The voice's own volume, 0 to 1, before its groups' volumes apply. Defaults to 1.
  - returns: The voice.
  - throws `String`: When the queue is disposed.

  Playing it again stops its earlier voice and keeps its samples. Its voice ends only when stopped, which drops the samples not yet heard. It can't be moved (`Voice.setPosition`).
- `dispose`: Stops its voice and lets go of the queue and its samples. Does nothing once disposed.

## Sound

*class* in [`libs/services/src/helix/services/audio/Sound.hx`](../../libs/services/src/helix/services/audio/Sound.hx), `import helix.services.audio.Sound;`

Represents a sound ready to play: decoded whole (`Audio.load`), made from samples (`Audio.createSound`), or opened to be read as it plays (`Audio.stream`).

```haxe
var path(default, null):String
var streamed(default, null):Bool
var channelCount(default, null):Int
var duration(get, never):Float
```

- `path`: Gets the path it was loaded from, or "" for a sound made from samples (`Audio.createSound`).
- `streamed`: Gets a value indicating whether the sound is read as it plays (`Audio.stream`) rather than held whole.
- `channelCount`: Gets the number of channels it plays, 1 (mono) or 2 (stereo); 0 for a streamed sound whose channels the platform can't tell (`IAudio.getStreamChannelCount`).
- `duration`: Gets the sound's length in seconds, or 0 while it isn't known.
  A sound held whole knows its length at once. A streamed sound's is the platform's (`IAudio.getStreamDuration`), which may come later. A streamed sound downloading from a server knows its length once the file's start and its last 64 KiB have arrived, which `Assets` fetches first.

## Voice

*class* in [`libs/services/src/helix/services/audio/Voice.hx`](../../libs/services/src/helix/services/audio/Voice.hx), `import helix.services.audio.Voice;`

Represents a sound or a queue playing (`Audio.play`, `SampleQueue.play`), until it ends or is stopped.

Once it has ended, its members change nothing and `playing` is false.

```haxe
var sound(default, null):Null<Sound>
var group(default, null):Group
var playing(get, never):Bool
var volume(default, set):Float
var pitch(default, set):Float
var pan(default, set):Float
var paused(default, set):Bool
var position(get, never):Float
function setPosition(seconds:Float):Bool
function fadeTo(volume:Float, seconds:Float, ?done:() -> Void):Void
function stop():Void
```

- `sound`: Gets the sound it plays, or null for a queue's voice (`SampleQueue.play`).
- `group`: Gets the group it plays in.
- `playing`: Gets a value indicating whether the voice is playing or paused. It is false once the voice ended or was stopped.
- `volume`: Gets or sets the voice's own volume, 0 to 1, before its groups' volumes apply. Setting it ends a fade.
- `pitch`: Gets or sets the playback rate, which changes pitch and length together. Clamped to 0.25 to 4. Defaults to 1, as recorded.
- `pan`: Gets or sets where the voice is heard, from -1 for left to 1 for right. Clamped to -1 to 1. Defaults to 0, the middle.
- `paused`: Gets or sets a value indicating whether the voice is paused, holding its place. Defaults to false.
- `position`: Gets how far the voice has played, in seconds from the start of its sound.
  A looping voice goes back to 0 at each loop. A queue's voice counts what it has played since it started. It is 0 once the voice has ended.
- `setPosition`: Moves the voice to a position in its sound, playing or paused.
  - `seconds`: The position in seconds from the start, 0 or more.
  - returns: False, changing nothing, when the voice has ended, is a queue's, or can't be moved there.

  A position past the end is clamped to the end, where a voice that doesn't loop ends. A queue's voice can't be moved, nor, in a page, a stream from a server that doesn't take range requests.
- `fadeTo`: Fades the voice's own volume to another over some real time, on a curve the ear hears as even (in decibels).
  - `volume`: The volume to end at, 0 to 1.
  - `seconds`: The fade's length, in real seconds. 0 or less sets the volume at once.
  - `done`: Optional. Called once the volume is reached, unless another fade, a set volume or the voice's end comes first.

  Does nothing once the voice has ended.
- `stop`: Stops the voice for good. Does nothing once it has ended.
