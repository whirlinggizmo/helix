import haxe.io.Bytes;
import helix.services.assets.Assets;
import helix.services.assets.FileSystemSource;
import helix.services.images.Image;
import helix.services.images.Images;

/** Checks Images over fakes: files loaded through Assets and decoded, answered at a poll and never during the call, failures named by
	path (a file that won't decode, one not found), bytes decoded with no path, loads and decodes aborted (and an abort after the answer
	doing nothing), and nothing answered after dispose. */
class ImagesTests {
	static var checks = 0;

	static function check(value:Bool, message:String):Void {
		if (!value)
			throw message;
		checks++;
	}

	static function main():Void {
		var files = new FakeFileSystem();
		files.files.set("hero.png", Bytes.ofString("4x2"));
		files.files.set("tiles.png", Bytes.ofString("8x8"));
		files.files.set("bad.png", Bytes.ofString("junk"));
		var decoder = new FakeImageDecoder();
		var assets = new Assets([new FileSystemSource(files)]);
		var images = new Images(decoder, assets);
		function pump()
			for (_ in 0...5) {
				files.poll();
				decoder.poll();
				images.poll();
			}

		var hero:Image = null, why = [];
		var abortHero = images.load("hero.png", image -> hero = image);
		check(hero == null, "not answered during the call");
		images.load("bad.png", _ -> {}, message -> why.push(message));
		images.load("none.png", _ -> {}, message -> why.push(message));
		pump();
		check(hero != null && hero.path == "hero.png" && hero.width == 4 && hero.height == 2 && hero.pixels.length == 32 && hero.pixels.get(0) == 7,
			"loaded and decoded: its path, size and pixels");
		check(why.length == 2 && why.join("|").indexOf("bad.png") >= 0 && why.join("|").indexOf("none.png") >= 0,
			"a file that won't decode, and one not found, fail by name");
		abortHero();
		check(hero.width == 4, "an abort after the answer does nothing");

		var tiles:Image = null;
		var abortTiles = images.load("tiles.png", image -> tiles = image);
		files.poll();
		abortTiles();
		pump();
		check(tiles == null, "a load aborted in flight answers nothing");

		var embedded:Image = null, bad = "";
		images.decode(Bytes.ofString("2x3"), image -> embedded = image);
		images.decode(Bytes.ofString("junk"), _ -> {}, message -> bad = message);
		var abortDecode = images.decode(Bytes.ofString("1x1"), _ -> throw "an aborted decode answered");
		abortDecode();
		pump();
		check(embedded != null && embedded.path == "" && embedded.width == 2 && embedded.height == 3, "bytes decoded, with no path");
		check(bad == "not an image", "bytes that won't decode fail");

		var late:Image = null;
		images.load("hero.png", image -> late = image);
		images.dispose();
		pump();
		check(late == null, "nothing answered after dispose");
		var report = haxe.Json.stringify({passed: true, checks: checks});
		#if js
		js.Syntax.code("console.log({0})", report);
		#else
		Sys.println(report);
		#end
	}
}
