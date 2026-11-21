import haxe.io.Bytes;
import helix.raylib.Raylib.*;
import helix.raylib.extras.Assets.*;
import helix.raylib.internal.Runtime;
import helix.services.assets.AssetRequest;
import helix.services.assets.AssetSource;
import helix.services.assets.Assets;
import helix.platform.IFontRasterizer;
import helix.platform.RasterFont;
import helix.platform.RasterGlyph;
import helix.platform.StreamSource;
import helix.services.time.Time;

/** Checks the Assets extra: files ensured together, their fetches all asked for before any is answered, whether by one
	`EnsureAssetsAsync` or by `EnsureAssetAsync` calls in a row; the progress counted; a file that can't be ensured failing once while
	the others stay ensured; a file already ensured answered after the call, not during it; `IsAssetEnsured`; a name read from the
	host's root, `.` and `..` followed, and one climbing above it failing; an image ensured, loaded at once by `LoadImage`, `LoadTexture` and
	`LoadImageRaw`, and one not ensured loaded during the call natively and failing in a page; a font ensured, opened, loaded by
	`LoadFontEx` and `LoadFont` during the call, and closed as it's released; a compiled shader ensured (tests/shaders' glow, embedded
	by the build), loaded at once by `LoadCompiledShader`, one not ensured loaded during the call natively and empty in a page, and a
	.shader file that isn't a compiled shader failing its ensure; an .mtl file ensured, each `LoadMaterials` of it materials of its own,
	until it's released; and the asset hosts' order,
	the option first, then `SetAssetHosts`, then the build's define, then the default, each list in its order, and the ensured assets
	released as the hosts are set. On a source of the test's own that answers only once as many fetches as it waits for have been
	asked. */
@:access(helix.raylib.internal.Runtime)
class EnsureTests {
	static var checks = 0;

	static function check(value:Bool, message:String):Void {
		if (!value)
			throw message;
		checks++;
	}

