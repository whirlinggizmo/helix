package helix.scene;

import helix.graphics.Color;
import helix.render2d.Drawing2D;
import helix.render2d.Node2D;
import helix.render2d.Stage;

/** How one screen gives way to the next on the stage (docs/DISPLAY_MODEL.md): a cover drawn over everything, covering for coverSeconds and
	uncovering for uncoverSeconds, what's shown swapped at the middle between; after a delay when given, held covered at the middle for
	hold seconds, each half along its own ease. It runs itself (run, swap) on the frames' time, not the game's clock, so a paused game still transitions to its
	menu; quick (the run option quick=1) skips it, swapping at once. Fade is the one made; another draws anything into its cover by progress
	(draw). */
class Transition {
	/** A transition taking seconds, half covering and half uncovering (coverSeconds, uncoverSeconds). Throws for 0 or less. */
	public function new(seconds:Float) {
		if (!(seconds > 0))
			throw 'A transition takes some time, not $seconds';
		coverSeconds = uncoverSeconds = seconds / 2;
	}

	/** Seconds it takes to cover, from its start (after its delay) to its middle, where what's shown swaps: half the seconds it was made
		with to start; 0 for less (covered at once). A quick close and a slow open: coverSeconds .2, uncoverSeconds .8. */
	public var coverSeconds(default, set):Float;

	function set_coverSeconds(value:Float):Float
		return coverSeconds = value > 0 ? value : 0;

	/** Seconds it takes to uncover, from the end of its hold to its end: half the seconds it was made with to start; 0 for less. */
	public var uncoverSeconds(default, set):Float;

	function set_uncoverSeconds(value:Float):Float
		return uncoverSeconds = value > 0 ? value : 0;

	/** How long it covers and uncovers, its delay and hold aside: coverSeconds and uncoverSeconds together. */
	public var seconds(get, never):Float;

	function get_seconds():Float
		return coverSeconds + uncoverSeconds;

	/** Whether it's running now: from run through its delay, its covering, its hold and its uncovering. */
	public var running(default, null):Bool = false;

	/** Where it is, as last drawn: 0 to .5 covering, .5 covered (at the middle and through its hold), .5 to 1 uncovering, each half
		after its ease; 0 before it starts (and through its delay), 1 once done. */
	public var progress(default, null):Float = 0;

	/** Seconds after run before it starts covering, nothing drawn meanwhile: 0 to start (and for less). */
	public var delay(default, set):Float = 0;

	function set_delay(value:Float):Float
		return delay = value > 0 ? value : 0;

	/** Seconds it stays fully covered at its middle, after the swap and before it uncovers: 0 to start (and for less). */
	public var hold(default, set):Float = 0;

	function set_hold(value:Float):Float
		return hold = value > 0 ? value : 0;

	/** How its first half goes, an easing from time to progress, 0 to 1 (helix.tween.Ease's, called from a lambda so a hot reload reaches
		it: t -> Ease.quadIn(t) starts slow): linear to start. What it gives is held to 0..1, so a curve past the ends (back, elastic) can't
		overshoot the cover. */
	public var coverEase:Float->Float = t -> t;

	/** How its second half goes, as coverEase: linear to start. */
	public var uncoverEase:Float->Float = t -> t;

	/** Draws the cover at progress 0 to 1 (the swap at .5) into cover (cleared before each call, over everything on the stage, in the stage's
		units), the visible area x, y, width x height. Nothing by default. */
	public function draw(cover:Drawing2D, x:Float, y:Float, width:Float, height:Float, progress:Float):Void {}

	/** Runs it over the stage, after its delay: atMiddle at its middle (swap what's shown there), held covered for its hold, done (when
		given) at its end. False, running nothing, while it's running already. */
	public function run(atMiddle:Void->Void, ?done:Void->Void):Bool {
		if (running)
			return false;
		if (Flow.quick) {
			atMiddle();
			if (done != null)
				done();
			return true;
		}
		running = true;
		progress = 0;
		var cover = new Drawing2D(), elapsed = 0., swapped = false;
		cover.pickable = false;
		Stage.addChild(cover);
		Flow.run(dt -> {
			elapsed += Math.max(0, dt);
			// Where it is: waiting out its delay, covering, held at the middle, or uncovering.
			var covering = coverSeconds,
				uncovering = uncoverSeconds,
				since = elapsed - delay;
			if (!swapped && since >= covering) {
				swapped = true;
				atMiddle();
				// Over what the swap put on the stage.
				Stage.addChild(cover);
			}
			inline function eased(curve:Float->Float, t:Float):Float {
				var v = curve(t < 1 ? t : 1);
				return v > 0 ? (v < 1 ? v : 1) : 0;
			}
			var progress = -1.;
			if (since >= covering + hold)
				progress = .5 + eased(uncoverEase, uncovering > 0 ? (since - covering - hold) / uncovering : 1) * .5;
			else if (since >= covering)
				progress = .5;
			else if (since >= 0)
				progress = eased(coverEase, since / covering) * .5;
			this.progress = progress >= 0 ? progress : 0;
			var area = helix.host.Screen.instance;
			cover.clear();
			if (progress >= 0)
				draw(cover, area.visibleX, area.visibleY, area.visibleWidth, area.visibleHeight, progress);
			if (since < covering + hold + uncovering)
				return true;
			Stage.removeChild(cover);
			running = false;
			this.progress = 1;
			if (done != null)
				done();
			return false;
		});
		return true;
	}

