# Milestone 12: input actions and audio control (design)

The design for the roadmap's milestone 12: an action map, audio buses with fades, pitch and pan, and native network streaming. Settled with the user on 2026-10-18: touch regions are anchored on the visible area in the game's units (`Screen`'s), a rebind replaces the binding of the same device kind, and buses are objects a sound is played through, their names only for saving. **Done when:** the `ui` example's settings screen rebinds a key and sets the buses, and a native stream starts before its download ends.

## What exists

- `IInput` asks by device: `isDown(Key)`, `isPadDown(PadButton)`, `getPadAxis(PadAxis)` across pads, touches and gestures; ticks and frames each have their own pressed and released. `InputState` keeps the states and `InputRouter` feeds them from a source. The autopilot replaces the source, so anything built on `IInput` replays.
- The earlier framework's action map: an action is a name with up to 16 bindings, each giving a value from -1 to 1. A binding is a key, a pair of keys, a pad button, a pair of pad buttons, a pad axis with a side and a threshold, or a touch region. The action is whichever binding is pushed furthest across every pad, with `axis`, `value`, `down` at 0.5 or the threshold, `pressed` and `released`, and text for each binding for a remap screen.
- Audio: `IAudio` plays clips and streams with a per-voice volume, pause and stop; `AudioResources` (the static `Audio`) loads and plays, `AudioPlayback` is a voice with `volume` and `state`. Natively one mixer in C (`adapters/shared/mixer.c`) mixes mono voices into the output with a resampling step; in the browser Web Audio.
- Native streams play from a stored file through libsndfile, which already reads from memory through its virtual I/O. `Remote` is refused natively ("ensure the asset first"). The native HTTP adapter hands the body over in parts as it arrives.

## Actions

`helix.input.Actions`, built on `IInput`, so the autopilot drives it:

```haxe
var actions = new Actions(Input.instance);
actions.bind("jump", Keyboard(Space));
actions.bind("jump", Pad(South));
actions.bind("steer", KeyboardPair(Left, Right));
actions.bind("steer", Axis(LeftX, 0, .15));
actions.bind("fire", TouchRegion(BottomRight, -120, -120, 96, 96));   // anchored on the visible area, in Screen's units

if (actions.isPressed("jump")) jump();
car.steer = actions.axis("steer");
```

- **A binding** is an enum, `Binding`: `Keyboard(key)`, `KeyboardPair(negative, positive)`, `Pad(button)`, `PadPair(negative, positive)`, `Axis(axis, side, threshold)`, `Mouse(button)`, `TouchRegion(anchor, x, y, width, height)` (named apart from the types `Key`, `PadButton`, `PadAxis`, `MouseButton` and `Touch`, so a file importing `Binding` still writes `Key.Space`). A touch region is an anchor on the visible area (`Screen.visibleX` and the rest: a corner, an edge's middle or the center) and an offset and size from it in the game's units, converted through `Screen` when a finger lands: with a design size set it scales with everything the game draws and stays where the design put it, following the visible edge in the modes that show more on one axis; without one a unit is a logical pixel and the region keeps its physical size. A binding to a UI widget, so the drawn button and the pressed region are one, comes when the UI asks.
- **Reading**: `axis(name)` -1 to 1, `value(name)` 0 to 1, `isDown`, `isPressed`, `isReleased` per tick and the `Frame` pair as `IInput` has them, the binding pushed furthest winning, across every pad. An unknown action reads as up, not as an error, so a game's code runs before its bindings load.
- **Rebinding**: `capture(name, done:Binding->Void, ?cancel)` waits for the next key, button, axis past a half or touch, Escape cancelling, then replaces the binding of the same device kind (a keyboard rebind leaves the pad's binding alone). `bindings(name)`, `unbind(name, binding)`, `clear(name)`, and `describe(binding)` gives the text a remap screen shows ("Space", "Pad south", "Left stick X", "Touch").
- **Saving**: `actions.save()` and `load()` as JSON through `Storage` under one key, beside the defaults the game bound in code, which `reset()` restores. A saved map naming an action the game no longer binds is dropped.
- **Names are strings.** A game wanting typed names writes an enum abstract over String and passes that.

## Audio buses, fades, pitch, pan

`helix.audio.Bus`: an object with a name, a parent, a volume, a mute and its fades. `Audio.master` is the root, `Audio.music` and `Audio.effects` are under it from the start, and a game adds its own, `final ambience = Audio.addBus("ambience", Audio.effects)`, holding it as any reference (decision 61: references are objects, never names). A sound is played through its bus, `ambience.play(rain, true)`, `Audio.music.play(theme, true)`; `Audio.play(sound)` is `Audio.effects.play(sound)`. The bus tree is plain engine data, made before the runner binds the service, so a bus can be made in a static initializer (`@:hot static final`, so a native reload keeps it) and reaches the service only when it plays. Its name is used only to save and load the volumes.

- **Volume** on a bus and a playback is a property, 0 to 1, clamped; a playback's heard volume is its own times its buses' up to the master. Muting is a bus's `muted` flag, keeping the volume for unmuting.
- **Fades**: `fade(to, seconds, ?done)` on a bus and on a playback, linear in decibels so a fade sounds even, with `stopWhenSilent` for fade-out-and-stop. Crossfading music is two playbacks' fades; a helper `Audio.crossfade(from, to, seconds)` does both.
- **Pitch** on a playback: 0.25 to 4, 1 normal, the playback rate (it changes the length too). **Pan** on a playback: -1 left to 1 right, equal power.
- **Where it runs**: the buses, the fades and the heard volume are the engine's, worked out once a frame, so both targets do the same arithmetic. The contract gains `setPitch(voice, pitch)` and `setPan(voice, pan)` beside `setVolume`; each adapter ramps a volume or pan change across its next block (the mixer per callback, Web Audio by `setTargetAtTime`) so a fade stepped at the frame rate doesn't click. The native mixer becomes stereo out of mono voices for the pan, its step multiplied by the pitch.
- **Saved** like the actions: `Audio.saveBuses()`/`loadBuses()`, the volumes and mutes under one Storage key.

## Native network streaming

A native `Remote` stream plays while it downloads, and the file is kept in the asset cache when the download ends, as the browser keeps it:

- The asset service, asked to locate a remote stream, starts the download into a growing buffer and returns a new `AudioLocation.Downloading(source)` where `source` reports the bytes so far, the total from Content-Length when given, and the end.
- The native decoder opens it through libsndfile's virtual I/O over that buffer. libsndfile reads ahead and takes a short read as the end of the file, so the producer decodes only while the download is a margin ahead of the decoder's position (64 KB, or the whole file once done), and holds the voice's ring otherwise; with the stream ring's 2 s that covers a slow connection's gaps. A file without Content-Length can't be opened this way (libsndfile asks the length): it waits for the whole download, as today's ensure does.
- The finished download is stored in the cache under the asset's key, so the next play is local.
- Shown by a test fixture served slowly: the services tests' native run starts a stream from a local server that sends 32 KB every 100 ms, and checks the voice is playing before the server has sent the last byte.

## The example

The `ui` example gains a settings screen: a list of actions with each one's bindings as text and a Rebind button (capture, then save), and three sliders for master, music and effects (saved), with music playing under it to hear them. Its autopilot rebinds an action by a pressed key and checks the binding's text, and moves a slider and checks the bus volume; both the same final game on both targets.

## Order of work

1. Actions: the enum, the map, reading, capture, describe, save and load; unit tests through a scripted `IInput`.
2. Audio contract: pitch and pan in both adapters (the mixer to stereo), the volume ramps; the engine's buses, fades, crossfade and saving; unit tests over a recording `IAudio` double.
3. Native network streaming: the growing source, the decoder's virtual I/O over it, the cache write, the slow-server services test.
4. The `ui` example's settings screen and autopilot; docs (CONVENTIONS for actions and buses, ARCHITECTURE, DECISIONS, the API reference); checkpoint on both targets.

Phases 1 and 2 can run as parallel agents; 3 after 2 (it touches the native audio); 4 last.
