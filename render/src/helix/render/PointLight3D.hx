package helix.render;

import helix.math.Vector3D;

/** Represents a light from a point, in every direction, falling off with the square of the distance and, given a range, to nothing at
	it.

	Its intensity is three.js's PointLight's with decay 2 (candela, as glTF's KHR_lights_punctual has it): the light falling on a
	surface facing it at a distance d is its color times intensity / d². A range fades that smoothly to nothing at the range, as glTF's
	recommended window does: times (1 - (d / range)⁴)², clamped to 0. */
class PointLight3D extends Light3D {
	/** Gets its position, in world units: the origin until changed. */
	public final position = new Vector3D();

	/** Gets or sets its range, in world units, past which it lights nothing: 0 for none, so it only falls off. 0 until set; below 0 is
		clamped to 0. */
	public var range(default, set):Float = 0;

	/** Creates a white point light of intensity π at the origin, with no range: a white surface facing it 1 unit away shows white. */
	public function new() {
		super();
	}

	function set_range(value:Float):Float {
		return range = Math.max(0, value);
	}
}
