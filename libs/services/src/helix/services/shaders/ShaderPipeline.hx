package helix.services.shaders;

/** Represents a pipeline `ShaderPrograms` keeps for a shader, a state and a vertex layout: an object a renderer holds, whose `handle`
	stays current across the shader's replacements.

	It is never built inside a pass. After its shader is replaced, `handle` keeps the old pipeline, which draws as before, until the next
	`ShaderPrograms.prepareFrame`, the frame's start, disposes the old program and its pipelines and builds the new; `buildCount` then
	moves. A replaced program the GPU refuses is never a throw: the old program and pipeline stay, and `buildError` and the shader's
	`reloadError` say why. */
class ShaderPipeline {
	/** Gets the shader. */
	public final shader:Shader;

	/** Gets the state. */
	public final state:ShaderPipelineState;

	/** Gets the vertex layout. */
	public final layout:ShaderVertexLayout;

	/** Gets the pipeline's `IGraphics` handle: the one built last, the old one until the frame after a replacement. */
	public var handle(get, never):Int;

	/** Gets the number of times it has been built: a renderer comparing it with the count it saw knows the handle changed. */
	public var buildCount(default, null):Int = 0;

	/** Gets why the last build failed (a replaced program the GPU refused, with its log), the old pipeline kept, or null. */
	public var buildError(default, null):Null<String>;

	@:allow(helix.services.shaders)
	function new(shader:Shader, state:ShaderPipelineState, layout:ShaderVertexLayout) {
		this.shader = shader;
		this.state = state;
		this.layout = layout;
	}

	function get_handle():Int {
		return current;
	}

	// The pipeline built last, 0 when none is.
	var current = 0;

	// Records a build: its handle, or why it failed, the old kept.

	@:allow(helix.services.shaders)
	function built(handle:Int):Void {
		current = handle;
		buildCount++;
		buildError = null;
	}

	@:allow(helix.services.shaders)
	function failed(why:String):Void
		buildError = why;

	@:allow(helix.services.shaders)
	function forget():Void
		current = 0;
}
