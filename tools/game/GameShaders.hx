package tools.game;

import haxe.io.Path;
import sys.FileSystem;
import tools.shader.ShaderPacker;

/** `shader`: the game's shaders (its shaders/*.glsl, or the files named) packed into .hxshader assets by tools/shader/ShaderPacker.hx, and
	with watch again as each changes, until Ctrl+C. When the assets carry manifests (tools/gen_manifest.py's), those from their root down to
	the shaders' folder are written again after a pack. */
class GameShaders {
	// How often a watch looks for changes, in seconds.
	static inline final POLL = 0.25;

	/** Packs the shaders of the game in game into out as <name>.hxshader, with SDL_GPU's dialects when sdlGpu; with watch, again as each
		changes (and new ones in shaders/ when none were named), until Ctrl+C. Returns the outputs written. */
	public static function pack(root:String, game:String, files:Array<String>, out:String, sdlGpu:Bool, watch:Bool):Array<String> {
		var gameFolder = Files.resolve(Sys.getCwd(), game);
		var target = Files.resolve(gameFolder, out);
		var named = [for (f in files) Files.resolve(gameFolder, f)];
		for (source in named)
			if (!Files.isFile(source))
				throw new CommandError('shader: ${Files.relative(source, gameFolder)} is not a file');
		function sources():Array<String> {
			if (named.length > 0)
				return named;
			var folder = Path.join([gameFolder, "shaders"]);
			if (!Files.isFolder(folder))
				return [];
			var found = [
				for (name in FileSystem.readDirectory(folder))
					if (StringTools.endsWith(name, ".glsl") && Files.isFile(Path.join([folder, name]))) Path.join([folder, name])
			];
			found.sort(Reflect.compare);
			return found;
		}
		if (!watch && sources().length == 0)
			throw new CommandError('shader: nothing to pack: no shaders/*.glsl in $gameFolder and no file named');
		var packer = new ShaderPacker(root);
		var written = [];
		var packed = new Map<String, Float>();
		function packChanged():Void {
			var changed = false;
			for (source in sources()) {
				var stamp = FileSystem.stat(source).mtime.getTime();
				if (packed.get(source) == stamp)
					continue;
				packed.set(source, stamp);
				var output = Path.join([target, Path.withoutExtension(Path.withoutDirectory(source)) + ".hxshader"]);
				try {
					packer.pack(source, output, sdlGpu);
				} catch (error:CommandError) {
					if (!watch)
						throw error;
					Sys.println('shader: ${Path.withoutDirectory(source)} failed, kept as it was: ${error.message}');
					continue;
				}
				Sys.println('shader: ${Files.relative(source, gameFolder)} -> ${Files.relative(output, gameFolder)}');
				written.push(output);
				changed = true;
			}
			if (changed) {
				var manifests = manifestRoot(target, gameFolder);
				if (manifests != null) {
					Manifests.rewrite(manifests, target);
					Sys.println('shader: manifests rewritten under ${Files.relative(manifests, gameFolder)}');
				}
			}
		}
		packChanged();
		if (watch) {
			Sys.println('shader: watching ${named.length == 0 ? "shaders/" : named.length + " file(s)"} for changes; Ctrl+C stops');
			while (true) {
				Sys.sleep(POLL);
				packChanged();
			}
		}
		return written;
	}

	/** The root of the manifests that out is under: the highest folder from out up to game holding a manifest.json; null when there is none,
		as a game without a manifest needs nothing. */
	public static function manifestRoot(out:String, game:String):Null<String> {
		var folder = out, found:Null<String> = null;
		while (true) {
			if (Files.isFile(Path.join([folder, "manifest.json"])))
				found = folder;
			var parent = Path.directory(folder);
			if (folder == game || parent == folder || parent == "")
				return found;
			folder = parent;
		}
	}
}
