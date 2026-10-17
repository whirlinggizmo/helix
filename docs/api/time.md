# helix.time

[Back to the index](README.md)

## Clock

*class* in `src/helix/time/Clock.hx`

A game's time, from the frames' (FrameClock): scaled and paused as a whole, so everything fed by it (a Ticker's steps, tweens, timers, animators, emitters) slows, stops and resumes together, with nothing else to flag. Services.clock is the program's, updated by the runner before each frame; a game keeps more where times differ: a menu's clock running while the world's is paused (Unity's unscaled time). Each frame has two measures, as FrameClock's: the delta, held at MAX_DELTA (a stall moves animation on by that much), and the elapsed time, unheld, for a Ticker, which bounds its own catch-up. Both are 0 while paused.

```haxe
function new()
function update(frameElapsed:Float):Void
function getDelta():Float
function getElapsed():Float
function getTime():Float
function getTimeScale():Float
function setTimeScale(value:Float):Bool
function isPaused():Bool
function pause():Void
function resume():Void
```

- `new`: A clock at 0, running at the frames' pace.
- `update`: Advances by frameElapsed seconds of the frames' time (Services.getFrameElapsed), scaled; nothing while paused. Once a frame.
- `getDelta`: This frame's delta in its seconds: the elapsed time held at FrameClock.MAX_DELTA, for animation; 0 while paused.
- `getElapsed`: This frame's elapsed time in its seconds, unheld, for a Ticker; 0 while paused.
- `getTime`: Its seconds so far: the deltas summed (what animation has seen), not moving while paused.
- `getTimeScale`: How fast it runs against the frames: 1 as they do, 0.5 slow motion, 0 still.
- `setTimeScale`: Sets how fast it runs; false, changing nothing, for a scale under 0.
- `isPaused`: Whether it's paused: updates give 0 until resume.
- `pause`: Stops it; the time scale is kept for resume.
- `resume`: Runs it on from where it stopped.

## Ticker

*class* in `src/helix/time/Ticker.hx`

A fixed-rate simulation inside the frame callback, fed a clock's elapsed time (Clock.getElapsed: paused or scaled there, so the ticks are too). Each tick sees the input's tick edges, consumed after it, so a press is seen by exactly one tick. getFraction is how far the frame is between the last tick and the next, for drawing between them.

```haxe
function new(input:IInput, ?rate:Float = 60.)
function getRate():Float
function setRate(value:Float):Bool
function getDelta():Float
function getFraction():Float
function getMaxSteps():Int
function setMaxSteps(value:Int):Bool
function advance(elapsed:Float, tick:() -> Void):Int
```

- `new`: Ticks at rate a second, consuming input's tick edges after each. Throws for a rate of 0 or less.
- `getRate`: Ticks a second.
- `setRate`: False for a rate of 0 or less.
- `getDelta`: Seconds a tick simulates.
- `getFraction`: How far the frame is from the last tick to the next, from 0 to under 1.
- `getMaxSteps`: Ticks run in one frame at most; a longer stall loses the rest rather than spiralling.
- `setMaxSteps`: False for fewer than 1.
- `advance`: Runs tick for each step due after elapsed seconds (a Clock's getElapsed, Services.clock's for the game's time), at most getMaxSteps of them; returns how many ran.

## Timer

*class* in `src/helix/time/Timers.hx`

One timer of a Timers set: cancelled by the game, or done once it has fired (a repeating one never is until cancelled).

```haxe
function getRemaining():Float
function getInterval():Float
function isRepeating():Bool
function isDone():Bool
function cancel():Void
```

- `getRemaining`: Seconds until it fires (next), 0 or less when due.
- `getInterval`: Its interval, the seconds it was set with.
- `isRepeating`: Whether it repeats.
- `isDone`: Whether it's over: cancelled, or fired once for a one-shot.
- `cancel`: Stops it from firing again (nothing if it's done).

## Timers

*class* in `src/helix/time/Timers.hx`

Timers on a clock: after(seconds, f) runs f once, every(seconds, f) runs it each interval, both measured in the clock's deltas (Clock.getDelta, so a stall fires each once, not a burst) when update runs each frame. Those due in one update fire in the order made; one made or cancelled inside a callback takes effect from the next update.

```haxe
function new()
function after(seconds:Float, f:() -> Void):Timer
function every(seconds:Float, f:() -> Void):Timer
function getCount():Int
function clear():Void
function update(delta:Float):Void
```

- `new`: No timers yet.
- `after`: Runs f once, seconds from now (at once on the next update for 0 or less).
- `every`: Runs f every seconds, starting one interval from now, until cancelled. Throws for an interval of 0 or less, which would never stop firing.
- `getCount`: How many are set (running or waiting), done ones gone.
- `clear`: Cancels every timer.
- `update`: Advances every timer by delta seconds (a clock's getDelta) and runs those due. Once a frame.
