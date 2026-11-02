package helix.render;

/** Represents an environment map on the GPU: the irradiance, prefiltered cube and background cube a finished `EnvironmentBake3D` made.

	`Renderer.createEnvironmentMap` makes one; an `Environment3D` lights by it (`setMap`) and shows it behind everything (`setBackground`,
	`Batch3D.drawBackground`), and a `Material3D` may name one of its own. The program frees it with `dispose`. */
class EnvironmentMap3D {
	/** Gets the irradiance: 9 spherical-harmonic coefficients, red, green and blue each (27 floats), over π, in linear light. */
	public final irradiance:Array<Float>;

	@:allow(helix.render)
	function new(irradiance:Array<Float>) {
		this.irradiance = irradiance;
	}

	/** Frees its cubes on the GPU, after the frame being recorded when it holds a draw with them. A second call does nothing. */
	public function dispose():Void {
		throw "helix-render: EnvironmentMap3D.dispose is not yet built (stage 4, environment maps)";
	}
}
