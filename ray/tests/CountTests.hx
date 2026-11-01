import haxe.io.Bytes;
import helix.ray.*;
import helix.ray.Raylib.*;
import helix.ray.internal.Frame;
import helix.ray.internal.Runtime;
import helix.ray.internal.Textures;

/** Checks helix-ray's counting of what models hold (docs/DECISIONS.md 25), on graphics that count what is live: a texture the program
	unloads after giving it to a model, one given straight to a map and unloaded through it, a material shared by two models, a mesh
	replaced, a material unloaded before its model, a mesh LoadModelFromMesh takes over, two loads of one glTF file, and a texture copied
	out of a map freed with its model, where raylib leaks it. Nothing is freed while held, nothing twice, and nothing is left. */
@:access(helix.ray.internal.Runtime)
@:access(helix.ray.internal.Textures)
@:access(helix.ray.Mesh)
@:access(helix.ray.Material)
class CountTests {
	static var checks = 0;
	static var graphics:CountingGraphics;
	static var baseTextures = 0;
	static var baseBuffers = 0;
	static var baseEntries = 0;

	static function check(value:Bool, message:String):Void {
		if (!value)
			throw message;
		checks++;
	}

	static function count<V>(m:Map<Int, V>):Int
		return [for (k in m.keys()) k].length;

	// Whether nothing is left beyond what the frame itself holds: no texture record, no GPU texture or buffer, nothing disposed twice.
	static function clean(message:String):Void {
		check(count(Textures.entries) == baseEntries, '$message: texture records ${count(Textures.entries)}, not $baseEntries');
		check(count(graphics.textures) == baseTextures, '$message: GPU textures ${count(graphics.textures)}, not $baseTextures');
		check(count(graphics.buffers) == baseBuffers, '$message: GPU buffers ${count(graphics.buffers)}, not $baseBuffers');
		check(graphics.doubles == 0, '$message: ${graphics.doubles} disposed twice');
	}

	static function alive(id:Int):Bool
		return Textures.entries.exists(id);

	// A texture of its own, sent to the GPU.
	static function texture():Texture2D {
		var t = LoadTextureFromImage(GenImageColor(2, 2, RED));
		Textures.handle(t.id);
		return t;
	}

