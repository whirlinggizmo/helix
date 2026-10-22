package helix.shader;

/** Vignette, a screen effect of the library: the frame shaded toward color from radius out to its corners. */
class Vignette extends LibraryScreenEffect {
	/** A black vignette of strength (0..1), from .4 of the way to a corner, softness .6. */
	public function new(strength = .4) {
		super("vignette", VignettePacked.text());
		this.strength = strength;
		color = 0xff000000;
		radius = .4;
		softness = .6;
	}

	/** How far the corners go toward color, 0 (none) to 1 (all the way): .4 by default. */
	public var strength(default, set):Float;

	function set_strength(value:Float):Float
		return strength = writeFloat("strength", value, 0, 1);

	/** What the corners go toward, 0xAARRGGBB (sRGB as the frame is, alpha ignored): black by default. */
	public var color(default, set):Int;

	function set_color(value:Int):Int {
		parameters.setColor("color", value);
		return color = value;
	}

	/** Where the shading starts, a share of the way from the middle to a corner, 0 to 1: .4 by default. */
	public var radius(default, set):Float;

	function set_radius(value:Float):Float
		return radius = writeFloat("radius", value, 0, 1);

	/** How far past radius the shading takes to reach its strength, the same share, .001 (a hard edge) to 2: .6 by default. */
	public var softness(default, set):Float;

	function set_softness(value:Float):Float
		return softness = writeFloat("softness", value, .001, 2);
}
