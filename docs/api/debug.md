# helix.debug

[Back to the index](README.md)

## Autopilot

*class* in `src/helix/debug/Autopilot.hx`

Bounded JSON commands produce normal input, a tick at a time; probes (named values) are supplied by the app. A script replays alike on every target when it keeps two rules: - It waits on state, never on time, for anything that isn't the simulation's (a load, a menu, a screen appearing): `wait` on a probe, its limit in seconds (`"seconds"`); tick counts (`"timeout"`, `hold`) only for what the simulation itself does, once a wait has found it running. - The game starts each replayed phase from a known state when it begins: play starting fresh from the seed (a new level), however late it starts; a title screen's motion is dressing, not part of the game. Then a menu, a slow load or a frame's timing can delay a start without the game differing. A `sample` reads the frame's pixels at points and puts them in snapshot's samples under its name, which tools/example.py compares between the browser and native: `{"op": "sample", "name": "lit", "points": [[x, y], ...]}`, the points in the design's units (Screen's), 1 to 64 of them; `"tolerance"`, how far each channel (0 to 255) may differ across targets, 3 when not given; and `"differsFrom"` with `"by"`, an earlier sample's name and an amount, failing the script unless every point differs from the same point there by at least that much in some channel (an effect turned on against it off, so a shader drawing nothing fails). The frame read is the one drawn after the ticks before it: while it waits for that frame to end, awaitingFrame is true and the app runs no tick.

```haxe
function new(json:String, ?screenshot:Null<String> -> Void, ?press:String -> Bool, ?sample:(points:Array<Array<Float>>, done:Array<Array<Int>> -> Void, failed:String -> Void) -> Void)
var done(default, null):Bool
var tickCount(get, never):Int
var input(get, never):IInput
var seed(default, null):Int
var outcomes(default, null):Array<Dynamic>
var awaitingFrame(default, null):Bool
function advance(probe:String -> Dynamic):IInput
var snapshot(get, never):Dynamic
```

- `new`: Checks a whole script ({version: 1, seed, commands}: press, hold, wait, assert, click, screenshot, sample; at most 128) and throws on anything invalid or unknown. A wait has one limit: "timeout" in ticks, or "seconds" of the clock. A click uses a UI's widget by name, waiting (as a web suite's actions do) until press, the app's (Ui.press, say), finds it shown and usable, within its limit; without press it fails. A screenshot command calls screenshot with its name (null for the default name; Screenshots.take, say), or does nothing without one. A sample calls sample with its points (Screenshots.sample, say), which calls done with each point's color as [r, g, b, a], 0 to 255, once the frame has ended, or failed; without sample it fails.
- `done`: Whether every command has finished.
- `tickCount`: Ticks the commands have run so far.
- `input`: The input the script plays, the one advance returns: the same object for the whole script, so what reads it (a UI, an Actions map) can be given it before the first tick.
- `seed`: The script's seed, 1 to 2147483647, for the app's random numbers.
- `outcomes`: One record a finished command: its index, op, the tick it finished on and the probe's value.
- `awaitingFrame`: Whether a sample waits for the frame being drawn to end: the input advance returned isn't to be played, and the app runs no tick this frame (its tick loop stops when this is true, as it does when done).
- `advance`: Once a tick: runs commands until one needs this tick, asking probe for named values, and returns the input to play it with. Throws when a wait times out or an assert fails.
- `snapshot`: Progress as a record: completed, ticks, the current command index, the outcomes and the samples (by name: points, colors as [r, g, b, a] and tolerance).

## FpsOverlay

*class* in `src/helix/debug/FpsOverlay.hx`

The frame rate and the frame's cost, averaged over half a second, drawn in a corner in screen units (a Camera2D at zoom 1).

```haxe
function new()
var frameRate(get, never):Float
var frameMs(get, never):Float
function update(dt:Float, cpu:Float):Void
function draw(batch:Batch2D, x:Float, y:Float, ?size:Float = 16., ?color:Int = 0x7fe07fff):Void
```

- `new`: An overlay showing 0 until half a second of frames has been seen.
- `frameRate`: Frames a second over the last half second.
- `frameMs`: The frame's average cost in milliseconds over the last half second.
- `update`: dt: the frame's interval; cpu: what the frame cost, in milliseconds (Time.frameCpu).
- `draw`: Draws the rate and cost with the top-left at x, y; size is the glyph height and color is 0xRRGGBBAA.

## ITestHarness

*class* in `src/helix/debug/ITestHarness.hx`

How a program hands its result to the check that launched it (an autopilot's final state, a test's checks). A test hook only: a game's profile can plug in one that does nothing.

```haxe
function publish(value:Dynamic):Void
```

- `publish`: Hands value (JSON-able) to the check: window.result in a browser; natively a JSON line on stdout, also written to the file HELIX_RESULT names.

## TestHarness

*class* in `src/helix/debug/TestHarness.hx`

Where results go for the check that launched the program (an autopilot's final state, a test's checks). The program's one, a static class: each member forwards to instance, written by helix.macro.Facade from ITestHarness's public members with their doc comments.

```haxe
static var instance(default, null):ITestHarness
static function publish(value:Dynamic):Void
```

- `instance`: The harness forwarded to: the profile's from its init to its cleanup, null outside them. Kept across a hot reload (@:hot): set once by the runner, nothing would set it again.
- `publish`: Hands value (JSON-able) to the check: window.result in a browser; natively a JSON line on stdout, also written to the file HELIX_RESULT names.
