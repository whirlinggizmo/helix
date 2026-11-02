package helix.ray.internal;

import haxe.io.Bytes;
import helix.platform.IGraphics;

/** Holds a raylib shader on the GPU: its program, the current values of its blocks, the textures set on it, and its pipelines. */
@:noCompletion
class Program {
	/** The attributes, as raylib names them, by slot. */
	public final attributes:Array<String>;

	/** Each uniform and texture by its location, as `GetShaderLocation` gives it. */
	public final names:Array<String> = [];

	/** The blocks' bytes by their index in a draw's uniforms: 0 the platform's flip, 1 the vertex stage's values, 6 the fragment stage's
		(its slot 2). */
	public final blocks:Array<Null<Bytes>> = [for (_ in 0...7) null];

	/** The texture at each slot, set by `SetShaderValueTexture` or by the draw. */
	public final textures:Array<Int> = [];

	/** Whether the texture at each slot is a `samplerCube`, which only a cubemap binds to. */
	public final cubes:Array<Bool> = [];

	/** The texture unit each slot's sampler reads, as `SetShaderValue` sets it (raylib's skybox sets its `environmentMap` to
		`MATERIAL_MAP_CUBEMAP`), so `DrawMesh` binds the material's map of that index there; -1 until set. */
	public final units:Array<Int> = [];

	/** The slots of raylib's textures, -1 for one it doesn't declare. */
	public final texture0:Int;

	public final texture1:Int;
	public final texture2:Int;

	/** The platform's program handle. */
	public final handle:Int;

	final source:ProgramSource;
	final pipelines = new Map<String, Int>();
	final graphics:IGraphics;

	/** Makes the program on the GPU.

		@param graphics  The graphics.
		@param source  The program as compiled. */
	public function new(graphics:IGraphics, source:ProgramSource) {
		this.graphics = graphics;
		this.source = source;
		attributes = source.attributes;
		handle = graphics.createShader(source.source);
		for (b in source.source.uniformBlocks)
			blocks[b.stage == "fragment" ? 4 + b.slot : b.slot] = Bytes.alloc(b.size);
		if (blocks[0] != null)
			for (i in 0...4)
				blocks[0].setFloat(i * 4, 1);
		for (u in source.uniforms)
			if (names.indexOf(u.name) < 0)
				names.push(u.name);
		var slots = new Map<String, Int>();
		for (t in source.textures) {
			slots.set(t.name, t.slot);
			names.push(t.name);
		}
		texture0 = slots.exists("texture0") ? slots.get("texture0") : -1;
		texture1 = slots.exists("texture1") ? slots.get("texture1") : -1;
		texture2 = slots.exists("texture2") ? slots.get("texture2") : -1;
		var count = 0;
		for (t in source.textures)
			if (t.slot + 1 > count)
				count = t.slot + 1;
		for (_ in 0...count) {
			textures.push(0);
			cubes.push(false);
			units.push(-1);
		}
		for (t in source.source.textures)
			if (t.slot < count)
				cubes[t.slot] = t.cube;
	}

	/** Returns a uniform's or texture's location.

		@param name  Its name.
		@return  The location, or -1 when the program doesn't declare it. */
	public function locate(name:String):Int {
		return names.indexOf(name);
	}

	/** Returns whether a location is a texture's, and its slot.

		@param location  The location.
		@return  The texture's slot, or -1 for a uniform's location. */
	public function textureSlot(location:Int):Int {
		if (location < 0 || location >= names.length)
			return -1;
		for (t in source.textures)
			if (t.name == names[location])
				return t.slot;
		return -1;
	}

	/** Writes numbers to a uniform, in each stage that declares it.

		@param location  Its location.
		@param values  The numbers, in GLSL's order (a matrix by columns).
		@param first  Optional. The first array element written. */
	public function write(location:Int, values:Array<Float>, first = 0):Void {
		if (location < 0 || location >= names.length)
			return;
		var name = names[location];
		for (u in source.uniforms)
			if (u.name == name)
				put(blocks[u.block], u, values, first);
	}

	/** Writes numbers to a uniform by name, when the program declares it.

		@param name  The uniform's name.
		@param values  The numbers. */
	public function writeNamed(name:String, values:Array<Float>):Void {
		for (u in source.uniforms)
			if (u.name == name)
				put(blocks[u.block], u, values, 0);
	}

	/** Returns whether the program declares a uniform.

		@param name  The name.
		@return  True when it does. */
	public function declares(name:String):Bool {
		for (u in source.uniforms)
			if (u.name == name)
				return true;
		return false;
	}

	// std140: each element of an array, and each column of a matrix, starts on 16 bytes.
	static function put(bytes:Null<Bytes>, u:{offset:Int, type:String, count:Int}, values:Array<Float>, first:Int):Void {
		if (bytes == null)
			return;
		var columns = 1, rows = 1;
		switch u.type {
			case "float":
				rows = 1;
			case "vec2":
				rows = 2;
			case "vec3":
				rows = 3;
			case "vec4":
				rows = 4;
			case "mat2":
				columns = 2;
				rows = 2;
			case "mat3":
				columns = 3;
				rows = 3;
			case "mat4":
				columns = 4;
				rows = 4;
			case _:
				rows = 4;
		}
		var element = columns * rows, stride = columns * 16;
		var at = 0, index = first;
		while (at + element <= values.length && index < u.count) {
			for (c in 0...columns)
				for (r in 0...rows) {
					var offset = u.offset + index * stride + c * 16 + r * 4;
					if (offset + 4 <= bytes.length)
						bytes.setFloat(offset, values[at + c * rows + r]);
				}
			at += element;
			index++;
		}
	}

	/** Returns the pipeline drawing through the program in a way.

		@param key  The way, as a string, for the cache.
		@param make  Makes it. */
	public function pipeline(key:String, make:Void->Int):Int {
		var p = pipelines.get(key);
		if (p == null) {
			p = make();
			pipelines.set(key, p);
		}
		return p;
	}

	/** How many hold it (docs/DECISIONS.md 25): the program from `LoadShader` until `UnloadShader`, and each material given it. It is
		freed when the last lets go; the default program is never counted. */
	public var refs = 1;

	/** How many of `refs` are the program's own, from `LoadShader`, so `UnloadShader` on a material's copy lets go of one of those first. */
	public var held = 1;

	/** Frees the pipelines and the program. */
	public function dispose():Void {
		for (p in pipelines)
			graphics.disposePipeline(p);
		graphics.disposeShader(handle);
	}
}