	static function cube():Mesh {
		var m = GenMeshCube(1, 1, 1);
		UploadMesh(m, false);
		return m;
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

	static function load():Model {
		var model:Model = null;
		LoadModelAsync("ship.gltf", m -> model = m, e -> throw e);
		pump(() -> model != null);
		for (m in model.meshes)
			UploadMesh(m, false);
		for (m in model.materials)
			for (map in m.maps)
				Textures.handle(map.texture.id);
		return model;
	}

	static function main():Void {
		SetTraceLogLevel(LOG_NONE);
		graphics = new CountingGraphics();
		Runtime.graphics = graphics;
		Runtime.frame = new Frame(graphics);
		var files = new MemoryFiles(["ship.gltf" => Bytes.ofString(ship())]),
			decoder = new SolidDecoder();
		Runtime.polled.push(files);
		Runtime.polled.push(decoder);
		Runtime.assets = new helix.services.assets.Assets({sources: [FileSystem(files)]});
		Runtime.decoding = new helix.services.images.Images(decoder, Runtime.assets);
		Runtime.polled.push(Runtime.decoding);
		Runtime.models = new helix.services.models.Models(Runtime.assets, Runtime.decoding);
		baseTextures = count(graphics.textures);
		baseBuffers = count(graphics.buffers);
		baseEntries = count(Textures.entries);

		// A texture alone: UnloadTexture frees it.
		var lone = texture(), id = lone.id;
		UnloadTexture(lone);
		check(lone.id == 0 && !alive(id), "alone: UnloadTexture frees it");
		clean("alone");

		// raylib's pattern: a texture given to a model, unloaded, then the model.
		var model = LoadModelFromMesh(cube()), tex = texture();
		id = tex.id;
		model.materials[0].maps[MATERIAL_MAP_DIFFUSE].texture = tex;
		UnloadTexture(tex);
		check(tex.id == 0 && alive(id) && model.materials[0].maps[MATERIAL_MAP_DIFFUSE].texture.id == id,
			"assigned: the map keeps the texture the program unloaded");
		var mesh = model.meshes[0], material = model.materials[0];
		UnloadModel(model);
		check(!alive(id) && mesh.refs == 0 && material.refs == 0 && model.meshCount == 0, "assigned: UnloadModel frees it, the mesh and material");
		clean("assigned");

		// A texture given straight to a map, unloaded through the map.
		model = LoadModelFromMesh(cube());
		model.materials[0].maps[MATERIAL_MAP_DIFFUSE].texture = texture();
		id = model.materials[0].maps[MATERIAL_MAP_DIFFUSE].texture.id;
		UnloadTexture(model.materials[0].maps[MATERIAL_MAP_DIFFUSE].texture);
		check(alive(id) && model.materials[0].maps[MATERIAL_MAP_DIFFUSE].texture.id == id, "through the map: the map still draws it");
		UnloadModel(model);
		check(!alive(id), "through the map: UnloadModel frees it");
		clean("through the map");

		// A material shared by two models.
		var a = LoadModelFromMesh(cube()), b = LoadModelFromMesh(cube());
		var shared = LoadMaterialDefault(), t = texture();
		id = t.id;
		shared.maps[MATERIAL_MAP_DIFFUSE].texture = t;
		UnloadTexture(t);
		var first = a.materials[0];
		a.materials[0] = shared;
		b.materials[0] = shared;
		check(first.refs == 0 && shared.refs == 3, "shared: the replaced material is freed, the shared one held three times");
		UnloadMaterial(shared);
		UnloadModel(a);
		check(alive(id) && shared.refs == 1, "shared: held by the second model after the first is unloaded");
		UnloadModel(b);
		check(!alive(id) && shared.refs == 0, "shared: freed with the second");
		clean("shared");

		// A mesh replaced.
		var m1 = cube(), m2 = cube();
		model = LoadModelFromMesh(m1);
		var before = count(graphics.buffers);
		model.meshes[0] = m2;
		check(m1.refs == 0 && count(graphics.buffers) < before, "replaced: the old mesh's buffers freed");
		UnloadMesh(m2);
		check(m2.refs == 1 && model.meshes[0] == m2, "replaced: the program's UnloadMesh leaves the model's");
		UnloadModel(model);
		UnloadMesh(m1);
		check(m1.refs == 0 && m2.refs == 0, "replaced: nothing below 0");
		clean("replaced");

		// A material unloaded before its model; a mesh LoadModelFromMesh took over, unloaded after it.
		mesh = cube();
		model = LoadModelFromMesh(mesh);
		check(mesh.refs == 1, "taken over: LoadModelFromMesh takes the program's hold");
		model.materials[0].maps[MATERIAL_MAP_DIFFUSE].texture = texture();
		id = model.materials[0].maps[MATERIAL_MAP_DIFFUSE].texture.id;
		material = model.materials[0];
		UnloadMaterial(material);
		check(material.refs == 0 && alive(id), "before its model: the program's hold on the texture stays");
		UnloadTexture(model.materials[0].maps[MATERIAL_MAP_DIFFUSE].texture);
		UnloadModel(model);
		UnloadMesh(mesh);
		check(material.refs == 0 && mesh.refs == 0 && !alive(id), "before its model: freed once, nothing below 0");
		clean("before its model");

		// Two loads of one file: one's material unloaded, then each model.
		var one = load(), two = load();
		var ids = [
			for (m in two.materials)
				for (map in m.maps)
					if (map.texture.id > Textures.DEFAULT)
						map.texture.id
		];
		check(ids.length == 4, 'two loads: four textures (base color, roughness, metalness, normal), not ${ids.length}');
		UnloadMaterial(one.materials[1]);
		check(Lambda.foreach(ids, alive), "two loads: UnloadMaterial on one leaves the other's textures");
		UnloadModel(one);
		check(Lambda.foreach(ids, alive) && count(graphics.buffers) > baseBuffers, "two loads: the second keeps its textures and buffers");
		UnloadModel(two);
		check(!Lambda.exists(ids, alive), "two loads: freed with the last");
		clean("two loads");

		// A texture copied out of a map, its model unloaded: freed here, where raylib leaks it.
		var three = load();
		var copied = three.materials[1].maps[MATERIAL_MAP_ALBEDO].texture;
		id = copied.id;
		UnloadModel(three);
		// Its record keeps the id (the first load's maps let go last), but the texture is gone: it draws as none.
		check(!alive(id) && Textures.handle(copied.id) == 0, "copied out: freed with its model");
		clean("copied out");

		var report = haxe.Json.stringify({passed: true, checks: checks});
		#if js
		js.Syntax.code("console.log({0})", report);
		#else
		Sys.println(report);
		#end
	}

	// A glTF file of one triangle on a material with a base color, a metallic-roughness and a normal texture, its images any bytes.
	static function ship():String {
		var b = new haxe.io.BytesOutput();
		for (v in [0., 0, 0, 1, 0, 0, 0, 1, 0])
			b.writeFloat(v);
		var buffer = haxe.crypto.Base64.encode(b.getBytes());
		var image = 'data:image/png;base64,${haxe.crypto.Base64.encode(Bytes.ofString("png"))}';
		return '{"asset":{"version":"2.0"},"scene":0,"scenes":[{"nodes":[0]}],"nodes":[{"mesh":0}],
			"meshes":[{"primitives":[{"attributes":{"POSITION":0},"material":0}]}],
			"materials":[{"pbrMetallicRoughness":{"baseColorTexture":{"index":0},"metallicRoughnessTexture":{"index":1}},"normalTexture":{"index":1}}],
			"textures":[{"source":0},{"source":1}],"images":[{"uri":"$image"},{"uri":"$image"}],
			"buffers":[{"byteLength":36,"uri":"data:application/octet-stream;base64,$buffer"}],
			"bufferViews":[{"buffer":0,"byteOffset":0,"byteLength":36}],
			"accessors":[{"bufferView":0,"componentType":5126,"count":3,"type":"VEC3","min":[0,0,0],"max":[1,1,0]}]}';
	}
}

