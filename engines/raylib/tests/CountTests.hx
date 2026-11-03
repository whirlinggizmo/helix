import haxe.io.Bytes;
import helix.raylib.*;
import helix.raylib.Raylib.*;
import helix.raylib.Extras.*;
import helix.raylib.internal.Frame;
import helix.raylib.internal.Runtime;
import helix.raylib.internal.Textures;

/** Checks helix-raylib's counting of what models hold (docs/DECISIONS.md 25), on graphics that count what is live: a texture the program
	unloads after giving it to a model, one given straight to a map and unloaded through it, a material shared by two models, a mesh
	replaced, a material unloaded before its model, a mesh LoadModelFromMesh takes over, two loads of one glTF file, and a texture copied
	out of a map freed with its model, where raylib leaks it; two loads unloaded in either order, UnloadTexture on one load's texture
	leaving the other's, a lone load's UnloadMaterial freeing its textures, a load after the last re-reading the file; a shader shared by
	two models' materials, the program unloading it first and last; two loads of an OBJ file sharing its textures and buffers, and an MTL
	file's materials, held by the program, sharing a texture the program loaded; a cubemap in a model's cubemap map, as raylib's skybox
	holds one; IQM, VOX and M3D files refused. Nothing is freed while held, nothing twice, and nothing
	is left. */
@:access(helix.raylib.internal.Runtime)
@:access(helix.raylib.internal.Textures)
@:access(helix.raylib.Mesh)
@:access(helix.raylib.Material)
class CountTests {
	static var checks = 0;
	static var graphics:CountingGraphics;
	static var baseTextures = 0;
	static var baseBuffers = 0;
	static var baseEntries = 0;
	static var baseShaders = 0;
	static var files:MemoryFiles;

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
		check(count(graphics.shaders) == baseShaders, '$message: GPU shaders ${count(graphics.shaders)}, not $baseShaders');
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

	// A load's textures of its own, every map's but the default texture.
	static function textures(model:Model):Array<Int>
		return [
			for (m in model.materials)
				for (map in m.maps)
					if (map.texture.id > Textures.DEFAULT)
						map.texture.id
		];

	// A shader of its own: raylib's default program, made again, as LoadShader makes one.
	static function makeShader():Shader
		return @:privateAccess helix.raylib.modules.RModels.makeShader(helix.raylib.internal.Defaults.shader());

	// A material's shader set, as raylib programs set one.
	static function SetMaterialShader(material:Material, shader:Shader):Void
		material.shader = shader;

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
		files = new MemoryFiles([
			"ship.gltf" => Bytes.ofString(ship()),
			"hut.obj" => Bytes.ofString("mtllib hut.mtl\nv 0 0 0\nv 1 0 0\nv 0 1 0\nusemtl wood\nf 1 2 3\nusemtl roof\nf 1 3 2\n"),
			"hut.mtl" => Bytes.ofString("newmtl wood\nKd 1 1 1\nNs 1\nmap_Kd wood.png\nmap_Ks wood.png\nbump bump.png\nnewmtl roof\nKd 1 0 0\nNs 1\n"),
			"wood.png" => Bytes.ofString("any"),
			"bump.png" => Bytes.ofString("any")
		]);
		var decoder = new SolidDecoder();
		Runtime.polled.push(files);
		Runtime.polled.push(decoder);
		Runtime.assets = new helix.services.assets.Assets([new helix.services.assets.FileSystemSource(files)]);
		Runtime.decoding = new helix.services.images.Images(decoder, Runtime.assets);
		Runtime.polled.push(Runtime.decoding);
		Runtime.models = new helix.services.models.Models(Runtime.assets, Runtime.decoding);
		baseTextures = count(graphics.textures);
		baseBuffers = count(graphics.buffers);
		baseEntries = count(Textures.entries);
		baseShaders = count(graphics.shaders);

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

		// raylib's skybox: a cubemap given to a model's cubemap map, unloaded through the map, then the model.
		model = LoadModelFromMesh(cube());
		var sky = LoadTextureCubemap(GenImageColor(2, 12, RED), CUBEMAP_LAYOUT_AUTO_DETECT);
		id = sky.id;
		check(sky.width == 2 && sky.height == 2 && sky.mipmaps == 1 && Textures.isCube(id), "cubemap: a column of 2 by 2 faces");
		model.materials[0].maps[MATERIAL_MAP_CUBEMAP].texture = sky;
		var gpu = Textures.handle(id);
		check(Textures.isCubeHandle(gpu), "cubemap: on the GPU as a cube");
		UnloadTexture(model.materials[0].maps[MATERIAL_MAP_CUBEMAP].texture);
		check(alive(id), "cubemap: the map still holds it");
		UnloadModel(model);
		check(!alive(id) && !Textures.isCubeHandle(gpu), "cubemap: UnloadModel frees it");
		clean("cubemap");

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

		// Two loads unloaded the other way about.
		one = load();
		two = load();
		ids = textures(one);
		UnloadModel(two);
		check(Lambda.foreach(ids, alive), "other order: the first keeps its textures");
		UnloadModel(one);
		check(!Lambda.exists(ids, alive), "other order: freed with the last");
		clean("other order");

		// UnloadTexture on one load's texture, then that load unloaded: the other load's hold stays.
		one = load();
		two = load();
		id = one.materials[1].maps[MATERIAL_MAP_ALBEDO].texture.id;
		UnloadTexture(one.materials[1].maps[MATERIAL_MAP_ALBEDO].texture);
		UnloadModel(one);
		check(alive(id) && two.materials[1].maps[MATERIAL_MAP_ALBEDO].texture.id == id, "one load's texture: the other load keeps it");
		UnloadModel(two);
		check(!alive(id), "one load's texture: freed with the other");
		clean("one load's texture");

