package helix.shaders;

import helix.graphics.Graphics;
import helix.graphics.SpriteEffect;

/** A sprite effect of the library: a color mixed over the sprite's (its alpha kept), all of it at a trigger and fading to none over some
	seconds of the batch's time (Batch2D.time; a Stage2D's time), as a hit flashes a sprite, or an amount held. Shared by the sprites given it
	(SpriteEffect): each sprite flashing on its own has a SpriteFlash of its own. Built on the program's GPU (Graphics) the first time one is
	made. */
class SpriteFlash extends SpriteEffect {
	// The fade: its length in seconds (0: an amount held), and the batch's time it began at (NaN until the first draw after the trigger).
	var seconds = 0.;
	var start = Math.NaN;
	var held = 0.;

	/** The flash's color, 0xRRGGBBAA (sRGB, its alpha how strong at most). White by default. */
	public var color(default, set):Int = 0xffffffff;

	function set_color(value:Int):Int {
		color = value;
		write(seconds > 0 ? fade(start) : held);
		return value;
	}

	/** How much of the flash is held, 0 to 1 (times its color's alpha): 0, none, by default. Assigning holds it, ending a fade; read during a
		fade, it's the fade's start, 1. Clamped to 0..1 (NaN is 0). */
	public var amount(get, set):Float;

	function get_amount():Float
		return seconds > 0 ? 1 : held;

	function set_amount(value:Float):Float {
		value = value > 0 ? (value < 1 ? value : 1) : 0;
		held = value;
		seconds = 0;
		write(value);
		return value;
	}

	/** No flash until triggered or an amount is held. */
	public function new() {
		super(ShaderLibrary.get(Graphics.instance, "sprite_flash", SpriteFlashPacked.text()));
		write(0);
	}

	/** Flashes color (0xRRGGBBAA, sRGB, its alpha how strong) all at once, fading to nothing over seconds of the batch's time from the next
		draw. False, changing nothing, for seconds not above 0. */
	public function trigger(color:Int, seconds:Float):Bool {
		if (!(seconds > 0))
			return false;
		this.seconds = seconds;
		start = Math.NaN;
		this.color = color;
		return true;
	}

	/** Brings a fade to time (seconds of the batch's clock): its start the first time after a trigger. */
	override public function prepare(time:Float):Void {
		if (seconds <= 0)
			return;
		if (Math.isNaN(start))
			start = time;
		write(fade(time));
	}

	// How much of a fade is left at time: 1 before it starts, 0 from seconds after it on.
	function fade(time:Float):Float {
		if (Math.isNaN(time) || Math.isNaN(start))
			return 1;
		var left = 1 - (time - start) / seconds;
		return left > 0 ? (left < 1 ? left : 1) : 0;
	}

	// The flash's color, its alpha times how much of it now.
	function write(now:Float):Void
		parameters.setValues("flash", [
			(color >>> 24) / 255,
			((color >>> 16) & 255) / 255,
			((color >>> 8) & 255) / 255,
			(color & 255) / 255 * now
		]);
}
