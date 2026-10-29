# helix.services.audio

[Back to the index](README.md)

## Audio

*class* in [`services/src/helix/services/audio/Audio.hx`](../../services/src/helix/services/audio/Audio.hx), `import helix.services.audio.Audio;`, implements `IPollable`

Provides sounds by path, played as voices in groups whose volumes and fades apply to every voice in them.

A sound is loaded one of two ways: decoded whole (`load`), for short sounds played often, or played as it's read (`stream`), for music and other long sounds. Every group is under `master`. A fade runs on real time from when it's asked for, whether or not anything is heard yet: in a page, sound starts with the player's first key, click or tap (`IAudio.running`), and a fade asked for before then may have ended by then. The program calls `poll` once a frame, which steps the fades and lets go of ended voices.

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

- `new`: Creates the audio over the platform's output, with only `master`.
  - `output`: The platform's sound output.
  - `decoder`: The platform's decoder, for sounds loaded whole.
  - `assets`: Where sounds are found by path.
  - `system`: The platform's facts: fades read its monotonic time (`getTime`).
- `master`: Gets the group every other is under: its volume and `muted` apply to every voice.
- `createGroup`: Creates a group, such as music or effects, with its own volume.
  - `parent`: Optional. The group it's under; `master` by default.
  - returns: The group, at volume 1.
- `load`: Loads a sound whole: read through `Assets.load`, decoded and held as samples, so it plays at once each time.
  - `path`: The file's path, as `Assets` finds it: WAV, Ogg Vorbis, MP3 or FLAC.
  - `loaded`: Receives the sound.
  - `failed`: Optional. Receives why it can't be had or decoded; left out, it's logged with the path.
  - returns: The abort: nothing is called after it.
- `stream`: Opens a sound to be played as it's read, never held whole.
  - `path`: The file's path, as `Assets` finds it.
  - `opened`: Receives the sound, once enough of it is there to start.
  - `failed`: Optional. Receives why it can't be had or opened; left out, it's logged with the path.
  - returns: The abort: nothing is called after it.

  It's found through `Assets.locate`: a file system's file is read where it is; a server's file is read from its kept copy, or played as it downloads while the copy is kept.
- `play`: Starts a sound playing.
  - `sound`: The sound, as `load` or `stream` gave it.
  - `group`: Optional. The group it plays in; `master` by default.
  - `loop`: Optional. True to play it again from the start each time it ends; false by default.
  - `volume`: Optional. Its own volume, 0 to 1, before its groups'; 1 by default.
  - returns: The voice, to change or stop it.
  - throws `String`: For a null sound, or one unloaded.
- `unload`: Lets go of a sound: its voices stop, and what holds it is freed.
  - `sound`: The sound.
- `poll`: Steps the fades to now and lets go of the voices that ended; call once a frame.
- `dispose`: Stops every voice and lets go of every sound; before the output, decoder and `Assets` it was given are disposed.

## Group

*class* in [`services/src/helix/services/audio/Group.hx`](../../services/src/helix/services/audio/Group.hx), `import helix.services.audio.Group;`

Represents voices whose volume is set together, such as the music or the effects (`Audio.createGroup`).

A voice is heard at its own volume times its group's and each group's above it, and not at all while any of them is muted.

```haxe
var parent(default, null):Null<Group>
var volume(default, set):Float
var muted:Bool
function fadeTo(volume:Float, seconds:Float, ?done:() -> Void):Void
```

- `parent`: Gets the group it's under, or null for `Audio.master`.
- `volume`: Gets or sets its volume, 0 to 1; setting it ends a fade.
- `muted`: Gets or sets a value indicating whether its voices are silent, their volumes kept; false by default.
- `fadeTo`: Fades its volume to another over some real time, on a curve the ear hears as even (in decibels).
  - `volume`: The volume to end at, 0 to 1.
  - `seconds`: How long it takes, in real seconds; 0 sets it at once.
  - `done`: Optional. Called once it's reached, unless another fade or a set volume ends it first.

## Sound

*class* in [`services/src/helix/services/audio/Sound.hx`](../../services/src/helix/services/audio/Sound.hx), `import helix.services.audio.Sound;`

Represents a sound ready to play: decoded whole (`Audio.load`) or opened to be read as it plays (`Audio.stream`).

```haxe
var path(default, null):String
var streamed(default, null):Bool
```

- `path`: Gets the path it was loaded from.
- `streamed`: Gets a value indicating whether it's read as it plays (`Audio.stream`) rather than held whole.

## Voice

*class* in [`services/src/helix/services/audio/Voice.hx`](../../services/src/helix/services/audio/Voice.hx), `import helix.services.audio.Voice;`

Represents a sound playing (`Audio.play`), until it ends or is stopped.

Once it has ended its members change nothing, and `playing` is false.

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
- `playing`: Gets a value indicating whether it's still playing or paused: false once it ended or was stopped.
- `volume`: Gets or sets its own volume, 0 to 1, before its groups'; setting it ends a fade.
- `pitch`: Gets or sets its playback rate, which changes its pitch and length together: 0.25 to 4, 1 as recorded.
- `pan`: Gets or sets where it's heard: -1 left to 1 right, 0 the middle.
- `paused`: Gets or sets a value indicating whether it's paused, holding its place.
- `fadeTo`: Fades its own volume to another over some real time, on a curve the ear hears as even (in decibels).
  - `volume`: The volume to end at, 0 to 1.
  - `seconds`: How long it takes, in real seconds; 0 sets it at once.
  - `done`: Optional. Called once it's reached, unless another fade, a set volume or the voice's end comes first.
- `stop`: Stops it for good. Does nothing once it has ended.
