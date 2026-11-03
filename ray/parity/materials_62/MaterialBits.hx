import helix.ray.*;
import helix.ray.Raylib.*;
import helix.ray.internal.Frame;
import helix.ray.internal.Runtime;
import helix.ray.internal.Textures;

// helix-ray's glTF materials, printed as ref.c prints raylib 6.2's, for tools/ray_parity.py.
@:access(helix.ray.internal.Runtime)
class MaterialBits {
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

	static function load(file:String):Model {
		var model:Model = null;
		LoadModelAsync(file, m -> model = m, e -> throw e);
		pump(() -> model != null);
		return model;
	}

	static function main() {
		SetTraceLogLevel(LOG_WARNING);
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
		var model = load("web/materials.gltf");
		line('model ${model.meshCount} ${model.materialCount}');
		for (i in 0...model.meshCount)
			line('meshmaterial $i ${model.meshMaterial[i]}');
		var shader = LoadMaterialDefault().shader;
		for (i => m in model.materials) {
			line('material $i default ${m.shader.id == shader.id ? 1 : 0}');
			for (k => map in m.maps) {
				var c = map.color;
				line('map $i $k color ${c.r} ${c.g} ${c.b} ${c.a} value ${map.value}');
				texture('texture $i $k', map.texture);
			}
		}
		Parity.save();
	}
}
