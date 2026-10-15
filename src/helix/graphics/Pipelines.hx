package helix.graphics;

import helix.graphics.PipelineDesc;

/** The framework's programs and pipelines on one GPU, shared by everything drawing on it: each framework program built once from its
	generated source (the layouts' source()), and each pipeline described here (its program, buffers' layout and state: PipelineDesc) and made
	the first time it's asked for, then kept. Drawing code asks for its pipeline at each draw and never keeps the handle, so a program built
	again (an app's shader reloaded, or in development a framework program whose source changed) has its pipelines made again behind it.
	This is the framework's knowledge of its pipelines; an adapter knows none of it. */
class Pipelines {
	static var all = new haxe.ds.ObjectMap<IGraphics, Pipelines>();

	var gpu:IGraphics;
	// The framework programs built, by name: their handle and the source they were built from.
	var programs = new Map<String, {handle:Int, source:ShaderSource}>();
	// Pipelines made, by key (a program's handle and its variant), and by program, the keys made over it.
	var made = new Map<Int, Int>();
	var byShader = new Map<Int, Array<Int>>();

	function new(gpu:IGraphics)
		this.gpu = gpu;

	/** gpu's, made the first time it's asked for. */
	public static function of(gpu:IGraphics):Pipelines {
		var found = all.get(gpu);
		if (found == null) {
			found = new Pipelines(gpu);
			all.set(gpu, found);
		}
		return found;
	}

	/** Frees gpu's pipelines and framework programs, before the adapter shuts down. */
	public static function release(gpu:IGraphics):Void {
		var found = all.get(gpu);
		if (found == null)
			return;
		for (handle in found.made)
			gpu.destroyPipeline(handle);
		for (p in found.programs)
			gpu.destroyShader(p.handle);
		all.remove(gpu);
	}

	/** Destroys the pipelines made over shader (an app's, before it is destroyed or replaced); asked for again, they're made again. */
	public function forgetShader(shader:Int):Void {
		var keys = byShader.get(shader);
		if (keys == null)
			return;
		for (key in keys) {
			gpu.destroyPipeline(made.get(key));
			made.remove(key);
		}
		byShader.remove(shader);
	}

	// A framework program's handle, built from source the first time.
	function program(name:String, source:Void->ShaderSource):Int {
		var p = programs.get(name);
		if (p == null) {
			var s = source();
			p = {handle: gpu.createShader(s), source: s};
			programs.set(name, p);
		}
		return p.handle;
	}

	// The pipeline of shader in variant (blend, then flags: a small number), made from describe the first time.
	function pipeline(shader:Int, variant:Int, describe:Int->PipelineDesc):Int {
		var key = shader * 64 + variant, handle = made.get(key);
		if (handle == null) {
			handle = gpu.createPipeline(describe(shader));
			made.set(key, handle);
			var keys = byShader.get(shader);
			if (keys == null)
				byShader.set(shader, keys = []);
			keys.push(key);
		}
		return handle;
	}

	static function describe(shader:Int, buffers:Array<VertexBuffer>, blend:BlendMode, flip:ClipFlip, ?options:{
		?primitive:Primitive,
		?indexed:Bool,
		?depthTest:Bool,
		?depthWrite:Bool,
		?cullBack:Bool,
		?clockwise:Bool,
		?depthOnly:Bool
	}):PipelineDesc
		return {
			shader: shader,
			buffers: buffers,
			primitive: options != null && options.primitive != null ? options.primitive : Triangles,
			indexed: options != null && options.indexed == true,
			blend: blend,
			depthTest: options != null && options.depthTest == true,
			depthWrite: options != null && options.depthWrite == true,
			cullBack: options != null && options.cullBack == true,
			clockwise: options != null && options.clockwise == true,
			depthOnly: options != null && options.depthOnly == true,
			flip: flip
		};

	/** 2D sprites and shapes: Sprite2DLayout's vertices in clip space (its block the clip scale), no depth. */
	public function sprite2D(blend:BlendMode):Int
		return pipeline(program("sprite2d", Sprite2DLayout.source), blend, s -> describe(s, Sprite2DLayout.buffers(), blend, ClipScale));

	/** Vertex-colored 3D triangles (Color3DLayout, the view-projection its block), depth tested and written. */
	public function color3D():Int
		return pipeline(program("color3d", Color3DLayout.source), 0,
			s -> describe(s, Color3DLayout.buffers(), Opaque, ViewProjection, {depthTest: true, depthWrite: true}));

	/** Color3D's vertices as lines, two each. */
	public function lines3D():Int
		return pipeline(program("color3d", Color3DLayout.source), 1,
			s -> describe(s, Color3DLayout.buffers(), Opaque, ViewProjection, {primitive: Lines, depthTest: true, depthWrite: true}));

