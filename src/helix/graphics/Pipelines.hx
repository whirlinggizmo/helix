package helix.graphics;

import helix.graphics.PipelineDesc;
import helix.graphics.DepthTest;
import helix.graphics.ClipFlip;

/** The framework's programs and pipelines on one GPU, shared by everything drawing on it: each framework program built once from its
	generated source (the program classes' source()), and each pipeline described here (its program, buffers' layout and state: PipelineDesc) and made
	the first time it's asked for, then kept. Drawing code asks for its pipeline at each draw and never keeps the handle, so a program built
	again (an app's shader reloaded, or in development a framework program whose source changed) has its pipelines made again behind it.
	This is the framework's knowledge of its pipelines; an adapter knows none of it. */
@:noCompletion
@:allow(helix)
class Pipelines {
	// Kept across a hot reload, so the reload's rebuild finds every GPU's pipelines.
	@:hot static var all = new haxe.ds.ObjectMap<IGraphics, Pipelines>();

	var gpu:IGraphics;
	// The framework programs built, by name: their handle and the source they were built from.
	var programs = new Map<String, {handle:Int, source:ShaderSource}>();
	// Pipelines made, by key (a program's handle and its variant), and by program, the keys made over it.
	var made = new Map<Int, Int>();
	var byShader = new Map<Int, Array<Int>>();

	function new(gpu:IGraphics)
		this.gpu = gpu;

	/** gpu's, made the first time it's asked for. */
	static function of(gpu:IGraphics):Pipelines {
		var found = all.get(gpu);
		if (found == null) {
			found = new Pipelines(gpu);
			all.set(gpu, found);
		}
		return found;
	}

	/** Frees gpu's pipelines and framework programs, before the adapter shuts down. */
	static function release(gpu:IGraphics):Void {
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
	function forgetShader(shader:Int):Void {
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
		?depthTest:DepthTest,
		?depthWrite:Bool,
		?cull:CullFace,
		?clockwise:Bool,
		?depthOnly:Bool
	}):PipelineDesc
		return {
			shader: shader,
			buffers: buffers,
			primitive: options != null && options.primitive != null ? options.primitive : Triangles,
			indexed: options != null && options.indexed == true,
			blend: blend,
			depthTest: options != null && options.depthTest != null ? options.depthTest : Off,
			depthWrite: options != null && options.depthWrite == true,
			cull: options != null && options.cull != null ? options.cull : None,
			clockwise: options != null && options.clockwise == true,
			depthOnly: options != null && options.depthOnly == true,
			flip: flip
		};

	/** 2D sprites and shapes: Sprite2DProgram's vertices in clip space (its block the clip scale), no depth. */
	function sprite2D(blend:BlendMode):Int
		return pipeline(program("sprite2d", () -> Sprite2DProgram.source()), blend, s -> describe(s, Sprite2DProgram.buffers(), blend, ClipScale));

	/** Vertex-colored 3D triangles (Color3DProgram, the view-projection its block), depth tested and written. */
	function color3D():Int
		return pipeline(program("color3d", () -> Color3DProgram.source()), 0,
			s -> describe(s, Color3DProgram.buffers(), Opaque, ViewProjection, {depthTest: LessEqual, depthWrite: true}));

	/** Color3D's vertices as lines, two each. */
	function lines3D():Int
		return pipeline(program("color3d", () -> Color3DProgram.source()), 1,
			s -> describe(s, Color3DProgram.buffers(), Opaque, ViewProjection, {primitive: Lines, depthTest: LessEqual, depthWrite: true}));

	// A lit model's state over buffers: indexed, depth tested and written (see-through ones too), back faces culled unless double sided.
	static function lit(shader:Int, buffers:Array<VertexBuffer>, blend:BlendMode, doubleSided:Bool, clockwise:Bool):PipelineDesc
		return describe(shader, buffers, blend, ViewProjection, {
			indexed: true,
			depthTest: LessEqual,
			depthWrite: true,
			cull: doubleSided ? None : Back,
			clockwise: clockwise
		});

	static inline function variant(blend:BlendMode, doubleSided:Bool, clockwise:Bool):Int
		return (blend : Int) + (doubleSided ? 4 : 0) + (clockwise ? 8 : 0);

	/** Lit models (Lit3DProgram): blended or not, double sided or not, front faces clockwise (a mirrored placement's) or not. */
	function lit3D(blend:BlendMode, doubleSided:Bool, clockwise:Bool):Int
		return pipeline(program("lit3d", () -> Lit3DProgram.source()), variant(blend, doubleSided, clockwise),
			s -> lit(s, Lit3DProgram.buffers(), blend, doubleSided, clockwise));

	/** Skinned lit models (Skinned3DProgram: Lit3D's buffers and the skin), as lit3d's variants. */
	function skinned3D(blend:BlendMode, doubleSided:Bool, clockwise:Bool):Int
		return pipeline(program("skinned3d", () -> Skinned3DProgram.source()), variant(blend, doubleSided, clockwise),
			s -> lit(s, Skinned3DProgram.buffers(), blend, doubleSided, clockwise));

	/** An app's surface shader (its handle; for a skinned model its skinned variant's, over Skinned3DProgram's buffers) drawing lit models, as
		lit3d's variants. */
	function surface(shader:Int, blend:BlendMode, doubleSided:Bool, clockwise:Bool, skinned:Bool):Int
		return pipeline(shader, variant(blend, doubleSided, clockwise),
			s -> lit(s, skinned ? Skinned3DProgram.buffers() : Lit3DProgram.buffers(), blend, doubleSided, clockwise));

