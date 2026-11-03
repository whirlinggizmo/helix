package helix.raylib.internal;

import haxe.io.Bytes;
import helix.platform.IGraphics;
import helix.services.shaders.Shader;
import helix.services.shaders.ShaderSnapshot;
import helix.services.shaders.ShaderUniform;
import helix.services.shaders.ShaderValues;

/** Holds a raylib shader on the GPU: its compiled shader (helix-services'), the values every draw through it reads (raylib shares a
	shader's uniforms between every material drawn with it), the textures set on it, its locations, and its pipelines. */
@:noCompletion
class Program {
	/** The attributes, as raylib names them, by slot; a matrix's other columns "". */
	public final attributes:Array<String>;

	/** The compiled shader. */
	public final shader:Shader;

	/** The values its uniforms hold, as `SetShaderValue` writes them. */
	public final values:ShaderValues;

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

	/** Where its pipelines flip a draw into a render target: its clip scale's block slot and offset. */
	public final flipSlot:Int;

	public final flipOffset:Int;

	// Each location, as `GetShaderLocation` hands them out: a uniform and an element, or a sampler's name.
	final locations:Array<{
		name:String,
		uniform:Null<ShaderUniform>,
		elementIndex:Int,
		sampler:String
	}> = [];
	final pipelines = new Map<String, Int>();
	final graphics:IGraphics;
	// raylib's own uniforms, written by each draw: null for one the shader doesn't declare.
	final mvp:Null<ShaderUniform>;
	final matModel:Null<ShaderUniform>;
	final matView:Null<ShaderUniform>;
	final matProjection:Null<ShaderUniform>;
	final matNormal:Null<ShaderUniform>;
	final colDiffuse:Null<ShaderUniform>;

	/** Makes the program on the GPU.

		@param graphics  The graphics.
		@param shader  The shader as compiled. */
	public function new(graphics:IGraphics, shader:Shader) {
		this.graphics = graphics;
		this.shader = shader;
		attributes = shader.source.attributes;
		handle = graphics.createShader(shader.source);
		values = new ShaderValues(shader);
		var place = shader.findUniformPlace(shader.getUniform("helix_clipScale"));
		flipSlot = place.blockSlot;
		flipOffset = place.offset;
		for (s in shader.samplers) {
			while (textures.length <= s.slot) {
				textures.push(0);
				cubes.push(false);
				units.push(-1);
			}
			cubes[s.slot] = s.kind == Cube;
		}
		texture0 = slotOf("texture0");
		texture1 = slotOf("texture1");
		texture2 = slotOf("texture2");
		mvp = shader.findUniform("mvp");
		matModel = shader.findUniform("matModel");
		matView = shader.findUniform("matView");
		matProjection = shader.findUniform("matProjection");
		matNormal = shader.findUniform("matNormal");
		colDiffuse = shader.findUniform("colDiffuse");
	}

	function slotOf(name:String):Int {
		var s = shader.findSampler(name);
		return s == null ? -1 : s.slot;
	}

	/** Returns a uniform's or texture's location, as GL gives it: -1 for a name the shader doesn't declare, or declares and doesn't read.
		A path into an array (`lights[1].color`) has a location of its own.

		@param name  Its name.
		@return  The location, or -1. */
	public function locate(name:String):Int {
		for (i => l in locations)
			if (l.name == name)
				return i;
		var sampler = shader.findSampler(name);
		if (sampler != null) {
			if (!sampler.active)
				return -1;
			locations.push({
				name: name,
				uniform: null,
				elementIndex: 0,
				sampler: name
			});
			return locations.length - 1;
		}
		var path = shader.findUniformPath(name);
		if (path == null || !path.uniform.active || path.uniform.name == "helix_clipScale")
			return -1;
		locations.push({
			name: name,
			uniform: path.uniform,
			elementIndex: path.elementIndex,
			sampler: ""
		});
		return locations.length - 1;
	}

	/** Returns whether a location is a texture's, and its slot.

		@param location  The location.
		@return  The texture's slot, or -1 for a uniform's location. */
	public function textureSlot(location:Int):Int {
		if (location < 0 || location >= locations.length || locations[location].sampler == "")
			return -1;
		return slotOf(locations[location].sampler);
	}

	/** Writes numbers to a uniform, from its element, as many whole elements as they hold (a matrix by columns), integers and bools
		as their numbers taken whole, as GL's `glUniform` takes them.

		@param location  Its location.
		@param numbers  The numbers, in GLSL's order. */
	public function write(location:Int, numbers:Array<Float>):Void {
		if (location < 0 || location >= locations.length || locations[location].uniform == null)
			return;
		var l = locations[location];
		put(l.uniform, numbers, l.elementIndex);
	}

	// Writes whole elements of numbers into a uniform from an element, past its end dropped.
	function put(u:ShaderUniform, numbers:Array<Float>, first:Int):Void {
		var size = u.type.componentCount * u.type.columnCount;
		var count = Std.int(numbers.length / size);
		if (first + count > u.elementCount)
			count = u.elementCount - first;
		if (count <= 0)
			return;
		if (u.type.integer)
			values.writeInts(u, [for (i in 0...count * size) Std.int(numbers[i])], first);
		else
			values.writeFloats(u, numbers.length == count * size ? numbers : numbers.slice(0, count * size), first);
	}

	/** Writes a uniform by name, when the shader declares it.

		@param name  The uniform's name.
		@param numbers  The numbers. */
	public function writeNamed(name:String, numbers:Array<Float>):Void {
		var u = shader.findUniform(name);
		if (u != null)
			put(u, numbers, 0);
	}

	/** Returns the blocks a draw reads, raylib's own uniforms written first: the matrices and the diffuse color, each copied, as a draw is
		recorded and submitted when the frame is drawn.

		@param model  The model's matrix.
		@param view  The view's.
		@param projection  The projection's.
		@param diffuse  The diffuse color, 0 to 1 each.
		@param mvpView  Optional. The view the mvp is made with in place of `view` (an eye's, in stereo).
		@param mvpProjection  Optional. The projection it is made with in place of `projection`.
		@return  The blocks' bytes, by stage and slot. */
	public function capture(model:helix.math.Matrix3D, view:helix.math.Matrix3D, projection:helix.math.Matrix3D, diffuse:Array<Float>,
			?mvpView:helix.math.Matrix3D, ?mvpProjection:helix.math.Matrix3D):Array<Null<Bytes>> {
		if (mvp != null)
			values.writeMatrix(mvp,
				helix.math.Matrix3D.compose(helix.math.Matrix3D.compose(model, mvpView != null ? mvpView : view),
					mvpProjection != null ? mvpProjection : projection));
		if (matModel != null)
			values.writeMatrix(matModel, model);
		if (matView != null)
			values.writeMatrix(matView, view);
		if (matProjection != null)
			values.writeMatrix(matProjection, projection);
		if (matNormal != null) {
			var normal = new helix.math.Matrix3D().copyFrom(model);
			normal.invert(normal);
			values.writeMatrix(matNormal, normal.transpose(normal));
		}
		if (colDiffuse != null)
			put(colDiffuse, diffuse, 0);
		var snapshot = new ShaderSnapshot();
		values.capture(snapshot);
		return snapshot.uniforms;
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