	/** Runs it, taking from off the stage and putting to on it at its middle (either null for none), done (when given) at its end. False,
		running nothing, while it's running already. */
	public function swap(from:Null<Node2D>, to:Null<Node2D>, ?done:Void->Void):Bool
		return run(() -> {
			if (from != null)
				Stage.removeChild(from);
			if (to != null)
				Stage.addChild(to);
		}, done);
}

/** A fade to a color and back: covered at the middle, where what's shown swaps. */
class Fade extends Transition {
	/** A fade over seconds (half a second unless given) through color (black unless given, 0xAARRGGBB, its alpha the cover at the middle). */
	public function new(seconds = .5, color = 0xff000000) {
		super(seconds);
		this.color = color;
	}

	/** Its color. */
	public var color(default, null):Int;

	override public function draw(cover:Drawing2D, x:Float, y:Float, width:Float, height:Float, progress:Float):Void {
		var amount = progress < .5 ? progress * 2 : (1 - progress) * 2;
		cover.rect(x, y, width, height, Color.withAlpha(color, Math.round(Color.getAlpha(color) * amount)));
	}
}

/** Which way a Slide's cover moves across the screen: it comes in from the opposite side (Left enters from the right). */
enum SlideDirection {
	Left;
	Right;
	Up;
	Down;
	UpLeft;
	UpRight;
	DownLeft;
	DownRight;
}

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

/** A hole in the cover closing on a point until all is covered at the middle, where what's shown swaps, then opening from it: the hole
	round (Iris) or a diamond (Diamond). The point is the stage's, read as it draws, so it can follow something moving; the middle of the
	visible area unless set. */
class Closing extends Transition {
	/** A close and open over seconds in color (0xAARRGGBB). */
	function new(seconds:Float, color:Int) {
		super(seconds);
		this.color = color;
	}

	/** Its color. */
	public var color(default, null):Int;

	/** The point it closes on and opens from, in the stage's units; NaN (the default) for the middle of the visible area. */
	public var pointX:Float = Math.NaN;

	/** The point's y; NaN for the middle. */
	public var pointY:Float = Math.NaN;

	/** Sets the point it closes on and opens from, in the stage's units. */
	public function setPoint(x:Float, y:Float):Void {
		pointX = x;
		pointY = y;
	}

	override public function draw(cover:Drawing2D, x:Float, y:Float, width:Float, height:Float, progress:Float):Void {
		var cx = Math.isNaN(pointX) ? x + width / 2 : pointX,
			cy = Math.isNaN(pointY) ? y + height / 2 : pointY;
		var reach = reachOf(cx - x, cy - y, x + width - cx, y + height - cy);
		var size = reach * (progress < .5 ? 1 - progress * 2 : (progress - .5) * 2);
		if (size < .5) {
			cover.rect(x, y, width, height, color);
			return;
		}
		// The cover as two pieces round the hole, above and below a line through the point, over an area holding the visible one and the hole.
		var left = Math.min(x, cx - size) - 1,
			right = Math.max(x + width, cx + size) + 1,
			top = Math.min(y, cy - size) - 1,
			bottom = Math.max(y + height, cy + size) + 1;
		var upper = [left, top, right, top, right, cy], lower = [left, cy];
		var edge = rim(cx, cy, size);
		// The rim from its right round over the top to its left, then on under the bottom back to the right.
		var half = Std.int(edge.length / 4);
		for (i in 0...half + 1) {
			upper.push(edge[i * 2]);
			upper.push(edge[i * 2 + 1]);
		}
		upper.push(left);
		upper.push(cy);
		for (i in half...half * 2 + 1) {
			var at = i % (half * 2);
			lower.push(edge[at * 2]);
			lower.push(edge[at * 2 + 1]);
		}
		lower.push(right);
		lower.push(cy);
		lower.push(right);
		lower.push(bottom);
		lower.push(left);
		lower.push(bottom);
		cover.polygon(upper, color);
		cover.polygon(lower, color);
	}

