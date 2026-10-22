package helix.scene;

import helix.graphics.Color;
import helix.render2d.Drawing2D;
import helix.render2d.Node2D;
import helix.render2d.Stage;

/** How one screen gives way to the next on the stage (docs/DISPLAY_MODEL.md): a cover drawn over everything for its seconds, what's shown
	swapped at its middle. It runs itself (run, swap) on the frames' time, not the game's clock, so a paused game still transitions to its
	menu; quick (the run option quick=1) skips it, swapping at once. Fade is the one made; another draws anything into its cover by progress
	(draw). */
class Transition {
	/** A transition taking seconds. Throws for 0 or less. */
	public function new(seconds:Float) {
		if (!(seconds > 0))
			throw 'A transition takes some time, not $seconds';
		this.seconds = seconds;
	}

	/** How long it takes. */
	public var seconds(default, null):Float;

	/** Whether it's running now. */
	public var running(default, null):Bool = false;

	/** Draws the cover at progress 0 to 1 (the swap at .5) into cover (cleared before each call, over everything on the stage, in the stage's
		units), the visible area x, y, width x height. Nothing by default. */
	public function draw(cover:Drawing2D, x:Float, y:Float, width:Float, height:Float, progress:Float):Void {}

	/** Runs it over the stage: atMiddle at its middle (swap what's shown there), done (when given) at its end. False, running nothing, while
		it's running already. */
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
		var cover = new Drawing2D(), elapsed = 0., swapped = false;
		cover.pickable = false;
		Stage.addChild(cover);
		Flow.run(dt -> {
			elapsed += Math.max(0, dt);
			if (!swapped && elapsed >= seconds / 2) {
				swapped = true;
				atMiddle();
				// Over what the swap put on the stage.
				Stage.addChild(cover);
			}
			var progress = Math.min(1, elapsed / seconds),
				area = helix.host.Screen.instance;
			cover.clear();
			draw(cover, area.visibleX, area.visibleY, area.visibleWidth, area.visibleHeight, progress);
			if (progress < 1)
				return true;
			Stage.removeChild(cover);
			running = false;
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
