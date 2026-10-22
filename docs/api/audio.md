# helix.audio

[Back to the index](README.md)

## Audio

*class* in [`src/helix/audio/Audio.hx`](../../src/helix/audio/Audio.hx)

Sounds: clips and streams loaded through the assets, decoded and played (AudioResources), through buses. The audio output under it (IAudio) is the adapter's. The program's one, a static class: each member forwards to instance, written by helix.macro.Facade from AudioResources' public members with their doc comments, but for the buses and what plays through them, written here: the bus tree is plain engine data, there from the program's start, before the runner binds instance.

```haxe
static final master(default, null):Bus
static final music(default, null):Bus
static final effects(default, null):Bus
static function addBus(name:String, parent:Bus):Null<Bus>
static function play(sound:AudioResource, ?loop:Bool = false, ?volume:Float = 1.):AudioPlayback
static function crossfade(from:AudioPlayback, to:AudioPlayback, seconds:Float, ?toVolume:Float = 1.):Void
static function saveBuses(?key:String = "audio", ?done:() -> Void, ?failed:String -> Void):Void
static function loadBuses(?key:String = "audio", ?done:() -> Void, ?failed:String -> Void):Void
static function loadClip(path:String, loaded:AudioClip -> Void, ?failed:String -> Void):IRequest
static function loadStream(path:String, loaded:AudioStream -> Void, ?failed:String -> Void):IRequest
```

