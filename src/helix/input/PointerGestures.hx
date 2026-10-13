package helix.input;

/** Taps, drags and flicks from IInput's pointer, in screen pixels; touch and mouse alike. Update once per tick, before the input is consumed. */
class PointerGestures {
	var slop:Float;
	var tapSeconds:Float;
	var down = false;
	var pressed = false;
	var released = false;
	var dragging = false;
	var tapped = false;
	var x = 0.;
	var y = 0.;
	var startX = 0.;
	var startY = 0.;
	var flickX = 0.;
	var flickY = 0.;
	var started = 0.;
	var samples:Array<Float> = [];

	public function new(slop = 12., tapSeconds = .3) {
		this.slop = slop;
		this.tapSeconds = tapSeconds;
	}

	/** How far a press may move and still be a tap, in pixels. */
	public function getSlop():Float
		return slop;

	/** False for under 0. */
	public function setSlop(value:Float):Bool {
		if (!(value >= 0))
			return false;
		slop = value;
		return true;
	}

	/** How long a press may last and still be a tap, in seconds. */
	public function getTapSeconds():Float
		return tapSeconds;

	/** False for 0 or less. */
	public function setTapSeconds(value:Float):Bool {
		if (!(value > 0))
			return false;
		tapSeconds = value;
		return true;
	}

	public function isDown():Bool
		return down;

	public function isPressed():Bool
		return pressed;

	public function isReleased():Bool
		return released;

	/** Moved past the slop during this press. */
	public function isDragging():Bool
		return dragging;

	public function isTapped():Bool
		return tapped;

	public function getX():Float
		return x;

	public function getY():Float
		return y;

	public function getStartX():Float
		return startX;

	public function getStartY():Float
		return startY;

	/** Velocity over the last tenth of a second before release, pixels per second. */
	public function getFlickX():Float
		return flickX;

	public function getFlickY():Float
		return flickY;

	public function update(input:IInput, now:Float):Void {
		pressed = false;
		released = false;
		tapped = false;
		flickX = flickY = 0;
		if (input.isPointerPressed() && !down) {
			down = true;
			pressed = true;
			dragging = false;
			started = now;
			startX = x = input.getPointerX();
			startY = y = input.getPointerY();
			samples = [];
		}
		if (down) {
			if (input.getPointerX() >= 0) {
				x = input.getPointerX();
				y = input.getPointerY();
			}
			samples.push(now);
			samples.push(x);
			samples.push(y);
			while (samples.length > 3 && now - samples[0] > .1)
				samples.splice(0, 3);
			if (!dragging && (Math.abs(x - startX) > slop || Math.abs(y - startY) > slop))
				dragging = true;
			if (input.isPointerReleased() || !input.isPointerDown()) {
				down = false;
				released = true;
				tapped = !dragging && now - started <= tapSeconds;
				var span = now - samples[0];
				if (span > 0) {
					flickX = (x - samples[1]) / span;
					flickY = (y - samples[2]) / span;
				}
			}
		}
	}
}
