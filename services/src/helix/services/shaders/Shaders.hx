package helix.services.shaders;

import helix.services.assets.Assets;

/** Provides shaders replaced in place when their files change, and shaders that are only files, through the assets.

	A shader compiled into the program with `ShaderOptions.file` is watched (`watch`): each time the assets are told its file changed
	(`Assets.notifyChanged`), the new file replaces it in place. Nothing is compiled while the program runs: the build compiled the
	file. A program that is only given shaders as files (a mod's) loads them (`load`) and they are watched alike.

	A replacement changes the shader's `source` and reflection and moves its `reloadCount`. Its handles and every `ShaderValues` made
	for it follow on their own. What was built on the GPU from it is its holder's: comparing `reloadCount` with the count it built at,
	the holder disposes its program (and the pipelines made with it, which `IGraphics.disposeShader` disposes) and builds again, as
	`ShaderPrograms` does. A file that no longer reads, or holds a shader of another kind (one shader where variants were, or other
	features), leaves the shader as it was: its `reloadError` says why, and the log says so with the path.

	**Who wires it.** Nothing watches files on its own. The program wires its hot reloader to the assets, one line in a page's
	development build with hotreload-hx: `reloader.assetsChanged = urls -> for (url in urls) assets.notifyUrlChanged(url);`. Nothing is
	polled beyond the assets' adapters (the HTTP client and file systems the program already polls each frame): this has no `poll`.

	**A release build** needs no conditional. hotreload-hx's `Reloader` does nothing outside a hot JS build (`-D hotreload`), on any
	target, so the line above compiles in a release build and links only that empty class; a program not using hotreload-hx exports a
	plain function the page's own development script calls with the changed paths. A release build writes no file and tells the assets
	of nothing, so a watch waits and costs nothing.

	**When a replacement happens.** A changed file is read when the assets bring it, and held: it replaces its shader at the next
	`prepareFrame`, which the program, or the renderer it draws through, calls at the frame's start, before `ShaderPrograms.prepareFrame`
	and before any values are written for the frame. So nothing changes in the middle of a frame: values repack, handles move and
	pipelines are rebuilt at the same boundary. Then the shader's reload listeners (`Shader.reloadListeners`) are called; nothing need
	poll `reloadCount`. helix-draw and helix-ray call both `prepareFrame`s inside their own frames.

	```haxe
	var shaders = new Shaders(assets);
	var glow = Shader.compile("quad.vert", "glow.frag", {file: "shaders/glow.shader"});
	shaders.watch(glow);
	``` */
class Shaders {
	final assets:Assets;

	/** Creates the shaders over the assets their files are read through.

		@param assets  The assets. */
	public function new(assets:Assets) {
		this.assets = assets;
	}

	/** Applies, at a frame's start, every replacement whose file has arrived since the last call, and calls their reload listeners.
		Before `ShaderPrograms.prepareFrame`, and before the frame's values are written. */
	public function prepareFrame():Void {
		if (arrived.length == 0)
			return;
		var now = arrived.copy();
		arrived.resize(0);
		var replaced:Array<Void->Void> = [];
		for (a in now) {
			var why = a.apply(a.bytes);
			if (why != null)
				helix.log.Log.warn('shaders: ${a.path}: $why; the shader stays as it was', "shaders");
			else
				replaced.push(a.listeners);
		}
		for (f in replaced)
			f();
	}

	/** Replaces a shader in place each time its file changes (at the `prepareFrame` after it arrives), until the returned function is
		called.

		@param shader  A shader compiled with `ShaderOptions.file`.
		@return  A function that stops watching it, the same for every call with the same shader (watching twice is watching once).
		@throws String  A shader compiled without `ShaderOptions.file` (`filePath` null), whatever the build. */
	public function watch(shader:Shader):Void->Void {
		var stop = watching.get(shader);
		if (stop != null)
			return stop;
		if (shader.filePath == null)
			throw 'shaders: a shader compiled without ShaderOptions.file can\'t be watched';
		var path = shader.filePath;
		var unwatch = assets.watch(path, bytes -> arrive(path, bytes, b -> replaceShader(shader, b), () -> shader.reloaded()));
		stop = () -> {
			unwatch();
			watching.remove(shader);
		};
		watching.set(shader, stop);
		return stop;
	}

	/** Replaces each variant in place each time their file changes, until the returned function is called.

		@param variants  Variants compiled with `ShaderOptions.file`.
		@return  A function that stops watching them, the same for every call with the same variants.
		@throws String  Variants compiled without `ShaderOptions.file`, whatever the build. */
	public function watchVariants(variants:ShaderVariants):Void->Void {
		var stop = watchingVariants.get(variants);
		if (stop != null)
			return stop;
		if (variants.filePath == null)
			throw 'shaders: variants compiled without ShaderOptions.file can\'t be watched';
		var path = variants.filePath;
		var unwatch = assets.watch(path, bytes -> arrive(path, bytes, b -> replaceVariants(variants, b), () -> variants.reloaded()));
		stop = () -> {
			unwatch();
			watchingVariants.remove(variants);
		};
		watchingVariants.set(variants, stop);
		return stop;
	}

