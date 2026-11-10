import helix.raylib.*;
import helix.raylib.Raylib.*;
import helix.raylib.internal.Frame;
import helix.raylib.internal.Runtime;
import helix.raylib.internal.Textures;

// helix-raylib's materials, printed as ref.c prints raylib 5.5's, for tools/raylib_parity.py. Where ref.c sees a texture freed or kept by
// whether GL takes its name again, this sees its pixels gone or there (Textures.imageOf).
@:access(helix.raylib.internal.Runtime)
class MaterialDefaultBits {
	static function line(s:String)
		Parity.line(s);

	static function texture(key:String, t:Texture2D)
		line(t.id == 0 ? '$key none' : '$key ${t.id == Textures.DEFAULT ? "default" : "own"} ${t.width} ${t.height} ${t.mipmaps} ${t.format}');

	static function maps(name:String, m:Material)
		for (k => map in m.maps) {
			var c = map.color;
			line('$name map $k color ${c.r} ${c.g} ${c.b} ${c.a} value ${map.value}');
			texture('$name texture $k', map.texture);
		}

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

	static function pixels(key:String, t:Texture2D) {
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

	static function valid(m:Material):Int
		return IsMaterialValid(m) ? 1 : 0;

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
		var m = LoadMaterialDefault(), shader = m.shader;
		line('default valid ${valid(m)} shader ${shader.id == Runtime.frame.defaultProgram.handle ? 1 : 0} params ${m.params.join(" ")}');
		maps("default", m);
		line('empty valid ${valid(new Material(@:privateAccess new Shader(0, [], null), null))}');
		line('noshader valid ${valid(new Material(@:privateAccess new Shader(0, [], null), LoadMaterialDefault().maps))}');
		line('nomaps valid ${valid(new Material(shader, null))}');

		// A material given a texture on two maps, the texture unloaded, then the material.
		var checked = GenImageChecked(4, 4, 1, 1, RED, BLUE);
		var own = LoadTextureFromImage(checked), id = own.id;
		var u = LoadMaterialDefault();
		u.maps[MATERIAL_MAP_NORMAL].texture = own;
		u.maps[MATERIAL_MAP_EMISSION].texture = own;
		UnloadTexture(own);
		UnloadMaterial(u);
		line('unloaded valid ${valid(u)}');
		var white:Image = null;
		LoadImageFromTextureAsync(u.maps[MATERIAL_MAP_DIFFUSE].texture, i -> white = i, e -> throw e);
		pump(() -> white != null);
		Parity.image("unloaded default", white);
		line('unloaded freed ${Textures.imageOf(id) == null ? 1 : 0}');

		// A model given a texture, the texture unloaded, then the model.
		var tex = LoadTextureFromImage(checked), texId = tex.id;
		var cube = LoadModelFromMesh(GenMeshCube(1, 1, 1));
		cube.materials[0].maps[MATERIAL_MAP_DIFFUSE].texture = tex;
		UnloadTexture(tex);
		UnloadModel(cube);
		line('assigned freed ${Textures.imageOf(texId) == null ? 1 : 0}');

		// Two loads of the file: the first's material unloaded, the second's textures read after.
		var first = load("web/materials.gltf"),
			second = load("web/materials.gltf");
		UnloadMaterial(first.materials[1]);
		pixels("shared albedo", second.materials[1].maps[MATERIAL_MAP_ALBEDO].texture);
		pixels("shared normal", second.materials[1].maps[MATERIAL_MAP_NORMAL].texture);
		Parity.save();
	}
}
