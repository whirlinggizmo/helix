import haxe.io.Bytes;
import helix.raylib.*;
import helix.raylib.Raylib.*;
import helix.raylib.extras.Textures.*;
import helix.raylib.internal.Frame;
import helix.raylib.internal.Models;
import helix.raylib.internal.Runtime;
import helix.raylib.internal.Textures;

/** Checks what helix-raylib does when the GPU's context is lost and given back (Event.GraphicsLost, Event.GraphicsRestored), on graphics
	that count what is made: nothing throws while it is lost; at the restore the frame's own texture and buffer are made again, a file's
	texture is decoded again from its bytes and sent when next drawn, a font's atlas is sent again from the pixels it kept, a mesh is
	sent again when next drawn, a render texture keeps the handle the platform remade, a data texture is left to the platform, and a
	texture made from pixels let go of is drawn as nothing with one warning. */
@:access(helix.raylib.internal.Runtime)
@:access(helix.raylib.internal.Textures)
@:access(helix.raylib.Mesh)
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
		var files = new MemoryFiles(["wood.png" => Bytes.ofString("any")]);
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
		var font = GetFontDefault();
		var fontGpu = Textures.handle(font.texture.id);
		var mesh = GenMeshCube(1, 1, 1);
		UploadMesh(mesh, false);
		var target = LoadRenderTexture(4, 4);
		var data = Runtime.graphics.createDataTexture(256, 1);
		check(fileGpu != 0 && pixelsGpu != 0 && fontGpu != 0 && mesh.gpu.buffers != null && target.id != 0 && data != 0, "before: everything on the GPU");
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

		// The file's texture: decoded again from its bytes, drawn as nothing meanwhile, then sent.
		check(Textures.onGpu(file.id) == 0, "a file's texture: off the GPU");
		pump(() -> Runtime.picture("wood.png") != null);
		var again = Textures.handle(file.id);
		check(again != 0 && again != fileGpu && graphics.textureCreations == textures + 1, "a file's texture: sent again from its bytes");
		textures++;
		check(Textures.handle(file.id) == again && graphics.textureCreations == textures, "a file's texture: sent once");

		// One from pixels let go of: nothing, warned of once.
		check(Textures.handle(pixels.id) == 0 && warnings == 1, "a texture from pixels: drawn as nothing, warned of");
		Textures.handle(pixels.id);
		check(warnings == 1 && graphics.textureCreations == textures, "a texture from pixels: warned of once, nothing made");

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

		// The render texture and the data texture: the platform's to remake, under their handles.
		check(Textures.onGpu(target.texture.id) == target.id && graphics.targetCreations == targets, "a render texture: its handle kept");
		check(graphics.dataTextureCreations == dataTextures, "a data texture: left to the platform");

		// Unloading afterwards frees what is live and nothing twice.
		UnloadTexture(file);
		UnloadTexture(pixels);
		UnloadMesh(mesh);
		UnloadRenderTexture(target);
		check(graphics.doubles == 0, "unloaded: nothing disposed twice");

		var report = haxe.Json.stringify({passed: true, checks: checks});
		#if js
		js.Syntax.code("console.log({0})", report);
		#else
		Sys.println(report);
		#end
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