	static function main():Void {
		SetTraceLogLevel(LOG_NONE);
		var system = new FakeSystem();
		Runtime.system = system;
		Runtime.time = new Time(system);
		var gate = new GatedSource(["a.txt" => "A", "b.txt" => "B", "c.txt" => "C", "d.txt" => "D", "e.txt" => "E"]);
		Runtime.assets = new Assets([gate]);
		Runtime.polled.push(Runtime.assets);

		// Three files ensured together: answered only as the third is asked, which fetches one after another would never reach.
		gate.waitFor = 3;
		var ensured = false, counted:Array<String> = [];
		EnsureAssetsAsync(["a.txt", "./b.txt", "c.txt", "a.txt"], () -> ensured = true, error -> throw error, (done, total) -> counted.push('$done/$total'));
		check(gate.asked.length == 3, 'every fetch asked for in the call, a name provided twice once: ${gate.asked}');
		check(!ensured, "ensured later, not during the call");
		poll();
		check(ensured && counted.join(",") == "1/3,2/3,3/3", 'ensured, its progress counted: $ensured $counted');
		check(IsAssetEnsured("a.txt") && IsAssetEnsured("b.txt") && IsAssetEnsured("./c.txt") && !IsAssetEnsured("d.txt"), "each ensured");
		check(Runtime.files.get("b.txt").toString() == "B", "an ensured file's bytes in memory");

		// EnsureAssetAsync calls in a row are fetched together too.
		gate.waitFor = 2;
		var ones = 0;
		EnsureAssetAsync("d.txt", () -> ones++);
		EnsureAssetAsync("e.txt", () -> ones++);
		poll();
		check(ones == 2, 'calls in a row fetched together: $ones');

		// A file already ensured: answered after the call, with nothing fetched.
		var asked = gate.asked.length, again = false;
		EnsureAssetAsync("a.txt", () -> again = true);
		check(!again, "an ensured file answered after the call");
		poll();
		check(again && gate.asked.length == asked, "and not fetched again");

		// A file that isn't there fails once; the others ensured with it stay ensured.
		gate.waitFor = 1;
		var failures:Array<String> = [], whole = false;
		EnsureAssetsAsync(["missing.txt", "a.txt"], () -> whole = true, error -> failures.push(error));
		poll();
		check(failures.length == 1 && !whole, 'failed once, not ensured: $failures');
		check(IsAssetEnsured("a.txt") && !IsAssetEnsured("missing.txt"), "the other file still ensured");

		// A name is read from the host's root, `.` and `..` followed, never above it; an absolute path is another file.
		check(IsAssetEnsured("x/../b.txt") && IsAssetEnsured("./x/./y/../../c.txt") && !IsAssetEnsured("/b.txt"),
			". and .. followed to the same file, an absolute path another");
		var escapes:Array<String> = [];
		EnsureAssetsAsync(["../b.txt", "x/../../b.txt"], () -> throw "a name above the host was ensured", error -> escapes.push(error));
		poll();
		check(escapes.length == 1 && escapes[0].indexOf("is outside every asset source's root") >= 0 && !IsAssetEnsured("../b.txt"),
			'a name climbing above the host fails, as outside every root: $escapes');

		// An image ensured is decoded to its pixels, and raylib's loads of it answer at once.
		var graphics = new CountingGraphics();
		Runtime.graphics = graphics;
		Runtime.frame = new helix.raylib.internal.Frame(graphics);
		var decoder = new FakeImageDecoder();
		Runtime.polled.push(decoder);
		Runtime.decoding = new helix.services.images.Images(decoder, Runtime.assets);
		Runtime.polled.push(Runtime.decoding);
		gate.files.set("hero.png", "4x2");
		gate.files.set("late.png", "2x3");
		gate.files.set("pixels.raw", "abcdefghijklmnop");
		var images = false;
		EnsureAssetsAsync(["hero.png", "pixels.raw"], () -> images = true, error -> throw error);
		poll();
		check(images, "an image and a raw file ensured");
		var image = LoadImage("hero.png");
		check(image.width == 4 && image.height == 2 && image.format == PIXELFORMAT_UNCOMPRESSED_R8G8B8A8 && image.data.get(0) == 7,
			'LoadImage of an ensured file: ${image.width} x ${image.height}');
		var texture = LoadTexture("hero.png");
		check(texture.id != 0 && texture.width == 4 && texture.height == 2, 'LoadTexture of an ensured file: ${texture.id}');
		var raw = LoadImageRaw("pixels.raw", 2, 2, PIXELFORMAT_UNCOMPRESSED_R8G8B8A8, 0);
		check(raw.width == 2 && raw.data.getString(0, 4) == "abcd", "LoadImageRaw of an ensured file");
		// A file not ensured: natively the load waits for it, in a page it fails as a missing file does.
		var late = LoadTexture("late.png");
		#if js
		check(late.id == 0, 'in a page, a texture not ensured is texture 0: ${late.id}');
		#else
		check(late.id != 0 && late.width == 2 && late.height == 3, 'natively, a texture not ensured is loaded during the call: ${late.id}');
		#end

		// A font ensured is opened, and raylib's loads of it rasterize it during the call, at the size each asks for.
		var rasterizer = new OpenedRasterizer();
		Runtime.fontRasterizer = rasterizer;
		Runtime.polled.push(rasterizer);
		gate.files.set("title.ttf", "font");
		var fontEnsured = false;
		EnsureAssetAsync("title.ttf", () -> fontEnsured = true, error -> throw error);
		poll();
		check(fontEnsured && rasterizer.open.length == 1, "a font ensured is opened");
		var font = LoadFontEx("title.ttf", 40, null, 0);
		check(font.baseSize == 40 && font.glyphCount == 95 && font.texture.id != 0,
			'LoadFontEx of an ensured font, at once: ${font.baseSize} ${font.glyphCount}');
		SetTextureFilter(font.texture, TEXTURE_FILTER_BILINEAR);
		var small = LoadFont("title.ttf");
		check(small.baseSize == 32 && small.glyphCount == 95 && small.texture.id != 0, 'LoadFont of an ensured font, at once: ${small.baseSize}');
		ReleaseAsset("title.ttf");
		check(rasterizer.open.length == 0 && !IsAssetEnsured("title.ttf"), "a font released is closed");

		// A compiled shader ensured is read, and its load makes the shader at once, each load a shader of its own.
		gate.files.set("glow.shader", haxe.Resource.getString("glow.shader"));
		gate.files.set("late.shader", haxe.Resource.getString("glow.shader"));
		gate.files.set("notes.shader", "not a shader");
		var shaderEnsured = false, notShader:Array<String> = [];
		EnsureAssetAsync("glow.shader", () -> shaderEnsured = true, error -> throw error);
		EnsureAssetAsync("notes.shader", () -> throw "ensured", error -> notShader.push(error));
		poll();
		check(shaderEnsured && !Runtime.files.exists("glow.shader"), "a compiled shader ensured, read, its bytes let go");
		check(notShader.length == 1
			&& notShader[0].indexOf("notes.shader isn't a compiled shader") >= 0
			&& !IsAssetEnsured("notes.shader"),
			'a .shader file that isn\'t a compiled shader fails its ensure: $notShader');
		var glow = LoadCompiledShader("glow.shader"),
			glowAgain = LoadCompiledShader("./glow.shader");
		check(IsShaderValid(glow) && GetShaderLocation(glow, "glow") >= 0, 'LoadCompiledShader of an ensured file, at once: ${glow.id}');
		check(IsShaderValid(glowAgain) && glowAgain.id != glow.id, "a second load of it a shader of its own");
		var lateShader = LoadCompiledShader("late.shader");
		#if js
		check(!IsShaderValid(lateShader), 'in a page, a shader not ensured is empty: ${lateShader.id}');
		#else
		check(IsShaderValid(lateShader), 'natively, a shader not ensured is loaded during the call: ${lateShader.id}');
		#end
		ReleaseAsset("glow.shader");
		check(!IsAssetEnsured("glow.shader") && !Runtime.compiledShaders.exists("glow.shader"), "a compiled shader released");

		// An .mtl file ensured stays for every load, each making materials of its own.
		gate.files.set("crate.mtl", "newmtl wood\nKd 1 0.5 0\n");
		var library = false;
		EnsureAssetAsync("crate.mtl", () -> library = true, error -> throw error);
		poll();
		var count = [0];
		var first = LoadMaterials("crate.mtl", count),
			second = LoadMaterials("crate.mtl", count);
		check(library && first.length == 1 && second.length == 1 && count[0] == 1 && first[0] != second[0],
			'each load of an ensured .mtl file its own materials: ${first.length} ${second.length}');
		first[0].maps[MATERIAL_MAP_ALBEDO].color = new helix.raylib.Color(0, 0, 255, 255);
		check(second[0].maps[MATERIAL_MAP_ALBEDO].color.r == 255, "one load's material changed, not another's");
		ReleaseAsset("crate.mtl");
		check(!IsAssetEnsured("crate.mtl") && !Runtime.materialLibraries.exists("crate.mtl"), "an .mtl file released");

		// A file released is no longer ensured, and a load of it is one of a file never ensured.
		ReleaseAssets(["pixels.raw"]);
		check(!IsAssetEnsured("pixels.raw"), "a released file isn't ensured");
		#if js
		check(LoadImageRaw("pixels.raw", 2, 2, PIXELFORMAT_UNCOMPRESSED_R8G8B8A8, 0).data == null, "in a page, a released file doesn't load");
		#end

		// The hosts: the option's, then the program's, then the build's define's, then the default.
		#if js
		check(GetAssetHosts().length == 1 && GetAssetHosts()[0] == "", 'the default in a page: ${GetAssetHosts()}');
		#else
		check(GetAssetHosts().join("|") == "../web", 'the default natively: ${GetAssetHosts()}');
		#end
		Runtime.builtHosts = "mods/, https://built.example/,";
		check(GetAssetHosts().join("|") == "mods/|https://built.example/", 'the build\'s define over the default, its list in order: ${GetAssetHosts()}');
		var out = ["stale"];
		check(GetAssetHosts(out) == out
			&& out.join("|") == "mods/|https://built.example/", 'the hosts filled into an array provided: $out');
		check(IsAssetEnsured("b.txt") && Runtime.files.exists("b.txt"), "a file ensured before the hosts are set");
		var hosts = ["files/", "https://program.example/"],
			before = Runtime.assets;
		Runtime.files.set("loaded.txt", haxe.io.Bytes.ofString("a load's"));
		SetAssetHosts(hosts);
		hosts.push("later/");
		check(GetAssetHosts().join("|") == "files/|https://program.example/", 'the program\'s over the build\'s, as they were when set: ${GetAssetHosts()}');
		check(!IsAssetEnsured("b.txt") && !Runtime.files.exists("b.txt") && !IsAssetEnsured("a.txt"), "the ensured assets released as the hosts are set");
		check(!Runtime.files.exists("loaded.txt"), "a file a load brought into memory released too");
		check(Runtime.assets == before, "the assets the same, for the sounds and the fonts loading through them");
		system.options.set("asset_hosts", "https://option.example/,extra/");
		check(GetAssetHosts().join("|") == "https://option.example/|extra/", 'the option over the program\'s: ${GetAssetHosts()}');
		SetAssetHosts(["ignored/"]);
		check(GetAssetHosts().join("|") == "https://option.example/|extra/", "the option over a later SetAssetHosts");

		var report = haxe.Json.stringify({passed: true, checks: checks});
		#if js
		js.Syntax.code("console.log({0})", report);
		#else
		Sys.println(report);
		#end
	}

