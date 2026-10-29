# helix.services.time

[Back to the index](README.md)

## Time

*class* in [`services/src/helix/services/time/Time.hx`](../../services/src/helix/services/time/Time.hx), `import helix.services.time.Time;`, implements `IPollable`

Provides a frame's time: the game's seconds, which can be scaled and paused and have timers on them, and the real seconds beside them.

The program constructs one and calls `poll` once a frame; game code then moves by `delta`. Something that must keep time while the game is paused, such as a menu's animation, moves by `realDelta`, or by a second `Time` of its own.

```haxe
var time = new Time(system);
time.every(1, () -> trace('at $x, $y'));
// each frame:
time.poll();
x += speed * time.delta;
```

```haxe
function new(system:ISystem)
var delta(default, null):Float
var realDelta(default, null):Float
var elapsed(default, null):Float
var scale(default, set):Float
var paused:Bool
var maxDelta(default, set):Float
function after(seconds:Float, f:() -> Void):Timer
function every(seconds:Float, f:() -> Void):Timer
function poll():Void
function dispose():Void
```

- `new`: Creates the game's time at 0.
  - `system`: The platform's facts: it reads their monotonic time (`getTime`).
- `delta`: Gets the game's seconds this frame: the real seconds times `scale`, and 0 while paused.
- `realDelta`: Gets the real seconds this frame: not scaled, running while paused, at most `maxDelta`.
- `elapsed`: Gets the game's seconds since this was made: the sum of every `delta`.
- `scale`: Gets or sets how fast the game's time runs: 1 as real time, 2 twice as fast, 0 stopped; 0 or more, 1 by default.
- `paused`: Gets or sets a value indicating whether the game's time stands still: `delta` is 0 and the timers wait; false by default.
- `maxDelta`: Gets or sets the most real seconds one frame counts, so a frame after a stall (a page in the background, a debugger) doesn't jump; more than 0, 0.25 by default.
- `after`: Calls a function once, after some of the game's time.
  - `seconds`: The game's seconds from now; 0 or less calls it at the next `poll`.
  - `f`: The function.
  - returns: The timer, to cancel it.
- `every`: Calls a function each time some of the game's time passes, until it's cancelled.
  - `seconds`: The game's seconds between calls, more than 0.
  - `f`: The function.
  - returns: The timer, to cancel it.

  A frame longer than the interval calls it once for each interval it holds.
- `poll`: Measures this frame from the platform's time, and calls the timers that are due, in the order they fall due; call once a frame.
- `dispose`: Cancels every timer.

## Timer

*class* in [`services/src/helix/services/time/Timer.hx`](../../services/src/helix/services/time/Timer.hx), `import helix.services.time.Timer;`

Represents a function called after some of the game's time, once or repeatedly (`Time.after`, `Time.every`).

```haxe
var remaining(default, null):Float
var interval(default, null):Float
var done(default, null):Bool
function cancel():Void
```

- `remaining`: Gets the game's seconds until the next call.
- `interval`: Gets the game's seconds between calls for a repeating timer, or 0 for one called once.
- `done`: Gets a value indicating whether it will call its function no more: called once, or cancelled.
- `cancel`: Stops it: its function isn't called again. Does nothing once it's done.
