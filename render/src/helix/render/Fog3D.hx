package helix.render;

/** Represents fog: what is drawn fades toward a color with its distance from the camera.

	A `Batch3D` draws through its `fog`, read at each `begin`; a material opts out with `Material3D.fog`, the batch draws with `Batch3D.fogged`. The background isn't fogged.

	```haxe
	var mist = new Fog3D(0xffa0b0c0);
	mist.near = 10;
	mist.far = 60;
	batch.fog = mist;
	``` */
class Fog3D {
	/** Gets or sets the color it fades to. */
	public var color:Int;

	/** Gets or sets how it thickens: Linear until set. */
	public var mode:FogMode3D = Linear;

	/** Gets or sets where linear fog starts, in world units from the camera: 1 until set. */
	public var near:Float = 1;

	/** Gets or sets where linear fog is whole, in world units from the camera: 1000 until set. */
	public var far:Float = 1000;

	/** Gets or sets how thick exponential fog is, per world unit: 0.00025 until set, as three.js's FogExp2. Below 0 is clamped to 0. */
	public var density(default, set):Float = .00025;

	/** Creates linear fog of a color.

		@param color  The color, as 0xAARRGGBB; its alpha is ignored. */
	public function new(color:Int) {
		this.color = color;
	}

	function set_density(value:Float):Float {
		throw "helix-render: Fog3D.set_density is not yet built (stage 1)";
	}
}
