package helix.shader;

/** CRT, a screen effect of the library: the frame as an old monitor shows it, its glass curved (black beyond the bent frame), dark lines
	between its rows, an aperture grille (columns of red, green and blue), and a flicker over the effect's time. */
class Crt extends LibraryScreenEffect {
	/** A CRT of 240 lines, darkness .35, curvature .3, mask .3 of columns a pixel wide, flicker .5. */
	public function new() {
		super("crt", CrtPacked.text());
		lines = 240;
		darkness = .35;
		curvature = .3;
		mask = .3;
		maskSize = 1;
		flicker = .5;
	}

	/** The rows down the frame, 1 to 4096: 240 by default. */
	public var lines(default, set):Float;

	function set_lines(value:Float):Float
		return lines = writeFloat("lines", value, 1, 4096);

	/** How dark the lines between rows go, 0 (none) to 1 (black): .35 by default. */
	public var darkness(default, set):Float;

	function set_darkness(value:Float):Float
		return darkness = writeFloat("darkness", value, 0, 1);

	/** How far the glass bends, 0 (flat) to 1: .3 by default. */
	public var curvature(default, set):Float;

	function set_curvature(value:Float):Float
		return curvature = writeFloat("curvature", value, 0, 1);

	/** How strong the aperture grille is, 0 (none) to 1: .3 by default. */
	public var mask(default, set):Float;

	function set_mask(value:Float):Float
		return mask = writeFloat("mask", value, 0, 1);

	/** A grille column's width, in the frame's pixels, 1 to 64: 1 by default. */
	public var maskSize(default, set):Float;

	function set_maskSize(value:Float):Float
		return maskSize = writeFloat("mask_size", value, 1, 64);

	/** How much the brightness wobbles over time, 0 (steady) to 1 (6% either way): .5 by default. */
	public var flicker(default, set):Float;

	function set_flicker(value:Float):Float
		return flicker = writeFloat("flicker", value, 0, 1);
}
