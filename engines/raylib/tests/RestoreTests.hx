import haxe.io.Bytes;
import helix.raylib.*;
import helix.raylib.Raylib.*;
import helix.raylib.extras.Textures.*;
import helix.raylib.extras.Models.*;
import helix.raylib.extras.Lights.*;
import helix.raylib.internal.Frame;
import helix.raylib.internal.Models;
import helix.raylib.internal.Runtime;
import helix.raylib.internal.Textures;

/** Checks what helix-raylib does when the GPU's context is lost and given back (Event.GraphicsLost, Event.GraphicsRestored), on graphics
	that count what is made: nothing throws while it is lost; at the restore the frame's own texture and buffer are made again, a file's
	texture is decoded again from its bytes and sent when next drawn, a font's atlas is sent again from the pixels it kept, a mesh is
	sent again when next drawn, a render texture keeps the handle the platform remade, a data texture is left to the platform, a
	texture made from pixels (`LoadTextureFromImage`) and a cubemap are sent again from the pixels a page keeps, with what
	`UpdateTexture` wrote since (natively, where none are kept, drawn as nothing with one warning each), a model's textures held in its file (its base color, and
	the roughness and metalness split from one image) are decoded again from the model's bytes and sent, as is one a load makes after
	the program unloaded the last load's, and a texture set on a shader (`SetShaderValueTexture`) is bound by the handle it was sent
	again with. */
@:access(helix.raylib.internal.Runtime)
@:access(helix.raylib.internal.Textures)
@:access(helix.raylib.Mesh)
@:access(helix.raylib.Shader)
@:access(helix.raylib.internal.Frame)
@:access(helix.raylib.internal.Program)
class RestoreTests {
	static var checks = 0;
	static var graphics:CountingGraphics;
	static var warnings = 0;

