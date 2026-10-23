package helix.scene.transition;

import helix.render2d.Drawing2D;

/** A cover sliding across: in from one side until it covers everything at the middle, where what's shown swaps, then on out across the
	far side, or back out the way it came (back). Its edge is square to the way it moves, so a diagonal one sweeps corner to corner. */
class Slide extends Transition {
	/** A slide over seconds (half a second unless given) moving direction (Left unless given), back out the way it came when back, in color
		(black unless given, 0xAARRGGBB). */
	public function new(seconds = .5, direction:SlideDirection = Left, back = false, color = 0xff000000) {
		super(seconds);
		this.direction = direction;
		this.back = back;
		this.color = color;
	}

	/** Which way it moves. */
	public var direction(default, null):SlideDirection;

	/** Whether it leaves the way it came in (true) or goes on across (false). */
	public var back(default, null):Bool;

	/** Its color. */
	public var color(default, null):Int;

	override public function draw(cover:Drawing2D, x:Float, y:Float, width:Float, height:Float, progress:Float):Void {
		// The way it moves, a unit vector (the stage's y down), and how far along it the visible area reaches from its near to its far side.
		var dx = 0., dy = 0.;
		final diagonal = Math.sqrt(.5);
		switch direction {
			case Left:
				dx = -1;
			case Right:
				dx = 1;
			case Up:
				dy = -1;
			case Down:
				dy = 1;
			case UpLeft:
				dx = dy = -diagonal;
			case UpRight:
				dx = diagonal;
				dy = -diagonal;
			case DownLeft:
				dx = -diagonal;
				dy = diagonal;
			case DownRight:
				dx = dy = diagonal;
		}
		var near = Math.POSITIVE_INFINITY, far = Math.NEGATIVE_INFINITY;
		for (corner in [[x, y], [x + width, y], [x, y + height], [x + width, y + height]]) {
			var along = corner[0] * dx + corner[1] * dy;
			near = Math.min(near, along);
			far = Math.max(far, along);
		}
		var span = far - near;
		// In: the cover is what's behind its leading edge, which moves from the near side to the far one. Out on across: what's ahead of its
		// trailing edge, moving the same way; out back: behind its edge again, moving back to the near side.
		if (progress < .5) {
			var edge = near + span * progress * 2;
			fill(cover, x, y, width, height, -dx, -dy, -edge, color);
		} else if (back) {
			var edge = far - span * (progress - .5) * 2;
			fill(cover, x, y, width, height, -dx, -dy, -edge, color);
		} else {
			var edge = near + span * (progress - .5) * 2;
			fill(cover, x, y, width, height, dx, dy, edge, color);
		}
	}

	// The visible area's part where a x + b y >= c, filled.
	static function fill(cover:Drawing2D, x:Float, y:Float, width:Float, height:Float, a:Float, b:Float, c:Float, color:Int):Void {
		var corners = [x, y, x + width, y, x + width, y + height, x, y + height],
			kept:Array<Float> = [];
		for (i in 0...4) {
			var px = corners[i * 2],
				py = corners[i * 2 + 1],
				qx = corners[(i + 1) % 4 * 2],
				qy = corners[(i + 1) % 4 * 2 + 1];
			var p = a * px + b * py - c, q = a * qx + b * qy - c;
			if (p >= 0) {
				kept.push(px);
				kept.push(py);
			}
			if ((p >= 0) != (q >= 0)) {
				var t = p / (p - q);
				kept.push(px + (qx - px) * t);
				kept.push(py + (qy - py) * t);
			}
		}
		if (kept.length >= 6)
			cover.polygon(kept, color);
	}
}
