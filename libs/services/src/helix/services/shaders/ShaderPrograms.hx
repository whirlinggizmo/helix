package helix.services.shaders;

import helix.platform.IGraphics;

/** Provides shaders built on the GPU: a program for each shader, a pipeline for each state and vertex layout it is drawn with, each
	built again when the shader is replaced in place.

	`getPipeline` returns a `ShaderPipeline`, the same object for the same shader, state and layout (the state told apart by its
	values, the layout by its values too, so a layout made again with the same buffers, placements and constants finds the same
	pipeline), which a renderer holds and draws through by its `handle`. The layout is resolved for each shader
	by name or slot (`ShaderVertexLayout.computeBuffers`), with what no buffer feeds read as its constant; the state's `flipUniform` is
	found in each shader (`Shader.findUniformPlace`). Both are done once, and again after a replacement; nothing is made per draw.

	**Nothing is built inside a pass**, and that is enforced. A frame runs from `prepareFrame`, which the program, or the renderer it
	draws through, calls before the frame's first pass (before `IGraphics.beginTargetPass`, `beginShadowPass` or `beginFrame`), to
	`finishFrame`, after its last. `prepareFrame` rebuilds what a replaced shader made stale; until it does, draws use the old pipeline.
	Between the two, a `getPipeline`, `getProgram` or `prepare` that would build throws, naming the pipeline, while `findPipeline` and a
	`getPipeline` of one already built never build. First builds happen at setup, or while a level loads, through `prepare` and
	`prepareVariants`.

	```haxe
	var programs = new ShaderPrograms(graphics);
	programs.prepareVariants(lit, [
		{features: ShaderFeatures.NONE, state: ShaderPipelineState.OPAQUE, layout: mesh},
		{features: skinned, state: ShaderPipelineState.OPAQUE, layout: skinnedMesh},
		{features: ShaderFeatures.NONE, state: shadowCaster, layout: mesh}
	]);
	var pipeline = programs.getPipeline(lit.getShader(skinned), ShaderPipelineState.OPAQUE, skinnedMesh);   // kept by the renderer
	// each frame:
	programs.prepareFrame();
	graphics.beginFrame(width, height, 0xff000000);
	graphics.draw(pipeline.handle, buffers, null, indices, 0, count, 0, 1, values.textures, values.samplings, values.uniforms);
	graphics.endFrame();
	programs.finishFrame();
	``` */
class ShaderPrograms {
	final graphics:IGraphics;

	/** Creates the programs over the graphics they are built on.

		@param graphics  The graphics. */
	public function new(graphics:IGraphics) {
		this.graphics = graphics;
	}

	/** Starts a frame, before its first pass: rebuilds every program and pipeline whose shader was replaced since, then refuses builds
		until `finishFrame`. A rebuild the GPU refuses keeps the old (`ShaderPipeline.buildError`, `Shader.reloadError`). */
	public function prepareFrame():Void {
		inFrame = false;
		if (rebuilding != null)
			rebuilding(this);
		inFrame = true;
	}

	/** Ends a frame, after its last pass: builds are allowed again. */
	public function finishFrame():Void {
		inFrame = false;
		var deferred = disposing.copy();
		disposing.resize(0);
		for (shader in deferred)
			disposeShader(shader);
	}

	/** Returns a shader's program, built the first time and again at the `prepareFrame` after each replacement.

		@param shader  The shader.
		@return  The program's `IGraphics` handle.
		@throws String  A first build inside a frame (between `prepareFrame` and `finishFrame`), or a first program the GPU doesn't build,
			with its log. */
	public function getProgram(shader:Shader):Int {
		var built = programs.get(shader);
		if (built != null)
			return built.handle;
		if (inFrame)
			throw 'shader programs: a first build of a program inside a frame; build it before prepareFrame (prepare, prepareVariants)';
		var handle = graphics.createShader(shader.source);
		programs.set(shader, {handle: handle, reloadCount: shader.reloadCount, pipelines: []});
		return handle;
	}

