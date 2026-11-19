package helix.raylib.modules;

#if !macro
import helix.raylib.*;
import helix.raylib.internal.Answers;
import helix.raylib.internal.Runtime;
#end

using StringTools;

/** Provides the path to the asset host, and ensures assets are available for raylib's `Load*` functions.

	`helix.raylib.extras.Assets` forwards to each member (`tools/gen_raylib.py`). */
@:noCompletion
@:allow(helix.raylib)
class RAssets {
	#if !macro
	// ---- Asset host ----

	/** Sets where the program's assets come from, unless the option `asset_host` gives a host. Assets ensured before the call stay
		ensured.

		The host is the first given of: the option `asset_host` (`--asset_host=https://example.com/game/` on the command line,
		the environment variable HELIX_ASSET_HOST, `?asset_host=...` in a page's query), this call, the build's define
		(`-D helix-raylib-asset-host=...`), and the default: natively `../web` beside the program's directory, in a page the page's own.

		A URL's assets are fetched over HTTP and kept in the program's cache, natively and in a page alike. A directory's are read in place.

		Every asset is read from the host, as a web server reads a file from its own root: a name starting with `/` from the host's root,
		`.` and `..` followed, and nothing above the host. A name whose `..` climbs above it fails as a missing file does.

		@param host  A URL (`https://...`, `http://...`), or a directory, relative to the program's directory when relative. */
	static function SetAssetHost(host:String):Void {
		Runtime.setAssetHost(host);
	}

	/** Returns the asset host in use: the option's, `SetAssetHost`'s, the build's define's, or the default.

		@return  The host. */
	static function GetAssetHost():String {
		return Runtime.assetHost();
	}

	// ---- Ensuring ----

	/** Asynchronously ensures an asset is available for raylib's `Load*` functions. Ensuring an asset fetches its bytes (if absent) from
		the asset host into the program's cache, then decodes the asset into memory. See `EnsureAssetsAsync` for ensuring several assets
		in parallel.

		Each kind of asset is decoded to:

		- an image: its pixels.
		- a sound: its wave.
		- a glTF, GLB or OBJ model: the model, with its images decoded and a glTF model's animations read.
		- an .mtl material library: its materials.
		- a TrueType or OpenType font: a font ready to be rasterized at any size.
		- a BMFont: the font with its pages.
		- a compiled shader (a .shader file from `CompileShaderFile`): the shader.
		- any other asset: its bytes, unchanged.

		Ensuring an asset already ensured doesn't refetch it, and the `ensured` callback is still called. Sequential `EnsureAssetAsync`
		calls fetch and decode their assets in parallel.

		@param fileName  The asset's file name, relative to the asset host.
		@param ensured  Called once the asset is ensured.
		@param failed  Optional. Called with the reason the asset can't be ensured, in place of `ensured`. When omitted, the reason is
			logged. */
	static function EnsureAssetAsync(fileName:String, ensured:Void->Void, ?failed:String->Void):Void {
		var path = RCore.normalize(fileName);
		if (Runtime.ensured.exists(path)) {
			Runtime.later(ensured);
			return;
		}
		prepare(path, error -> {
			if (error != null) {
				Answers.refuse("EnsureAssetAsync", error, failed);
				return;
			}
			Runtime.ensured.set(path, true);
			ensured();
		});
	}

	/** Asynchronously ensures several assets in parallel, each as `EnsureAssetAsync` does.

		@param fileNames  The assets' file names, relative to the asset host.
		@param ensured  Called once every asset is ensured.
		@param failed  Optional. Called once, with the reason an asset can't be ensured, in place of `ensured`. When omitted, the reason
			is logged. The assets already ensured stay ensured.
		@param progress  Optional. Called as each asset is ensured, with the number ensured and the total. */
	static function EnsureAssetsAsync(fileNames:Array<String>, ensured:Void->Void, ?failed:String->Void, ?progress:(done:Int, total:Int) -> Void):Void {
		var paths:Array<String> = [];
		for (name in fileNames) {
			var path = RCore.normalize(name);
			if (paths.indexOf(path) < 0)
				paths.push(path);
		}
		if (paths.length == 0) {
			Runtime.later(ensured);
			return;
		}
		var done = 0, refused = false;
		for (path in paths)
			EnsureAssetAsync(path, () -> {
				if (refused)
					return;
				done++;
				if (progress != null)
					progress(done, paths.length);
				if (done == paths.length)
					ensured();
			}, error -> {
				if (refused)
					return;
				refused = true;
				failed != null ? failed(error) : Runtime.log(4, error);
			});
	}

	/** Returns whether an asset has been ensured in this run (`EnsureAssetAsync`).

		@param fileName  The asset's file name, relative to the asset host.
		@return  True when the asset has been ensured. */
	static function IsAssetEnsured(fileName:String):Bool {
		return Runtime.ensured.exists(RCore.normalize(fileName));
	}

