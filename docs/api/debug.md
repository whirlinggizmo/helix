# helix.debug

[Back to the index](README.md)

## Autopilot

*class* in `src/helix/debug/Autopilot.hx`

Bounded JSON commands produce normal input, a tick at a time; probes (named values) are supplied by the app. A script replays alike on every target when it keeps two rules: - It waits on state, never on time, for anything that isn't the simulation's (a load, a menu, a screen appearing): `wait` on a probe, its limit in seconds (`"seconds"`); tick counts (`"timeout"`, `hold`) only for what the simulation itself does, once a wait has found it running. - The game starts each replayed phase from a known state when it begins: play starting fresh from the seed (a new level), however late it starts; a title screen's motion is dressing, not part of the game. Then a menu, a slow load or a frame's timing can delay a start without the game differing.

```haxe
function new(json:String, ?screenshot:Null<String> -> Void, ?press:String -> Bool)
function isDone():Bool
function getTickCount():Int
function getSeed():Int
function getOutcomes():Array<Dynamic>
function advance(probe:String -> Dynamic):IInput
function getSnapshot():Dynamic
```

- `new`: Checks a whole script ({version: 1, seed, commands}: press, hold, wait, assert, screenshot; at most 128) and throws on anything invalid or unknown. A wait has one limit: "timeout" in ticks, or "seconds" of the clock. A click uses a UI's widget by name, waiting (as a web suite's actions do) until press, the app's (Ui.press, say), finds it shown and usable, within its limit; without press it fails. A screenshot command calls screenshot with its name (null for the default name; Screenshots.take, say), or does nothing without one.
- `isDone`: Whether every command has finished.
- `getTickCount`: Ticks the commands have run so far.
- `getSeed`: The script's seed, 1 to 2147483647, for the app's random numbers.
- `getOutcomes`: One record a finished command: its index, op, the tick it finished on and the probe's value.
- `advance`: Once a tick: runs commands until one needs this tick, asking probe for named values, and returns the input to play it with. Throws when a wait times out or an assert fails.
- `getSnapshot`: Progress as a record: completed, ticks, the current command index and the outcomes.

## FpsOverlay

*class* in `src/helix/debug/FpsOverlay.hx`

The frame rate and the frame's cost, averaged over half a second, drawn in a corner in screen units (a Camera2D at zoom 1).

```haxe
function new()
function getFrameRate():Float
function getFrameMs():Float
function update(dt:Float, cpu:Float):Void
function draw(batch:Batch2D, x:Float, y:Float, ?size:Float = 16., ?color:Int = 0x7fe07fff):Void
```

- `new`: An overlay showing 0 until half a second of frames has been seen.
- `getFrameRate`: Frames a second over the last half second.
- `getFrameMs`: The frame's average cost in milliseconds over the last half second.
- `update`: dt: the frame's interval; cpu: what the frame cost, in milliseconds (Services.getFrameCpu).
- `draw`: Draws the rate and cost with the top-left at x, y; size is the glyph height and color is 0xRRGGBBAA.

## ITestHarness

*class* in `src/helix/debug/ITestHarness.hx`

How a program hands its result to the check that launched it (an autopilot's final state, a test's checks). A test hook only: a game's profile can plug in one that does nothing.

```haxe
function publish(value:Dynamic):Void
```

- `publish`: Hands value (JSON-able) to the check: window.result in a browser; natively a JSON line on stdout, also written to the file HELIX_RESULT names.