	/** Returns the pipeline drawing a shader with a state and a vertex layout, built the first time.

		@param shader  The shader.
		@param state  What the pipeline fixes besides its program and layout.
		@param layout  The mesh's vertex layout.
		@return  The pipeline, the same object for the same shader, state and layout.
		@throws String  A first build inside a frame; a layout the shader can't read (`ShaderVertexLayout.computeBuffers`); a state whose
			`flip` isn't `None` for a shader without its `flipUniform`; or a first build the GPU refuses. */
	public function getPipeline(shader:Shader, state:ShaderPipelineState, layout:ShaderVertexLayout):ShaderPipeline {
		var found = findPipeline(shader, state, layout);
		if (found != null && found.handle != 0)
			return found;
		if (inFrame)
			throw 'shader programs: a first build of a pipeline inside a frame (state ${state.key}); build it before prepareFrame (prepare, prepareVariants)';
		var program = getProgram(shader);
		var built = programs.get(shader);
		var pipeline = found != null ? found : new ShaderPipeline(shader, state, layout);
		pipeline.built(make(shader, program, state, layout));
		if (found == null) {
			built.pipelines.push(pipeline);
			var byState = pipelines.get(shader);
			if (byState == null)
				pipelines.set(shader, byState = new Map());
			var byLayout = byState.get(state.key);
			if (byLayout == null)
				byState.set(state.key, byLayout = new Map());
			byLayout.set(layout.key, pipeline);
		} else if (built.pipelines.indexOf(pipeline) < 0)
			built.pipelines.push(pipeline);
		return pipeline;
	}

	/** Finds a pipeline already built, never building one, as a draw inside a pass may ask.

		@param shader  The shader.
		@param state  The state.
		@param layout  The vertex layout.
		@return  The pipeline, or null when none was built for them. */
	public function findPipeline(shader:Shader, state:ShaderPipelineState, layout:ShaderVertexLayout):Null<ShaderPipeline> {
		var byState = pipelines.get(shader);
		if (byState == null)
			return null;
		var byLayout = byState.get(state.key);
		return byLayout == null ? null : byLayout.get(layout.key);
	}

	/** Builds a shader's program and a pipeline ahead of its draws, outside a frame.

		@param shader  The shader.
		@param state  The state.
		@param layout  The vertex layout.
		@throws String  A call inside a frame, or what `getPipeline` throws. */
	public function prepare(shader:Shader, state:ShaderPipelineState, layout:ShaderVertexLayout):Void {
		if (inFrame)
			throw 'shader programs: prepare inside a frame; prepare outside one, at setup or while a level loads';
		getPipeline(shader, state, layout);
	}

	/** Builds the pipelines some variants are drawn with, each variant with the state and layout it pairs with, outside a frame.

		@param variants  The set.
		@param pipelines  Each pipeline to build: a variant's features, a state and a layout. A variant may come several times.
		@return  The pipelines, by the same index.
		@throws String  A call inside a frame, a combination not compiled, or what `getPipeline` throws. */
	public function prepareVariants(variants:ShaderVariants,
			pipelines:Array<{features:ShaderFeatures, state:ShaderPipelineState, layout:ShaderVertexLayout}>):Array<ShaderPipeline> {
		if (inFrame)
			throw 'shader programs: prepareVariants inside a frame; prepare outside one, at setup or while a level loads';
		return [
			for (p in pipelines)
				getPipeline(variants.getShader(p.features), p.state, p.layout)
		];
	}

	/** Disposes a shader's program and its pipelines, as when it is no longer drawn. Inside a frame it is deferred to `finishFrame`, so
		draws already made keep working. Its held `ShaderPipeline`s then have `handle` 0, and are built again, the same objects, by the next
		`getPipeline` or `prepare` for them outside a frame.

		@param shader  The shader. */
	public function disposeShader(shader:Shader):Void {
		if (inFrame) {
			if (disposing.indexOf(shader) < 0)
				disposing.push(shader);
			return;
		}
		var built = programs.get(shader);
		if (built == null)
			return;
		graphics.disposeShader(built.handle);
		for (p in built.pipelines)
			p.forget();
		programs.remove(shader);
	}

