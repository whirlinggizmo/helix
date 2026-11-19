import haxe.io.Bytes;
import helix.raylib.*;
import helix.raylib.Raylib.*;
import helix.raylib.Raymath.*;
import helix.raylib.extras.Lighting.*;
import helix.raylib.extras.Materials.*;
import helix.raylib.internal.Frame;
import helix.raylib.internal.Program;
import helix.raylib.internal.Runtime;

/** Checks the Materials extra, on graphics that count what is live: each setter and getter, its defaults and ranges; the default shader
	drawing a material as raylib's until it is cut out or emits light, then through its variant, its values written; a model's
	emission added to its materials' own at `DrawModel`, not at `DrawMesh`, and an intensity of 0 leaving the model as authored; the lit
	and PBR shaders' draws writing every value; and a glTF material's `MASK` and `alphaCutoff`, `emissiveFactor` and
	`KHR_materials_unlit` loaded into them. */
@:access(helix.raylib.internal.Runtime)
@:access(helix.raylib.internal.Frame)
@:access(helix.raylib.internal.Program)
@:access(helix.raylib.modules.RMaterials)
@:access(helix.raylib.Shader)
@:access(helix.services.shaders)
class MaterialsTests {
	static var checks = 0;

	static function check(value:Bool, message:String):Void {
		if (!value)
			throw message;
		checks++;
	}

	// The last draw recorded.
	static function lastDraw():Dynamic {
		var pass = Runtime.frame.pass;
		return pass.draws[pass.draws.length - 1];
	}

	// Whether the last draw went through a program (one of its pipelines).
	static function drewThrough(p:Program):Bool
		return [for (_ => id in p.pipelines) id].indexOf(lastDraw().pipeline) >= 0;

	// A float uniform's component in the last draw's blocks.
	static function drawn(p:Program, name:String, component = 0):Float {
		for (block in p.shader.blocks)
			for (m in block.members)
				if (m.glslName == name)
					return m.type == "int" ? (lastDraw().uniforms[block.indices[0]] : Bytes).getInt32(m.offset) : (lastDraw()
						.uniforms[block.indices[0]] : Bytes).getFloat(m.offset
						+ component * 4);
		throw 'no $name';
	}

	static function near(a:Float, b:Float):Bool
		return Math.abs(a - b) < 1e-5;

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

