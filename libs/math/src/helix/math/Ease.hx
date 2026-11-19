package helix.math;

/** Represents an easing curve: the shape a tween moves by, or any move from 0 to 1. `Interpolate`'s thirty curves are each one
	(`Ease.outCubic` is `Interpolate.easeOutCubic`), `Ease.linear` is a straight line, and `Ease.of` makes one of a program's own
	function.

	```haxe
	var ease = Ease.outBack;
	// each frame
	scale = Interpolate.lerp(1, 2, ease.at(elapsed / 0.5));
	``` */
abstract Ease(EaseCurve) {
	/** Gets the straight line: a fraction unchanged. */
	public static final linear:Ease = new Ease(new EaseCurve());

	/** Gets the curve slow at the start, a quarter sine wave: `Interpolate.easeInSine`. */
	public static final inSine:Ease = new Ease(new InSine());

	/** Gets the curve slow at the end, a quarter sine wave: `Interpolate.easeOutSine`. */
	public static final outSine:Ease = new Ease(new OutSine());

	/** Gets the curve slow at both ends, a quarter sine wave: `Interpolate.easeInOutSine`. */
	public static final inOutSine:Ease = new Ease(new InOutSine());

	/** Gets the curve slow at the start, t squared: `Interpolate.easeInQuad`. */
	public static final inQuad:Ease = new Ease(new InQuad());

	/** Gets the curve slow at the end, t squared: `Interpolate.easeOutQuad`. */
	public static final outQuad:Ease = new Ease(new OutQuad());

	/** Gets the curve slow at both ends, t squared: `Interpolate.easeInOutQuad`. */
	public static final inOutQuad:Ease = new Ease(new InOutQuad());

	/** Gets the curve slow at the start, t cubed: `Interpolate.easeInCubic`. */
	public static final inCubic:Ease = new Ease(new InCubic());

	/** Gets the curve slow at the end, t cubed: `Interpolate.easeOutCubic`. */
	public static final outCubic:Ease = new Ease(new OutCubic());

	/** Gets the curve slow at both ends, t cubed: `Interpolate.easeInOutCubic`. */
	public static final inOutCubic:Ease = new Ease(new InOutCubic());

	/** Gets the curve slow at the start, t to the fourth: `Interpolate.easeInQuart`. */
	public static final inQuart:Ease = new Ease(new InQuart());

	/** Gets the curve slow at the end, t to the fourth: `Interpolate.easeOutQuart`. */
	public static final outQuart:Ease = new Ease(new OutQuart());

	/** Gets the curve slow at both ends, t to the fourth: `Interpolate.easeInOutQuart`. */
	public static final inOutQuart:Ease = new Ease(new InOutQuart());

	/** Gets the curve slow at the start, t to the fifth: `Interpolate.easeInQuint`. */
	public static final inQuint:Ease = new Ease(new InQuint());

	/** Gets the curve slow at the end, t to the fifth: `Interpolate.easeOutQuint`. */
	public static final outQuint:Ease = new Ease(new OutQuint());

	/** Gets the curve slow at both ends, t to the fifth: `Interpolate.easeInOutQuint`. */
	public static final inOutQuint:Ease = new Ease(new InOutQuint());

	/** Gets the curve slow at the start, two to the power of t: `Interpolate.easeInExpo`. */
	public static final inExpo:Ease = new Ease(new InExpo());

	/** Gets the curve slow at the end, two to the power of t: `Interpolate.easeOutExpo`. */
	public static final outExpo:Ease = new Ease(new OutExpo());

	/** Gets the curve slow at both ends, two to the power of t: `Interpolate.easeInOutExpo`. */
	public static final inOutExpo:Ease = new Ease(new InOutExpo());

	/** Gets the curve slow at the start, a quarter circle: `Interpolate.easeInCirc`. */
	public static final inCirc:Ease = new Ease(new InCirc());

	/** Gets the curve slow at the end, a quarter circle: `Interpolate.easeOutCirc`. */
	public static final outCirc:Ease = new Ease(new OutCirc());

	/** Gets the curve slow at both ends, a quarter circle: `Interpolate.easeInOutCirc`. */
	public static final inOutCirc:Ease = new Ease(new InOutCirc());

	/** Gets the curve slow at the start, pulling back a tenth before it goes: `Interpolate.easeInBack`. */
	public static final inBack:Ease = new Ease(new InBack());

	/** Gets the curve slow at the end, pulling back a tenth before it goes: `Interpolate.easeOutBack`. */
	public static final outBack:Ease = new Ease(new OutBack());

	/** Gets the curve slow at both ends, pulling back a tenth before it goes: `Interpolate.easeInOutBack`. */
	public static final inOutBack:Ease = new Ease(new InOutBack());

	/** Gets the curve slow at the start, springing past its end and back: `Interpolate.easeInElastic`. */
	public static final inElastic:Ease = new Ease(new InElastic());

	/** Gets the curve slow at the end, springing past its end and back: `Interpolate.easeOutElastic`. */
	public static final outElastic:Ease = new Ease(new OutElastic());

	/** Gets the curve slow at both ends, springing past its end and back: `Interpolate.easeInOutElastic`. */
	public static final inOutElastic:Ease = new Ease(new InOutElastic());

	/** Gets the curve slow at the start, bouncing to rest: `Interpolate.easeInBounce`. */
	public static final inBounce:Ease = new Ease(new InBounce());

	/** Gets the curve slow at the end, bouncing to rest: `Interpolate.easeOutBounce`. */
	public static final outBounce:Ease = new Ease(new OutBounce());

	/** Gets the curve slow at both ends, bouncing to rest: `Interpolate.easeInOutBounce`. */
	public static final inOutBounce:Ease = new Ease(new InOutBounce());

	/** Returns a curve of a program's own function.

		On hxcpp each `at` of the returned curve allocates, as hxcpp boxes a number passed to a function value. The curves named here
		allocate nothing.

		@param curve  The function: it accepts a fraction from 0 to 1 and returns the eased fraction, 0 at 0 and 1 at 1.
		@return  The curve. */
	public static function of(curve:Float->Float):Ease
		return new Ease(new FunctionEase(curve));

	inline function new(curve:EaseCurve)
		this = curve;

	/** Returns a fraction eased along this curve.

		@param t  The fraction, 0 to 1.
		@return  The eased fraction, 0 at 0 and 1 at 1. */
	public inline function at(t:Float):Float
		return this.at(t);
}