	// A lit model's state over buffers: indexed, depth tested and written (see-through ones too), back faces culled unless double sided.
	static function lit(shader:Int, buffers:Array<VertexBuffer>, blend:BlendMode, doubleSided:Bool, clockwise:Bool):PipelineDesc
		return describe(shader, buffers, blend, ViewProjection, {
			indexed: true,
			depthTest: true,
			depthWrite: true,
			cullBack: !doubleSided,
			clockwise: clockwise
		});

	static inline function variant(blend:BlendMode, doubleSided:Bool, clockwise:Bool):Int
		return (blend : Int) + (doubleSided ? 4 : 0) + (clockwise ? 8 : 0);

	/** Lit models (Lit3DLayout): blended or not, double sided or not, front faces clockwise (a mirrored placement's) or not. */
	public function lit3D(blend:BlendMode, doubleSided:Bool, clockwise:Bool):Int
		return pipeline(program("lit3d", Lit3DLayout.source), variant(blend, doubleSided, clockwise),
			s -> lit(s, Lit3DLayout.buffers(), blend, doubleSided, clockwise));

	/** Skinned lit models (Skinned3DLayout: Lit3D's buffers and the skin), as lit3d's variants. */
	public function skinned3D(blend:BlendMode, doubleSided:Bool, clockwise:Bool):Int
		return pipeline(program("skinned3d", Skinned3DLayout.source), variant(blend, doubleSided, clockwise),
			s -> lit(s, Skinned3DLayout.buffers(), blend, doubleSided, clockwise));

	/** An app's surface shader (its handle) drawing lit models, as lit3d's variants. */
	public function surface(shader:Int, blend:BlendMode, doubleSided:Bool, clockwise:Bool):Int
		return pipeline(shader, variant(blend, doubleSided, clockwise), s -> lit(s, Lit3DLayout.buffers(), blend, doubleSided, clockwise));

	// A quad an instance (sprites, particles): indexed, depth tested, written only when opaque, nothing culled.
	static function quads(shader:Int, buffers:Array<VertexBuffer>, blend:BlendMode):PipelineDesc
		return describe(shader, buffers, blend, ViewProjection, {indexed: true, depthTest: true, depthWrite: blend == Opaque});

	/** 3D sprites (Sprite3DLayout). */
	public function sprite3D(blend:BlendMode):Int
		return pipeline(program("sprite3d", Sprite3DLayout.source), blend, s -> quads(s, Sprite3DLayout.buffers(), blend));

	/** Particles (Particle3DLayout). */
	public function particle3D(blend:BlendMode):Int
		return pipeline(program("particle3d", Particle3DLayout.source), blend, s -> quads(s, Particle3DLayout.buffers(), blend));

	/** Shadow-map casters (Depth3DLayout): depth only, nothing culled (a one-sided floor still casts). */
	public function depth3D():Int
		return pipeline(program("depth3d", Depth3DLayout.source), 0, s -> describe(s, Depth3DLayout.buffers(), Opaque, ViewProjection, {
			indexed: true,
			depthTest: true,
			depthWrite: true,
			depthOnly: true
		}));

	/** Skinned shadow-map casters (Skinneddepth3DLayout). */
	public function skinnedDepth3D():Int
		return pipeline(program("skinneddepth3d", Skinneddepth3DLayout.source), 0, s -> describe(s, Skinneddepth3DLayout.buffers(), Opaque, ViewProjection, {
			indexed: true,
			depthTest: true,
			depthWrite: true,
			depthOnly: true
		}));

	/** An environment behind a 3D scene (Background3DLayout): one triangle at the far plane, depth tested (less or equal) and not written. */
	public function background3D():Int
		return pipeline(program("background3d", Background3DLayout.source), 0, s -> describe(s, [], Opaque, ClipScale, {depthTest: true}));

	/** An app's screen effect (its handle): one triangle over the viewport, no depth. */
	public function screen(shader:Int, blend:BlendMode):Int
		return pipeline(shader, blend, s -> describe(s, [], blend, ClipScale));

	#if hotreload
	// Development only (hotreload-hx): a reload brings new generated sources; a framework program whose source changed is built again, its
	// pipelines with it, as they're next asked for.
	@:afterHotReload static function reloadPrograms():Void
		for (pipelines in all)
			pipelines.rebuild();

	function rebuild():Void {
		var sources:Map<String, Void->ShaderSource> = [
			"sprite2d" => Sprite2DLayout.source,
			"color3d" => Color3DLayout.source,
			"lit3d" => Lit3DLayout.source,
			"skinned3d" => Skinned3DLayout.source,
			"sprite3d" => Sprite3DLayout.source,
			"particle3d" => Particle3DLayout.source,
			"depth3d" => Depth3DLayout.source,
			"skinneddepth3d" => Skinneddepth3DLayout.source,
			"background3d" => Background3DLayout.source
		];
		for (name => p in programs) {
			var fresh = sources[name]();
			if (haxe.Json.stringify(fresh) == haxe.Json.stringify(p.source))
				continue;
			forgetShader(p.handle);
			gpu.destroyShader(p.handle);
			programs.remove(name);
		}
	}
	#end
}
