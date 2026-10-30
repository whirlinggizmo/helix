package helix.ray.internal;

#if macro
import haxe.io.Path;
import haxe.macro.Compiler;
import haxe.macro.Context;
import haxe.macro.Expr;
import sys.FileSystem;

/** Lets a program keep raylib's own shape, `while (!WindowShouldClose()) { ... }`, on every target.

	A page can't block, so the loop's body becomes a function called once a frame, and what follows the loop runs when it stops. The
	program's `main` runs once its files are loaded (`Runtime.boot`). The files are those under `-D helix-ray-files=<directory>` (default `web`),
	the directory the program's paths are relative to as it builds; natively the program finds them at `-D helix-ray-native-root=<directory>`
	(default `../web`), relative to its own. A page loads before `main` only the files its program names and those under
	`-D helix-ray-preload=<folder>,...`. */
class Loop {
	/** Adds `build` to the program's main class. Run by the library's `extraParams.hxml`. */
	public static function install():Void {
		var main = Compiler.getConfiguration().mainClass;
		if (main == null)
			return;
		var name = main.pack.concat([main.name]).join(".");
		Compiler.addMetadata("@:build(helix.ray.internal.Loop.build())", name);
	}

	/** Rewrites the main class: the loop in whichever static function holds it, and `main` to run once the files are loaded. */
	public static function build():Array<Field> {
		var fields = Context.getBuildFields();
		var pos = Context.currentPos();
		for (field in fields)
			switch field.kind {
				case FFun(f) if (f.expr != null):
					f.expr = rewriteLoop(f.expr);
				case _:
			}
		var files = Context.definedValue("helix-ray-files");
		if (files == null)
			files = "web";
		var root = Context.definedValue("helix-ray-native-root");
		if (root == null)
			root = "../web";
		var all = [];
		if (FileSystem.exists(files))
			list(files, "", all);
		// A page reads before main the files the program names in its sources (a string equal to a file's path, wherever it is
		// written), those a named glTF file points to, and every file under -D helix-ray-preload's folders; the rest it loads with the
		// ...Async functions. Natively nothing is read before main.
		var sources = Path.directory(Context.getPosInfos(Context.getLocalClass().get().pos).file);
		var text = sourceText(sources == "" ? "." : sources);
		var named = new Map<String, Bool>();
		var literal = ~/"([^"\n]+)"|'([^'\n]+)'/;
		var scan = text;
		while (literal.match(scan)) {
			var value = literal.matched(1) != null ? literal.matched(1) : literal.matched(2);
			while (StringTools.startsWith(value, "./"))
				value = value.substr(2);
			named.set(value, true);
			scan = literal.matchedRight();
		}
		// Music is streamed (LoadMusicStream), so a file named only there isn't read before main.
		var streamed = ~/LoadMusicStream\s*\(\s*["']([^"'\n]+)["']/;
		var rest = text, music = new Map<String, Bool>();
		while (streamed.match(rest)) {
			music.set(streamed.matched(1), true);
			rest = streamed.matchedRight();
		}
		for (path in music.keys()) {
			var others = new EReg('"' + EReg.escape(path) + '"|\'' + EReg.escape(path) + '\'', "g");
			var count = 0, scanText = text;
			while (others.match(scanText)) {
				count++;
				scanText = others.matchedRight();
			}
			if (count <= 1)
				named.remove(path);
		}
		var folders = Context.definedValue("helix-ray-preload");
		var paths = [];
		for (path in all) {
			var inFolder = false;
			if (folders != null)
				for (folder in folders.split(","))
					if (StringTools.trim(folder) != "" && StringTools.startsWith(path, StringTools.trim(folder) + "/"))
						inFolder = true;
			// A shader is compiled into the program as it builds (LoadShader), so it isn't read at all.
			var shader = ~/\.(vs|fs|vert|frag|glsl)$/i.match(path);
			if ((named.exists(path) || inFolder) && !shader)
				paths.push(path);
		}
		for (path in paths.copy())
			for (dependency in gltfFiles(files, path))
				if (all.indexOf(dependency) >= 0 && paths.indexOf(dependency) < 0)
					paths.push(dependency);
		paths.sort(Reflect.compare);
		// Only what the program uses is read before main, and linked: its files when it has any, the saves when its code names the
		// functions that read or write them.
		var preloads = [];
		if (paths.length > 0)
			preloads.push(macro helix.ray.internal.Runtime.preloadFiles($v{paths}));
		if (~/\b(SaveFileText|LoadFileText|LoadFileTextAsync|FileExists)\b/.match(text))
			preloads.push(macro helix.ray.internal.Runtime.preloadSaves());
		for (field in fields)
			if (field.name == "main")
				switch field.kind {
					case FFun(f) if (f.expr != null):
						var body = f.expr;
						f.expr = macro {
							helix.ray.internal.Runtime.root = $v{root};
							helix.ray.internal.Runtime.boot([$a{preloads}], () -> $body);
						};
					case _:
				}
		return fields;
	}

	// The program's sources, under the main class's directory, as one text.
	static function sourceText(dir:String):String {
		var out = new StringBuf();
		for (entry in FileSystem.readDirectory(dir)) {
			var path = Path.join([dir, entry]);
			if (FileSystem.isDirectory(path))
				out.add(sourceText(path));
			else if (StringTools.endsWith(entry, ".hx"))
				out.add(sys.io.File.getContent(path));
		}
		return out.toString();
	}

	// The files a glTF file points to (its buffers' and images' uris), as paths beside it; none for anything else.
	static function gltfFiles(base:String, path:String):Array<String> {
		var lower = path.toLowerCase();
		if (!StringTools.endsWith(lower, ".gltf") && !StringTools.endsWith(lower, ".glb"))
			return [];
		try {
			var bytes = sys.io.File.getBytes(Path.join([base, path]));
			var json = if (bytes.length >= 20 && bytes.getString(0, 4) == "glTF") bytes.getString(20, bytes.getInt32(12)) else bytes.toString();
			var document:Dynamic = haxe.Json.parse(json);
			var directory = Path.directory(path);
			var out = [];
			for (list in [document.buffers, document.images])
				if (list != null)
					for (entry in (list : Array<Dynamic>))
						if (entry.uri != null && !StringTools.startsWith(entry.uri, "data:"))
							out.push(directory == "" ? entry.uri : directory + "/" + entry.uri);
			return out;
		} catch (e:Dynamic) {
			return [];
		}
	}

	// The files under a directory, as paths relative to it, leaving out the page's own.
	static function list(base:String, relative:String, out:Array<String>):Void {
		var dir = relative == "" ? base : Path.join([base, relative]);
		for (entry in FileSystem.readDirectory(dir)) {
			var path = relative == "" ? entry : relative + "/" + entry;
			if (FileSystem.isDirectory(Path.join([base, path])))
				list(base, path, out);
			else if (!~/\.(html|js|map)$/i.match(entry))
				out.push(path);
		}
	}

	// Finds `while (!WindowShouldClose()) body` among a block's statements, and hands the body and the statements after it to Runtime.run.
	static function rewriteLoop(e:Expr):Expr {
		switch e.expr {
			case EBlock(statements):
				for (i in 0...statements.length)
					switch statements[i].expr {
						case EWhile(condition, body, true) if (isShouldClose(condition)):
							var before = statements.slice(0, i);
							var after = statements.slice(i + 1);
							var frame = frameBody(body);
							before.push(macro helix.ray.internal.Runtime.run(() -> $frame, () -> $b{after}));
							return {expr: EBlock(before), pos: e.pos};
						case _:
					}
				return e;
			case _:
				return e;
		}
	}

	static function isShouldClose(condition:Expr):Bool {
		return switch condition.expr {
			case EParenthesis(inner): isShouldClose(inner);
			case EUnop(OpNot, false, {expr: ECall({expr: EField(_, "WindowShouldClose")}, [])}): true;
			case EUnop(OpNot, false, {expr: ECall({expr: EConst(CIdent("WindowShouldClose"))}, [])}): true;
			case _: false;
		}
	}

	// The loop's body as a frame: `continue` ends the frame, and `break` ends the loop, outside any loop of its own.
	static function frameBody(body:Expr):Expr {
		function map(e:Expr):Expr {
			return switch e.expr {
				case EContinue: macro return;
				case EBreak: macro {
						helix.ray.internal.Runtime.shouldClose = true;
						return;
					};
				case EWhile(_, _, _) | EFor(_, _) | EFunction(_, _): e;
				case _: haxe.macro.ExprTools.map(e, map);
			}
		}
		return map(body);
	}
}
#end
