package helix.raylib.extras;

import helix.raylib.*;

/** Represents how a light's shadows are made: the shadow map's size and reach, its bias against a surface shadowing itself, and how
	soft and dark its shadows are. Each field has a default. Sizes and biases are in shadow-map texels, so they hold whatever the map's
	size and reach. */
@:structInit class ShadowOptions {
	/** Gets or sets the map's width and height, in texels: 2048 when not given. A power of two from 256 to 4096; another is rounded down
		to one. */
	@:optional public var mapSize:Null<Int>;

	/** Gets or sets how far from the camera a directional light's shadows reach, in world units: 50 when not given. A point light's reach
		is its range, or this when it has none. Shorter is sharper. */
	@:optional public var distance:Null<Float>;

	/** Gets or sets the box a directional light's map covers, in place of what the camera sees out to `distance`: none when not given,
		so the map follows the camera. A fixed box suits a small scene seen whole. */
	@:optional public var bounds:Null<BoundingBox>;

	/** Gets or sets a directional light's number of cascades, 1 to 4: 1 when not given. Each covers a farther part of `distance`, near
		shadows sharp and far ones still there. */
	@:optional public var cascades:Null<Int>;

	/** Gets or sets the constant bias, in texels: 1 when not given. Too little and a lit surface speckles with its own shadow; too much
		and shadows lift off their casters' feet. */
	@:optional public var bias:Null<Float>;

	/** Gets or sets the bias added where the light grazes the surface, in texels: 4 when not given. */
	@:optional public var slopeBias:Null<Float>;

	/** Gets or sets how far the lookup moves off the surface along its normal, in texels: 1 when not given. */
	@:optional public var normalOffset:Null<Float>;

	/** Gets or sets how soft a shadow's edge is, in texels: 1 when not given. 0 is hard. */
	@:optional public var softness:Null<Float>;

	/** Gets or sets how much of the light a shadow takes away, 0 to 1: 1 when not given. */
	@:optional public var strength:Null<Float>;
}
