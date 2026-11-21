package helix.raylib.modules;

#if !macro
import helix.raylib.*;
import helix.raylib.internal.Answers;
import helix.raylib.internal.Runtime;
#end

using StringTools;

/** Sets the asset hosts, and ensures assets are available for raylib's `Load*` functions.

	`helix.raylib.extras.Assets` forwards to each member (`tools/gen_raylib.py`). */
@:noCompletion
@:allow(helix.raylib)
class RAssets {
	#if !macro
	// ---- Asset hosts ----

	/** Sets where the program's assets come from, unless the option `asset_hosts` names the hosts. An asset is read from the first host
		with a file at its path. Assets ensured before the call are released, and a load after the call reads the new hosts. An asset
		being ensured or loaded during the call is read from the hosts set before it.

		Each host is a URL (`https://...`, `http://...`) or a directory, relative to the program's directory when relative. A URL's assets
		are fetched over HTTP and stored in the program's cache, and a changed file on the server replaces its cached copy. Natively a
		directory's assets are read in place. In a page a directory is relative to the page's, and its assets are fetched as a URL's are.

		A directory before a URL overrides the URL's files, as a mod does. Natively a directory after a URL is the URL's shipped files: a
		shipped file the server's manifest lists at the same hash is read in place, and only a changed file is downloaded. The manifests
		are written as the program builds, by `helix.services.tools.AssetManifests.write` over the shipped directory and the served one.

		An asset's path is relative to each host, with `.` and `..` followed. An absolute path or a URL is read from the host it is
		under. A path outside every host is refused as an invalid file path.

		The hosts are the first of these that is set: the option `asset_hosts`, a list separated by commas
		(`--asset_hosts=mods/bigheads/,https://example.com/game/` on the command line, the environment variable HELIX_ASSET_HOSTS,
		`?asset_hosts=...` in a page's query), this call, the build's define (`-D helix-raylib-asset-hosts=...`), and the default:
		natively `../web` beside the program's directory, in a page the page's own directory.

		@param hosts  The hosts, in the order they are asked. */
	static function SetAssetHosts(hosts:Array<String>):Void {
		// Every file in memory is the old hosts': the ensured ones, and the ones a load brought in.
		var paths = [for (path in Runtime.ensured.keys()) path];
		for (path in Runtime.files.keys())
			paths.push(path);
		for (path in Runtime.pictures.keys())
			paths.push(path);
		for (path in Runtime.images.keys())
			paths.push(path);
		ReleaseAssets(paths);
		Runtime.setAssetHosts(hosts);
	}

	/** Returns the asset hosts in use, in the order they are asked.

		@param out  Optional. The array to fill and return.
		@return  The hosts. */
	static function GetAssetHosts(?out:Array<String>):Array<String> {
		return Runtime.assetHosts(out);
	}

	// ---- The cache ----

	/** Asynchronously lists the assets stored in the program's cache under a directory. The cache contains every asset fetched from a
		URL host, in this run or an earlier one, whatever the hosts in use now. Natively a host's manifests are listed among them.

		@param path  The directory, relative to each host. "" lists the whole cache.
		@param listed  Called with each cached asset's file name, relative to its host, and its host's URL.
		@param failed  Optional. Called with the reason the cache can't be listed, in place of `listed`. When omitted, the reason is
			logged. */
	static function ListAssetCacheAsync(path:String, listed:Array<{fileName:String, host:String}>->Void, ?failed:String->Void):Void {
		Runtime.listAssetCache(path, listed, error -> Answers.refuse("ListAssetCacheAsync", error, failed));
	}

	/** Asynchronously deletes every asset stored in the program's cache, whatever the hosts in use now. Ensured assets stay ensured, and
		the files the program saved are untouched. A later ensure of a deleted asset fetches it again.

		@param cleared  Optional. Called once the cache is empty.
		@param failed  Optional. Called with the reason the cache can't be emptied, in place of `cleared`. When omitted, the reason is
			logged. */
	static function ClearAssetCacheAsync(?cleared:Void->Void, ?failed:String->Void):Void {
		Runtime.clearAssetCache(() -> if (cleared != null) cleared(), error -> Answers.refuse("ClearAssetCacheAsync", error, failed));
	}

	// ---- Ensuring ----