	static function main():Void {
		SetTraceLogLevel(LOG_NONE);
		var graphics = new CountingGraphics();
		Runtime.graphics = graphics;
		Runtime.frame = new Frame(graphics);

		// Each setter and getter, and the defaults.
		var cube = LoadModelFromMesh(GenMeshCube(1, 1, 1));
		var material = cube.materials[0];
		check(GetMaterialAlphaCutoff(material) == 0
			&& GetMaterialEmissive(material).x == 0
			&& !IsMaterialUnlit(material)
			&& IsMaterialShadowed(material),
			"a material's defaults: no cutoff, no emission, lit, shadowed");
		SetMaterialAlphaCutoff(material, 0.4);
		check(GetMaterialAlphaCutoff(material) == 0.4, "the alpha cutoff set");
		SetMaterialAlphaCutoff(material, 2);
		check(GetMaterialAlphaCutoff(material) == 1, "the alpha cutoff clamped to 1");
		SetMaterialAlphaCutoff(material, 0);
		SetMaterialEmissive(material, new Color(255, 51, 0, 255), 2);
		var out = new Vector3(9, 9, 9);
		check(GetMaterialEmissive(material, out) == out && out.x == 2 && near(out.y, 0.4) && out.z == 0,
			"the emission, its color times its intensity, into out");
		SetMaterialUnlit(material, true);
		SetMaterialShadowed(material, false);
		check(IsMaterialUnlit(material) && !IsMaterialShadowed(material), "unlit and shadowed set");
		SetMaterialUnlit(material, false);
		SetMaterialShadowed(material, true);
		SetMaterialEmissive(material, WHITE, 0);
		check(GetMaterialEmissive(material).x == 0, "an intensity of 0 emits nothing");

		// The default shader: raylib's while a material is neither cut out nor emits light, then its variant.
		var defaultProgram = Runtime.frame.defaultProgram;
		DrawModel(cube, Vector3Zero(), 1, WHITE);
		check(drewThrough(defaultProgram), "a plain material draws through raylib's default shader");
		SetMaterialAlphaCutoff(material, 0.5);
		DrawModel(cube, Vector3Zero(), 1, WHITE);
		var variant = @:privateAccess helix.raylib.modules.RMaterials.variant.program;
		check(drewThrough(variant) && drawn(variant, "alphaCutoff") == 0.5, "a cut out material draws through the variant, its cutoff written");
		check(variant.twin != null, "the variant has a skinned twin");
		SetMaterialAlphaCutoff(material, 0);
		SetMaterialEmissive(material, new Color(0, 255, 0, 255), 0.5);
		DrawModel(cube, Vector3Zero(), 1, WHITE);
		check(drewThrough(variant) && drawn(variant, "emissiveColor", 1) == 0.5 && drawn(variant, "alphaCutoff") == 0,
			"a material emitting light draws through the variant, its emission written");
		SetMaterialEmissive(material, WHITE, 0);

		// A model's emission: added at DrawModel, not at DrawMesh; 0 leaves the model as authored.
		SetModelEmissive(cube, new Color(255, 255, 255, 255), 0.8);
		DrawModel(cube, Vector3Zero(), 1, WHITE);
		check(drewThrough(variant) && near(drawn(variant, "modelEmissiveColor"), 0.8) && drawn(variant, "emissiveColor") == 0,
			"a model's emission makes its plain material draw through the variant, the model's light written apart");
		DrawMesh(cube.meshes[0], material, MatrixIdentity());
		check(drewThrough(defaultProgram), "a draw of the mesh alone reads no model's emission");
		SetModelEmissive(cube, WHITE, 0);
		DrawModel(cube, Vector3Zero(), 1, WHITE);
		check(drewThrough(defaultProgram), "a model's emission of 0 draws as authored, through raylib's default shader");

		// The PBR shader: every value written, the model's added to the material's own.
		var pbr = LoadPbrShader();
		var p = pbr.program;
		material.shader = pbr;
		SetMaterialEmissive(material, new Color(255, 0, 0, 255), 1);
		SetMaterialAlphaCutoff(material, 0.25);
		SetModelEmissive(cube, new Color(0, 0, 255, 255), 2);
		DrawModel(cube, Vector3Zero(), 1, WHITE);
		check(drewThrough(p)
			&& drawn(p, "emissiveColor") == 1
			&& drawn(p, "modelEmissiveColor", 2) == 2
			&& drawn(p, "alphaCutoff") == 0.25
			&& drawn(p, "unlitValue") == 0,
			"a PBR draw writes the material's emission, the model's, the cutoff and unlit");
		SetModelEmissive(cube, WHITE, 0);
		DrawModel(cube, Vector3Zero(), 1, WHITE);
		check(drawn(p, "modelEmissiveColor", 2) == 0
			&& drawn(p, "emissiveColor") == 1, "a model's emission of 0 keeps the material's own");

		// The lit shader: the same values.
		var lit = LoadLightingShader();
		material.shader = lit;
		SetMaterialUnlit(material, true);
		DrawModel(cube, Vector3Zero(), 1, WHITE);
		check(drewThrough(lit.program)
			&& drawn(lit.program, "unlitValue") == 1
			&& drawn(lit.program, "emissiveColor") == 1
			&& drawn(lit.program, "alphaCutoff") == 0.25,
			"a lit draw writes unlit, the emission and the cutoff");

		// A glTF file's materials: MASK and its cutoff, the emissive factor, KHR_materials_unlit.
		var shown:helix.platform.IFileSystem = new GltfFiles(gltf());
		Runtime.polled.push(shown);
		Runtime.assets = new helix.services.assets.Assets([new helix.services.assets.FileSystemSource(shown)]);
		var decoder = new NoImages();
		Runtime.polled.push(decoder);
		Runtime.decoding = new helix.services.images.Images(decoder, Runtime.assets);
		Runtime.polled.push(Runtime.decoding);
		Runtime.models = new helix.services.models.Models(Runtime.assets, Runtime.decoding);
		var model:Model = null;
		LoadModelAsync("sign.gltf", m -> model = m, e -> throw e);
		pump(() -> model != null);
		var masked = model.materials[1],
			glowing = model.materials[2],
			sign = model.materials[3],
			plain = model.materials[4];
		check(GetMaterialAlphaCutoff(masked) == 0.3
			&& GetMaterialAlphaCutoff(plain) == 0, "a MASK material loads its cutoff, an OPAQUE one none");
		check(GetMaterialAlphaCutoff(sign) == 0.5, "a MASK material without a cutoff loads 0.5");
		var e = GetMaterialEmissive(glowing);
		check(e.x == 1 && e.y == 0.5 && e.z == 0, "a material's emissiveFactor loads as its emission");
		check(IsMaterialUnlit(sign) && !IsMaterialUnlit(glowing), "a KHR_materials_unlit material loads unlit");

		var report = haxe.Json.stringify({passed: true, checks: checks});
		#if js
		js.Syntax.code("console.log({0})", report);
		#else
		Sys.println(report);
		#end
	}