	/** A surface shader's shadow caster (its handle: Shader.caster's, or its skinned variant's caster for a skinned model, over Skinned3DProgram's
		buffers), from the lit models' records: depth only, nothing culled, as the framework's casters. */
	function surfaceCaster(shader:Int, skinned:Bool):Int
		return pipeline(shader, 0, s -> describe(s, skinned ? Skinned3DProgram.buffers() : Lit3DProgram.buffers(), Opaque, ViewProjection, {
			indexed: true,
			depthTest: LessEqual,
			depthWrite: true,
			depthOnly: true
		}));

	/** A model's flat pass (Flat3DProgram, or Skinnedflat3DProgram for a skinned model), from its mesh's pass vertices (Mesh3D.passVertices) and
		the lit models' instance records: an outline's shell (front faces culled, depth tested and written, opaque), or with behind, a
		silhouette (only where something nearer was drawn: depth greater, not written, blended, back faces culled); front faces clockwise (a
		mirrored placement's) or not. */
	function flat3D(skinned:Bool, behind:Bool, clockwise:Bool):Int {
		var options = {
			indexed: true,
			depthTest: behind ? Greater : LessEqual,
			depthWrite: !behind,
			cull: behind ? Back : Front,
			clockwise: clockwise
		};
		var key = (behind ? 1 : 0) + (clockwise ? 2 : 0);
		return skinned ? pipeline(program("skinnedflat3d", () -> Skinnedflat3DProgram.source()), key,
			s -> describe(s, Skinnedflat3DProgram.buffers(), behind ? Alpha : Opaque, ViewProjection,
				options)) : pipeline(program("flat3d", () -> Flat3DProgram.source()), key,
				s -> describe(s, Flat3DProgram.buffers(), behind ? Alpha : Opaque, ViewProjection, options));
	}

	// A quad an instance (sprites, particles): indexed, depth tested, written only when opaque, nothing culled.
	static function quads(shader:Int, buffers:Array<VertexBuffer>, blend:BlendMode):PipelineDesc
		return describe(shader, buffers, blend, ViewProjection, {indexed: true, depthTest: LessEqual, depthWrite: blend == Opaque});

	/** 3D sprites (Sprite3DProgram). */
	function sprite3D(blend:BlendMode):Int
		return pipeline(program("sprite3d", () -> Sprite3DProgram.source()), blend, s -> quads(s, Sprite3DProgram.buffers(), blend));

	/** A sprite effect's Renderer3D variant (its handle: SpriteEffect.shader.sprite3D's) drawing 3D sprites (Sprite3DProgram), as sprite3D's. */
	function spriteEffect3D(shader:Int, blend:BlendMode):Int
		return pipeline(shader, blend, s -> quads(s, Sprite3DProgram.buffers(), blend));

	/** Particles (Particle3DProgram). */
	function particle3D(blend:BlendMode):Int
		return pipeline(program("particle3d", () -> Particle3DProgram.source()), blend, s -> quads(s, Particle3DProgram.buffers(), blend));

	/** Shadow-map casters (Depth3DProgram): depth only, nothing culled (a one-sided floor still casts). */
	function depth3D():Int
		return pipeline(program("depth3d", () -> Depth3DProgram.source()), 0, s -> describe(s, Depth3DProgram.buffers(), Opaque, ViewProjection, {
			indexed: true,
			depthTest: LessEqual,
			depthWrite: true,
			depthOnly: true
		}));

	/** Skinned shadow-map casters (Skinneddepth3DProgram). */
	function skinnedDepth3D():Int
		return pipeline(program("skinneddepth3d", () -> Skinneddepth3DProgram.source()), 0,
			s -> describe(s, Skinneddepth3DProgram.buffers(), Opaque, ViewProjection, {
				indexed: true,
				depthTest: LessEqual,
				depthWrite: true,
				depthOnly: true
			}));

	/** An environment behind a 3D scene (Background3DProgram): one triangle at the far plane, depth tested (less or equal) and not written. */
	function background3D():Int
		return pipeline(program("background3d", () -> Background3DProgram.source()), 0, s -> describe(s, [], Opaque, ClipScale, {depthTest: LessEqual}));

	/** A sprite effect's shader (its handle: SpriteEffect.shader's) drawing 2D sprites: Effect2DProgram's vertices in clip space (block 0 the
		clip scale), no depth. */
	function spriteEffect(shader:Int, blend:BlendMode):Int
		return pipeline(shader, blend, s -> describe(s, Effect2DProgram.buffers(), blend, ClipScale));

	/** An app's screen effect (its handle): one triangle over the viewport, no depth. */
	function screen(shader:Int, blend:BlendMode):Int
		return pipeline(shader, blend, s -> describe(s, [], blend, ClipScale));

	#if hotreload
	// Development only (hotreload-hx): a reload brings new generated sources; a framework program whose source changed is built again, its
	// pipelines with it, as they're next asked for.
	@:afterHotReload static function reloadPrograms():Void
		for (pipelines in all)
			pipelines.rebuild();

	function rebuild():Void {
		var sources:Map<String, Void->ShaderSource> = [
			"sprite2d" => () -> Sprite2DProgram.source(),
			"color3d" => () -> Color3DProgram.source(),
			"lit3d" => () -> Lit3DProgram.source(),
			"skinned3d" => () -> Skinned3DProgram.source(),
			"sprite3d" => () -> Sprite3DProgram.source(),
			"particle3d" => () -> Particle3DProgram.source(),
			"depth3d" => () -> Depth3DProgram.source(),
			"skinneddepth3d" => () -> Skinneddepth3DProgram.source(),
			"background3d" => () -> Background3DProgram.source(),
			"flat3d" => () -> Flat3DProgram.source(),
			"skinnedflat3d" => () -> Skinnedflat3DProgram.source()
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
