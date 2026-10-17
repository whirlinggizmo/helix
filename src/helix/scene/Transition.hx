package helix.scene;

import helix.render2d.Batch2D;

/** How one scene gives way to the next on a Scenes stack: drawn over the frames for its seconds, the old scene under its first half and the
	new under its second (the swap is at the middle). A transition runs on the frames' time, not the game's clock, so a paused game still
	transitions to its menu. Fade is the one made; another draws anything over the frame by progress. */
class Transition {
	/** A transition taking seconds. Throws for 0 or less. */
	public function new(seconds:Float) {
		if (!(seconds > 0))
			throw 'A transition takes some time, not $seconds';
		this.seconds = seconds;
	}

	/** How long it takes. */
	public var seconds(default, null):Float;

	/** Draws it over the frame, width by height framebuffer pixels, at progress 0 to 1 (the swap at .5), into batch, begun on a camera of
		framebuffer pixels. Nothing by default. */
	public function draw(batch:Batch2D, width:Float, height:Float, progress:Float):Void {}
}

/** A fade to a color and back: covered at the middle, where the scenes swap. */
class Fade extends Transition {
	/** A fade over seconds (half a second unless given) through color (black unless given, 0xRRGGBBAA, its alpha the cover at the middle). */
	public function new(seconds = .5, color = 0x000000ff) {
		super(seconds);
		this.color = color;
	}

	/** Its color. */
	public var color(default, null):Int;

	override public function draw(batch:Batch2D, width:Float, height:Float, progress:Float):Void {
		var cover = progress < .5 ? progress * 2 : (1 - progress) * 2;
		var alpha = Math.round((color & 0xff) * cover);
		batch.rect(0, 0, width, height, (color & 0xffffff00) | alpha);
	}
}
