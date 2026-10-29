# helix.services.audio

[Back to the index](README.md)

## Audio

*class* in [`services/src/helix/services/audio/Audio.hx`](../../services/src/helix/services/audio/Audio.hx), `import helix.services.audio.Audio;`, implements `IPollable`

Provides sounds by path, played as voices in groups whose volumes and fades apply to every voice in them.

A sound is loaded in one of two ways. `load` decodes it whole, for short sounds played often. `stream` plays it as it is read, for music and other long sounds. Every group is under `master`.

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
- `dispose`: Stops every voice and unloads every sound.
  Call it before disposing the output, decoder and `Assets` it was given.

## Group

*class* in [`services/src/helix/services/audio/Group.hx`](../../services/src/helix/services/audio/Group.hx), `import helix.services.audio.Group;`

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

## Sound

*class* in [`services/src/helix/services/audio/Sound.hx`](../../services/src/helix/services/audio/Sound.hx), `import helix.services.audio.Sound;`

Represents a sound ready to play, either decoded whole (`Audio.load`) or opened to be read as it plays (`Audio.stream`).

```haxe
var path(default, null):String
var streamed(default, null):Bool
```

- `path`: Gets the path it was loaded from.
- `streamed`: Gets a value indicating whether the sound is read as it plays (`Audio.stream`) rather than held whole.

## Voice

*class* in [`services/src/helix/services/audio/Voice.hx`](../../services/src/helix/services/audio/Voice.hx), `import helix.services.audio.Voice;`

Represents a sound playing (`Audio.play`), until it ends or is stopped.

Once it has ended, its members change nothing and `playing` is false.

```haxe
var sound(default, null):Sound
var group(default, null):Group
var playing(get, never):Bool
var volume(default, set):Float
var pitch(default, set):Float
var pan(default, set):Float
var paused(default, set):Bool
function fadeTo(volume:Float, seconds:Float, ?done:() -> Void):Void
function stop():Void
```

- `sound`: Gets the sound it plays.
- `group`: Gets the group it plays in.
- `playing`: Gets a value indicating whether the voice is playing or paused. It is false once the voice ended or was stopped.
- `volume`: Gets or sets the voice's own volume, 0 to 1, before its groups' volumes apply. Setting it ends a fade.
- `pitch`: Gets or sets the playback rate, which changes pitch and length together. Clamped to 0.25 to 4. Defaults to 1, as recorded.
- `pan`: Gets or sets where the voice is heard, from -1 for left to 1 for right. Clamped to -1 to 1. Defaults to 0, the middle.
- `paused`: Gets or sets a value indicating whether the voice is paused, holding its place. Defaults to false.
- `fadeTo`: Fades the voice's own volume to another over some real time, on a curve the ear hears as even (in decibels).
  - `volume`: The volume to end at, 0 to 1.
  - `seconds`: The fade's length, in real seconds. 0 or less sets the volume at once.
  - `done`: Optional. Called once the volume is reached, unless another fade, a set volume or the voice's end comes first.

  Does nothing once the voice has ended.
- `stop`: Stops the voice for good. Does nothing once it has ended.