	/** Disposes every program and pipeline it built. */
	public function dispose():Void {
		for (shader => built in programs)
			graphics.disposeShader(built.handle);
		for (_ => byState in pipelines)
			for (_ => byLayout in byState)
				for (p in byLayout)
					p.forget();
		programs.clear();
		pipelines.clear();
		disposing.resize(0);
	}

	// What prepareFrame rebuilds with, installed by the first replacement of any shader (Shader.replace), so a program that never replaces
	// one links none of it (docs/CONVENTIONS.md, "A program links only what it names").
	@:allow(helix.services.shaders)
	static var rebuilding:Null<ShaderPrograms->Void> = null;

	// Every program and pipeline whose shader was replaced since it was built, built again.

	@:allow(helix.services.shaders)
	static function rebuildReplaced(programs:ShaderPrograms):Void {
		for (shader => built in programs.programs)
			if (built.reloadCount != shader.reloadCount)
				programs.rebuild(shader, built);
	}

	// Each shader's program, the reloadCount it was built at, and the pipelines made with it.
	final programs = new haxe.ds.ObjectMap<Shader, {handle:Int, reloadCount:Int, pipelines:Array<ShaderPipeline>}>();
	// The held pipelines, by shader, state and layout.
	final pipelines = new haxe.ds.ObjectMap<Shader, Map<String, Map<String, ShaderPipeline>>>();
	// Between prepareFrame and finishFrame: nothing is built.
	var inFrame = false;
	// Shaders disposed inside a frame, disposed at its finish.
	final disposing:Array<Shader> = [];

	// The pipeline as the platform makes it: the layout resolved for the shader, its unfed attributes' constants, and the flip's place.
	function make(shader:Shader, program:Int, state:ShaderPipelineState, layout:ShaderVertexLayout):Int {
		var buffers = layout.computeBuffers(shader);
		var place:Null<{blockSlot:Int, offset:Int}> = null;
		if (state.flip != None) {
			var u = shader.findUniform(state.flipUniform);
			place = u == null ? null : shader.findUniformPlace(u);
			if (place == null)
				throw 'shader programs: the state flips ${state.flipUniform}, which the shader doesn\'t declare (flip None, or a uniform it reads)';
		}
		return graphics.createPipeline({
			shader: program,
			buffers: buffers,
			primitive: state.primitive,
			indexed: state.indexed,
			blend: state.blend,
			colorWrite: state.colorWrite,
			depthTest: state.depthTest,
			depthWrite: state.depthWrite,
			cull: state.cull,
			clockwise: state.clockwise,
			depthOnly: state.depthOnly,
			flip: state.flip,
			flipBlockSlot: place == null ? 0 : place.blockSlot,
			flipOffset: place == null ? 0 : place.offset,
			attributeConstants: layout.computeConstants(shader, buffers)
		});
	}

	// A replaced shader's program and pipelines built again; a program or pipeline the GPU refuses keeps the old, saying why.
	function rebuild(shader:Shader, built:{handle:Int, reloadCount:Int, pipelines:Array<ShaderPipeline>}):Void {
		built.reloadCount = shader.reloadCount;
		var program = try graphics.createShader(shader.source) catch (e:Dynamic) {
			var why = 'the replaced program doesn\'t build: $e';
			shader.refuse(why);
			for (p in built.pipelines)
				p.failed(why);
			helix.log.Log.warn('shader programs: ${shader.filePath}: $why', "shaders");
			return;
		};
		var made = [];
		for (p in built.pipelines) {
			var handle = try make(shader, program, p.state, p.layout) catch (e:Dynamic) {
				for (m in made)
					graphics.disposePipeline(m);
				graphics.disposeShader(program);
				var why = 'a replaced pipeline doesn\'t build: $e';
				shader.refuse(why);
				for (q in built.pipelines)
					q.failed(why);
				helix.log.Log.warn('shader programs: ${shader.filePath}: $why', "shaders");
				return;
			};
			made.push(handle);
		}
		// The old program goes, its pipelines with it; the new ones take their places.
		graphics.disposeShader(built.handle);
		built.handle = program;
		for (k => p in built.pipelines)
			p.built(made[k]);
	}
}