/** Represents a curve as an object with a typed method, which hxcpp calls without boxing its number. The base is the straight line. */
private class EaseCurve {
	/** Creates the straight line. */
	public function new() {}

	/** Returns a fraction eased along this curve. */
	public function at(t:Float):Float
		return t;
}

/** Represents a program's own function as a curve. */
private class FunctionEase extends EaseCurve {
	final curve:Float->Float;

	/** Creates a curve of a function. */
	public function new(curve:Float->Float) {
		super();
		this.curve = curve;
	}

	override public function at(t:Float):Float
		return curve(t);
}

/** Represents `Interpolate.easeInSine` as a curve. */
private class InSine extends EaseCurve {
	override public function at(t:Float):Float
		return Interpolate.easeInSine(t);
}

/** Represents `Interpolate.easeOutSine` as a curve. */
private class OutSine extends EaseCurve {
	override public function at(t:Float):Float
		return Interpolate.easeOutSine(t);
}

/** Represents `Interpolate.easeInOutSine` as a curve. */
private class InOutSine extends EaseCurve {
	override public function at(t:Float):Float
		return Interpolate.easeInOutSine(t);
}

/** Represents `Interpolate.easeInQuad` as a curve. */
private class InQuad extends EaseCurve {
	override public function at(t:Float):Float
		return Interpolate.easeInQuad(t);
}

/** Represents `Interpolate.easeOutQuad` as a curve. */
private class OutQuad extends EaseCurve {
	override public function at(t:Float):Float
		return Interpolate.easeOutQuad(t);
}

/** Represents `Interpolate.easeInOutQuad` as a curve. */
private class InOutQuad extends EaseCurve {
	override public function at(t:Float):Float
		return Interpolate.easeInOutQuad(t);
}

/** Represents `Interpolate.easeInCubic` as a curve. */
private class InCubic extends EaseCurve {
	override public function at(t:Float):Float
		return Interpolate.easeInCubic(t);
}

/** Represents `Interpolate.easeOutCubic` as a curve. */
private class OutCubic extends EaseCurve {
	override public function at(t:Float):Float
		return Interpolate.easeOutCubic(t);
}