	static function poll():Void {
		for (_ in 0...20)
			Runtime.pollAnswers();
	}
}

// A source answering its loads only once as many as it waits for have been asked, at a later poll as a real source does, from files of
// its own; a name it hasn't is missing.

@:access(helix.raylib.internal.Runtime)
@:access(helix.services.assets.AssetSource)
private class GatedSource extends AssetSource {
	/** The files it has, by path. */
	public final files:Map<String, String>;

	final pending:Array<Void->Void> = [];

	/** The fetches it waits for before answering any. */
	public var waitFor = 1;

	/** Every path it was asked for, in order. */
	public final asked:Array<String> = [];

	public function new(files:Map<String, String>) {
		super();
		this.files = files;
	}

	// A path's . and .. followed, as a file system source follows them.
	function nameOf(path:String):Null<String>
		return AssetSource.follow(path);

	function locationOf(name:String):String
		return name;

	public function read(path:String, request:AssetRequest, loaded:Bytes->Void, missing:Void->Void, failed:String->Void):Void {
		asked.push(path);
		pending.push(() -> files.exists(path) ? loaded(Bytes.ofString(files.get(path))) : missing());
		if (pending.length >= waitFor) {
			var now = pending.splice(0, pending.length);
			for (answer in now)
				Runtime.later(answer);
		}
	}

