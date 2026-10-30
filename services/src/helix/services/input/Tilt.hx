package helix.services.input;

import helix.platform.IEvents;
import helix.platform.ITilt;
import helix.platform.IPollable;
import helix.platform.TiltStatus;

/** Provides the device's tilt, from level and turned with the screen, for a game steered by tilting a phone or a tablet.

	The program constructs one over its `IEvents` and its `ITilt`, calls `requestAccess`, and calls `poll` once a frame, as `Keyboard` is. A page may need
	the player's permission, asked at the player's next tap, so a game asks before the tap that starts play. Level is taken once the
	device is held steady, and the tilt reads 0 until then (`calibrating`). Natively it is unavailable.

	```haxe
	var tilt = new Tilt(events, tiltAdapter);
	tilt.requestAccess(() -> trace("tilt on"), why -> trace(why));
	// each frame:
	tilt.poll();
	x += speed * tilt.getAxis(X) * time.delta;
	``` */
class Tilt implements IPollable implements IActionDevice {
	/** How steady the device is held, and for how long, before that is taken as level. */
	static inline final STEADY_DEGREES = 3.;

	static inline final STEADY_SECONDS = .5;

	final events:IEvents;
	final device:ITilt;
	// The tilt read this poll and the one before, x then y; the reading taken as level, and the screen's quarter turn when it was taken;
	// while level is being taken, the reading the device is held near, and since when (seconds, NaN before a reading).
	final tilt = [0., 0.];
	final lastTilt = [0., 0.];
	var level = false;
	var levelBeta = 0.;
	var levelGamma = 0.;
	var levelQuarter = 0;
	var steadyBeta = 0.;
	var steadyGamma = 0.;
	var steadySince = Math.NaN;

	/** Creates the tilt over the platform's events and tilt, off until `requestAccess`.

		@param events  The platform's events, whose last `poll` this one reads.
		@param tilt  The platform's tilt, whose readings those events carry. */
	public function new(events:IEvents, tilt:ITilt) {
		this.events = events;
		device = tilt;
	}

	/** Asks for the device's motion sensor, as `ITilt.requestAccess` does.

		A page may need the player's permission, which is asked at the player's next tap. `status` follows each change, for a game that shows
		"tap to start tilt" while it waits.
		@param done  Optional. Called once readings arrive.
		@param failed  Optional. Receives why there will be none: the player refused, the page isn't secure, or the browser reads no
			orientation.
		@return  False, calling neither, where the tilt can't be read at all, as natively. */
	public function requestAccess(?done:Void->Void, ?failed:String->Void):Bool {
		return device.requestAccess(done, failed);
	}

	/** Stops the readings, and reads 0 from then. A permission the player granted stays granted, so a later `requestAccess` usually starts
		without asking again. */
	public function releaseAccess():Void {
		device.releaseAccess();
		tilt[0] = tilt[1] = 0;
		level = false;
	}

	/** Gets where the tilt is: Off, WaitingForTap, On, Refused, Unavailable or NeedsHttps. Defaults to Off. */
	public var status(default, null):TiltStatus = Off;

	/** Gets a value indicating whether level is being taken.

		Level is taken once the device is held within 3 degrees for half a second: when the tilt starts, after the screen turns, and after
		`calibrate`. The tilt reads 0 meanwhile. */
	public var calibrating(default, null):Bool = false;

	/** Takes level again from how the device is held next, as a game's "Level" button does. */
	public function calibrate():Void {
		level = false;
		steadySince = Math.NaN;
		tilt[0] = tilt[1] = 0;
		if (status == On)
			calibrating = true;
	}

	/** Returns how far the device is tilted from level along an axis, turned with the screen.

		@param axis  The axis: X across the screen, right positive; Y along it, toward the player positive.
		@return  -1 to 1, where `range` degrees reads 1; 0 while level is being taken, or when the tilt isn't on. */
	public function getAxis(axis:TiltAxis):Float {
		return tilt[axis == X ? 0 : 1];
	}

	/** Gets or sets how many degrees of tilt read 1. Clamped to at least 1. Defaults to 30. */
	public var range(default, set):Float = 30;

	function set_range(value:Float):Float {
		return range = value > 1 ? value : 1;
	}

	/** Reads the events the last `IEvents.poll` delivered: the tilt's status and its readings. Call it once a frame. */
	public function poll():Void {
		lastTilt[0] = tilt[0];
		lastTilt[1] = tilt[1];
		for (event in events.events)
			switch event {
				case TiltState(next):
					status = next;
					if (next != On)
						tilt[0] = tilt[1] = 0;
				case Tilt(beta, gamma, screenAngle):
					reading(beta, gamma, screenAngle);
				case _:
			}
	}

	@:noCompletion
	public function reads(binding:Binding):Bool
		return binding.match(Tilt(_, _));

	@:noCompletion
	public function getValue(binding:Binding):Float
		return switch binding {
			case Tilt(axis, direction): side(tilt[axis == X ? 0 : 1], direction);
			case _: 0;
		}

	@:noCompletion
	public function wasDown(binding:Binding):Bool
		return switch binding {
			case Tilt(axis, direction): side(lastTilt[axis == X ? 0 : 1], direction) > 0;
			case _: false;
		}

	@:noCompletion
	public function isPressed(binding:Binding):Bool
		return getValue(binding) > 0 && !wasDown(binding);

	@:noCompletion
	public function isReleased(binding:Binding):Bool
		return wasDown(binding) && getValue(binding) == 0;

	// A reading: its change from level, turned from the device's way up to the screen's, over range degrees and clamped to -1 to 1.
	function reading(beta:Float, gamma:Float, screenAngle:Float):Void {
		var quarter = Math.round(((screenAngle % 360) + 360) % 360 / 90) % 4;
		if (quarter != levelQuarter) {
			level = false;
			steadySince = Math.NaN;
			levelQuarter = quarter;
		}
		if (!level) {
			var now = haxe.Timer.stamp();
			if (Math.isNaN(steadySince)
				|| Math.abs(beta - steadyBeta) > STEADY_DEGREES
				|| Math.abs(gamma - steadyGamma) > STEADY_DEGREES) {
				steadyBeta = beta;
				steadyGamma = gamma;
				steadySince = now;
			}
			tilt[0] = tilt[1] = 0;
			if (now - steadySince < STEADY_SECONDS) {
				calibrating = true;
				return;
			}
			level = true;
			levelBeta = beta;
			levelGamma = gamma;
		}
		calibrating = false;
		var forward = beta - levelBeta, across = gamma - levelGamma;
		// The screen turned counterclockwise from the device's way up by screenAngle: its across and down in the device's terms.
		var x = across, y = forward;
		switch quarter {
			case 1:
				x = forward;
				y = -across;
			case 2:
				x = -across;
				y = -forward;
			case 3:
				x = -forward;
				y = across;
			case _:
		}
		tilt[0] = clampUnit(x / range);
		tilt[1] = clampUnit(y / range);
	}

	static function clampUnit(value:Float):Float
		return value < -1 ? -1 : value > 1 ? 1 : value;

	static function side(value:Float, direction:AxisDirection):Float {
		var toward = direction == Negative ? -value : value;
		return toward > 0 ? toward : 0;
	}
}
