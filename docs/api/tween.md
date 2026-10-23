# helix.tween

[Back to the index](README.md)

## Ease

*class* in [`src/helix/tween/Ease.hx`](../../src/helix/tween/Ease.hx), `import helix.tween.Ease;`

Easing functions: from progress t, 0 to 1, to how far along a tween is, 0 to 1 (past them for back and elastic). Robert Penner's set, each in its three forms: in (starting slow), out (ending slow), inOut (both). linear is as it is.

```haxe
static function linear(t:Float):Float
static function quadIn(t:Float):Float
static function quadOut(t:Float):Float
static function quadInOut(t:Float):Float
static function cubicIn(t:Float):Float
static function cubicOut(t:Float):Float
static function cubicInOut(t:Float):Float
static function quartIn(t:Float):Float
static function quartOut(t:Float):Float
static function quartInOut(t:Float):Float
static function sineIn(t:Float):Float
static function sineOut(t:Float):Float
static function sineInOut(t:Float):Float
static function expoIn(t:Float):Float
static function expoOut(t:Float):Float
static function expoInOut(t:Float):Float
static function circIn(t:Float):Float
static function circOut(t:Float):Float
static function circInOut(t:Float):Float
static function backIn(t:Float):Float
static function backOut(t:Float):Float
static function backInOut(t:Float):Float
static function elasticIn(t:Float):Float
static function elasticOut(t:Float):Float
static function elasticInOut(t:Float):Float
static function bounceOut(t:Float):Float
static function bounceIn(t:Float):Float
static function bounceInOut(t:Float):Float
```

- `linear`: As it is.
- `quadIn`: Quadratic, in.
- `quadOut`: Quadratic, out.
- `quadInOut`: Quadratic, in then out.
- `cubicIn`: Cubic, in.
- `cubicOut`: Cubic, out.
- `cubicInOut`: Cubic, in then out.
- `quartIn`: Quartic, in.
- `quartOut`: Quartic, out.
- `quartInOut`: Quartic, in then out.
- `sineIn`: Sine, in.
- `sineOut`: Sine, out.
- `sineInOut`: Sine, in then out.
- `expoIn`: Exponential, in.
- `expoOut`: Exponential, out.
- `expoInOut`: Exponential, in then out.
- `circIn`: Circular, in.
- `circOut`: Circular, out.
- `circInOut`: Circular, in then out.
- `backIn`: Back, in: pulls back under 0 before going.
- `backOut`: Back, out: overshoots past 1 before settling.
- `backInOut`: Back, in then out.
- `elasticIn`: Elastic, in: springs past 0 before going.
- `elasticOut`: Elastic, out: springs past 1 before settling.
- `elasticInOut`: Elastic, in then out.
- `bounceOut`: Bounce, out: lands and bounces to rest.
- `bounceIn`: Bounce, in.
- `bounceInOut`: Bounce, in then out.

## Tween

*class* in [`src/helix/tween/Tweens.hx`](../../src/helix/tween/Tweens.hx), `import helix.tween.Tweens;`

One tween of a Tweens set, made by Tweens.to: set its delay and repeats before its first update; read its value any time.

```haxe
function setDelay(value:Float):Bool
var delay(default, null):Float
function setRepeat(count:Int, ?yoyo:Bool = false):Bool
var repeat(default, null):Int
var yoyo(default, null):Bool
function setComplete(f:Null<() -> Void>):Void
var value(default, null):Float
var progress(get, never):Float
var done(default, null):Bool
function cancel():Void
```

- `setDelay`: Waits seconds before starting (the first update comes then). False, changing nothing, for under 0 or once it has started.
- `delay`: Seconds before it starts.
- `setRepeat`: Plays count more times after the first (-1: for ever), and with yoyo each repeat goes back the way it came rather than jumping to the start. False, changing nothing, for a count under -1 or once it has started.
- `repeat`: How many more times it plays after the first; -1 for ever.
- `yoyo`: Whether repeats go back the way they came.
- `setComplete`: Runs f once it ends (not when cancelled).
- `value`: The value now: from before it starts, to once it ends.
- `progress`: How far along the current play is, 0 to 1 (before easing).
- `done`: Whether it has ended or was cancelled.
- `cancel`: Stops it where it is: no more updates, no completion.

## Tweens

*class* in [`src/helix/tween/Tweens.hx`](../../src/helix/tween/Tweens.hx), `import helix.tween.Tweens;`

Tweens on a clock: a value moved from one number to another over seconds by an easing, told to the game each update (a node's x, an alpha, a camera's zoom), with a delay before, repeats and a yoyo back, and a completion. update runs each frame with the clock's delta (Clock.delta), so tweens pause and slow with the game. Each tween moves in the order made; one made inside a callback starts from the next update.

```haxe
function new()
function to(from:Float, to:Float, seconds:Float, ?ease:Float -> Float, ?update:Float -> Void):Tween
var count(get, never):Int
function clear():Void
function update(delta:Float):Void
```

- `new`: No tweens yet.
- `to`: Moves from from to to over seconds by ease (linear when not given), calling update with the value each frame, the first at the start and the last with to exactly. Throws for seconds under 0.
- `count`: How many are moving or waiting, done ones gone.
- `clear`: Cancels every tween where it is.
- `update`: Advances every tween by delta seconds (a clock's delta). Once a frame.
