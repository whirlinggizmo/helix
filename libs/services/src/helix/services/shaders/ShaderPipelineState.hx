package helix.services.shaders;

import helix.platform.Blend;
import helix.platform.ClipFlip;
import helix.platform.ColorChannels;
import helix.platform.CullFace;
import helix.platform.DepthTest;
import helix.platform.Primitive;

/** Represents what a pipeline fixes besides its program and its vertex layout: a `PipelineDesc` without `shader` and `buffers`, and the
	uniform flipped for a render target by name, for `ShaderPrograms`, which keeps one pipeline for each state by its values.

	```haxe
	var shadowCaster = ShaderPipelineState.OPAQUE.with({depthOnly: true, cull: Front});
	``` */
class ShaderPipelineState {
	/** Opaque triangles, indexed, depth tested and written, back faces culled, the uniform `viewProjection` flipped for a render
		target: the name a library's shaders use. A layer whose shaders name it otherwise gives its own (raylib's `mvp`:
		`OPAQUE.with({flipUniform: "mvp"})`). */
	public static final OPAQUE = new ShaderPipelineState();

	/** As `OPAQUE`, blended by alpha, depth not written. */
	public static final ALPHA = new ShaderPipelineState({blend: Blend.ALPHA, depthWrite: false});

	/** As `ALPHA`, adding light. */
	public static final ADDITIVE = new ShaderPipelineState({blend: Blend.ADDITIVE, depthWrite: false});

	/** 2D: blended by alpha, no depth, nothing culled, `projection` flipped. */
	public static final SPRITES = new ShaderPipelineState({
		blend: Blend.ALPHA,
		depthTest: Off,
		depthWrite: false,
		cull: None,
		flipUniform: "projection"
	});

	/** As `OPAQUE`, flipping the clip scale a shader compiled with `ShaderOptions.clipScale` declares, whatever else it reads. */
	public static final CLIP_SCALE = new ShaderPipelineState({flip: ClipScale, flipUniform: "helix_clipScale"});

	/** Gets the primitive the draws make. */
	public final primitive:Primitive;

	/** Gets whether the draws are indexed, by uint32 indices. */
	public final indexed:Bool;

	/** Gets how the colors are combined with the target's. */
	public final blend:Blend;

	/** Gets the depth test. */
	public final depthTest:DepthTest;

	/** Gets whether the draws write depth. */
	public final depthWrite:Bool;

	/** Gets which faces are culled. */
	public final cull:CullFace;

	/** Gets whether clockwise winding is the front face. */
	public final clockwise:Bool;

	/** Gets whether the draws write depth alone, for a shadow pass. */
	public final depthOnly:Bool;

	/** Gets the color channels the draws write. */
	public final colorWrite:ColorChannels;

	/** Gets how a draw into a render target is turned the right way up: `ViewProjection` a matrix's y row, `ClipScale` a vec4 clip
		scale the shader multiplies `gl_Position` by, `None` nothing.

		A shader is flipped only through a uniform it reads, one of those two; `ShaderOptions.clipScale` gives any shader one
		(`CLIP_SCALE`). A flipped draw's winding is reversed with it, by the
		adapter, so `clockwise` and `cull` mean what they say in a target and on the screen alike. A shadow pass is never flipped: a shadow
		map is stored bottom first, as clip space maps to it (`IGraphics.createShadowMap`). */
	public final flip:ClipFlip;

	/** Gets the uniform `flip` reads, by name. `ShaderPrograms` finds its place in each shader (`Shader.findUniformPlace`), again after a
		replacement, and the pipeline names that place (platform proposal 9); `ShaderPrograms.getPipeline` refuses a shader without it
		unless `flip` is `None`. */
	public final flipUniform:String;

	/** Creates a state, each value given or as `OPAQUE` has it.

		@param values  Optional. The values that differ from `OPAQUE`'s. */
	public function new(?values:{
		?primitive:Primitive,
		?indexed:Bool,
		?blend:Blend,
		?depthTest:DepthTest,
		?depthWrite:Bool,
		?cull:CullFace,
		?clockwise:Bool,
		?depthOnly:Bool,
		?colorWrite:ColorChannels,
		?flip:ClipFlip,
		?flipUniform:String
	}) {
		if (values == null)
			values = {};
		var v = values;
		primitive = v.primitive != null ? v.primitive : Triangles;
		indexed = v.indexed != null ? v.indexed : true;
		blend = v.blend != null ? v.blend : Blend.OPAQUE;
		depthTest = v.depthTest != null ? v.depthTest : LessEqual;
		depthWrite = v.depthWrite != null ? v.depthWrite : true;
		cull = v.cull != null ? v.cull : Back;
		clockwise = v.clockwise != null ? v.clockwise : false;
		depthOnly = v.depthOnly != null ? v.depthOnly : false;
		colorWrite = v.colorWrite != null ? v.colorWrite : All;
		flip = v.flip != null ? v.flip : ViewProjection;
		flipUniform = v.flipUniform != null ? v.flipUniform : "viewProjection";
		key = '${(primitive : Int)} ${indexed} ${(blend : Int)} ${(depthTest : Int)} ${depthWrite} ${(cull : Int)} ${clockwise} ${depthOnly} '
			+ '${(colorWrite : Int)} ${(flip : Int)} $flipUniform';
	}

	/** Returns this state with some values changed; this one is unchanged.

		@param values  The values that differ.
		@return  The new state. */
	public function with(values:{
		?primitive:Primitive,
		?indexed:Bool,
		?blend:Blend,
		?depthTest:DepthTest,
		?depthWrite:Bool,
		?cull:CullFace,
		?clockwise:Bool,
		?depthOnly:Bool,
		?colorWrite:ColorChannels,
		?flip:ClipFlip,
		?flipUniform:String
	}):ShaderPipelineState {
		return new ShaderPipelineState({
			primitive: values.primitive != null ? values.primitive : primitive,
			indexed: values.indexed != null ? values.indexed : indexed,
			blend: values.blend != null ? values.blend : blend,
			depthTest: values.depthTest != null ? values.depthTest : depthTest,
			depthWrite: values.depthWrite != null ? values.depthWrite : depthWrite,
			cull: values.cull != null ? values.cull : cull,
			clockwise: values.clockwise != null ? values.clockwise : clockwise,
			depthOnly: values.depthOnly != null ? values.depthOnly : depthOnly,
			colorWrite: values.colorWrite != null ? values.colorWrite : colorWrite,
			flip: values.flip != null ? values.flip : flip,
			flipUniform: values.flipUniform != null ? values.flipUniform : flipUniform
		});
	}

	// Its values as one string: states with the same values find the same pipeline.
	@:allow(helix.services.shaders)
	final key:String;
}
