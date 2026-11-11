import helix.raylib.*;
import helix.raylib.Raylib.*;
import helix.raylib.internal.Frame;
import helix.raylib.internal.Runtime;
import helix.raylib.internal.Textures;

// helix-raylib's glTF materials, printed as ref.c prints raylib 6.2's, for tools/raylib_parity.py.
@:access(helix.raylib.internal.Runtime)
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
		// "factors", with no metallic-roughness image: the file's factors, where raylib's are 0 (DECISIONS 71, the manifest's bar).
		var factors = model.materials[2].maps;
		if (Math.abs(factors[MATERIAL_MAP_ROUGHNESS].value - 0.15) > 1e-6 || Math.abs(factors[MATERIAL_MAP_METALNESS].value - 0.45) > 1e-6)
			throw 'factors: roughness ${factors[MATERIAL_MAP_ROUGHNESS].value} and metalness ${factors[MATERIAL_MAP_METALNESS].value}, not the file\'s 0.15 and 0.45';
		var shader = LoadMaterialDefault().shader;
		for (i => m in model.materials) {
			line('material $i default ${m.shader.id == shader.id ? 1 : 0}');
			for (k => map in m.maps) {
				var c = map.color;
				line('map $i $k color ${c.r} ${c.g} ${c.b} ${c.a}');
				line('value $i $k ${map.value}');
				texture('texture $i $k', map.texture);
			}
		}
		Parity.save();
	}
}
