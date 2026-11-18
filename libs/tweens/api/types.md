# helix.tweens

[Back to the library](README.md)

## ColorTween

*class* in [`libs/tweens/src/helix/tweens/ColorTween.hx`](../src/helix/tweens/ColorTween.hx), `import helix.tweens.ColorTween;`, extends `EasedTween`

Represents a color fading from one color to another, each of its four channels on its own.

The colors are integers of four bytes in any one order (0xAARRGGBB as helix-math's `Color` holds them, or another), the same order for all three.

```haxe
var flash = new ColorTween(0xffffffff, 0xffff0000, 0.2, Ease.outQuad);
// each frame
flash.update(dt);
sprite.tint = flash.value;
```

```haxe
function new(from:Int, to:Int, duration:Float, ?ease:Ease)
var from:Int
var to:Int
var value(get, never):Int
```

- `new`: Creates a tween of a color, at its start.
  - `from`: The color at the start.
  - `to`: The color at the end.
  - `duration`: The seconds one play takes, 0 or more.
  - `ease`: Optional. The easing curve; a straight line when omitted.
- `from`: Gets or sets the color at the start.
- `to`: Gets or sets the color at the end.
- `value`: Gets the color now, its channels rounded and kept to 0 to 255 where the easing curve overshoots.

## EasedTween

*class* in [`libs/tweens/src/helix/tweens/EasedTween.hx`](../src/helix/tweens/EasedTween.hx), `import helix.tweens.EasedTween;`, extends `Tween`

Represents a play along an easing curve, from 0 to 1. `FloatTween`, `Vector3Tween` and the other kinds move a value by it, and a program moves a value of its own by `amount`.

```haxe
var grow = new EasedTween(0.5, Ease.outBack);
// each frame
grow.update(dt);
rect.width = Interpolate.lerp(40, 200, grow.amount);
rect.height = Interpolate.lerp(10, 60, grow.amount);
```

```haxe
function new(duration:Float, ?ease:Ease)
var ease:Ease
var amount(default, null):Float
```

- `new`: Creates a tween at its start.
  - `duration`: The seconds one play takes, 0 or more. A play of 0 seconds jumps to its end.
  - `ease`: Optional. The easing curve, one of `Ease`'s (`Ease.outBounce`) or a function of the program's own (`Ease.of`); a straight line when omitted.
- `ease`: Gets or sets the easing curve.
- `amount`: Gets how far along the move is, by the easing curve: 0 at the start and 1 at the end. A curve that overshoots (`Ease.outBack`) passes 1 on the way.

## FloatTween

*class* in [`libs/tweens/src/helix/tweens/FloatTween.hx`](../src/helix/tweens/FloatTween.hx), `import helix.tweens.FloatTween;`, extends `EasedTween`

Represents a number moving from one value to another.

```haxe
var zoom = new FloatTween(1, 2, 0.3, Ease.outCubic);
// each frame
zoom.update(dt);
camera.zoom = zoom.value;
```

```haxe
function new(from:Float, to:Float, duration:Float, ?ease:Ease)
var from:Float
var to:Float
var value(get, never):Float
```

- `new`: Creates a tween of a number, at its start.
  - `from`: The value at the start.
  - `to`: The value at the end.
  - `duration`: The seconds one play takes, 0 or more.
  - `ease`: Optional. The easing curve; a straight line when omitted.
- `from`: Gets or sets the value at the start.
- `to`: Gets or sets the value at the end.
- `value`: Gets the value now: `from` until the tween starts, `to` once it ends.

## QuaternionTween

*class* in [`libs/tweens/src/helix/tweens/QuaternionTween.hx`](../src/helix/tweens/QuaternionTween.hx), `import helix.tweens.QuaternionTween;`, extends `EasedTween`

Represents a rotation turning from one rotation to another, the short way round (`Quaternion.slerp`).

```haxe
var turn = new QuaternionTween(turret.rotation, aimed, 0.8, Ease.inOutCubic, turret.rotation);
// each frame
turn.update(dt); // turns turret.rotation
```

```haxe
function new(from:Quaternion, to:Quaternion, duration:Float, ?ease:Ease, ?out:Quaternion)
final from:Quaternion
final to:Quaternion
final value:Quaternion
```

- `new`: Creates a tween of a rotation, at its start.
  - `from`: The rotation at the start. The tween keeps a copy.
  - `to`: The rotation at the end. The tween keeps a copy.
  - `duration`: The seconds one play takes, 0 or more.
  - `ease`: Optional. The easing curve; a straight line when omitted.
  - `out`: Optional. The rotation each `update` writes, which may be `from` or `to`; a new one when omitted.
- `from`: Gets the rotation at the start, the tween's own. Setting its components moves the start.
- `to`: Gets the rotation at the end, the tween's own. Setting its components moves the end, as for a target that moves.
- `value`: Gets the rotation each `update` writes: the `out` the tween was made with, or the tween's own.

## Tween

*class* in [`libs/tweens/src/helix/tweens/Tween.hx`](../src/helix/tweens/Tween.hx), `import helix.tweens.Tween;`

Represents something that plays over time: a value moving along an easing curve (`EasedTween` and its kinds) or tweens placed in time (`TweenSequence`). A program steps a tween with `update`, or adds the tween to a `Tweens` set or a sequence, which steps it.

A tween's settings are its fields, read at each `update`.

```haxe
var duration(get, never):Float
var delay:Float
var repeatCount:Int
var repeatDelay:Float
var yoyo:Bool
var timeScale:Float
var paused:Bool
var onStart:Null<() -> Void>
var onUpdate:Null<() -> Void>
var onRepeat:Null<() -> Void>
var onComplete:Null<() -> Void>
var time(default, null):Float
var progress(default, null):Float
var reversed(default, null):Bool
var done(default, null):Bool
function update(dt:Float):Void
function play():Void
function reverse():Void
function seek(seconds:Float):Void
function restart():Void
function finish():Void
function cancel():Void
```

- `duration`: Gets the seconds one play takes: what a kind was made with, or what a sequence's tweens add up to.
- `delay`: Gets or sets the seconds the tween waits before its first play. Defaults to 0.
- `repeatCount`: Gets or sets how many more times the tween plays after the first: 0 for none, -1 for ever. Defaults to 0.
- `repeatDelay`: Gets or sets the seconds the tween waits before each repeat. Defaults to 0.
- `yoyo`: Gets or sets whether each repeat plays back the way the play before it came, where otherwise each repeat jumps to the start. Defaults to false.
- `timeScale`: Gets or sets how fast the tween plays: 1 as timed, 2 twice as fast, 0.5 half as fast; 0 or more. Defaults to 1.
- `paused`: Gets or sets whether `update` leaves the tween where it is. Defaults to false.
- `onStart`: Gets or sets the function called once, when the first play begins, after `delay`.
- `onUpdate`: Gets or sets the function called after each `update` that moved the tween.
- `onRepeat`: Gets or sets the function called as each repeat begins.
- `onComplete`: Gets or sets the function called when the tween ends: at the end of its last play, or at its start when it plays backwards. `cancel` doesn't call it.
- `time`: Gets the seconds played: 0 at the start, counting each repeat and the wait before each, and not `delay`.
- `progress`: Gets how far through the current play the tween is, 0 to 1.
- `reversed`: Gets a value indicating whether the tween plays backwards (`reverse`).
- `done`: Gets a value indicating whether the tween has ended or was cancelled. `play`, `reverse`, `seek` and `restart` set a tween that is done going again.
- `update`: Steps the tween by some seconds: through its delay, then its plays.
  - `dt`: The seconds to step by, multiplied by `timeScale`. Less than 0 counts as 0.

  Each play ends exactly at its end. Seconds left over when a play ends go to the repeat after it. Does nothing when the tween is paused or done, or is placed in a sequence, which steps it.
- `play`: Plays the tween forwards from where it is. A paused tween is no longer paused.
- `reverse`: Plays the tween backwards from where it is, back through its repeats to its start. The delay isn't waited again. A paused tween is no longer paused.
- `seek`: Jumps the tween to a time, forwards or backwards. No callback is made for what the jump passes.
  - `seconds`: The time to jump to, as `time` counts it, kept between 0 and the tween's end.
- `restart`: Puts the tween back at its start, playing forwards, its delay and its repeats to come again. A paused tween is no longer paused.
- `finish`: Jumps the tween to the end of its last play and calls `onComplete`, and no other callback for what the jump passes. A tween that repeats for ever jumps to the end of its current play. Does nothing when the tween is done.
- `cancel`: Stops the tween where it is. The tween is done, and `onComplete` isn't called.

## TweenSequence

*class* in [`libs/tweens/src/helix/tweens/TweenSequence.hx`](../src/helix/tweens/TweenSequence.hx), `import helix.tweens.TweenSequence;`, extends `Tween`

Represents tweens placed in time: one after another, together, or each at a time of its own, with waits and calls between them.

A sequence is a tween, so a sequence repeats, reverses and seeks as one, and can be placed in another sequence. The sequence steps the tweens in it: a program steps the sequence alone.

```haxe
var intro = new TweenSequence();
intro.append(logoFade).join(logoGrow).appendDelay(0.5).append(titleSlide).appendCall(showMenu);
// each frame
intro.update(dt);
```

```haxe
function new()
function append(tween:Tween):TweenSequence
function join(tween:Tween):TweenSequence
function insert(seconds:Float, tween:Tween):TweenSequence
function appendDelay(seconds:Float):TweenSequence
function appendCall(call:() -> Void):TweenSequence
function insertCall(seconds:Float, call:() -> Void):TweenSequence
```

- `new`: Creates an empty sequence.
- `append`: Places a tween after everything placed before it.
  - `tween`: The tween, or another sequence.
  - returns: This sequence.
  - throws `String`: A tween already placed in a sequence.

  The tween takes the time its delay, its duration and its repeats add up to when it is placed, at its `timeScale` then. Nothing placed after a tween that repeats for ever is reached.
- `join`: Places a tween to start when the tween placed before it starts.
  - `tween`: The tween, or another sequence.
  - returns: This sequence.
  - throws `String`: A tween already placed in a sequence.
- `insert`: Places a tween at a time of its own, which may overlap the others.
  - `seconds`: The time the tween starts at, from the sequence's start, 0 or more.
  - `tween`: The tween, or another sequence.
  - returns: This sequence.
  - throws `String`: A tween already placed in a sequence.
- `appendDelay`: Places a wait after everything placed before it.
  - `seconds`: The seconds to wait, 0 or more.
  - returns: This sequence.
- `appendCall`: Places a call after everything placed before it.
  - `call`: The function, called each time the sequence passes the call's time, forwards or backwards.
  - returns: This sequence.
- `insertCall`: Places a call at a time of its own.
  - `seconds`: The time of the call, from the sequence's start, 0 or more.
  - `call`: The function, called each time the sequence passes the call's time, forwards or backwards.
  - returns: This sequence.

## Tweens

*class* in [`libs/tweens/src/helix/tweens/Tweens.hx`](../src/helix/tweens/Tweens.hx), `import helix.tweens.Tweens;`

Provides a set of tweens stepped together. A tween leaves the set when it is done, so a program can add one and keep nothing.

```haxe
var tweens = new Tweens();
var pop = tweens.add(new Vector3Tween(coin.position, hud, 0.6, Ease.inBack, coin.position));
pop.onComplete = () -> score++;
// each frame
tweens.update(dt);
```

```haxe
function new()
var tweenCount(get, never):Int
function add(tween:T):T
function update(dt:Float):Void
function cancelAll():Void
```

- `new`: Creates an empty set.
- `tweenCount`: Gets how many tweens the set holds.
- `add`: Adds a tween to the set. A tween added during `update` is first stepped by the next `update`.
  - `tween`: The tween, of any kind, or a sequence.
  - returns: The tween.
  - throws `String`: A tween placed in a sequence, which the sequence steps.
- `update`: Steps each tween by some seconds, in the order added, and drops the ones that are done.
  - `dt`: The seconds to step by.
- `cancelAll`: Cancels every tween in the set and empties the set.

## Vector2CurveTween

*class* in [`libs/tweens/src/helix/tweens/Vector2CurveTween.hx`](../src/helix/tweens/Vector2CurveTween.hx), `import helix.tweens.Vector2CurveTween;`, extends `EasedTween`

Represents a point moving along a curve in 2 dimensions (`helix.math.Curve`): through points, along Bézier pieces or straight from point to point.

The point moves at a steady speed along the curve's length, which the easing curve then shapes. `from` and `to` choose a part of the curve to move along.

```haxe
var swoop = new Vector2CurveTween(Curve.through([40, 300, 200, 80, 360, 300]), 1.5, Ease.inOutQuad, bird.position);
// each frame
swoop.update(dt); // moves bird.position along the curve
bird.rotation = Math.atan2(swoop.direction.y, swoop.direction.x);
```

```haxe
function new(curve:Curve, duration:Float, ?ease:Ease, ?out:Vector2)
final curve:Curve
var from:Float
var to:Float
final value:Vector2
final direction:Vector2
```

- `new`: Creates a tween along a curve, at the curve's start.
  - `curve`: The curve, in 2 dimensions. The tween keeps the curve itself.
  - `duration`: The seconds one play takes, 0 or more.
  - `ease`: Optional. The easing curve; a straight line when omitted.
  - `out`: Optional. The vector each `update` writes; a new one when omitted.
  - throws `String`: A curve in 3 dimensions.
- `curve`: Gets the curve the point moves along.
- `from`: Gets or sets where along the curve the point starts, as a fraction of the curve's length: 0 for the curve's start, 1 for its end. Defaults to 0.
- `to`: Gets or sets where along the curve the point ends, as a fraction of the curve's length. A fraction less than `from` moves the point back along the curve. Defaults to 1.
- `value`: Gets the vector each `update` writes: the `out` the tween was made with, or the tween's own.
  A place before the curve's start or past its end, by `from`, `to` or an easing curve that overshoots, is held at that end of an open curve and carries on round a closed one.
- `direction`: Gets the way the curve heads at `value`, of length 1, which each `update` writes. It is the curve's own heading, whichever way the point moves.

## Vector2Tween

*class* in [`libs/tweens/src/helix/tweens/Vector2Tween.hx`](../src/helix/tweens/Vector2Tween.hx), `import helix.tweens.Vector2Tween;`, extends `EasedTween`

Represents a point or a direction in 2 dimensions moving from one vector to another, in a straight line.

```haxe
var slide = new Vector2Tween(panel.position, shown, 0.4, Ease.outCubic, panel.position);
// each frame
slide.update(dt); // moves panel.position
```

```haxe
function new(from:Vector2, to:Vector2, duration:Float, ?ease:Ease, ?out:Vector2)
final from:Vector2
final to:Vector2
final value:Vector2
```

- `new`: Creates a tween of a vector, at its start.
  - `from`: The vector at the start. The tween keeps a copy.
  - `to`: The vector at the end. The tween keeps a copy.
  - `duration`: The seconds one play takes, 0 or more.
  - `ease`: Optional. The easing curve; a straight line when omitted.
  - `out`: Optional. The vector each `update` writes, which may be `from` or `to`; a new one when omitted.
- `from`: Gets the vector at the start, the tween's own. Setting its components moves the start.
- `to`: Gets the vector at the end, the tween's own. Setting its components moves the end, as for a target that moves.
- `value`: Gets the vector each `update` writes: the `out` the tween was made with, or the tween's own.

## Vector3CurveTween

*class* in [`libs/tweens/src/helix/tweens/Vector3CurveTween.hx`](../src/helix/tweens/Vector3CurveTween.hx), `import helix.tweens.Vector3CurveTween;`, extends `EasedTween`

Represents a point moving along a curve (`helix.math.Curve`): through points, along Bézier pieces or straight from point to point. `Vector2CurveTween` is the same for a curve in 2 dimensions.

The point moves at a steady speed along the curve's length, which the easing curve then shapes. `from` and `to` choose a part of the curve to move along.

```haxe
var patrol = new Vector3CurveTween(Curve.through(corners, 3, true), 12, guard.position);
patrol.repeatCount = -1;
// each frame
patrol.update(dt); // walks guard.position round the corners
```

```haxe
function new(curve:Curve, duration:Float, ?ease:Ease, ?out:Vector3)
final curve:Curve
var from:Float
var to:Float
final value:Vector3
final direction:Vector3
```

- `new`: Creates a tween along a curve, at the curve's start.
  - `curve`: The curve, in 3 dimensions. The tween keeps the curve itself.
  - `duration`: The seconds one play takes, 0 or more.
  - `ease`: Optional. The easing curve; a straight line when omitted.
  - `out`: Optional. The vector each `update` writes; a new one when omitted.
  - throws `String`: A curve in 2 dimensions.
- `curve`: Gets the curve the point moves along.
- `from`: Gets or sets where along the curve the point starts, as a fraction of the curve's length: 0 for the curve's start, 1 for its end. Defaults to 0.
- `to`: Gets or sets where along the curve the point ends, as a fraction of the curve's length. A fraction less than `from` moves the point back along the curve. Defaults to 1.
- `value`: Gets the vector each `update` writes: the `out` the tween was made with, or the tween's own.
  A place before the curve's start or past its end, by `from`, `to` or an easing curve that overshoots, is held at that end of an open curve and carries on round a closed one.
- `direction`: Gets the way the curve heads at `value`, of length 1, which each `update` writes. It is the curve's own heading, whichever way the point moves.

## Vector3Tween

*class* in [`libs/tweens/src/helix/tweens/Vector3Tween.hx`](../src/helix/tweens/Vector3Tween.hx), `import helix.tweens.Vector3Tween;`, extends `EasedTween`

Represents a point or a direction moving from one vector to another, in a straight line. `Vector2Tween` and `Vector4Tween` are the same for their vectors.

```haxe
var slide = new Vector3Tween(door.position, open, 1.5, Ease.inOutQuad, door.position);
// each frame
slide.update(dt); // moves door.position
```

```haxe
function new(from:Vector3, to:Vector3, duration:Float, ?ease:Ease, ?out:Vector3)
final from:Vector3
final to:Vector3
final value:Vector3
```

- `new`: Creates a tween of a vector, at its start.
  - `from`: The vector at the start. The tween keeps a copy.
  - `to`: The vector at the end. The tween keeps a copy.
  - `duration`: The seconds one play takes, 0 or more.
  - `ease`: Optional. The easing curve; a straight line when omitted.
  - `out`: Optional. The vector each `update` writes, which may be `from` or `to`; a new one when omitted.
- `from`: Gets the vector at the start, the tween's own. Setting its components moves the start.
- `to`: Gets the vector at the end, the tween's own. Setting its components moves the end, as for a target that moves.
- `value`: Gets the vector each `update` writes: the `out` the tween was made with, or the tween's own.

## Vector4Tween

*class* in [`libs/tweens/src/helix/tweens/Vector4Tween.hx`](../src/helix/tweens/Vector4Tween.hx), `import helix.tweens.Vector4Tween;`, extends `EasedTween`

Represents four numbers moving from one vector to another, each on its own.

```haxe
var warm = new Vector4Tween(new Vector4(1, 1, 1, 1), new Vector4(1, 0.8, 0.6, 1), 2, Ease.inOutSine);
// each frame
warm.update(dt);
material.setColor(warm.value);
```

```haxe
function new(from:Vector4, to:Vector4, duration:Float, ?ease:Ease, ?out:Vector4)
final from:Vector4
final to:Vector4
final value:Vector4
```

- `new`: Creates a tween of a vector, at its start.
  - `from`: The vector at the start. The tween keeps a copy.
  - `to`: The vector at the end. The tween keeps a copy.
  - `duration`: The seconds one play takes, 0 or more.
  - `ease`: Optional. The easing curve; a straight line when omitted.
  - `out`: Optional. The vector each `update` writes, which may be `from` or `to`; a new one when omitted.
- `from`: Gets the vector at the start, the tween's own. Setting its components moves the start.
- `to`: Gets the vector at the end, the tween's own. Setting its components moves the end, as for a target that moves.
- `value`: Gets the vector each `update` writes: the `out` the tween was made with, or the tween's own.