// Files held in memory, each answer at the next poll.
private class MemoryFiles implements helix.platform.IFileSystem {
	final files:Map<String, Bytes>;
	final waiting:Array<Void->Void> = [];

	public function new(files:Map<String, Bytes>)
		this.files = files;

	public var root(get, never):String;

	function get_root():String
		return "";

	public var canWrite(get, never):Bool;

	function get_canWrite():Bool
		return false;

	public function read(path:String, maxBytes:Int, loaded:Bytes->Void, missing:Void->Void, failed:String->Void):Void->Void {
		waiting.push(() -> files.exists(path) ? loaded(files.get(path)) : missing());
		return () -> {};
	}

	public function write(path:String, bytes:Bytes, written:Void->Void, failed:String->Void):Void
		waiting.push(() -> failed("read only"));

	public function deleteFile(path:String, deleted:Void->Void, failed:String->Void):Void
		waiting.push(() -> failed("read only"));

	public function deleteFiles(deleted:Void->Void, failed:String->Void):Void
		waiting.push(() -> failed("read only"));

	public function getInfo(path:String, found:(size:Int, modified:Float) -> Void, missing:Void->Void, failed:String->Void):Void
		waiting.push(() -> files.exists(path) ? found(files.get(path).length, 0) : missing());

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

// Images that decode to 2x2 pixels, green and blue apart, each answer at the next poll.
private class SolidDecoder implements helix.platform.IImageDecoder {
	final waiting:Array<Void->Void> = [];

	public function new() {}

	public function decode(encoded:Bytes, decoded:(pixels:Bytes, width:Int, height:Int) -> Void, failed:String->Void):Void {
		var p = Bytes.alloc(16);
		for (i in 0...16)
			p.set(i, i * 15);
		waiting.push(() -> decoded(p, 2, 2));
	}

	public function poll():Void {
		var now = waiting.copy();
		waiting.resize(0);
		for (f in now)
			f();
	}

	public function dispose():Void {}
}