	static function check(value:Bool, message:String):Void {
		if (!value)
			throw message;
		checks++;
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

	static function main():Void {
		Runtime.logLevel = LOG_WARNING;
		Runtime.logCallback = (level, text) -> {
			if (level == LOG_WARNING && text.indexOf("Lost with the GPU context") >= 0)
				warnings++;
		};
		graphics = new CountingGraphics();
		Runtime.graphics = graphics;
		Runtime.frame = new Frame(graphics);
		var files = new MemoryFiles(["wood.png" => Bytes.ofString("any"), "ship.gltf" => Bytes.ofString(ship())]);
		var decoder = new SolidDecoder();
		Runtime.polled.push(files);
		Runtime.polled.push(decoder);
		Runtime.assets = new helix.services.assets.Assets([new helix.services.assets.FileSystemSource(files)]);
		Runtime.decoding = new helix.services.images.Images(decoder, Runtime.assets);
		Runtime.polled.push(Runtime.decoding);

		// Before: a file's texture, one from pixels, the default font's atlas, a mesh and a render texture, each on the GPU.
		var file:Texture2D = null;
		LoadTextureAsync("wood.png", t -> file = t, e -> throw e);
		pump(() -> file != null);
		var fileGpu = Textures.handle(file.id);
		var pixels = LoadTextureFromImage(GenImageColor(2, 2, RED));
		var pixelsGpu = Textures.handle(pixels.id);
		var green = haxe.io.Bytes.alloc(16);
		for (i in 0...4)
			green.setInt32(i * 4, 0xff30e400);
		UpdateTexture(pixels, green);
		var sky = LoadTextureCubemap(GenImageColor(2, 12, BLUE), CUBEMAP_LAYOUT_LINE_VERTICAL);
		var skyGpu = Textures.handle(sky.id);
		var font = GetFontDefault();
		var fontGpu = Textures.handle(font.texture.id);
		var mesh = GenMeshCube(1, 1, 1);
		UploadMesh(mesh, false);
		var target = LoadRenderTexture(4, 4);
		var data = Runtime.graphics.createDataTexture(256, 1);
		check(fileGpu != 0 && pixelsGpu != 0 && skyGpu != 0 && fontGpu != 0 && mesh.gpu.buffers != null && target.id != 0 && data != 0,
			"before: everything on the GPU");
		// A model whose textures are held in its file: its base color, and the roughness and metalness split from one image.
		var model:Model = null;
		LoadModelAsync("ship.gltf", m -> model = m, e -> throw e);
		pump(() -> model != null);
		var maps = model.materials[1].maps;
		var albedo = maps[MATERIAL_MAP_ALBEDO].texture.id,
			rough = maps[MATERIAL_MAP_ROUGHNESS].texture.id,
			metal = maps[MATERIAL_MAP_METALNESS].texture.id;
		var albedoGpu = Textures.handle(albedo),
			roughGpu = Textures.handle(rough),
			metalGpu = Textures.handle(metal);
		check(albedoGpu != 0 && roughGpu != 0 && metalGpu != 0 && albedo != rough && rough != metal, "before: a model's textures on the GPU");
		// A texture set on a shader's own sampler, bound by its handle at each draw.
		var pbr = LoadPbrShader();
		SetShaderValueTexture(pbr, GetShaderLocation(pbr, "emissiveMap"), file);
		var cube = LoadModelFromMesh(GenMeshCube(1, 1, 1));
		cube.materials[0].shader = pbr;
		DrawModel(cube, new Vector3(0, 0, 0), 1, WHITE);
		var slot = pbr.program.slotOf("emissiveMap");
		function boundEmissive():Int {
			var pass = Runtime.frame.pass;
			var bound:Array<Int> = pass.draws[pass.draws.length - 1].textures;
			return bound[slot];
		}
		check(boundEmissive() == fileGpu, "before: a texture set on a shader bound by its handle");
		var white = Runtime.frame.white;
		var textures = graphics.textureCreations,
			buffers = graphics.bufferCreations,
			targets = graphics.targetCreations,
			dataTextures = graphics.dataTextureCreations;

		// Lost: the platform takes every call; helix-raylib changes nothing.
		Runtime.graphicsLost();
		check(Textures.handle(file.id) == fileGpu && Textures.handle(pixels.id) == pixelsGpu, "lost: handles as they were");
		Models.upload(mesh);
		check(graphics.textureCreations == textures && graphics.bufferCreations == buffers, "lost: nothing made");

		// Restored: the frame's own made again now; the rest as they are next drawn.
		Runtime.graphicsRestored();
		check(Runtime.frame.white != white && Runtime.frame.white != 0, "restored: the white texture made again");
		check(graphics.textureCreations == textures + 1 && graphics.bufferCreations == buffers + 1,
			"restored: the frame's texture and constants, nothing else yet");
		textures++;
		buffers++;
		check(Textures.onGpu(albedo) == 0 && Textures.onGpu(rough) == 0 && Textures.handle(albedo) == 0 && Textures.handle(rough) == 0,
			"a model's textures: off the GPU, drawn as nothing while the model's bytes are decoded again");

		// The file's texture: decoded again from its bytes, drawn as nothing meanwhile, then sent.
		check(Textures.onGpu(file.id) == 0, "a file's texture: off the GPU");
		pump(() -> Runtime.picture("wood.png") != null);
		var again = Textures.handle(file.id);
		check(again != 0 && again != fileGpu && graphics.textureCreations == textures + 1, "a file's texture: sent again from its bytes");
		textures++;
		check(Textures.handle(file.id) == again && graphics.textureCreations == textures, "a file's texture: sent once");
		DrawModel(cube, new Vector3(0, 0, 0), 1, WHITE);
		check(boundEmissive() == again, "a texture set on a shader: bound by the handle it was sent again with");
		// The draw sent the PBR shader's flat normal texel again, from the pixels it keeps.
		textures++;
		check(graphics.textureCreations == textures, "the PBR shader's flat normal: sent again from its kept pixels");

		// One from pixels, and a cubemap: sent again from the pixels kept in a page, the update with them. Natively, where a lost
		// context isn't recovered, they aren't kept: drawn as nothing, warned of once each.
		#if js
		var pixelsAgain = Textures.handle(pixels.id);
		check(pixelsAgain != 0 && pixelsAgain != pixelsGpu && graphics.textureCreations == textures + 1 && warnings == 0,
			"a texture from pixels: sent again from its kept pixels");
		check(graphics.lastLevels[0].getInt32(0) == 0xff30e400, "a texture from pixels: sent with what UpdateTexture wrote");
		textures++;
		var skyAgain = Textures.handle(sky.id);
		check(skyAgain != 0
			&& skyAgain != skyGpu
			&& graphics.textureCreations == textures + 1, "a cubemap: sent again from its kept faces");
		textures++;
		#else
		check(Textures.handle(pixels.id) == 0 && Textures.handle(sky.id) == 0 && warnings == 2,
			"natively: a texture from pixels and a cubemap drawn as nothing, warned of");
		Textures.handle(pixels.id);
		check(warnings == 2 && graphics.textureCreations == textures, "natively: warned of once each, nothing made");
		warnings = 0;
		#end

		// The font's atlas: kept in memory, sent again.
		var fontAgain = Textures.handle(font.texture.id);
		check(fontAgain != 0
			&& fontAgain != fontGpu
			&& graphics.textureCreations == textures + 1, "a font's atlas: sent again from its kept pixels");
		textures++;

		// The mesh: its buffers made again when next drawn.
		check(mesh.gpu.buffers == null && mesh.gpu.indexBuffer == 0, "a mesh: its buffers forgotten");
		Models.upload(mesh);
		check(mesh.gpu.buffers != null && mesh.gpu.indexBuffer != 0 && graphics.bufferCreations >= buffers + 4, "a mesh: sent again when drawn");

		// A model's textures held in its file: decoded again from the model's bytes, then sent, none warned of.
		pump(() -> Textures.handle(albedo) != 0);
		var albedoAgain = Textures.handle(albedo),
			roughAgain = Textures.handle(rough),
			metalAgain = Textures.handle(metal);
		check(albedoAgain != albedoGpu && roughAgain != 0 && roughAgain != roughGpu && metalAgain != 0 && metalAgain != metalGpu,
			"a model's textures: sent again from the file decoded again");
		check(graphics.textureCreations == textures + 3 && warnings == 0, "a model's textures: three made, none warned of");
		textures += 3;
		check(Textures.handle(albedo) == albedoAgain && Textures.handle(rough) == roughAgain && graphics.textureCreations == textures,
			"a model's textures: sent once");

		// A load's texture the program unloads while the model stays kept: the next load's is made with no picture in hand, from the file
		// decoded again.
		UnloadTexture(maps[MATERIAL_MAP_ALBEDO].texture);
		check(Textures.onGpu(albedo) == 0 && !Textures.hasPath("ship.gltf#0"), "a model's texture unloaded: freed");
		var second:Model = null;
		LoadModelAsync("ship.gltf", m -> second = m, e -> throw e);
		pump(() -> second != null);
		var made = second.materials[1].maps[MATERIAL_MAP_ALBEDO].texture.id;
		check(made != albedo && Textures.handle(made) == 0, "a texture made with no picture in hand: drawn as nothing while the file is decoded again");
		pump(() -> Textures.handle(made) != 0);
		check(Textures.handle(made) != 0 && warnings == 0, "then sent, not warned of");
		check(second.materials[1].maps[MATERIAL_MAP_ROUGHNESS].texture.id == rough, "the next load shares what is still held");
		UnloadModel(second);

		// The render texture and the data texture: the platform's to remake, under their handles.
		check(Textures.onGpu(target.texture.id) == target.id && graphics.targetCreations == targets, "a render texture: its handle kept");
		check(graphics.dataTextureCreations == dataTextures, "a data texture: left to the platform");

		// Unloading afterwards frees what is live and nothing twice.
		UnloadTexture(file);
		UnloadTexture(pixels);
		UnloadMesh(mesh);
		UnloadRenderTexture(target);
		UnloadModel(model);
		check(graphics.doubles == 0, "unloaded: nothing disposed twice");

		var report = haxe.Json.stringify({passed: true, checks: checks});
		#if js
		js.Syntax.code("console.log({0})", report);
		#else
		Sys.println(report);
		#end
	}

	// A glTF file holding a triangle and two images: the first its material's base color, the second its metallic-roughness image.
	static function ship():String {
		var b = new haxe.io.BytesOutput();
		for (v in [0., 0, 0, 1, 0, 0, 0, 1, 0])
			b.writeFloat(v);
		var buffer = haxe.crypto.Base64.encode(b.getBytes());
		var image = 'data:image/png;base64,${haxe.crypto.Base64.encode(Bytes.ofString("png"))}';
		return '{"asset":{"version":"2.0"},"scene":0,"scenes":[{"nodes":[0]}],"nodes":[{"mesh":0}],
			"meshes":[{"primitives":[{"attributes":{"POSITION":0},"material":0}]}],
			"materials":[{"pbrMetallicRoughness":{"baseColorTexture":{"index":0},"metallicRoughnessTexture":{"index":1}}}],
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

// Images that decode to 2x2 pixels, each answer at the next poll.
private class SolidDecoder implements helix.platform.IImageDecoder {
	final waiting:Array<Void->Void> = [];

	public function new() {}

	public function decode(encoded:Bytes, decoded:(pixels:Bytes, width:Int, height:Int) -> Void, failed:String->Void):Void {
		var p = Bytes.alloc(16);
		for (i in 0...16)
			p.set(i, i * 15);
		waiting.push(() -> decoded(p, 2, 2));
	}

	public function decodeForGpu(encoded:Bytes, decoded:helix.platform.IDecodedImage->Void, failed:String->Void):Void
		decode(encoded, (pixels, width, height) -> decoded(new helix.platform.adapters.shared.PixelsImage(width, height, pixels)), failed);

	public function poll():Void {
		var now = waiting.copy();
		waiting.resize(0);
		for (f in now)
			f();
	}

	public function dispose():Void {}
}