		// A lone load's UnloadMaterial frees its textures.
		one = load();
		ids = textures(one);
		UnloadMaterial(one.materials[1]);
		check(!Lambda.exists(ids, alive), "lone load: UnloadMaterial frees its textures");
		UnloadModel(one);
		clean("lone load");

		// A load after the last is unloaded reads the file again.
		var reads = files.reads;
		check(!helix.raylib.internal.Models.isKept("ship.gltf"), "again: the file leaves the cache with its last load");
		one = load();
		check(files.reads == reads + 1 && Lambda.foreach(textures(one), alive), "again: read afresh, its textures made again");
		UnloadModel(one);
		clean("again");

		// A shader shared by two models' materials, the program unloading it first.
		var shader = makeShader();
		a = LoadModelFromMesh(cube());
		b = LoadModelFromMesh(cube());
		a.materials[0].shader = shader;
		b.materials[0].shader = shader;
		var handle = shader.id;
		UnloadShader(shader);
		check(shader.id == 0 && graphics.shaders.exists(handle) && a.materials[0].shader.id == handle,
			"shader first: the materials keep the shader the program unloaded");
		UnloadModel(a);
		check(graphics.shaders.exists(handle), "shader first: held by the second model's material");
		UnloadModel(b);
		check(!graphics.shaders.exists(handle), "shader first: freed with the second model");
		clean("shader first");

		// The same, the program unloading it last.
		shader = makeShader();
		handle = shader.id;
		a = LoadModelFromMesh(cube());
		b = LoadModelFromMesh(cube());
		SetMaterialShader(a.materials[0], shader);
		b.materials[0].shader = shader;
		UnloadModel(a);
		UnloadModel(b);
		check(graphics.shaders.exists(handle) && shader.id == handle, "shader last: the program's hold keeps it");
		UnloadShader(shader);
		check(!graphics.shaders.exists(handle) && shader.id == 0, "shader last: UnloadShader frees it");
		clean("shader last");

		// A texture copied out of a map, its model unloaded: freed here, where raylib leaks it.
		var three = load();
		var copied = three.materials[1].maps[MATERIAL_MAP_ALBEDO].texture;
		id = copied.id;
		UnloadModel(three);
		// Its record keeps the id (the first load's maps let go last), but the texture is gone: it draws as none.
		check(!alive(id) && Textures.handle(copied.id) == 0, "copied out: freed with its model");
		clean("copied out");

		// Two loads of an OBJ file share its textures and GPU buffers, each holding them, until the last is unloaded.
		var hut:Model = null, hut2:Model = null;
		LoadModelAsync("hut.obj", m -> hut = m, e -> throw e);
		pump(() -> hut != null);
		LoadModelAsync("hut.obj", m -> hut2 = m, e -> throw e);
		pump(() -> hut2 != null);
		for (m in [hut, hut2]) {
			for (mesh in m.meshes)
				UploadMesh(mesh, false);
			for (material in m.materials)
				for (map in material.maps)
					Textures.handle(map.texture.id);
		}
		var wood = hut.materials[0].maps[MATERIAL_MAP_DIFFUSE].texture.id;
		check(hut.meshCount == 2
			&& hut.materialCount == 2
			&& wood > Textures.DEFAULT
			&& hut.materials[0].maps[MATERIAL_MAP_SPECULAR].texture.id == wood
			&& hut2.materials[0].maps[MATERIAL_MAP_DIFFUSE].texture.id == wood
			&& hut.materials[0] != hut2.materials[0],
			"OBJ: two loads share a texture, each with materials of its own");
		check(hut.meshes[0].gpu == hut2.meshes[0].gpu, "OBJ: two loads share GPU buffers");
		ids = textures(hut);
		UnloadModel(hut);
		check(Lambda.foreach(ids, alive), "OBJ: the other load keeps the textures");
		UnloadModel(hut2);
		check(!Lambda.exists(ids, alive)
			&& !helix.raylib.internal.Models.isKept("hut.obj"), "OBJ: freed with the last load, the file let go");
		clean("OBJ");

		// An MTL file's materials are the program's until UnloadMaterial; a texture the program loaded too stays with its load.
		var materials:Array<Material> = null, own:Texture2D = null;
		LoadTextureAsync("wood.png", t -> own = t, e -> throw e);
		pump(() -> own != null);
		LoadMaterialsAsync("hut.mtl", ms -> materials = ms, e -> throw e);
		pump(() -> materials != null);
		check(materials.length == 2 && materials[0].maps[MATERIAL_MAP_DIFFUSE].texture.id == own.id, "MTL: the program's texture shared");
		var bump = materials[0].maps[MATERIAL_MAP_NORMAL].texture.id;
		for (m in materials)
			UnloadMaterial(m);
		check(alive(own.id) && !alive(bump), "MTL: UnloadMaterial frees its own textures, the program's load keeps its");
		UnloadTexture(own);
		clean("MTL");

		// IQM, VOX and M3D aren't read: the refusal says so (docs/DECISIONS.md 27).
		for (file in ["guy.iqm", "knight.vox", "cesium.M3D"]) {
			var why:String = null;
			LoadModelAsync(file, _ -> throw 'loaded $file', e -> why = e);
			pump(() -> why != null);
			check(why.indexOf("not supported") >= 0 && why.indexOf(file) >= 0, '$file: refused as not supported: $why');
		}

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

	/** How many reads were asked for. */
	public var reads = 0;

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
		reads++;
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
