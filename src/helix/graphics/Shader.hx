package helix.graphics;

/** One of a shader's own parameters: its uniform block's slot, its byte offset there, its type (float, vec2, vec3, vec4, mat4) and how many
	(1 unless an array). */
typedef ShaderParameter = {
	final slot:Int;
	final offset:Int;
	final type:String;
	final elementCount:Int;
}

/** One program of a .hxshader as read: its source, its own parameters and textures by name, and once built, its handle. */
private typedef Program = {
	final source:ShaderSource;
	final parameters:Map<String, ShaderParameter>;
	final slotsByName:Map<String, Int>;
	var handle:Int;
}

/** A .hxshader as read: its kind, its program, and a surface or sprite shader's variants (null where it has none). */
private typedef ShaderFile = {
	final kind:String;
	final main:Program;
	final skinned:Null<Program>;
	final caster:Null<Program>;
	final skinnedCaster:Null<Program>;
	final sprite3D:Null<Program>;
}

/** An app's shader loaded from a .hxshader (src/helix/tool/shader/ShaderPacker.hx; Shaders loads them, the shader library packs its own into the program):
	its program built on the GPU, its kind ("screen", "surface" or "sprite"), its uniform blocks' sizes, its own parameters by name and its own textures
	by name. A surface shader comes with its variants, each a Shader of its own over the same parameters: skinned (drawing skinned models) and
	caster (drawing its shadow, when it has a vertex hook or a discard); a sprite shader with sprite3D (drawing a Renderer3D's sprites). A hot reload replaces the programs in place and bumps reloadCount; their
	pipelines (Pipelines) are made again over the new programs as they're next asked for. */
class Shader {
	/** The .hxshader format it reads (src/helix/tool/shader/ShaderPacker.hx's FORMAT). */
	public static inline var FORMAT = 2;

	var gpu:IGraphics;
	var source:ShaderSource;
	var parameters:Map<String, ShaderParameter>;
	var slotsByName:Map<String, Int>;
	var version = 0;

	function new(gpu:IGraphics)
		this.gpu = gpu;

	/** Builds a shader, and its variants, from a .hxshader's text on gpu (the program's, Graphics, when not given). Throws, saying why, for a
		file it can't read or a program that doesn't build. The caller destroys it. */
	public static function fromText(text:String, ?gpu:IGraphics):Shader {
		gpu = gpu != null ? gpu : Graphics.instance;
		var file = read(text);
		build(gpu, file);
		var shader = new Shader(gpu);
		shader.take(file.kind, file.main, file.skinned, file.caster, file.skinnedCaster, file.sprite3D);
		return shader;
	}

	// The programs of a .hxshader's text, not yet built. Throws for a file of another format.
	static function read(text:String):ShaderFile {
		var file:Dynamic = haxe.Json.parse(text);
		if (file.helixShader != FORMAT)
			throw 'Not a HeliX shader file (format $FORMAT): pack it again (helix.tool.Build.packShaders, or Watchers.watchShaders)';
		return {
			kind: file.kind,
			main: program(file),
			skinned: file.skinned == null ? null : program(file.skinned),
			caster: file.caster == null ? null : program(file.caster),
			skinnedCaster: file.skinnedCaster == null ? null : program(file.skinnedCaster),
			sprite3D: file.sprite3D == null ? null : program(file.sprite3D)
		};
	}

	// One program of the file (its main part or a variant): its source, parameters and textures.
	static function program(part:Dynamic):Program {
		var blocks:Array<Dynamic> = part.uniformBlocks,
			textures:Array<Dynamic> = part.textures;
		var source:ShaderSource = {
			attributes: part.attributes,
			glsl410: part.glsl410,
			glsl300es: part.glsl300es,
			sdlGpu: part.sdlGpu,
			uniformBlocks: [
				for (b in blocks)
					{
						slot: b.slot,
						stage: b.stage,
						size: b.size,
						glslName: b.glslName,
						vec4Count: b.vec4s
					}
			],
			textures: [
				for (t in textures)
					{
						slot: t.slot,
						stage: t.stage,
						glslName: t.glslName,
						shadow: t.shadow == true,
						cube: t.cube == true,
						data: t.data == true
					}
			]
		};
		var parameters = new Map<String, ShaderParameter>();
		for (b in blocks) {
			var members:Array<Dynamic> = b.members;
			if (members != null)
				for (m in members) {
					var parameter:ShaderParameter = {
						slot: b.slot,
						offset: m.offset,
						type: m.type,
						elementCount: m.count
					};
					parameters[(m.name : String)] = parameter;
				}
		}
		return {
			source: source,
			parameters: parameters,
			slotsByName: [for (t in textures) (t.name : String) => (t.slot : Int)],
			handle: 0
		};
	}

