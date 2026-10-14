package helix.graphics;

import haxe.io.Bytes;

/** One of a shader's own parameters: its uniform block's slot, its byte offset there, its type (float, vec2, vec3, vec4, mat4) and how many
	(1 unless an array). */
typedef ShaderParameter = {
	var slot:Int;
	var offset:Int;
	var type:String;
	var count:Int;
}

/** An app's shader loaded from a .hxshader (tools/pack_shader.py; Shaders loads them): its program built on the GPU, its kind ("screen"), its
	uniform blocks' sizes, its own parameters by name and its own textures by name. A hot reload replaces the program in place and bumps
	getVersion, so what draws with it makes its pipeline again. */
class Shader {
	var gpu:IGraphics;
	var handle:Int;
	var kind:String;
	var source:ShaderSource;
	var parameters:Map<String, ShaderParameter>;
	var textureSlots:Map<String, Int>;
	var version = 0;

	function new(gpu:IGraphics, text:String) {
		this.gpu = gpu;
		read(text);
		handle = gpu.createShader(source);
	}

	/** Builds a shader from a .hxshader's text on gpu. Throws, saying why, for a file it can't read or a program that doesn't build. The caller
		destroys it. */
	public static function fromText(gpu:IGraphics, text:String):Shader
		return new Shader(gpu, text);

	function read(text:String):Void {
		var file:Dynamic = haxe.Json.parse(text);
		if (file.helixShader != 1)
			throw "Not a HeliX shader file (format 1)";
		var blocks:Array<Dynamic> = file.uniformBlocks,
			textures:Array<Dynamic> = file.textures;
		kind = file.kind;
		source = {
			attributes: file.attributes,
			glsl410: file.glsl410,
			glsl300es: file.glsl300es,
			uniformBlocks: [
				for (b in blocks)
					{
						slot: b.slot,
						stage: b.stage,
						size: b.size,
						glslName: b.glslName,
						vec4s: b.vec4s
					}
			],
			textures: [for (t in textures) {slot: t.slot, stage: t.stage, glslName: t.glslName}]
		};
		parameters = new Map();
		for (b in blocks) {
			var members:Array<Dynamic> = b.members;
			if (members != null)
				for (m in members)
					parameters[m.name] = {
						slot: b.slot,
						offset: m.offset,
						type: m.type,
						count: m.count
					};
		}
		textureSlots = [for (t in textures) t.name => t.slot];
	}

	/** The IGraphics shader handle. */
	public function getHandle():Int
		return handle;

	/** Its kind: "screen" (a screen effect). */
	public function getKind():String
		return kind;

	/** How many times it has been replaced by a reload: a pipeline made before the latest is stale. */
	public function getVersion():Int
		return version;

	/** Its uniform blocks' sizes in bytes, by slot: 0 for a slot it lacks. */
	public function getBlockSizes():Array<Int> {
		var count = 0;
		for (b in source.uniformBlocks)
			count = b.slot + 1 > count ? b.slot + 1 : count;
		var sizes = [for (_ in 0...count) 0];
		for (b in source.uniformBlocks)
			sizes[b.slot] = b.size;
		return sizes;
	}

	/** One of its own parameters by name, or null. */
	public function getParameter(name:String):Null<ShaderParameter>
		return parameters[name];

	/** One of its own textures' slot by name, or -1. */
	public function getTextureSlot(name:String):Int {
		var slot = textureSlots[name];
		return slot == null ? -1 : slot;
	}

	/** How many textures it samples: its slots 0 to this less one. */
	public function getTextureCount():Int
		return source.textures.length;

	/** The file changed: the program is built again in place. A file that doesn't read or build leaves it as it was (and throws, saying why). */
	@:allow(helix.graphics.Shaders)
	function replace(text:String):Void {
		var old = {
			kind: kind,
			source: source,
			parameters: parameters,
			textureSlots: textureSlots
		};
		read(text);
		var made = try gpu.createShader(source) catch (e:Dynamic) {
			kind = old.kind;
			source = old.source;
			parameters = old.parameters;
			textureSlots = old.textureSlots;
			throw e;
		}
		gpu.destroyShader(handle);
		handle = made;
		version++;
	}

	/** Frees the program; the pipelines made with it must be destroyed first. */
	public function destroy():Void
		gpu.destroyShader(handle);
}
