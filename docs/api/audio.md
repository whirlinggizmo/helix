# helix.audio

[Back to the index](README.md)

## Audio

*class* in `src/helix/audio/Audio.hx`

Sounds: clips and streams loaded through the assets, decoded and played (AudioResources). The audio output under it (IAudio) is the adapter's. The program's one, a static class: each member forwards to instance, written by helix.macro.Facade from AudioResources' public members with their doc comments.

```haxe
static var instance(default, null):AudioResources
static function loadClip(path:String, complete:AudioLoadResult<AudioClip> -> Void):IRequest
static function loadStream(path:String, complete:AudioLoadResult<AudioStream> -> Void):IRequest
static function play(resource:AudioResource, ?loop:Bool = false, ?volume:Float = 1.):AudioPlayback
```

- `instance`: The sounds forwarded to: the runner's from its init to its cleanup, null outside them. Kept across a hot reload (@:hot): set once by the runner, nothing would set it again.
- `loadClip`: Loads path and decodes it whole into a clip, which reloads in place when the file changes. complete runs exactly once on the host thread with a clip the caller owns and releases; Failed for a closed service, a load or decode failure, or a clip the backend refuses. A clip that arrives after cancellation is released.
- `loadStream`: Opens path for progressive playback from a cached or packaged copy, or else its remote URL, without loading it whole. complete runs exactly once on the host thread with a stream the caller owns and releases (its stored copy's lease ends with it); Failed for a closed service, a missing asset, or a source the backend cannot open, such as a remote URL natively.
- `play`: Starts resource from the beginning at volume 0 to 1, looping if asked; the playback holds the resource until it stops or finishes. While audio hasn't started (a browser before the page's first key or pointer press) the playback waits and starts once it runs; without an output, or with no free voice, it's finished at once. Throws for a closed service, a resource of another backend or already released by its owner, or a volume outside 0 to 1.

## AudioClip

*class* in `src/helix/audio/AudioClip.hx`

Fully decoded, reusable audio resource.

```haxe
function new(id:Int, backend:IAudio, ?path:String)
function getPath():Null<String>
```

- `new`: Owns backend clip id, loaded from path when given; AudioResources.loadClip creates it.
- `getPath`: The asset it was loaded from, which a reload replaces in place.

## AudioDecodeResult

*enum* in `src/helix/audio/AudioDecoding.hx`

How a decode ended: mono 32-bit float PCM at 44100 Hz, samples -1 to 1; a failure message; or cancellation.

- `Decoded(samples:haxe.io.Bytes)`
- `Failed(message:String)`
- `Cancelled`

## AudioDecoding

*class* in `src/helix/audio/AudioDecoding.hx`

Whole-file audio decoding, the same on every platform: a WAV (mono PCM16 at 44100 Hz, at most 4 seconds) decoded here, an Ogg (Vorbis, Opus) or MP3 by the platform's IAudioDecoder; at most 8 MiB encoded and 2Mi frames decoded; at most two at once, each completing exactly once on the host thread.

```haxe
function new(decoder:IAudioDecoder)
static var MAX_ENCODED(inline, null):Int
static var MAX_FRAMES(inline, null):Int
static function sniff(encoded:haxe.io.Bytes):Null<String>
function decode(encoded:haxe.io.Bytes, complete:AudioDecodeResult -> Void):IRequest
function isBusy():Bool
function poll():Void
function shutdown():Void
```

- `new`: Decodes compressed files with decoder.
- `MAX_ENCODED`: The largest encoded file, in bytes.
- `MAX_FRAMES`: The most frames a decoded clip has.
- `sniff`: What encoded is by its first bytes: "wav", "ogg", "mp3" (an ID3 tag or an MPEG frame's sync bits), or null.
- `decode`: Decodes encoded whole; complete runs exactly once on the host thread at a later poll. Failed for a closed service, more than 8 MiB encoded, more than 2Mi frames decoded, or an unsupported or corrupt file.
- `isBusy`: Whether a decode is queued, under way, or its completion not yet run.
- `poll`: Delivers finished decodes, starts queued ones and runs completions. Call once per frame.
- `shutdown`: Cancels every pending decode (each completes Cancelled) and refuses later ones.

## AudioLoadResult<T>

*enum* in `src/helix/audio/AudioResources.hx`

How an audio load ended: the resource, which the caller owns and releases, a failure message, or cancellation.

- `Ready(resource:T)`
- `Failed(message:String)`
- `Cancelled`

## AudioPlayback

*class* in `src/helix/audio/AudioPlayback.hx`

One playback, playing or paused; holds its resource until stopped or played to its end. While audio hasn't started (a browser before the page's first key or pointer press) it waits, its pause and volume kept, and starts once audio runs.