	public function refetch(path:String, request:AssetRequest, loaded:Bytes->Void, missing:Void->Void, failed:String->Void):Void
		read(path, request, loaded, missing, failed);

	public function locate(path:String, request:AssetRequest, located:(StreamSource, Void->Void) -> Void, missing:Void->Void, failed:String->Void):Void
		missing();
}

// Opens "font" bytes at a later poll, and rasterizes an opened font during the call: each glyph a 2 by size box.
private class OpenedRasterizer implements IFontRasterizer {
	/** The fonts open, by id. */
	public final open:Array<Int> = [];

	final pending:Array<Void->Void> = [];
	var next = 1;

	public function new() {}

	public function rasterize(encoded:Bytes, size:Float, codepoints:Array<Int>,
			rasterized:(glyphs:Array<RasterGlyph>, ascent:Float, descent:Float, lineGap:Float) -> Void, failed:String->Void):Void
		pending.push(() -> failed("rasterized only when opened"));

	public function rasterizeDistanceField(encoded:Bytes, size:Float, codepoints:Array<Int>,
			rasterized:(glyphs:Array<RasterGlyph>, ascent:Float, descent:Float, lineGap:Float) -> Void, failed:String->Void):Void
		pending.push(() -> failed("rasterized only when opened"));

	public function openFont(encoded:Bytes, opened:(font:Int) -> Void, failed:String->Void):Void {
		var id = next++, font = encoded.toString() == "font";
		pending.push(() -> if (!font) failed("not a font") else {
			open.push(id);
			opened(id);
		});
	}

	public function rasterizeOpened(font:Int, size:Float, codepoints:Array<Int>):RasterFont {
		if (open.indexOf(font) < 0)
			throw 'font $font isn\'t open';
		var h = Std.int(size);
		return {
			glyphs: [
				for (c in codepoints)
					({
						codepoint:c, found:true, width:2, height:h, offsetX:0, offsetY: -h, advance:3, pixels:Bytes.alloc(2 * h)
					} : RasterGlyph)
			],
			ascent: size * .75,
			descent: -size * .25,
			lineGap: 0
		};
	}

	public function rasterizeDistanceFieldOpened(font:Int, size:Float, codepoints:Array<Int>):RasterFont
		return rasterizeOpened(font, size, codepoints);

	public function closeFont(font:Int):Void
		open.remove(font);

	public function poll():Void {
		var now = pending.splice(0, pending.length);
		for (f in now)
			f();
	}

	public function dispose():Void {}
}
