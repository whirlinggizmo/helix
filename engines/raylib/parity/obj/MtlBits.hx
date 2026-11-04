import helix.raylib.*;
import helix.raylib.Raylib.*;
import helix.raylib.extras.Textures.*;
import helix.raylib.extras.Models.*;
import helix.raylib.internal.Frame;
import helix.raylib.internal.Runtime;
import helix.raylib.internal.Textures;

// helix-raylib's MTL materials, printed as ref.c prints raylib 5.5's, for tools/raylib_parity.py. Where raylib's LoadMaterials gives none for a
// file it can't read, LoadMaterialsAsync fails: its failure is printed as a count of 0.
@:access(helix.raylib.internal.Runtime)
class MtlBits {
	static function line(s:String)
		Parity.line(s);

	static function pump(done:Void->Bool) {
		for (_ in 0...10000) {
			if (done())
				return;
			Runtime.pollAll();
			var now = Runtime.waiting;
			Runtime.waiting = [];
			for (f in now)
				f();
		}
		throw "never answered";
	}

	// A texture as ref.c prints it, its pixels read back (LoadImageFromTextureAsync gives them RGBA).
	static function texture(key:String, t:Texture2D) {
		if (t.id == 0) {
			line('$key none');
			return;
		}
		if (t.id == Textures.DEFAULT) {
			line('$key default ${t.width} ${t.height} ${t.mipmaps} ${t.format}');
			return;
		}
		line('$key own ${t.width} ${t.height} ${t.mipmaps} ${t.format}');
		var im:Image = null;
		LoadImageFromTextureAsync(t, i -> im = i, e -> throw e);
		pump(() -> im != null);
		Parity.image(key, im);
	}

	// How many materials a file gives: its failure 0.
	static function count(file:String):Int {
		var found:Null<Int> = null;
		LoadMaterialsAsync(file, ms -> found = ms.length, _ -> found = 0);
		pump(() -> found != null);
		return found;
	}

	static function main() {
		SetTraceLogLevel(LOG_NONE);
		var gr = new StubGraphics();
		Runtime.graphics = gr;
		Runtime.frame = new Frame(gr);
		var files = new DiskFiles(), decoder = new PngDecoder();
		Runtime.polled.push(files);
		Runtime.polled.push(decoder);
		Runtime.assets = new helix.services.assets.Assets([new helix.services.assets.FileSystemSource(files)]);
		Runtime.decoding = new helix.services.images.Images(decoder, Runtime.assets);
		Runtime.polled.push(Runtime.decoding);
		Runtime.models = new helix.services.models.Models(Runtime.assets, Runtime.decoding);
		var ms:Array<Material> = null;
		LoadMaterialsAsync("lib.mtl", m -> ms = m, e -> throw e);
		pump(() -> ms != null);
		line('lib count ${ms.length}');
		var shader = LoadMaterialDefault().shader;
		for (i => m in ms) {
			line('lib material $i default ${m.shader.id == shader.id ? 1 : 0} valid ${IsMaterialValid(m) ? 1 : 0}');
			for (k => map in m.maps) {
				var c = map.color;
				line('lib map $i $k color ${c.r} ${c.g} ${c.b} ${c.a} value ${map.value}');
				texture('lib texture $i $k', map.texture);
			}
		}
		line('missing count ${count("nothere.mtl")}');
		line('other count ${count("web/obj/shapes.obj")}');
		Parity.save();
	}
}
