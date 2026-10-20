package helix.input;

/** Taps, double taps, drags and flicks from IInput's pointer, in framebuffer pixels; touch and mouse alike (a double tap is a double click).
	Update once per tick, before the input is consumed, reading its tick edges; or once per frame, reading its frame edges, in a program
	without a fixed tick. */
class PointerGestures {
	var slop:Float;
	var tapSeconds:Float;
	var flickX = 0.;
	var flickY = 0.;
	var started = 0.;
	var samples:Array<Float> = [];
	// The last tap's start and where it began, for a double tap; lastTap is negative infinity when there's none to pair with.
	var lastTap = Math.NEGATIVE_INFINITY;
	var lastTapX = 0.;
	var lastTapY = 0.;
	var doubleSeconds = .5;
	var doubleSlop = 24.;

	/** Gestures with a tap's limits: slop in framebuffer pixels, tapSeconds in seconds, clamped as maxTapDistance and maxTapDuration are. */
	public function new(slop = 12., tapSeconds = .3) {
		maxTapDistance = slop;
		maxTapDuration = tapSeconds;
	}

	/** How far a press may move and still be a tap, in pixels. 0 or more (under 0, or NaN, is 0). */
	public var maxTapDistance(get, set):Float;

	function get_maxTapDistance():Float
		return slop;

	function set_maxTapDistance(value:Float):Float {
		value = value >= 0 ? value : 0;
		slop = value;
		return value;
	}

	/** How long a press may last and still be a tap, in seconds. At least 1e-6 (0 or less, or NaN, is 1e-6). */
	public var maxTapDuration(get, set):Float;

	function get_maxTapDuration():Float
		return tapSeconds;

	function set_maxTapDuration(value:Float):Float {
		value = value > 1e-6 ? value : 1e-6;
		tapSeconds = value;
		return value;
	}

	/** How long after one tap began the next may begin and make a double tap, in seconds. At least 1e-6 (0 or less, or NaN, is 1e-6);
		half a second at first. */
	public var maxDoubleTapInterval(get, set):Float;

	function get_maxDoubleTapInterval():Float
		return doubleSeconds;

	function set_maxDoubleTapInterval(value:Float):Float {
		value = value > 1e-6 ? value : 1e-6;
		doubleSeconds = value;
		return value;
	}

	/** How far from where one tap began the next may begin and make a double tap, in pixels. 0 or more (under 0, or NaN, is 0); 24 at first. */
	public var maxDoubleTapDistance(get, set):Float;

	function get_maxDoubleTapDistance():Float
		return doubleSlop;

	function set_maxDoubleTapDistance(value:Float):Float {
		value = value >= 0 ? value : 0;
		doubleSlop = value;
		return value;
	}

	/** Whether the pointer is down, as of the last update. */
	public var down(default, null):Bool = false;

	/** The pointer went down at the last update. */
	public var pressed(default, null):Bool = false;

	/** The pointer came up at the last update. */
	public var released(default, null):Bool = false;

	/** Moved past the slop during this press. */
	public var dragging(default, null):Bool = false;

	/** The press that ended at the last update was a tap: it stayed within the slop and the tap time. */
	public var tapped(default, null):Bool = false;

	/** The tap that ended at the last update was the second of a double tap (a double click): it began within maxDoubleTapInterval of the
		tap before it and within maxDoubleTapDistance of where that one began. A third tap starts a new pair. */
	public var doubleTapped(default, null):Bool = false;

	/** The pointer's x in framebuffer pixels, as of the last update while down; it holds while the pointer is off the window, and after
		release. */
	public var x(default, null):Float = 0.;

	/** The pointer's y in framebuffer pixels, held as x is. */
	public var y(default, null):Float = 0.;

	/** Where the current or last press began, x in framebuffer pixels. */
	public var startX(default, null):Float = 0.;

	/** Where the current or last press began, y in framebuffer pixels. */
	public var startY(default, null):Float = 0.;

	/** Velocity over the last tenth of a second before release, pixels per second. */
	public var flickVelocityX(get, never):Float;

	function get_flickVelocityX():Float
		return flickX;

	/** Vertical velocity as flickVelocityX, down positive. */
	public var flickVelocityY(get, never):Float;

	function get_flickVelocityY():Float
		return flickY;

	/** Reads the pointer: once per tick with perTick, its tick edges, before the input is consumed; or once per frame without, its frame
		edges. now is the time in seconds. */
	public function update(input:IInput, now:Float, perTick:Bool):Void {
		pressed = false;
		released = false;
		tapped = false;
		doubleTapped = false;
		flickX = flickY = 0;
		if ((perTick ? input.pointerPressed : input.pointerFramePressed) && !down) {
			down = true;
			pressed = true;
			dragging = false;
			started = now;
			startX = x = input.pointerX;
			startY = y = input.pointerY;
			samples = [];
		}
		if (down) {
			if (input.pointerX >= 0) {
				x = input.pointerX;
				y = input.pointerY;
			}
			samples.push(now);
			samples.push(x);
			samples.push(y);
			while (samples.length > 3 && now - samples[0] > .1)
				samples.splice(0, 3);
			if (!dragging && (Math.abs(x - startX) > slop || Math.abs(y - startY) > slop))
				dragging = true;
			if ((perTick ? input.pointerReleased : input.pointerFrameReleased) || !input.pointerDown) {
				down = false;
				released = true;
				tapped = !dragging && now - started <= tapSeconds;
				if (tapped) {
					doubleTapped = started - lastTap <= doubleSeconds
						&& Math.abs(startX - lastTapX) <= doubleSlop
						&& Math.abs(startY - lastTapY) <= doubleSlop;
					lastTap = doubleTapped ? Math.NEGATIVE_INFINITY : started;
					lastTapX = startX;
					lastTapY = startY;
				} else
					lastTap = Math.NEGATIVE_INFINITY;
				var span = now - samples[0];
				if (span > 0) {
					flickX = (x - samples[1]) / span;
					flickY = (y - samples[2]) / span;
				}
			}
		}
	}
}
