package helix.scene.transition;

import helix.render2d.Drawing2D;
import helix.render2d.Node2D;
import helix.render2d.Stage;
import helix.scene.Flow;

/** How one screen gives way to the next on the stage (docs/DISPLAY_MODEL.md): a cover drawn over everything, covering for coverSeconds and
	uncovering for uncoverSeconds, what's shown swapped at the middle between; after a delay when given, held covered at the middle for
	hold seconds, each half along its own ease. It runs itself (run, swap) on the frames' time, not the game's clock, so a paused game still transitions to its
	menu; quick (the run option quick=1) skips it, swapping at once. The kinds made (Fade, Slide, Iris, Diamond, Noise) each draw their cover;
	a game's own extends this and draws anything into its cover by progress (draw). */
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
