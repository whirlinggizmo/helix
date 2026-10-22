# helix.time

[Back to the index](README.md)

## Clock

*class* in `src/helix/time/Clock.hx`

A game's time, from the frames' (FrameClock): scaled and paused as a whole, so everything fed by it (a Ticker's steps, tweens, timers, animators, emitters) slows, stops and resumes together, with nothing else to flag. Time.clock is the program's, updated by the runner before each frame; a game keeps more where times differ: a menu's clock running while the world's is paused (Unity's unscaled time). Each frame has two measures, as FrameClock's: the delta, held at MAX_DELTA (a stall moves animation on by that much), and the elapsed time, unheld, for a Ticker, which bounds its own catch-up. Both are 0 while paused.

```haxe
function new()
function update(frameElapsed:Float):Void
var delta(default, null):Float
var elapsed(default, null):Float
var time(default, null):Float
var timeScale(default, set):Float
var paused(default, null):Bool
function pause():Void
function resume():Void
```

- `new`: A clock at 0, running at the frames' pace.
- `update`: Advances by frameElapsed seconds of the frames' time (Time.frameElapsed), scaled; nothing while paused. Once a frame.
- `delta`: This frame's delta in its seconds: the elapsed time held at FrameClock.MAX_DELTA, for animation; 0 while paused.
- `elapsed`: This frame's elapsed time in its seconds, unheld, for a Ticker; 0 while paused.
- `time`: Its seconds so far: the deltas summed (what animation has seen), not moving while paused.
- `timeScale`: How fast it runs against the frames: 1 as they do, 0.5 slow motion, 0 still. 0 or more (under 0, or NaN, is 0).
- `paused`: Whether it's paused: updates give 0 until resume.
- `pause`: Stops it; the time scale is kept for resume.
- `resume`: Runs it on from where it stopped.

## Ticker

*class* in `src/helix/time/Ticker.hx`

A fixed-rate simulation inside the frame callback, fed a clock's elapsed time (Clock.elapsed: paused or scaled there, so the ticks are too). Each tick sees the input's tick edges, consumed after it, so a press is seen by exactly one tick. fraction is how far the frame is between the last tick and the next, for drawing between them.

```haxe
function new(?rate:Float = 60., ?input:IInput)
var rate(default, set):Float
var delta(default, null):Float
var fraction(default, null):Float
var maxSteps(default, set):Int
function advance(elapsed:Float, tick:() -> Void):Int
```

- `new`: Ticks at rate a second (clamped as the rate property is), consuming input's tick edges after each: the program's (Input) when not given, read as it's used, so a ticker made before the program runs (a field's initial value) works.
- `rate`: Ticks a second. At least 1e-6 (0 or less, or NaN, is 1e-6).
- `delta`: Seconds a tick simulates.
- `fraction`: How far the frame is from the last tick to the next, from 0 to under 1.
- `maxSteps`: Ticks run in one frame at most; a longer stall loses the rest rather than spiralling. At least 1.
- `advance`: Runs tick for each step due after elapsed seconds (a Clock's elapsed, Time.clock's for the game's time), at most maxSteps of them; returns how many ran.

## Time

*class* in `src/helix/time/Time.hx`

The program's time: the host's clock, the frames' timings and the game's clock (clock), which tickers, tweens, timers, animators and emitters are fed. The program's one, a static class over the runner's frame clock, bound by the runner from its init to its cleanup.

```haxe
static var clock(default, null):Clock
static var time(get, never):Float
static var frameElapsed(get, never):Float
static var frameCpu(get, never):Float
static var frameInterval(get, never):Float
```

- `clock`: The game's time: the frames' time scaled and paused as a whole (Clock), updated before each frame; what tickers, tweens, timers, animators and emitters are fed. Null outside the runner's init and cleanup. Kept across a hot reload (@:hot): set once by the runner, nothing would set it again.
- `time`: Seconds on the host's monotonic clock.
- `frameElapsed`: The seconds since the last frame, unheld (the app's frame dt is held at 0.1), and 0 on the first: what a fixed-rate simulation (Ticker.advance) is fed, so a slow frame is caught up in ticks instead of lost.
- `frameCpu`: The last frame's CPU time in milliseconds, its services' polls included.
- `frameInterval`: Milliseconds between the last two frames' starts (0 for the first).

## Timer

*class* in `src/helix/time/Timers.hx`

One timer of a Timers set: cancelled by the game, or done once it has fired (a repeating one never is until cancelled).

```haxe
var remaining(default, null):Float
var interval(default, null):Float
var repeating(default, null):Bool
var done(default, null):Bool
function cancel():Void
```

- `remaining`: Seconds until it fires (next), 0 or less when due.
- `interval`: Its interval, the seconds it was set with.
- `repeating`: Whether it repeats.
- `done`: Whether it's over: cancelled, or fired once for a one-shot.
- `cancel`: Stops it from firing again (nothing if it's done).

## Timers

*class* in `src/helix/time/Timers.hx`

Timers on a clock: after(seconds, f) runs f once, every(seconds, f) runs it each interval, both measured in the clock's deltas (Clock.delta, so a stall fires each once, not a burst) when update runs each frame. Those due in one update fire in the order made; one made or cancelled inside a callback takes effect from the next update.

```haxe
function new()
function after(seconds:Float, f:() -> Void):Timer
function every(seconds:Float, f:() -> Void):Timer
var count(get, never):Int
function clear():Void
function update(delta:Float):Void
```

- `new`: No timers yet.
- `after`: Runs f once, seconds from now (at once on the next update for 0 or less).
- `every`: Runs f every seconds, starting one interval from now, until cancelled. Throws for an interval of 0 or less, which would never stop firing.
- `count`: How many are set (running or waiting), done ones gone.
- `clear`: Cancels every timer.
- `update`: Advances every timer by delta seconds (a clock's delta) and runs those due. Once a frame.
