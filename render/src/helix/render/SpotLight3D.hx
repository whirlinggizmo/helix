package helix.render;

import helix.math.Vector3D;

/** Represents a point light shining in a cone: full inside its inner cone, fading to nothing at its outer, falling off with distance as a
	`PointLight3D` does. */
class SpotLight3D extends Light3D {
	/** Gets its position, in world units: the origin until changed. */
	public final position = new Vector3D();

	/** Gets the direction it shines in, its cone's axis; it needn't be of length 1. Straight down until changed. */
	public final direction = new Vector3D(0, -1, 0);

	/** Gets or sets its range, in world units, past which it lights nothing: 0 for none. 0 until set; below 0 is clamped to 0. */
	public var range(default, set):Float = 0;

	/** Gets its inner cone, in radians from its axis: full light inside it. 0.3 until set. */
	public var innerCone(default, null):Float = .3;

	/** Gets its outer cone, in radians from its axis: no light past it. 0.4 until set. */
	public var outerCone(default, null):Float = .4;

	/** Creates a white spot light of intensity π at the origin shining straight down, with no range and cones of 0.3 and 0.4 radians. */
	public function new() {
		super();
	}

	function set_range(value:Float):Float {
		throw "helix-render: SpotLight3D.set_range is not yet built (stage 1)";
	}

	/** Sets its cones.

		@param innerCone  The inner cone, in radians from its axis.
		@param outerCone  The outer cone, in radians from its axis.
		@return  False, changing nothing, unless 0 <= innerCone <= outerCone < π / 2. */
	public function setCone(innerCone:Float, outerCone:Float):Bool {
		throw "helix-render: SpotLight3D.setCone is not yet built (stage 1)";
	}
}