```haxe
function new(resource:AudioResource, loop:Bool, volume:Float)
function getId():Int
function isFinished():Bool
function getSource():Int
function getState():PlayState
function stop():Bool
function pause():Bool
function resume():Bool
function getVolume():Float
function setVolume(volume:Float):Bool
function poll():Void
```

- `new`: A playback of resource (whose playback reference the caller retained) at volume, looping if asked: it starts now if audio runs, waits if audio is available but hasn't started, and finishes at once otherwise. AudioResources.play makes it.
- `getId`: The adapter's voice; 0 while it waits for audio to start, or when it couldn't start.
- `isFinished`: Whether it was stopped, played to its end, or never started; its resource reference is released then.
- `getSource`: The adapter's resource it plays, kept as it started: a reload may replace the resource's.
- `getState`: Playing or Paused while it lasts (waiting counts as playing); then Stopped (stop(), or it never started) or Complete (it played to its end).
- `stop`: Stops it and releases its resource reference. False once it has finished.
- `pause`: Pauses it where it is. False unless it's playing.
- `resume`: Plays on from where it was paused. False unless it's paused.
- `getVolume`: Its volume, 0 to 1.
- `setVolume`: Sets its volume, 0 to 1 (before it starts, it starts at it). False, changing nothing, for a volume outside 0 to 1, or once finished.
- `poll`: Starts it once audio runs, and finishes it, releasing its resource reference, once the adapter no longer plays it. AudioResources.poll calls it.

## AudioResource

*class* in `src/helix/audio/AudioResource.hx`

One owner plus active playback references. release() drops the owner's reference.

```haxe
function new(id:Int, backend:IAudio, destroy:() -> Void)
function getId():Int
function getBackend():IAudio
function isDisposed():Bool
function retainPlayback():Void
function releasePlayback():Void
function release():Void
```

- `new`: Owns backend resource id with the owner's reference; destroy runs when the last reference is released.
- `getId`: The backend clip or stream id, which a reload may replace.
- `getBackend`: The audio adapter that owns the backend resource.
- `isDisposed`: Whether the owner and every playback have released it, so its backend resource is destroyed.
- `retainPlayback`: Adds a reference for a starting playback. Throws once the owner has released it.
- `releasePlayback`: Drops a playback's reference; the last reference destroys the backend resource.
- `release`: Drops the owner's reference, once; the backend resource is destroyed when no playback still holds it.

## AudioResources

*class* in `src/helix/audio/AudioResources.hx`

Sounds, the same on every platform: clips loaded through the assets and decoded whole (AudioDecoding), streams opened from a cached or packaged copy (or a remote URL where the platform plays one), their lifetimes counted, and playbacks, which wait while audio hasn't started. Plays on a platform's IAudio, which it polls; neither that nor the decoding is shut down by it.

```haxe
function new(assets:IAssets, backend:IAudio, decoding:AudioDecoding)
function loadClip(path:String, complete:AudioLoadResult<AudioClip> -> Void):IRequest
function loadStream(path:String, complete:AudioLoadResult<AudioStream> -> Void):IRequest
function play(resource:AudioResource, ?loop:Bool = false, ?volume:Float = 1.):AudioPlayback
function reloaded(path:String, bytes:haxe.io.Bytes):Void
function poll():Void
function shutdown():Void
```

- `new`: Loads through assets, decodes with decoding (polled by its owner) and plays on backend (polled here).
- `loadClip`: Loads path and decodes it whole into a clip, which reloads in place when the file changes. complete runs exactly once on the host thread with a clip the caller owns and releases; Failed for a closed service, a load or decode failure, or a clip the backend refuses. A clip that arrives after cancellation is released.
- `loadStream`: Opens path for progressive playback from a cached or packaged copy, or else its remote URL, without loading it whole. complete runs exactly once on the host thread with a stream the caller owns and releases (its stored copy's lease ends with it); Failed for a closed service, a missing asset, or a source the backend cannot open, such as a remote URL natively.
- `play`: Starts resource from the beginning at volume 0 to 1, looping if asked; the playback holds the resource until it stops or finishes. While audio hasn't started (a browser before the page's first key or pointer press) the playback waits and starts once it runs; without an output, or with no free voice, it's finished at once. Throws for a closed service, a resource of another backend or already released by its owner, or a volume outside 0 to 1.
- `reloaded`: A clip's file changed: decode it, then give each clip from that path a new backend clip in place.
- `poll`: Polls the backend, destroys replaced clips nothing still plays, drops disposed resources and finished playbacks, and runs queued completions. Call once per frame on the host thread.
- `shutdown`: Cancels pending loads (each completes Cancelled), stops every playback, releases the owner's reference on every resource, destroys replaced clips, and refuses later loads and plays.

## AudioStream

*class* in `src/helix/audio/AudioStream.hx`

Progressively decoded resource. Stored and remote sources are independent policy.

```haxe
function new(id:Int, backend:IAudio, releaseSource:() -> Void)
```

