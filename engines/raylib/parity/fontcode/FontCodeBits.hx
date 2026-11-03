import helix.raylib.*;
import helix.raylib.Raylib.*;
import helix.raylib.Extras.*;
import helix.raylib.internal.Runtime;
import Parity.*;

// helix-raylib's ExportFontAsCodeAsync, printed as ref.c prints raylib 5.5's: the header's text, through SetSaveFileTextCallback, a line at a time
// as its bytes. TrueType glyphs are rasterized by the platform's native rasterizer, so this runs in hxcpp alone.
@:access(helix.raylib.internal.Runtime)
class FontCodeBits {
	static var saved = "";

	// Polls what loads until done says it has, the rasterizer working on a thread of its own.
	static function pump(done:Void->Bool):Void {
		for (_ in 0...20000) {
			if (done())
				return;
			Runtime.pollAll();
			var now = Runtime.waiting;
			Runtime.waiting = [];
			for (f in now)
				f();
			Sys.sleep(0.001);
		}
		throw "never answered";
	}

	static function load(fileName:String, fontSize:Int, codepoints:Array<Int>, count:Int):Font {
		var font:Font = null;
		LoadFontExAsync(fileName, fontSize, codepoints, count, loaded -> font = loaded, error -> throw error);
		pump(() -> font != null);
		return font;
	}

	static function exported(name:String, font:Font, fileName:String):Void {
		var written = -1;
		ExportFontAsCodeAsync(font, fileName, () -> written = 1, _ -> written = 0);
		pump(() -> written >= 0);
		line('$name exported $written');
		var lines = saved.split("\n");
		if (lines[lines.length - 1] == "")
			lines.pop();
		for (l in lines)
			str(name, l);
		line('$name lines ${lines.length} bytes ${haxe.io.Bytes.ofString(saved).length}');
	}

	static function main() {
		open();
		var files = new DiskFiles();
		Runtime.polled.push(files);
		Runtime.assets = new helix.services.assets.Assets([new helix.services.assets.FileSystemSource(files)]);
		SetSaveFileTextCallback((fileName, text) -> {
			saved = text;
			return true;
		});
		exported("default", GetFontDefault(), "font_default.h");
		exported("ttf", load("font.ttf", 20, null, 0), "jet_brains_mono.h");
		exported("large", load("font.ttf", 48, [65, 66, 103, 64, 0x2014], 5), "large.h");
		var sheet = GenImageColor(40, 22, MAGENTA);
		ImageDrawRectangle(sheet, 2, 2, 5, 8, WHITE);
		ImageDrawRectangle(sheet, 9, 2, 3, 8, new Color(200, 100, 50, 255));
		ImageDrawRectangle(sheet, 14, 2, 6, 8, new Color(10, 20, 30, 128));
		ImageDrawRectangle(sheet, 2, 12, 4, 8, BLACK);
		exported("image", LoadFontFromImage(sheet, MAGENTA, 32), "image_font.h");
		save();
	}
}