	// ---- Releasing ----

	/** Releases an ensured asset's bytes and decoded data from memory. A load of the asset then behaves as a load of an asset never
		ensured. What a load already made from the asset (a texture, a sound) stays, released by raylib's `Unload*` functions. The
		program's cache keeps the asset's fetched bytes, and ensuring the asset again doesn't refetch it.

		A program releases a level's assets when the player leaves the level.

		@param fileName  The asset's file name, relative to the asset host. */
	static function ReleaseAsset(fileName:String):Void {
		var path = RCore.normalize(fileName);
		Runtime.ensured.remove(path);
		Runtime.files.remove(path);
		Runtime.images.remove(path);
		Runtime.waves.remove(path);
		Runtime.gltfFiles.remove(path);
		Runtime.bmFonts.remove(path);
		Runtime.compiledShaders.remove(path);
		var font = Runtime.openFonts.get(path);
		if (font != null) {
			Runtime.openFonts.remove(path);
			Runtime.fonts().closeFont(font);
		}
		var model = Runtime.models3d.get(path);
		if (model != null) {
			Runtime.models3d.remove(path);
			RModels.UnloadModel(model);
		}
		Runtime.materialLibraries.remove(path);
		Runtime.forgetPicture(path);
	}

	/** Releases several assets, each as `ReleaseAsset` does.

		@param fileNames  The assets' file names, relative to the asset host. */
	static function ReleaseAssets(fileNames:Array<String>):Void {
		for (name in fileNames)
			ReleaseAsset(name);
	}

	// Brings a file into memory as its kind needs, as EnsureAssetAsync lists them (a GIF's first frame as raylib's LoadImage reads it),
	// anything else as its bytes, then calls done with null, or why it couldn't be.
	static function prepare(path:String, done:Null<String>->Void):Void {
		var type = haxe.io.Path.extension(path).toLowerCase();
		if (type == "gif") {
			RTexturesAsync.gifFile("EnsureAssetAsync", path, () -> done(null), done);
			return;
		}
		if (type == "png" || type == "jpg" || type == "jpeg" || type == "bmp" || type == "tga") {
			Runtime.fetchImage(path, done);
			return;
		}
		if (type == "wav" || type == "ogg" || type == "mp3" || type == "qoa") {
			Runtime.fetch(path, error -> {
				if (error != null) {
					done(error);
					return;
				}
				RAudioAsync.readWave("." + type, Runtime.files.get(path), wave -> {
					Runtime.waves.set(path, wave);
					done(null);
				}, message -> done('$path: $message'));
			});
			return;
		}
		if (type == "glb" || type == "gltf") {
			// Its model, with its images decoded, and the file read for its animations, together.
			var left = 2, answered = false;
			function part(error:Null<String>):Void {
				if (answered)
					return;
				if (error != null || --left == 0) {
					answered = true;
					done(error);
				}
			}
			RModelsAsync.loadModel(path, model -> {
				Runtime.models3d.set(path, model);
				part(null);
			}, part);
			helix.raylib.internal.Animations.read(path, file -> {
				Runtime.gltfFiles.set(path, file);
				part(null);
			}, part);
			return;
		}
		if (type == "obj") {
			RModelsAsync.loadModel(path, model -> {
				Runtime.models3d.set(path, model);
				done(null);
			}, done);
			return;
		}
		if (type == "ttf" || type == "otf") {
			// Its bytes, and the font opened, so a load rasterizes it at once at the size it asks for.
			Runtime.fetch(path, error -> {
				if (error != null) {
					done(error);
					return;
				}
				Runtime.fonts().openFont(Runtime.files.get(path), font -> {
					Runtime.openFonts.set(path, font);
					done(null);
				}, message -> done('$path: $message'));
			});
			return;
		}
		if (type == "fnt") {
			Runtime.fonts().loadBmFont(path, font -> {
				Runtime.bmFonts.set(path, font);
				done(null);
			}, done);
			return;
		}
		if (type == "shader") {
			// Read to what a load makes each shader of, its bytes let go.
			Runtime.fetch(path, error -> {
				if (error != null) {
					done(error);
					return;
				}
				var value = RCompiledShaders.read(Runtime.files.get(path));
				if (value == null) {
					done('$path isn\'t a compiled shader');
					return;
				}
				Runtime.files.remove(path);
				Runtime.compiledShaders.set(path, value);
				done(null);
			});
			return;
		}
		if (type == "mtl") {
			RModelsAsync.readLibrary(path, library -> RModelsAsync.withTextures(library, () -> {
				Runtime.materialLibraries.set(path, library);
				done(null);
			}), done);
			return;
		}
		Runtime.fetch(path, done);
	}
	#end
}
