package helix.render;

import helix.math.Bounds3D;

/** Represents how a light's shadows are made: its shadow map's size and reach, its bias against a surface shadowing itself, and how soft
	and dark its shadows are.

	Each `DirectionalLight3D`, `SpotLight3D` and `PointLight3D` has one (`Light3D.shadow`), used while its `castsShadow` is set. A
	casting light's map is drawn before the pass its batch draws in, from the meshes drawn with `Batch3D.castShadows` on, and read by the
	meshes drawn with `receiveShadows` on.

	- **Directional:** a square map, or up to 4 cascades, over what the camera sees out to `distance` (or over `bounds`), its texels
	  snapped to the world so its edges hold still as the camera moves and turns.
	- **Spot:** one map over its cone, out to its range or `distance`, the nearer.
	- **Point:** six maps, one a cube face, out to its range or `distance`.

	Bias is in shadow-map texels, so it holds whatever the map's size and reach: a constant, plus a slope where the light grazes the
	surface, and the lookup moved off the surface along its normal by `normalOffset` texels, more where the light grazes. A shadow fades
	out over the last tenth of the map, so it never ends at an edge. */
class LightShadow3D {
	/** Gets or sets the map's width and height, in texels: 2048 until set. A power of two from 256 to 4096; another is rounded down to
		one, and clamped. A batch's casting lights share the largest asked for. */
	public var mapSize(default, set):Int = 2048;

	/** Gets or sets how far from the camera a directional light's shadows reach, and at most a spot's or a point's, in world units: 50
		until set. Shorter is sharper. Clamped to at least 0.000001. */
	public var distance(default, set):Float = 50;

	/** Gets or sets the box a directional light's map covers, in world units, in place of what the camera sees; null until set, so the
		map follows the camera. A fixed box suits a small scene seen whole. */
	public var bounds:Null<Bounds3D> = null;

	/** Gets or sets a directional light's number of cascades, 1 to 4: 1 until set, a single map. Each covers a farther slice of `distance` with a map
		of its own, so near shadows are sharp and far ones still drawn; each costs a pass. */
	public var cascadeCount(default, set):Int = 1;

	/** Gets or sets how the cascades split `distance`: 0 evenly, 1 by the ratio of their ends, between them a blend. 0.6 until set;
		clamped to 0 to 1. */
	public var cascadeSplit(default, set):Float = .6;

	/** Gets or sets the constant bias, in texels: 1 until set. Below 0 is clamped to 0. */
	public var bias(default, set):Float = 1;

	/** Gets or sets the slope bias, in texels, added where the light grazes the surface: 4 until set. Below 0 is clamped to 0. */
	public var slopeBias(default, set):Float = 4;

	/** Gets or sets how far the lookup moves off the surface along its normal, in texels: 1 until set, so it holds whatever the map's
		size and reach. three.js's `normalBias` is in world units: a layer over it divides by a texel's size in the world. Below 0 is
		clamped to 0. */
	public var normalOffset(default, set):Float = 1;

	/** Gets or sets how soft the shadow's edge is, the filter's radius in texels: 1 until set, a 3 x 3 filter; 0 a single hard lookup;
		more, a wider disc of lookups. Clamped to 0 to 8. */
	public var radius(default, set):Float = 1;

	/** Gets or sets how much of the light a shadow takes away: 1 until set. Clamped to 0 to 1. */
	public var strength(default, set):Float = 1;

	/** Gets or sets what a shadow leaves of the surface's own color, 0xAARRGGBB, its alpha ignored: black until set, so nothing. A cold
		blue suits a sunny day's shade. */
	public var color:Int = 0xff000000;

	/** Creates the shadow settings of a light: 2048 texels, 50 units, one cascade, a bias of 1 and 4 texels and a normal offset of 1, a
		3 x 3 filter, full strength. */
	public function new() {}

	function set_mapSize(value:Int):Int {
		throw "helix-render: LightShadow3D.set_mapSize is not yet built (stage 1)";
	}

	function set_distance(value:Float):Float {
		throw "helix-render: LightShadow3D.set_distance is not yet built (stage 1)";
	}

	function set_cascadeCount(value:Int):Int {
		throw "helix-render: LightShadow3D.set_cascadeCount is not yet built (stage 1)";
	}

	function set_cascadeSplit(value:Float):Float {
		throw "helix-render: LightShadow3D.set_cascadeSplit is not yet built (stage 1)";
	}

	function set_bias(value:Float):Float {
		throw "helix-render: LightShadow3D.set_bias is not yet built (stage 1)";
	}

	function set_slopeBias(value:Float):Float {
		throw "helix-render: LightShadow3D.set_slopeBias is not yet built (stage 1)";
	}

	function set_normalOffset(value:Float):Float {
		throw "helix-render: LightShadow3D.set_normalOffset is not yet built (stage 1)";
	}

	function set_radius(value:Float):Float {
		throw "helix-render: LightShadow3D.set_radius is not yet built (stage 1)";
	}

	function set_strength(value:Float):Float {
		throw "helix-render: LightShadow3D.set_strength is not yet built (stage 1)";
	}
}
