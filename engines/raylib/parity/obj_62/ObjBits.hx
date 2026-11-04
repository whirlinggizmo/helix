import helix.raylib.*;
import helix.raylib.Raylib.*;
import helix.raylib.extras.Textures.*;
import helix.raylib.extras.Models.*;
import helix.raylib.internal.Frame;
import helix.raylib.internal.Runtime;
import helix.raylib.internal.Textures;

// helix-raylib's OBJ models, printed as ref.c prints raylib 6.2's, for tools/raylib_parity.py.
@:access(helix.raylib.internal.Runtime)
class ObjBits {
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

	static function materials(name:String, ms:Array<Material>) {
		var shader = LoadMaterialDefault().shader;
		for (i => m in ms) {
			line('$name material $i default ${m.shader.id == shader.id ? 1 : 0}');
			for (k => map in m.maps) {
				var c = map.color;
				line('$name map $i $k color ${c.r} ${c.g} ${c.b} ${c.a} value ${map.value}');
				texture('$name texture $i $k', map.texture);
			}
		}
	}

	// A model, or "failed" where LoadModelAsync fails: where raylib's LoadModel can't read the file and gives no meshes.
	static function model(name:String, file:String) {
		var model:Model = null, failed = false;
		LoadModelAsync(file, m -> model = m, e -> failed = true);
		pump(() -> model != null || failed);
		if (failed) {
			line('$name failed');
			return;
		}
		line('$name model ${model.meshCount} ${model.materialCount}');
		for (i in 0...model.meshCount) {
			line('$name meshmaterial $i ${model.meshMaterial[i]}');
			var m = model.meshes[i];
			Parity.mesh('$name $i', m);
			line('$name $i colors ${m.colors == null ? -1 : m.vertexCount * 4}' + (m.colors == null ? "" : [for (c in m.colors) ' $c'].join("")));
		}
		materials(name, [for (m in model.materials) m]);
		UnloadModel(model);
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
		model("shapes", "web/obj/shapes.obj");
		model("nolib", "web/obj/nolib.obj");
		model("plain", "web/obj/plain.obj");
		model("cube", "web/obj/cube.obj");
		model("groups", "web/obj/groups.obj");
		model("missing", "web/obj/missing.obj");
		model("empty", "web/obj/empty.obj");
		model("nothere", "web/obj/nothere.obj");
		model("latin", "web/obj/latin.obj");
		Parity.save();
	}
}