	// A glTF file of one triangle and four materials: masked, glowing, an unlit sign masked at glTF's default, and plain.
	static function gltf():String {
		var b = new haxe.io.BytesOutput();
		for (v in [0., 0, 0, 1, 0, 0, 0, 1, 0])
			b.writeFloat(v);
		var buffer = haxe.crypto.Base64.encode(b.getBytes());
		return '{"asset":{"version":"2.0"},"scene":0,"scenes":[{"nodes":[0]}],"nodes":[{"mesh":0}],
			"meshes":[{"primitives":[{"attributes":{"POSITION":0},"material":0}]}],
			"materials":[{"alphaMode":"MASK","alphaCutoff":0.3},{"emissiveFactor":[1,0.5,0]},
				{"alphaMode":"MASK","extensions":{"KHR_materials_unlit":{}}},{"alphaMode":"OPAQUE","alphaCutoff":0.9}],
			"buffers":[{"byteLength":36,"uri":"data:application/octet-stream;base64,$buffer"}],
			"bufferViews":[{"buffer":0,"byteOffset":0,"byteLength":36}],
			"accessors":[{"bufferView":0,"componentType":5126,"count":3,"type":"VEC3","min":[0,0,0],"max":[1,1,0]}]}';
	}
}

// The glTF file alone, read at the next poll.
private class GltfFiles implements helix.platform.IFileSystem {
	final text:String;
	final waiting:Array<Void->Void> = [];

	public function new(text:String)
		this.text = text;

	public var root(get, never):String;

	function get_root():String
		return "";

	public var canWrite(get, never):Bool;

	function get_canWrite():Bool
		return false;

	public function read(path:String, maxBytes:Int, loaded:Bytes->Void, missing:Void->Void, failed:String->Void):Void->Void {
		waiting.push(() -> path == "sign.gltf" ? loaded(Bytes.ofString(text)) : missing());
		return () -> {};
	}

	public function write(path:String, bytes:Bytes, written:Void->Void, failed:String->Void):Void
		waiting.push(() -> failed("read only"));

	public function deleteFile(path:String, deleted:Void->Void, failed:String->Void):Void
		waiting.push(() -> failed("read only"));

	public function deleteFiles(deleted:Void->Void, failed:String->Void):Void
		waiting.push(() -> failed("read only"));

	public function getInfo(path:String, found:(size:Int, modified:Float) -> Void, missing:Void->Void, failed:String->Void):Void
		waiting.push(() -> path == "sign.gltf" ? found(text.length, 0) : missing());

	public function list(directory:String, listed:Array<String>->Void, missing:Void->Void, failed:String->Void):Void
		waiting.push(() -> missing());

	public function locate(path:String, located:(location:String, release:Void->Void) -> Void, missing:Void->Void, failed:String->Void):Void
		waiting.push(() -> missing());

	public function poll():Void {
		var now = waiting.copy();
		waiting.resize(0);
		for (f in now)
			f();
	}

	public function dispose():Void {}
}

// A decoder the file never reaches: it names no image.
private class NoImages implements helix.platform.IImageDecoder {
	public function new() {}

	public function decode(encoded:Bytes, decoded:(pixels:Bytes, width:Int, height:Int) -> Void, failed:String->Void):Void
		failed("no images");

	public function decodeForGpu(encoded:Bytes, decoded:helix.platform.IDecodedImage->Void, failed:String->Void):Void
		failed("no images");

	public function poll():Void {}

	public function dispose():Void {}
}
