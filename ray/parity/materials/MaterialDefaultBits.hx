import helix.ray.*;
import helix.ray.Raylib.*;
import helix.ray.internal.Frame;
import helix.ray.internal.Runtime;
import helix.ray.internal.Textures;

// helix-ray's materials, printed as ref.c prints raylib 5.5's, for tools/ray_parity.py. Where ref.c sees a texture freed by GL taking
// its name again, this sees its pixels gone (Textures.imageOf).
@:access(helix.ray.internal.Runtime)
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

	static function valid(m:Material):Int
		return IsMaterialValid(m) ? 1 : 0;

	static function main() {
		SetTraceLogLevel(LOG_WARNING);
		var gr = new StubGraphics();
		Runtime.graphics = gr;
		Runtime.frame = new Frame(gr);
		var m = LoadMaterialDefault(), shader = m.shader;
		line('default valid ${valid(m)} shader ${shader.id == Runtime.frame.defaultProgram.handle ? 1 : 0} params ${m.params.join(" ")}');
		maps("default", m);
		line('empty valid ${valid(new Material(@:privateAccess new Shader(0, [], null), null))}');
		line('noshader valid ${valid(new Material(@:privateAccess new Shader(0, [], null), LoadMaterialDefault().maps))}');
		line('nomaps valid ${valid(new Material(shader, null))}');

		// A material with a texture of its own on two maps, unloaded.
		var checked = GenImageChecked(4, 4, 1, 1, RED, BLUE);
		var own = LoadTextureFromImage(checked), id = own.id;
		var u = LoadMaterialDefault();
		u.maps[MATERIAL_MAP_NORMAL].texture = own;
		u.maps[MATERIAL_MAP_EMISSION].texture = own;
		UnloadMaterial(u);
		line('unloaded valid ${valid(u)}');
		var white:Image = null;
		LoadImageFromTextureAsync(u.maps[MATERIAL_MAP_DIFFUSE].texture, i -> white = i, e -> throw e);
		pump(() -> white != null);
		Parity.image("unloaded default", white);
		line('unloaded freed ${Textures.imageOf(id) == null ? 1 : 0}');
		Parity.save();
	}
}
