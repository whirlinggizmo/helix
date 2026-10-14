package helix.render3d;

import haxe.ds.Vector;
import helix.graphics.IGraphics;

/** An environment map, ready to light a stage and stand behind it (Stage3D.setEnvironment, setBackground): its irradiance (the light it casts
	on rough surfaces, 9 spherical-harmonic coefficients), its prefiltered cube (what smooth to rough surfaces reflect) and its background cube
	(the image at its own resolution, blurred mips below), both half floats on the GPU. From Environments.load, which prepares it
	(EnvironmentBake) and replaces its cubes in place when its file changes during development. */
class Environment {
	var lighting:Int;
	var background:Int;
	var backgroundMips:Int;
	var irradiance:Vector<Float>;
	var path:String;

	function new(gpu:IGraphics, path:String, bake:EnvironmentBake) {
		this.path = path;
		take(gpu, bake);
	}

	/** An environment of a finished bake, its cubes uploaded to gpu: the file it came from is path. Throws where gpu can't sample half floats. */
	public static function fromBake(gpu:IGraphics, path:String, bake:EnvironmentBake):Environment
		return new Environment(gpu, path, bake);

	// The bake's cubes uploaded and its irradiance kept.
	function take(gpu:IGraphics, bake:EnvironmentBake):Void {
		var made = gpu.createCubeTexture(EnvironmentBake.CUBE_SIZE, bake.getLightingLevels(), Rgba16f);
		background = try gpu.createCubeTexture(bake.getBackgroundSize(), bake.getBackgroundLevels(), Rgba16f) catch (e:Dynamic) {
			gpu.destroyTexture(made);
			throw e;
		};
		lighting = made;
		backgroundMips = bake.getBackgroundLevels().length;
		irradiance = bake.getIrradiance();
	}

	/** The file it was loaded from. */
	public function getPath():String
		return path;

	/** The prefiltered cube's handle: EnvironmentBake.MIP_COUNT mips, roughness 0 to 1. */
	public function getLightingTexture():Int
		return lighting;

	/** The background cube's handle. */
	public function getBackgroundTexture():Int
		return background;

	/** The background cube's mips: blur 1 is its last. */
	public function getBackgroundMipCount():Int
		return backgroundMips;

	/** Its irradiance: 9 coefficients, RGB each (27 floats), over pi. */
	public function getIrradiance():Vector<Float>
		return irradiance;

	// A new bake of its file: the new cubes made before the old are let go of, so a failure leaves it as it was.
	function replace(gpu:IGraphics, bake:EnvironmentBake):Void {
		var oldLighting = lighting, oldBackground = background;
		take(gpu, bake);
		gpu.destroyTexture(oldLighting);
		gpu.destroyTexture(oldBackground);
	}

	/** Frees its cubes. Environments.release does it for one it loaded. */
	public function destroy(gpu:IGraphics):Void {
		gpu.destroyTexture(lighting);
		gpu.destroyTexture(background);
	}
}
