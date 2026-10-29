# helix.services.time

[Back to the index](README.md)

## Time

*class* in [`services/src/helix/services/time/Time.hx`](../../services/src/helix/services/time/Time.hx), `import helix.services.time.Time;`, implements `IPollable`

Provides a frame's time, in the game's seconds and in real seconds.

The game's seconds can be scaled and paused, and timers run on them. The program constructs one `Time` and calls `poll` once a frame. Game code then moves by `delta`. Something that must keep time while the game is paused, such as a menu's animation, moves by `realDelta`, or by a second `Time` of its own.

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

- `new`: Creates the game's time, starting at 0.
  - `system`: The platform's system, whose monotonic time (`getTime`) it reads.
- `delta`: Gets the game's seconds this frame, which is `realDelta` times `scale`, or 0 while paused.
- `realDelta`: Gets the real seconds this frame, at most `maxDelta`. It isn't scaled, and it keeps running while paused.
- `elapsed`: Gets the game's seconds since this `Time` was created, which is the sum of every `delta`.
- `scale`: Gets or sets how fast the game's time runs. Defaults to 1.
  1 runs as real time, 2 twice as fast, and 0 stops it. A negative value is clamped to 0.
- `paused`: Gets or sets a value indicating whether the game's time stands still. Defaults to false.
  While paused, `delta` is 0 and the timers wait.
- `maxDelta`: Gets or sets the most real seconds one frame counts. Defaults to 0.25, and is clamped to at least 0.001.
  It keeps a frame after a stall, such as a page in the background or a debugger, from jumping ahead.
- `after`: Calls a function once, after some of the game's time.
  - `seconds`: The game's seconds from now. 0 or less calls it at the next `poll`.
  - `f`: The function.
  - returns: The timer, which cancels the call.
- `every`: Calls a function each time an interval of the game's time passes, until it is cancelled.
  - `seconds`: The game's seconds between calls. Must be more than 0.
  - `f`: The function.
  - returns: The timer, which cancels the calls.
  - throws `String`: When seconds is 0 or less.

  A frame longer than the interval calls it once for each interval the frame holds.
- `poll`: Measures this frame from the platform's time, and calls the timers that are due, in the order they fall due.
  Call it once a frame. A timer created by a timer's function waits for the next `poll`.
- `dispose`: Cancels every timer.

## Timer

*class* in [`services/src/helix/services/time/Timer.hx`](../../services/src/helix/services/time/Timer.hx), `import helix.services.time.Timer;`

Represents a function called after some of the game's time, once (`Time.after`) or repeatedly (`Time.every`).

```haxe
var remaining(default, null):Float
var interval(default, null):Float
var done(default, null):Bool
function cancel():Void
```

- `remaining`: Gets the game's seconds until the next call. It is updated at each `Time.poll`.
- `interval`: Gets the game's seconds between calls for a repeating timer, or 0 for one called once.
- `done`: Gets a value indicating whether the timer will call its function no more, because it was called once or cancelled.
- `cancel`: Cancels the timer, so its function isn't called again. Does nothing once it is done.