	/** Loads a shader that is only a file, written by a build's `ShaderOptions.file`, and watches it.

		One of `loaded` or `failed` is called once, at a later `poll` of the assets, never during this call.
		@param path  The file, as the assets name it.
		@param loaded  Receives the shader.
		@param failed  Optional. Receives why it couldn't be loaded or read. When omitted, the failure is logged.
		@return  A function that aborts the load and stops watching; nothing is called after it. */
	public function load(path:String, loaded:Shader->Void, ?failed:String->Void):Void->Void {
		var stop:Null<Void->Void> = null, done = false;
		var abort = assets.load(path, bytes -> {
			var parsed = parse(bytes);
			if (parsed == null || parsed.kind != "shader") {
				fail(path, parsed == null ? "not a shader file" : "a file of variants, not one shader", failed);
				return;
			}
			var shader = new Shader(parsed.sources[0], path);
			shader.markShared(parsed.shared);
			stop = watch(shader);
			done = true;
			loaded(shader);
		}, message -> fail(path, message, failed));
		return () -> {
			abort();
			if (stop != null)
				stop();
		};
	}

	/** Loads variants that are only a file, and watches them.

		One of `loaded` or `failed` is called once, at a later `poll` of the assets, never during this call.
		@param path  The file, as the assets name it.
		@param loaded  Receives the variants.
		@param failed  Optional. Receives why they couldn't be loaded or read. When omitted, the failure is logged.
		@return  A function that aborts the load and stops watching; nothing is called after it. */
	public function loadVariants(path:String, loaded:ShaderVariants->Void, ?failed:String->Void):Void->Void {
		var stop:Null<Void->Void> = null;
		var abort = assets.load(path, bytes -> {
			var parsed = parse(bytes);
			if (parsed == null || parsed.kind != "variants") {
				fail(path, parsed == null ? "not a shader file" : "one shader, not a file of variants", failed);
				return;
			}
			var shaders = [
				for (source in parsed.sources) {
					var s = new Shader(source, path);
					s.markShared(parsed.shared);
					s;
				}
			];
			var variants = new ShaderVariants(parsed.featureNames, [for (f in parsed.variantFeatures) (f : ShaderFeatures)], shaders, path);
			stop = watchVariants(variants);
			loaded(variants);
		}, message -> fail(path, message, failed));
		return () -> {
			abort();
			if (stop != null)
				stop();
		};
	}

	// The watches, by what they watch: each one's stop.
	final watching = new haxe.ds.ObjectMap<Shader, Void->Void>();
	final watchingVariants = new haxe.ds.ObjectMap<ShaderVariants, Void->Void>();
	// Files that arrived since the last prepareFrame: each applied there, its listeners called after every one is.
	final arrived:Array<{
		path:String,
		bytes:haxe.io.Bytes,
		apply:haxe.io.Bytes->Null<String>,
		listeners:Void->Void
	}> = [];

	// A file's new bytes held for the next prepareFrame; a later copy of the same file replaces one not applied yet.
	function arrive(path:String, bytes:haxe.io.Bytes, apply:haxe.io.Bytes->Null<String>, listeners:Void->Void):Void {
		for (k => a in arrived)
			if (a.path == path && a.listeners == listeners) {
				arrived.splice(k, 1);
				break;
			}
		arrived.push({
			path: path,
			bytes: bytes,
			apply: apply,
			listeners: listeners
		});
	}

	// A shader replaced from its file's bytes, or why not.
	static function replaceShader(shader:Shader, bytes:haxe.io.Bytes):Null<String> {
		var parsed = parse(bytes);
		var why = parsed == null ? "the file doesn't read as a shader" : parsed.kind != "shader" ? "the file holds variants, not one shader" : null;
		if (why != null) {
			shader.refuse(why);
			return why;
		}
		shader.markSharedQuiet(parsed.shared);
		shader.replace(parsed.sources[0]);
		return null;
	}

	// Variants replaced from their file's bytes, or why not: the same features and combinations, in the same order.
	static function replaceVariants(variants:ShaderVariants, bytes:haxe.io.Bytes):Null<String> {
		var parsed = parse(bytes);
		var why = parsed == null ? "the file doesn't read as shaders" : parsed.kind != "variants" ? "the file holds one shader, not variants" : null;
		if (why == null
			&& (parsed.featureNames.join(",") != variants.featureNames.join(",")
				|| parsed.variantFeatures.join(",") != [for (f in variants.variantFeatures) (f : Int)].join(",")))
			why = "the file's variants have other features or combinations";
		if (why != null) {
			variants.refuse(why);
			return why;
		}
		for (s in variants.shaders)
			s.markSharedQuiet(parsed.shared);
		variants.replace(parsed.sources);
		return null;
	}

	// A shader file's contents, as a build writes them: one shader's source, or variants' features and sources; null for another file.
	static function parse(bytes:haxe.io.Bytes):Null<{
		kind:String,
		sources:Array<helix.platform.ShaderSource>,
		featureNames:Array<String>,
		variantFeatures:Array<Int>,
		shared:Array<String>
	}> {
		var value:Dynamic = try haxe.Json.parse(bytes.toString()) catch (_:Dynamic) null;
		if (value == null || !Std.isOfType(value.kind, String))
			return null;
		var shared:Array<String> = Std.isOfType(value.shared, Array) ? value.shared : [];
		if (value.kind == "shader" && value.source != null && Std.isOfType(value.source.attributes, Array))
			return {
				kind: "shader",
				sources: [value.source],
				featureNames: [],
				variantFeatures: [],
				shared: shared
			};
		if (value.kind == "variants"
			&& Std.isOfType(value.sources, Array)
			&& Std.isOfType(value.featureNames, Array)
			&& Std.isOfType(value.variantFeatures, Array))
			return {
				kind: "variants",
				sources: value.sources,
				featureNames: value.featureNames,
				variantFeatures: value.variantFeatures,
				shared: shared
			};
		return null;
	}

	static function fail(path:String, message:String, failed:Null<String->Void>):Void {
		if (failed != null)
			failed(message);
		else
			helix.log.Log.warn('shaders: $path: $message', "shaders");
	}
}