	// Builds every program of file on gpu: all of them, or (throwing, saying why) none.
	static function build(gpu:IGraphics, file:ShaderFile):Void {
		var made:Array<Program> = [];
		try {
			for (p in [file.main, file.skinned, file.caster, file.skinnedCaster, file.sprite3D])
				if (p != null) {
					p.handle = gpu.createShader(p.source);
					made.push(p);
				}
		} catch (e:Dynamic) {
			for (p in made)
				gpu.destroyShader(p.handle);
			throw e;
		}
	}

	// Takes built programs as its own: main its, the others its variants' (made, kept or dropped as the file has them).
	function take(kind:String, main:Program, skinned:Null<Program>, caster:Null<Program>, skinnedCaster:Null<Program>, sprite3D:Null<Program>):Void {
		this.kind = kind;
		source = main.source;
		parameters = main.parameters;
		slotsByName = main.slotsByName;
		handle = main.handle;
		if (skinned == null)
			this.skinned = null;
		else {
			if (this.skinned == null)
				this.skinned = new Shader(gpu);
			this.skinned.take(kind, skinned, null, skinnedCaster, null, null);
		}
		if (caster == null)
			this.caster = null;
		else {
			if (this.caster == null)
				this.caster = new Shader(gpu);
			this.caster.take(kind, caster, null, null, null, null);
		}
		if (sprite3D == null)
			this.sprite3D = null;
		else {
			if (this.sprite3D == null)
				this.sprite3D = new Shader(gpu);
			this.sprite3D.take(kind, sprite3D, null, null, null, null);
		}
	}

	/** The IGraphics shader handle. */
	public var handle(default, null):Int;

	/** Its kind: "screen" (a screen effect), "surface" (a Renderer3D material's) or "sprite" (a 2D sprite's: a SpriteEffect). */
	public var kind(default, null):String;

	/** The same surface shader drawing skinned models: its vertex stage moves each vertex by its joints (the stage's joint texture, at slot
		5) before its vertex hook, its fragment stage, parameters and textures this one's. Null for a screen or sprite shader. Its caster draws skinned
		casters. */
	public var skinned(default, null):Null<Shader>;

	/** The program drawing its shadow casters into a shadow map: the depth pass with its vertex hook, its fragment stage run for what it
		discards. Null for a surface shader with neither a vertex hook nor a discard, whose shadow the framework's caster draws, and for a
		screen or sprite shader. */
	public var caster(default, null):Null<Shader>;

	/** The same sprite shader drawing a Renderer3D's sprites (Sprite3D.effect): its fragment stage over the framework's 3D sprite vertex stage
		(Sprite3DProgram's records, block 0 the sprites' uniforms), its output applying each sprite's alpha mode; its parameters and textures this
		one's. Null for a screen or surface shader. */
	public var sprite3D(default, null):Null<Shader>;

	/** How many times it has been replaced by a reload: a pipeline made before the latest is stale. */
	public var reloadCount(get, never):Int;

	function get_reloadCount():Int
		return version;

	/** Its uniform blocks' sizes in bytes, by slot: 0 for a slot it lacks. */
	public var blockSizes(get, never):Array<Int>;

	function get_blockSizes():Array<Int> {
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
		var slot = slotsByName[name];
		return slot == null ? -1 : slot;
	}

	/** The texture slots it samples, the framework's and its own, in order (there may be gaps: a slot it doesn't use). */
	public var textureSlots(get, never):Array<Int>;

	function get_textureSlots():Array<Int>
		return [for (t in source.textures) t.slot];

	/** The file changed: its programs are built again in place, its variants with them. A file that doesn't read or build leaves it as it was
		(and throws, saying why). */
	@:allow(helix.graphics.Shaders)
	@:allow(helix.shader.ShaderLibrary)
	function replace(text:String):Void {
		var file = read(text);
		if (file.kind != kind)
			throw 'A $kind shader can\'t become a ${file.kind} one';
		build(gpu, file);
		release();
		take(file.kind, file.main, file.skinned, file.caster, file.skinnedCaster, file.sprite3D);
		bump();
	}

	// Counts a replacement, its variants' too.
	function bump():Void {
		version++;
		if (skinned != null)
			skinned.bump();
		if (caster != null)
			caster.bump();
		if (sprite3D != null)
			sprite3D.bump();
	}

	// Frees its programs, its variants' too, and the pipelines made over them.
	function release():Void {
		Pipelines.of(gpu).forgetShader(handle);
		gpu.destroyShader(handle);
		if (skinned != null)
			skinned.release();
		if (caster != null)
			caster.release();
		if (sprite3D != null)
			sprite3D.release();
	}

	/** Frees the programs, its variants' too, and the pipelines made over them. */
	public function destroy():Void
		release();
}
