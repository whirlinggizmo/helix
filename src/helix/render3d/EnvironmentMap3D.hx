package helix.render3d;

import haxe.ds.Vector;
import helix.graphics.IGraphics;

/** An environment map, ready to light a stage and stand behind it (Renderer3D.setEnvironment, setBackground): its irradiance (the light it casts
	on rough surfaces, 9 spherical-harmonic coefficients), its prefiltered cube (what smooth to rough surfaces reflect) and its background cube
	(the image at its own resolution, blurred mips below), both half floats on the GPU. From Environments3D.load, which prepares it
	(EnvironmentBake3D) and replaces its cubes in place when its file changes during development. */
class EnvironmentMap3D {
	var lighting:Int;
	var background:Int;
	var backgroundMips:Int;

	function new(gpu:IGraphics, path:String, bake:EnvironmentBake3D) {
		this.path = path;
		take(gpu, bake);
	}

	/** An environment of a finished bake, its cubes uploaded to gpu: the file it came from is path. Throws where gpu can't sample half floats. */
	public static function fromBake(gpu:IGraphics, path:String, bake:EnvironmentBake3D):EnvironmentMap3D
		return new EnvironmentMap3D(gpu, path, bake);

	// The bake's cubes uploaded and its irradiance kept.
	function take(gpu:IGraphics, bake:EnvironmentBake3D):Void {
		var made = gpu.createCubeTexture(EnvironmentBake3D.CUBE_SIZE, bake.lightingLevels, Rgba16f);
		background = try gpu.createCubeTexture(bake.backgroundSize, bake.backgroundLevels, Rgba16f) catch (e:Dynamic) {
			gpu.destroyTexture(made);
			throw e;
		};
		lighting = made;
		backgroundMips = bake.backgroundLevels.length;
		irradiance = bake.irradiance;
	}

	/** The file it was loaded from. */
	public var path(default, null):String;

	/** The prefiltered cube's handle: EnvironmentBake3D.MIP_COUNT mips, roughness 0 to 1. */
	public var lightingTexture(get, never):Int;

	function get_lightingTexture():Int
		return lighting;

	/** The background cube's handle. */
	public var backgroundTexture(get, never):Int;

	function get_backgroundTexture():Int
		return background;

	/** The background cube's mips: blur 1 is its last. */
	public var backgroundMipCount(get, never):Int;

	function get_backgroundMipCount():Int
		return backgroundMips;

	/** Its irradiance: 9 coefficients, RGB each (27 floats), over pi. */
	public var irradiance(default, null):Vector<Float>;

	// A new bake of its file: the new cubes made before the old are let go of, so a failure leaves it as it was.
	function replace(gpu:IGraphics, bake:EnvironmentBake3D):Void {
		var oldLighting = lighting, oldBackground = background;
		take(gpu, bake);
		gpu.destroyTexture(oldLighting);
		gpu.destroyTexture(oldBackground);
	}

	/** Frees its cubes on gpu, the program's (Graphics) when not given. Environments3D.release does it for one it loaded. */
	public function destroy(?gpu:IGraphics):Void {
		gpu = gpu != null ? gpu : helix.graphics.Graphics.instance;
		gpu.destroyTexture(lighting);
		gpu.destroyTexture(background);
	}
}
