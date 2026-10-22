package helix.render2d;

import helix.math.Interpolate;
import helix.math.Random;

/** A 2D camera following a target: the target moves freely inside a dead zone around the view's center, the view catching up smoothly (at
	the same speed at any frame rate) when it leaves, kept inside the world's bounds; and shaken (shake), a trauma that decays, the view
	thrown about by the square of it. update follows, apply places a camera there. Follow where the target is drawn (between simulation ticks,
	where it's interpolated), not where it's simulated, or the view jitters against it. The shake is the view's only, never the game's: its
	random numbers are its own. */
class CameraFollow2D {
	var halfDeadWidth = 0.;
	var halfDeadHeight = 0.;
	var bounded = false;
	var left = 0.;
	var top = 0.;
	var right = 0.;
	var bottom = 0.;
	var random:Random;
	// The shake's noise: a point now and the next, each axis, picked shakeFrequency times a second and moved between.
	var shakeTime = 0.;
	var fromX = 0.;
	var fromY = 0.;
	var toX = 0.;
	var toY = 0.;

	/** A follow at x, y (the view's center, world units) with no dead zone and no bounds; seed seeds its shake. */
	public function new(x = 0., y = 0., seed = 1) {
		this.x = x;
		this.y = y;
		random = new Random(seed);
	}

	/** The point followed to, before the shake: the view's center in world units. */
	public var x(default, null):Float;

	/** The point followed to, before the shake: the view's center in world units. */
	public var y(default, null):Float;

	/** How quickly the view catches up with the target when it leaves the dead zone: the rate of Interpolate.damp, per second (about a
		fifth of the way left after 1.6 / rate seconds). 0 or less catches up at once. */
	public var smoothing = 8.;

	/** How far the view is thrown at full trauma, as a share of the height it shows (0.04: 24 pixels of a 600-pixel view), so a shake looks
		the same in a world of pixels or of tiles. */
	public var shakeDistance = .04;

	/** How much trauma it loses a second: 1 settles a full shake in a second. */
	public var shakeRecovery = 1.5;

	/** How many times a second the shake changes direction. */
	public var shakeFrequency = 25.;

	/** The shake's trauma, 0 (still) to 1, falling by shakeRecovery a second; the view is thrown by its square, so small shakes are gentle. */
	public var trauma(default, null) = 0.;

	/** Where the shake throws the view now, across, in world units. */
	public var shakeX(default, null) = 0.;

	/** Where the shake throws the view now, down, in world units. */
	public var shakeY(default, null) = 0.;

	/** The target moves freely within width x height world units around the view's center (0, 0: none, the view always catching up). False,
		changing nothing, for a size below 0. */
	public function setDeadZone(width:Float, height:Float):Bool {
		if (!(width >= 0 && height >= 0))
			return false;
		halfDeadWidth = width / 2;
		halfDeadHeight = height / 2;
		return true;
	}

	/** Keeps the view inside the world from left, top to right, bottom (world units): it stops at their edges, centered on a world smaller
		than it. False, changing nothing, for an empty world. */
	public function setBounds(left:Float, top:Float, right:Float, bottom:Float):Bool {
		if (!(right > left && bottom > top))
			return false;
		this.left = left;
		this.top = top;
		this.right = right;
		this.bottom = bottom;
		bounded = true;
		return true;
	}

	/** Lets the view go anywhere. */
	public function clearBounds():Void
		bounded = false;

	/** Adds amount to the trauma (held to 1): 0.3 a bump, 1 an explosion. */
	public function shake(amount:Float):Void
		if (amount > 0)
			trauma = Math.min(1, trauma + amount);

	/** Puts the view's center at x, y at once (a respawn, a new level), within its bounds at the next update. */
	public function snap(x:Float, y:Float):Void {
		this.x = x;
		this.y = y;
	}

	/** Follows the target at targetX, targetY (world units) for dt seconds, seeing as much as camera shows (its viewport at its zoom), and
		advances the shake. */
	public function update(targetX:Float, targetY:Float, dt:Float, camera:Camera2D):Void {
		// The point the view wants: the target, less what the dead zone lets it stray.
		var wantX = x, wantY = y;
		if (targetX > x + halfDeadWidth)
			wantX = targetX - halfDeadWidth;
		else if (targetX < x - halfDeadWidth)
			wantX = targetX + halfDeadWidth;
		if (targetY > y + halfDeadHeight)
			wantY = targetY - halfDeadHeight;
		else if (targetY < y - halfDeadHeight)
			wantY = targetY + halfDeadHeight;
		x = smoothing > 0 ? Interpolate.damp(x, wantX, smoothing, dt) : wantX;
		y = smoothing > 0 ? Interpolate.damp(y, wantY, smoothing, dt) : wantY;
		if (bounded) {
			var halfWidth = camera.viewportWidth / camera.zoom / 2,
				halfHeight = camera.viewportHeight / camera.zoomY / 2;
			x = right - left <= halfWidth * 2 ? (left + right) / 2 : Interpolate.clamp(x, left + halfWidth, right - halfWidth);
			y = bottom - top <= halfHeight * 2 ? (top + bottom) / 2 : Interpolate.clamp(y, top + halfHeight, bottom - halfHeight);
		}
		advanceShake(dt, camera.viewportHeight / camera.zoomY);
	}

	/** Places camera at the followed point, thrown by the shake. */
	public function apply(camera:Camera2D):Void
		camera.setPosition(x + shakeX, y + shakeY);

	// The trauma falls; the throw moves smoothly between random points, scaled by the trauma's square and the height seen.
	function advanceShake(dt:Float, seen:Float):Void {
		if (!(dt > 0))
			return;
		trauma = Math.max(0, trauma - shakeRecovery * dt);
		if (trauma == 0) {
			shakeX = shakeY = 0;
			return;
		}
		shakeTime += dt * (shakeFrequency > 0 ? shakeFrequency : 0);
		while (shakeTime >= 1) {
			shakeTime -= 1;
			fromX = toX;
			fromY = toY;
			toX = random.nextRange(-1, 1);
			toY = random.nextRange(-1, 1);
		}
		var strength = trauma * trauma * shakeDistance * seen;
		shakeX = Interpolate.lerp(fromX, toX, shakeTime) * strength;
		shakeY = Interpolate.lerp(fromY, toY, shakeTime) * strength;
	}
}
