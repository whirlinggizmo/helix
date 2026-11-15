package helix.raylib.modules;

#if !macro
import helix.raylib.*;
import helix.raylib.internal.Answers;
import helix.raylib.internal.Runtime;
#end

using StringTools;

/** Provides where the program's files come from, and ensures them ahead of raylib's loads: helix-raylib's own.

	`helix.raylib.extras.Assets` forwards to each member (`tools/gen_raylib.py`). */
@:noCompletion
@:allow(helix.raylib)
class RAssets {
	#if !macro
	// ---- Asset host ----

	/** Sets where the program's files come from, unless the option `asset_host` gives a host. Files ensured before the call stay
		ensured.

		The host is the first given of: the option `asset_host` (`--asset_host=https://example.com/game/` on the command line,
		the environment variable HELIX_ASSET_HOST, `?asset_host=...` in a page's query), this call, the build's define
		(`-D helix-raylib-asset-host=...`), and the default: natively `../web` beside the program's directory, in a page the page's own.

		A URL's files are fetched over HTTP and kept in the program's cache, natively and in a page alike. A directory's are read in place.

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

	/** Asynchronously ensures a file: makes it local, fetching it from the asset host and keeping it in the program's cache when it isn't
		there, and decodes it into memory by its kind, so raylib's load of it answers at once on every target. An image is decoded to its
		pixels, a sound file to its wave, a glTF, GLB or OBJ file to its model (its images decoded) and a glTF file's animations
		read, an .mtl file to its materials, a TrueType or OpenType font opened to be rasterized at any size, a BMFont read with its
		pages.

		A file already ensured is ensured at once, though `ensured` is still called after the call returns. Several calls made in a row
		fetch and decode their files together, never one after another. See `EnsureAssetsAsync` for several files at once.

		Without an ensure, natively a load reads and decodes its file during the call. In a page a load of a file not ensured in this
		run fails as raylib's load of a missing file does, logging why: the browser reads its cache and decodes only asynchronously.

		@param fileName  The file's name, relative to the asset host.
		@param ensured  Called once the file is ensured.
		@param failed  Optional. Called with why the file can't be ensured, in place of `ensured`; when omitted, it is logged. */
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

	/** Asynchronously ensures several files together, as `EnsureAssetAsync` does each, fetching and decoding them all at once: for the
		files a program loads as it starts, or a loading screen.

		@param fileNames  The files' names, relative to the asset host.
		@param ensured  Called once every file is ensured.
		@param failed  Optional. Called with why a file can't be ensured, once, in place of `ensured`; when omitted, it is logged. The other
			files ensured stay ensured.
		@param progress  Optional. Called as each file is ensured, with how many are and how many there are. */
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

	/** Returns whether a file has been ensured in this run (`EnsureAssetAsync`), so a load of it answers at once on every target.

		@param fileName  The file's name, relative to the asset host.
		@return  True when it has. */
	static function IsAssetEnsured(fileName:String):Bool {
		return Runtime.ensured.exists(RCore.normalize(fileName));
	}

	// ---- Releasing ----

	/** Lets go of what ensuring a file kept in memory: its bytes and what was decoded from it. A load of it then behaves as one of a file
		never ensured. What a load already made from it (a texture, a sound) is the program's, let go of by raylib's unloads, and stays.
		The program's cache keeps its copy of a fetched file, so ensuring it again needs no fetch.

		A file's first load takes what was decoded from it, so a program only releases what it ensured and never loaded: a level's files
		when the player leaves for the menu.

		@param fileName  The file's name, relative to the asset host. */
	static function ReleaseAsset(fileName:String):Void {
		var path = RCore.normalize(fileName);
		Runtime.ensured.remove(path);
		Runtime.files.remove(path);
		Runtime.images.remove(path);
		Runtime.waves.remove(path);
		Runtime.gltfFiles.remove(path);
		Runtime.bmFonts.remove(path);
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
		var materials = Runtime.materials.get(path);
		if (materials != null) {
			Runtime.materials.remove(path);
			for (m in materials)
				RModels.UnloadMaterial(m);
		}
		Runtime.forgetPicture(path);
	}

	/** Lets go of several files' ensured data, as `ReleaseAsset` does each.

		@param fileNames  The files' names, relative to the asset host. */
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
		if (type == "mtl") {
			RModelsAsync.LoadMaterialsAsync(path, materials -> {
				Runtime.materials.set(path, materials);
				done(null);
			}, done);
			return;
		}
		Runtime.fetch(path, done);
	}
	#end
}