/** Represents `Interpolate.easeInOutCubic` as a curve. */
private class InOutCubic extends EaseCurve {
	override public function at(t:Float):Float
		return Interpolate.easeInOutCubic(t);
}

/** Represents `Interpolate.easeInQuart` as a curve. */
private class InQuart extends EaseCurve {
	override public function at(t:Float):Float
		return Interpolate.easeInQuart(t);
}

/** Represents `Interpolate.easeOutQuart` as a curve. */
private class OutQuart extends EaseCurve {
	override public function at(t:Float):Float
		return Interpolate.easeOutQuart(t);
}

/** Represents `Interpolate.easeInOutQuart` as a curve. */
private class InOutQuart extends EaseCurve {
	override public function at(t:Float):Float
		return Interpolate.easeInOutQuart(t);
}

/** Represents `Interpolate.easeInQuint` as a curve. */
private class InQuint extends EaseCurve {
	override public function at(t:Float):Float
		return Interpolate.easeInQuint(t);
}

/** Represents `Interpolate.easeOutQuint` as a curve. */
private class OutQuint extends EaseCurve {
	override public function at(t:Float):Float
		return Interpolate.easeOutQuint(t);
}

/** Represents `Interpolate.easeInOutQuint` as a curve. */
private class InOutQuint extends EaseCurve {
	override public function at(t:Float):Float
		return Interpolate.easeInOutQuint(t);
}

/** Represents `Interpolate.easeInExpo` as a curve. */
private class InExpo extends EaseCurve {
	override public function at(t:Float):Float
		return Interpolate.easeInExpo(t);
}

/** Represents `Interpolate.easeOutExpo` as a curve. */
private class OutExpo extends EaseCurve {
	override public function at(t:Float):Float
		return Interpolate.easeOutExpo(t);
}

/** Represents `Interpolate.easeInOutExpo` as a curve. */
private class InOutExpo extends EaseCurve {
	override public function at(t:Float):Float
		return Interpolate.easeInOutExpo(t);
}

/** Represents `Interpolate.easeInCirc` as a curve. */
private class InCirc extends EaseCurve {
	override public function at(t:Float):Float
		return Interpolate.easeInCirc(t);
}

/** Represents `Interpolate.easeOutCirc` as a curve. */
private class OutCirc extends EaseCurve {
	override public function at(t:Float):Float
		return Interpolate.easeOutCirc(t);
}

/** Represents `Interpolate.easeInOutCirc` as a curve. */
private class InOutCirc extends EaseCurve {
	override public function at(t:Float):Float
		return Interpolate.easeInOutCirc(t);
}

/** Represents `Interpolate.easeInBack` as a curve. */
private class InBack extends EaseCurve {
	override public function at(t:Float):Float
		return Interpolate.easeInBack(t);
}

/** Represents `Interpolate.easeOutBack` as a curve. */
private class OutBack extends EaseCurve {
	override public function at(t:Float):Float
		return Interpolate.easeOutBack(t);
}

/** Represents `Interpolate.easeInOutBack` as a curve. */
private class InOutBack extends EaseCurve {
	override public function at(t:Float):Float
		return Interpolate.easeInOutBack(t);
}

/** Represents `Interpolate.easeInElastic` as a curve. */
private class InElastic extends EaseCurve {
	override public function at(t:Float):Float
		return Interpolate.easeInElastic(t);
}

/** Represents `Interpolate.easeOutElastic` as a curve. */
private class OutElastic extends EaseCurve {
	override public function at(t:Float):Float
		return Interpolate.easeOutElastic(t);
}

/** Represents `Interpolate.easeInOutElastic` as a curve. */
private class InOutElastic extends EaseCurve {
	override public function at(t:Float):Float
		return Interpolate.easeInOutElastic(t);
}

/** Represents `Interpolate.easeInBounce` as a curve. */
private class InBounce extends EaseCurve {
	override public function at(t:Float):Float
		return Interpolate.easeInBounce(t);
}

/** Represents `Interpolate.easeOutBounce` as a curve. */
private class OutBounce extends EaseCurve {
	override public function at(t:Float):Float
		return Interpolate.easeOutBounce(t);
}

/** Represents `Interpolate.easeInOutBounce` as a curve. */
private class InOutBounce extends EaseCurve {
	override public function at(t:Float):Float
		return Interpolate.easeInOutBounce(t);
}