- `master`: The root bus, every other one under it. Kept across a hot reload (@:hot), as the buses a game holds are.
- `music`: The music's bus, under master. Kept across a hot reload (@:hot).
- `effects`: The sound effects' bus, under master: what play plays through. Kept across a hot reload (@:hot).
- `addBus`: A new bus named name under parent, at volume 1, held as a reference (`@:hot static final ambience = Audio.addBus("ambience", Audio.effects)`); its name is what saveBuses and loadBuses know it by. Null, adding none, for an empty name or one a bus has.
- `play`: Plays sound through effects from the beginning at volume (0 to 1), looping if asked: effects.play.
- `crossfade`: Fades from to silence and stops it, and to from its volume up to toVolume (1 by default; the track's own level), both over seconds and linear in power (FadeCurve.Power), so the two together hold their loudness through the middle: start to at 0 (`Audio.crossfade(theme, Audio.music.play(next, true, 0), 2)`).
- `saveBuses`: Saves every bus's volume and mute by name as JSON under key through Storage; done runs once it's written, failed (else the log, with the key) for a failed write or no Storage.
- `loadBuses`: Loads the volumes and mutes saveBuses saved under key into the buses of their names, a name with no bus skipped; a volume is clamped, and assigning it ends a bus's fade. done runs once they're set, or nothing was saved; failed (else the log, with the key) for a failed read, a file that isn't the saved JSON, or no Storage.
- `loadClip`: Loads path and decodes it whole into a clip, which reloads in place when the file changes. One of loaded or failed runs once on the host thread, and neither once the request is cancelled: loaded with a clip the caller owns and releases; failed (else the log, with the path) for a closed service, a load or decode failure, or a clip the backend refuses. A clip that arrives after cancellation is released.
- `loadStream`: Opens path for progressive playback from a cached or packaged copy, or else from the host without loading it whole: its remote URL where the backend plays one (a browser), else its download, played as it arrives and kept in the cache when it ends (IAssets.streamSource's download). One of loaded or failed runs once on the host thread, and neither once the request is cancelled: loaded with a stream the caller owns and releases (its stored copy's lease ends with it); failed (else the log, with the path) for a closed service, a missing asset, a failed download, or a source the backend cannot open.

## AudioClip

*class* in [`src/helix/audio/AudioClip.hx`](../../src/helix/audio/AudioClip.hx)

Fully decoded, reusable audio resource.

```haxe
function new(id:Int, backend:IAudio, ?path:String)
var path(default, null):Null<String>
```

- `new`: Owns backend clip id, loaded from path when given; AudioResources.loadClip creates it.
- `path`: The asset it was loaded from, which a reload replaces in place.

## AudioDecodeResult

*enum* in [`src/helix/audio/AudioDecoding.hx`](../../src/helix/audio/AudioDecoding.hx)

How a decode ended: mono 32-bit float PCM at 44100 Hz, samples -1 to 1; a failure message; or cancellation.

- `Decoded(samples:haxe.io.Bytes)`
- `Failed(message:String)`
- `Cancelled`

## AudioDecoding

*class* in [`src/helix/audio/AudioDecoding.hx`](../../src/helix/audio/AudioDecoding.hx)

Whole-file audio decoding, the same on every platform: a WAV (mono PCM16 at 44100 Hz, at most 4 seconds) decoded here, an Ogg (Vorbis, Opus) or MP3 by the platform's IAudioDecoder; at most 8 MiB encoded and 2Mi frames decoded; at most two at once, each completing exactly once on the host thread.

```haxe
function new(decoder:IAudioDecoder)
static var MAX_ENCODED(inline, null):Int
static var MAX_FRAMES(inline, null):Int
static function sniff(encoded:haxe.io.Bytes):Null<String>
function decode(encoded:haxe.io.Bytes, complete:AudioDecodeResult -> Void):IRequest
var busy(get, never):Bool
function poll():Void
function shutdown():Void
```

- `new`: Decodes compressed files with decoder.
- `MAX_ENCODED`: The largest encoded file, in bytes.
- `MAX_FRAMES`: The most frames a decoded clip has.
- `sniff`: What encoded is by its first bytes: "wav", "ogg", "mp3" (an ID3 tag or an MPEG frame's sync bits), or null.
- `decode`: Decodes encoded whole; complete runs exactly once on the host thread at a later poll. Failed for a closed service, more than 8 MiB encoded, more than 2Mi frames decoded, or an unsupported or corrupt file.
- `busy`: Whether a decode is queued, under way, or its completion not yet run.
- `poll`: Delivers finished decodes, starts queued ones and runs completions. Call once per frame.
- `shutdown`: Cancels every pending decode (each completes Cancelled) and refuses later ones.

## AudioPlayback

*class* in [`src/helix/audio/AudioPlayback.hx`](../../src/helix/audio/AudioPlayback.hx)

One playback, playing or paused, through a bus; holds its resource until stopped or played to its end. While audio hasn't started (a browser before the page's first key or pointer press) it waits, its pause, volume, pitch and pan kept, and starts once audio runs. What the adapter hears is heardVolume, its own volume times its bus's heard volume, sent once a frame when either changed.

```haxe
function new(resource:AudioResource, loop:Bool, volume:Float, bus:Bus)
var id(default, null):Int
var finished(default, null):Bool
var source(default, null):Int
var bus(default, null):Bus
var state(get, never):PlayState
function stop():Bool
function pause():Bool
function resume():Bool
var volume(default, set):Float
var heardVolume(get, never):Float
var pitch(default, set):Float
var pan(default, set):Float
function fade(to:Float, seconds:Float, ?done:() -> Void, ?stopWhenSilent:Bool = false):Void
function poll():Void
```

- `new`: A playback of resource (whose playback reference the caller retained) through bus at volume, looping if asked: it starts now if audio runs, waits if audio is available but hasn't started, and finishes at once otherwise. AudioResources.play makes it.
- `id`: The adapter's voice; 0 while it waits for audio to start, or when it couldn't start.
- `finished`: Whether it was stopped, played to its end, or never started; its resource reference is released then.
- `source`: The adapter's resource it plays, kept as it started: a reload may replace the resource's.
- `bus`: The bus it plays through.
- `state`: Playing or Paused while it lasts (waiting counts as playing); then Stopped (stop(), or it never started) or Complete (it played to its end).
- `stop`: Stops it and releases its resource reference. False once it has finished.
- `pause`: Pauses it where it is. False unless it's playing.
- `resume`: Plays on from where it was paused. False unless it's paused.
- `volume`: Its own volume, 0 to 1. Clamped to 0..1 (NaN is 0); once it has finished, kept but not heard. Assigning it ends a fade, whose done doesn't run.
- `heardVolume`: What it is heard at, 0 to 1: its volume times its bus's heardVolume.
- `pitch`: Its playback rate, 0.25 to 4 (1 as recorded; 2 an octave up and half as long), clamped (NaN is 1).
- `pan`: Where it is heard, -1 (left) to 1 (right), 0 the middle, equal power; clamped (NaN is 0).
- `fade`: Moves its volume to to (0 to 1, clamped) over seconds (0 or less, or NaN, sets it at once), linear in decibels, a silent end taken as -60 dB; at the end done runs (during this call for 0 seconds) and, with stopWhenSilent and an end of 0, it stops. A fade started over another, or a volume assigned, ends the earlier one, whose done doesn't run. Nothing once it has finished.
- `poll`: Starts it once audio runs, and finishes it, releasing its resource reference, once the adapter no longer plays it. AudioResources.poll calls it.

## AudioResource

*class* in [`src/helix/audio/AudioResource.hx`](../../src/helix/audio/AudioResource.hx)

One owner plus active playback references. release() drops the owner's reference.

```haxe
function new(id:Int, backend:IAudio, destroy:() -> Void)
var id(default, null):Int
var backend(default, null):IAudio
var disposed(default, null):Bool
function retainPlayback():Void
function releasePlayback():Void
function release():Void
```

- `new`: Owns backend resource id with the owner's reference; destroy runs when the last reference is released.
- `id`: The backend clip or stream id, which a reload may replace.
- `backend`: The audio adapter that owns the backend resource.
- `disposed`: Whether the owner and every playback have released it, so its backend resource is destroyed.
- `retainPlayback`: Adds a reference for a starting playback. Throws once the owner has released it.
- `releasePlayback`: Drops a playback's reference; the last reference destroys the backend resource.
- `release`: Drops the owner's reference, once; the backend resource is destroyed when no playback still holds it.

## AudioStream

*class* in [`src/helix/audio/AudioStream.hx`](../../src/helix/audio/AudioStream.hx)

Progressively decoded resource. Stored and remote sources are independent policy.

```haxe
function new(id:Int, backend:IAudio, releaseSource:() -> Void)
```

- `new`: Owns backend stream id; releaseSource ends the stored copy's lease after the stream is destroyed. AudioResources.loadStream creates it.

## Bus

*class* in [`src/helix/audio/Bus.hx`](../../src/helix/audio/Bus.hx)

A bus sounds are played through: a name, a parent, a volume, a mute and a fade, plain engine data. Audio.master is the root, Audio.music and Audio.effects are under it from the program's start, and Audio.addBus makes a game's own. A playback's heard volume is its own times its bus's heardVolume; the buses' fades advance and the heard volumes reach the voices once a frame (AudioResources.poll). A bus is held as a reference; its name is used only to save and load the volumes (Audio.saveBuses, Audio.loadBuses).

```haxe
final name:String
final parent:Null<Bus>
var volume(default, set):Float
var muted:Bool
var heardVolume(get, never):Float
function fade(to:Float, seconds:Float, ?done:() -> Void):Void
function play(sound:AudioResource, ?loop:Bool = false, ?volume:Float = 1.):AudioPlayback
function all():Array<Bus>
```

- `name`: Its name, unique among the buses: what saving and loading the volumes know it by.
- `parent`: The bus it plays into: null only for the master.
- `volume`: Its volume, 0 to 1, clamped (NaN is 0). Assigning it ends a fade, whose done doesn't run.
- `muted`: Whether it is muted: its heard volume, and everything played through it or a bus under it, is then 0, its volume kept for unmuting.
- `heardVolume`: What it plays at: its volume times its parents' up to the master, 0 when it or a parent is muted.
- `fade`: Moves its volume to to (0 to 1, clamped) over seconds (0 or less, or NaN, sets it at once), linear in decibels, a silent end taken as -60 dB; done runs at the end, during this call for 0 seconds. A fade started over another, or a volume assigned, ends the earlier one, whose done doesn't run.
- `play`: Plays sound through it from the beginning at volume (0 to 1), looping if asked: AudioResources.play on the program's (Audio.instance). Throws before the runner has bound one, and as AudioResources.play throws.
- `all`: This bus and every bus under it, parents before their children.

## Fade

*class* in [`src/helix/audio/Fade.hx`](../../src/helix/audio/Fade.hx)

A volume (0 to 1) moving from one level to another over seconds along a curve (FadeCurve): linear in decibels so it sounds even, a silent end taken as FLOOR_DB, or linear in power for a crossfade; the last step lands on the end exactly. A bus's and a playback's fades each step one, once a frame.

```haxe
function new(from:Float, to:Float, seconds:Float, ?done:() -> Void, ?curve:FadeCurve = FadeCurve.Decibels)
static var FLOOR_DB(inline, null):Float
static function at(from:Float, to:Float, fraction:Float, ?curve:FadeCurve = FadeCurve.Decibels):Float
final done:Null<() -> Void>
var finished(get, never):Bool
function step(delta:Float):Float
```

- `new`: From volume from to volume to (each 0 to 1) over seconds (0 or less ends at the first step) along curve, done run at the end by its owner.
- `FLOOR_DB`: The level a silent end (a volume of 0) is taken as, in decibels.
- `at`: The volume fraction (0 to 1) of the way from volume from to volume to along curve: linear in decibels, each end under FLOOR_DB's level taken as FLOOR_DB, or linear in power; to itself at 1.
- `done`: Runs once it reaches its end; null for none.
- `finished`: Whether it has reached its end.
- `step`: Moves it on by delta seconds (under 0 as 0) and returns the volume there: to exactly once finished.

## FadeCurve

*abstract* in [`src/helix/audio/FadeCurve.hx`](../../src/helix/audio/FadeCurve.hx)

How a Fade moves between its levels: Decibels, linear in decibels, even to the ear for a fade to or from silence (a bus's and a playback's fades); Power, linear in power (the volume's square), so two sounds crossfaded this way, one out and one in, keep their sum's loudness through the middle (Audio.crossfade).

## IAudio

*class* in [`src/helix/audio/IAudio.hx`](../../src/helix/audio/IAudio.hx)

Sound output on a platform: clips (PCM held whole) and streams (played as they're read), each played as voices. Ids are the adapter's; lifetimes, volume checks, buses and fades, waiting for audio to start and decoding are the shared AudioResources' and AudioDecoding's. A browser starts its audio on the page's first key or pointer press and suspends it while the page is hidden or blurred; natively it runs once the device opens.

```haxe
var available(get, never):Bool
var running(get, never):Bool
var playsUrls(get, never):Bool
function createClip(samples:haxe.io.Bytes):Int
function destroyClip(clip:Int):Void
function openStream(source:AudioLocation, done:StreamOpenResult -> Void):() -> Void
function destroyStream(stream:Int):Void
function playClip(clip:Int, loop:Bool, volume:Float):Int
function playStream(stream:Int, loop:Bool, volume:Float):Int
function stop(voice:Int):Void
function pause(voice:Int, paused:Bool):Void
function setVolume(voice:Int, volume:Float):Bool
function setPitch(voice:Int, pitch:Float):Bool
function setPan(voice:Int, pan:Float):Bool
function isPlaying(voice:Int):Bool
function poll():Void
function shutdown():Void
```

- `available`: Whether there is an output at all: false natively without an audio device.
- `running`: Whether voices start now: in a browser, once a key or pointer press has unlocked audio.
- `playsUrls`: Whether openStream plays a Remote location's URL itself (a browser's media element streams it). False natively: the shared AudioResources then asks the assets to download a remote stream, and opens the file arriving (Downloading).
- `createClip`: Copies samples (mono 32-bit float PCM at 44100 Hz, checked) into a new clip and returns its id. Throws when there's no room for a clip.
- `destroyClip`: Destroys clip and stops its voices. Throws for an unknown clip.
- `openStream`: Opens source for playing as it's read; done runs once on the host thread, never during this call: Opened, or Failed for a source the platform can't open (natively a remote URL, a file its codec can't read, or a download that failed or ended unreadable; in a browser a load error or no metadata within 15 seconds, and a Downloading source). A download is opened once enough of it has arrived for its codec. A Stored lease stays the caller's and must outlive the stream. Returns abort: nothing is called after it, and an opened stream is closed.
- `destroyStream`: Destroys stream and stops its voices. Throws for an unknown stream.
- `playClip`: Starts clip at volume (0 to 1), looping if asked, and returns its voice, or 0 when it can't start (no free voice). Throws for an unknown clip.
- `playStream`: Starts stream from its beginning at volume (0 to 1), looping if asked, and returns its voice, or 0 when it can't start. Throws for an unknown stream.
- `stop`: Stops voice; nothing for an unknown or ended one.
- `pause`: Pauses voice, or resumes it when paused is false; nothing for an unknown one.
- `setVolume`: Sets voice's volume, 0 to 1, a change ramped over a few milliseconds (the output's next block) so a fade stepped once a frame doesn't click. False, changing nothing, for a voice not playing (unknown, stopped or ended) or a volume outside 0 to 1.
- `setPitch`: Sets voice's playback rate (0.25 to 4, 1 as recorded; the engine holds it there), which changes its pitch and length together. False, changing nothing, for a voice not playing (unknown, stopped or ended).
- `setPan`: Sets voice's pan (-1 left to 1 right, 0 the middle; the engine holds it there), equal power, a change ramped as a volume's. False, changing nothing, for a voice not playing (unknown, stopped or ended).
- `isPlaying`: Whether voice is still playing (or paused); false once it ended or was stopped.
- `poll`: Keeps streamed voices fed and delivers what arrived from the platform's threads; the shared AudioResources calls it once a frame.
- `shutdown`: Stops every voice, destroys every stream and clip, and closes the output.

## IAudioDecoder

*class* in [`src/helix/audio/IAudioDecoder.hx`](../../src/helix/audio/IAudioDecoder.hx)

Compressed audio decoding on a platform: a whole Ogg (Vorbis, Opus) or MP3 file, mono or stereo, into mono 32-bit float PCM at 44100 Hz, samples -1 to 1 (mixed down and resampled as the platform can). Limits, the WAV path, queuing and cancellation are the shared AudioDecoding's.

```haxe
function decode(encoded:haxe.io.Bytes, done:AudioDecodeResult -> Void):Void
function poll():Void
```

- `decode`: Decodes encoded; done runs once on the host thread, never during this call: Decoded or Failed (a file it can't read).
- `poll`: Delivers what finished on the platform's threads since the last poll; the shared AudioDecoding calls it once a frame.

## Pcm

*class* in [`src/helix/audio/Pcm.hx`](../../src/helix/audio/Pcm.hx)

The PCM format of clips: mono 32-bit float samples.

```haxe
static function validate(samples:haxe.io.Bytes):Void
```

- `validate`: Throws unless samples is non-empty, a whole number of 4-byte floats, and every sample is finite and -1 to 1.

## PlayState

*abstract* in [`src/helix/audio/PlayState.hx`](../../src/helix/audio/PlayState.hx)

Where a playback is: playing, paused, stopped (by stop(), or it never started), or complete (it played to its end).

## StreamOpenResult

*enum* in [`src/helix/audio/IAudio.hx`](../../src/helix/audio/IAudio.hx)

How opening a stream ended: its id, or a failure message.

- `Opened(id:Int)`
- `Failed(message:String)`

## Wav

*class* in [`src/helix/audio/Wav.hx`](../../src/helix/audio/Wav.hx)

Minimal, bounded RIFF decoder for mono PCM16/44100 assets.

```haxe
static function decode(bytes:haxe.io.Bytes):haxe.io.Bytes
```

- `decode`: Decodes a whole mono PCM16 44100 Hz WAV of at most 4 seconds into mono 32-bit float PCM, -1 to 1. Throws for a bad header or chunk, another format, or missing or trailing data.