	/** Asynchronously ensures an asset is available for raylib's `Load*` functions. Ensuring an asset fetches its bytes (if absent) from
		its asset host into the program's cache, then decodes the asset into memory. See `EnsureAssetsAsync` for ensuring several assets
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

		@param fileName  The asset's file name, relative to the asset hosts.
		@param ensured  Called once the asset is ensured.
		@param failed  Optional. Called with the reason the asset can't be ensured, in place of `ensured`. When omitted, the reason is
			logged. */
	static function EnsureAssetAsync(fileName:String, ensured:Void->Void, ?failed:String->Void):Void {
		var path = RCore.keyOf(fileName);
		if (Runtime.ensured.exists(path)) {
			Runtime.later(ensured);
			return;
		}
		prepare(fileName, error -> {
			if (error != null) {
				Answers.refuse("EnsureAssetAsync", error, failed);
				return;
			}
			Runtime.ensured.set(path, true);
			ensured();
		});
	}

	/** Asynchronously ensures several assets in parallel, each as `EnsureAssetAsync` does.

		@param fileNames  The assets' file names, relative to the asset hosts.
		@param ensured  Called once every asset is ensured.
		@param failed  Optional. Called once, with the reason an asset can't be ensured, in place of `ensured`. When omitted, the reason
			is logged. The assets already ensured stay ensured.
		@param progress  Optional. Called as each asset is ensured, with the number ensured and the total. */
	static function EnsureAssetsAsync(fileNames:Array<String>, ensured:Void->Void, ?failed:String->Void, ?progress:(done:Int, total:Int) -> Void):Void {
		// One name for each file, the first spelling of it.
		var keys:Array<String> = [], paths:Array<String> = [];
		for (name in fileNames) {
			var key = RCore.keyOf(name);
			if (keys.indexOf(key) < 0) {
				keys.push(key);
				paths.push(name);
			}
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

		@param fileName  The asset's file name, relative to the asset hosts.
		@return  True when the asset has been ensured. */
	static function IsAssetEnsured(fileName:String):Bool {
		return Runtime.ensured.exists(RCore.keyOf(fileName));
	}

	// ---- Releasing ----

	/** Releases an ensured asset's bytes and decoded data from memory. A load of the asset then behaves as a load of an asset never
		ensured. What a load already made from the asset (a texture, a sound) stays, released by raylib's `Unload*` functions. The
		program's cache keeps the asset's fetched bytes, and ensuring the asset again doesn't refetch it.

		A program releases a level's assets when the player leaves the level.

		@param fileName  The asset's file name, relative to the asset hosts. */
	static function ReleaseAsset(fileName:String):Void {
		var path = RCore.keyOf(fileName);
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

		@param fileNames  The assets' file names, relative to the asset hosts. */
	static function ReleaseAssets(fileNames:Array<String>):Void {
		for (name in fileNames)
			ReleaseAsset(name);
	}

	// Brings a file into memory as its kind needs, as EnsureAssetAsync lists them (a GIF's first frame as raylib's LoadImage reads it),
	// anything else as its bytes, then calls done with null, or why it couldn't be.
	static function prepare(path:String, done:Null<String>->Void):Void {
		var key = RCore.keyOf(path),
			type = haxe.io.Path.extension(path).toLowerCase();
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
				RAudioAsync.readWave("." + type, Runtime.files.get(key), wave -> {
					Runtime.waves.set(key, wave);
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
				Runtime.models3d.set(key, model);
				part(null);
			}, part);
			helix.raylib.internal.Animations.read(path, file -> {
				Runtime.gltfFiles.set(key, file);
				part(null);
			}, part);
			return;
		}
		if (type == "obj") {
			RModelsAsync.loadModel(path, model -> {
				Runtime.models3d.set(key, model);
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
				Runtime.fonts().openFont(Runtime.files.get(key), font -> {
					Runtime.openFonts.set(key, font);
					done(null);
				}, message -> done('$path: $message'));
			});
			return;
		}
		if (type == "fnt") {
			Runtime.fonts().loadBmFont(path, font -> {
				Runtime.bmFonts.set(key, font);
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
				var value = RCompiledShaders.read(Runtime.files.get(key));
				if (value == null) {
					done('$path isn\'t a compiled shader');
					return;
				}
				Runtime.files.remove(key);
				Runtime.compiledShaders.set(key, value);
				done(null);
			});
			return;
		}
		if (type == "mtl") {
			RModelsAsync.readLibrary(path, library -> RModelsAsync.withTextures(library, () -> {
				Runtime.materialLibraries.set(key, library);
				done(null);
			}), done);
			return;
		}
		Runtime.fetch(path, done);
	}
	#end
}