- `new`: Owns backend stream id; releaseSource ends the stored copy's lease after the stream is destroyed. AudioResources.loadStream creates it.

## IAudio

*class* in `src/helix/audio/IAudio.hx`

Sound output on a platform: clips (PCM held whole) and streams (played as they're read), each played as voices. Ids are the adapter's; lifetimes, volume checks, waiting for audio to start and decoding are the shared AudioResources' and AudioDecoding's. A browser starts its audio on the page's first key or pointer press and suspends it while the page is hidden or blurred; natively it runs once the device opens.

```haxe
function isAvailable():Bool
function isRunning():Bool
function createClip(samples:haxe.io.Bytes):Int
function destroyClip(clip:Int):Void
function openStream(source:AudioLocation, done:StreamOpenResult -> Void):() -> Void
function destroyStream(stream:Int):Void
function playClip(clip:Int, loop:Bool, volume:Float):Int
function playStream(stream:Int, loop:Bool, volume:Float):Int
function stop(voice:Int):Void
function pause(voice:Int, paused:Bool):Void
function setVolume(voice:Int, volume:Float):Bool
function isPlaying(voice:Int):Bool
function poll():Void
function shutdown():Void
```

- `isAvailable`: Whether there is an output at all: false natively without an audio device.
- `isRunning`: Whether voices start now: in a browser, once a key or pointer press has unlocked audio.
- `createClip`: Copies samples (mono 32-bit float PCM at 44100 Hz, checked) into a new clip and returns its id. Throws when there's no room for a clip.
- `destroyClip`: Destroys clip and stops its voices. Throws for an unknown clip.
- `openStream`: Opens source for playing as it's read; done runs once on the host thread, never during this call: Opened, or Failed for a source the platform can't open (natively a remote URL or a file its codec can't read; in a browser a load error or no metadata within 15 seconds). A Stored lease stays the caller's and must outlive the stream. Returns abort: nothing is called after it, and an opened stream is closed.
- `destroyStream`: Destroys stream and stops its voices. Throws for an unknown stream.
- `playClip`: Starts clip at volume (0 to 1), looping if asked, and returns its voice, or 0 when it can't start (no free voice). Throws for an unknown clip.
- `playStream`: Starts stream from its beginning at volume (0 to 1), looping if asked, and returns its voice, or 0 when it can't start. Throws for an unknown stream.
- `stop`: Stops voice; nothing for an unknown or ended one.
- `pause`: Pauses voice, or resumes it when paused is false; nothing for an unknown one.
- `setVolume`: Sets voice's volume, 0 to 1. False, changing nothing, for a voice not playing (unknown, stopped or ended) or a volume outside 0 to 1.
- `isPlaying`: Whether voice is still playing (or paused); false once it ended or was stopped.
- `poll`: Keeps streamed voices fed and delivers what arrived from the platform's threads; the shared AudioResources calls it once a frame.
- `shutdown`: Stops every voice, destroys every stream and clip, and closes the output.

## IAudioDecoder

*class* in `src/helix/audio/IAudioDecoder.hx`

Compressed audio decoding on a platform: a whole Ogg (Vorbis, Opus) or MP3 file, mono or stereo, into mono 32-bit float PCM at 44100 Hz, samples -1 to 1 (mixed down and resampled as the platform can). Limits, the WAV path, queuing and cancellation are the shared AudioDecoding's.

```haxe
function decode(encoded:haxe.io.Bytes, done:AudioDecodeResult -> Void):Void
function poll():Void
```

- `decode`: Decodes encoded; done runs once on the host thread, never during this call: Decoded or Failed (a file it can't read).
- `poll`: Delivers what finished on the platform's threads since the last poll; the shared AudioDecoding calls it once a frame.

## Pcm

*class* in `src/helix/audio/Pcm.hx`

The PCM format of clips: mono 32-bit float samples.

```haxe
static function validate(samples:haxe.io.Bytes):Void
```

- `validate`: Throws unless samples is non-empty, a whole number of 4-byte floats, and every sample is finite and -1 to 1.

## PlayState

*abstract* in `src/helix/audio/PlayState.hx`

Where a playback is: playing, paused, stopped (by stop(), or it never started), or complete (it played to its end).

## StreamOpenResult

*enum* in `src/helix/audio/IAudio.hx`

How opening a stream ended: its id, or a failure message.

- `Opened(id:Int)`
- `Failed(message:String)`

## Wav

*class* in `src/helix/audio/Wav.hx`

Minimal, bounded RIFF decoder for mono PCM16/44100 assets.

```haxe
static function decode(bytes:haxe.io.Bytes):haxe.io.Bytes
```

- `decode`: Decodes a whole mono PCM16 44100 Hz WAV of at most 4 seconds into mono 32-bit float PCM, -1 to 1. Throws for a bad header or chunk, another format, or missing or trailing data.