	// How far the hole must open from the point to show the whole visible area, the point left, top, right and bottom of its edges.
	function reachOf(left:Float, top:Float, right:Float, bottom:Float):Float
		return 0;

	// The hole's rim round cx, cy at size, from its right point counterclockwise on screen (up first), an even count of points, x and y in turn.
	function rim(cx:Float, cy:Float, size:Float):Array<Float>
		return [];
}

/** A round hole closing on a point and opening from it (Closing). */
class Iris extends Closing {
	/** An iris over seconds (half a second unless given) in color (black unless given, 0xAARRGGBB), on the middle of the visible area until
		setPoint. */
	public function new(seconds = .5, color = 0xff000000)
		super(seconds, color);

	override function reachOf(left:Float, top:Float, right:Float, bottom:Float):Float {
		var across = Math.max(left, right), down = Math.max(top, bottom);
		return Math.sqrt(across * across + down * down);
	}

	override function rim(cx:Float, cy:Float, size:Float):Array<Float> {
		var points = [], count = 64;
		for (i in 0...count) {
			var a = -i * Math.PI * 2 / count;
			points.push(cx + Math.cos(a) * size);
			points.push(cy + Math.sin(a) * size);
		}
		return points;
	}
}

/** A diamond-shaped hole closing on a point and opening from it (Closing). */
class Diamond extends Closing {
	/** A diamond over seconds (half a second unless given) in color (black unless given, 0xAARRGGBB), on the middle of the visible area
		until setPoint. */
	public function new(seconds = .5, color = 0xff000000)
		super(seconds, color);

	override function reachOf(left:Float, top:Float, right:Float, bottom:Float):Float
		return Math.max(left, right) + Math.max(top, bottom);

	override function rim(cx:Float, cy:Float, size:Float):Array<Float>
		return [cx + size, cy, cx, cy - size, cx - size, cy, cx, cy + size];
}

/** The screen covered square by square in a scattered order, then uncovered the same way in another: a dissolve in blocks. */
class Noise extends Transition {
	/** Squares of cell stage units (24 unless given, at least 2) over seconds (half a second unless given) in color (black unless given,
		0xAARRGGBB). */
	public function new(seconds = .5, cell = 24., color = 0xff000000) {
		super(seconds);
		this.cell = cell > 2 ? cell : 2;
		this.color = color;
	}

	/** Each square's size, the stage's units. */
	public var cell(default, null):Float;

	/** Its color. */
	public var color(default, null):Int;

	override public function draw(cover:Drawing2D, x:Float, y:Float, width:Float, height:Float, progress:Float):Void {
		var columns = Math.ceil(width / cell), rows = Math.ceil(height / cell);
		var coming = progress < .5,
			amount = coming ? progress * 2 : (progress - .5) * 2;
		for (row in 0...rows) {
			// A row's neighboring squares drawn as one: a run from where it starts to where it stops.
			var start = -1;
			for (column in 0...columns + 1) {
				var drawn = false;
				if (column < columns) {
					// Each square's turn, from its place (the same every run): one order in, another out.
					var turn = order(column, row, coming ? 0x1e3779b9 : 0x7f4a7c15);
					drawn = coming ? (turn < amount) : (turn >= amount);
				}
				if (drawn && start < 0)
					start = column;
				else if (!drawn && start >= 0) {
					cover.rect(x + start * cell, y + row * cell, (column - start) * cell, cell, color);
					start = -1;
				}
			}
		}
	}

	// A square's turn, 0 to 1, scattered by its column, row and salt; every product under 2^53, so JS's doubles and native 32-bit
	// integers keep the same low bits and both targets scatter alike.
	static function order(column:Int, row:Int, salt:Int):Float {
		var h = ((column & 0xffff) * 0x3c6ef3) ^ ((row & 0xffff) * 0x1b8735) ^ salt;
		h = (h ^ (h >>> 15)) & 0x3fffff;
		h = (h * 0x2c1b3c) ^ ((h * 0x2c1b3c) >>> 13);
		h = (h & 0x3fffff) * 0x297a2d;
		h ^= h >>> 16;
		return (h & 0xffffff) / 0x1000000;
	}
}
