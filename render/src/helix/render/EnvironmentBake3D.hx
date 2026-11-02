package helix.render;

import haxe.io.Bytes;
import helix.services.images.Image;

/** Represents the preparing of an environment map on the CPU, a step at a time, so that it spreads over frames: from a picture of all
	around, its light for image-based lighting and its background.

	It makes what glTF viewers light by: the irradiance (the light a surface facing each way gets from all around) as 9
	spherical-harmonic coefficients; a 128-texel cube prefiltered for roughness 0 to 1 (GGX, a mip a step); and a background cube at the
	picture's own resolution with box-filtered mips for blur; both cubes RGBA half floats. A program runs it a little each frame
	(`run`) until it is `done`, then hands it to `Renderer.createEnvironmentMap`. It is the same on every target, and needs no float
	render target or cube pass.

	```haxe
	var bake = EnvironmentBake3D.fromImage(sky); // an equirectangular image
	// each frame, until done:
	if (bake != null && bake.run(4)) {
		batch.environment.setMap(renderer.createEnvironmentMap(bake), 1, 0);
		bake = null;
	}
	``` */
class EnvironmentBake3D {
	/** Gets a value indicating whether it is finished. */
	public var done(default, null):Bool = false;

	/** Gets how far it is, 0 to 1. */
	public var progress(default, null):Float = 0;

	@:allow(helix.render)
	function new() {}

	/** Returns a bake of an equirectangular picture (2:1, latitude and longitude) of 8-bit sRGB colors, as linear light up to 1.

		@param image  The picture.
		@return  The bake, not started.
		@throws String  An image that isn't twice as wide as it is high. */
	public static function fromImage(image:Image):EnvironmentBake3D {
		throw "helix-render: EnvironmentBake3D.fromImage is not yet built (stage 4, environment maps)";
	}

	/** Returns a bake of an equirectangular picture of linear light, which may run past 1, as a Radiance .hdr holds it.

		@param width  The width, in pixels: twice the height.
		@param height  The height, in pixels.
		@param pixels  Red, green and blue a pixel, rows top first, as little-endian 32-bit floats: `width * height * 12` bytes.
		@return  The bake, not started.
		@throws String  A size that isn't 2:1, or pixels too short. */
	public static function fromPixels(width:Int, height:Int, pixels:Bytes):EnvironmentBake3D {
		throw "helix-render: EnvironmentBake3D.fromPixels is not yet built (stage 4, environment maps)";
	}

	/** Returns a bake of six square pictures, a cube's faces, of 8-bit sRGB colors.

		@param faces  The faces, in the order +X, -X, +Y, -Y, +Z, -Z, as a cube's faces are seen from inside it, each the same size.
		@return  The bake, not started.
		@throws String  Not six faces, or faces not square and alike. */
	public static function fromCubeImages(faces:Array<Image>):EnvironmentBake3D {
		throw "helix-render: EnvironmentBake3D.fromCubeImages is not yet built (stage 4, environment maps)";
	}

	/** Works its steps until it is done or a time has passed, at least one step.

		@param budgetMs  The time to work for, in milliseconds.
		@return  True once it is done. */
	public function run(budgetMs:Float):Bool {
		throw "helix-render: EnvironmentBake3D.run is not yet built (stage 4, environment maps)";
	}
}
