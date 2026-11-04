package helix.render;

import helix.math.Matrix2D;
import helix.math.Matrix3D;
import helix.platform.Sampling;
import helix.services.shaders.Shader;
import helix.services.shaders.ShaderSampler;
import helix.services.shaders.ShaderUniform;
import helix.services.shaders.ShaderValues;

/** The names helix-render fills in one shader, found once by name, and the draw's own values it writes them on, its base the program's
	values for each draw: a name the shader doesn't declare, or declares in a shared block, is skipped. */
@:noCompletion
@:allow(helix.render)
class RenderFill {
	final shader:Shader;
	final values:ShaderValues;
	final model:ShaderUniform;
	final normalMatrix:ShaderUniform;
	final modelViewProjection:ShaderUniform;
	final baseColor:ShaderUniform;
	final fontKind:ShaderUniform;
	final lineWidth:ShaderUniform;
	final pointSize:ShaderUniform;
	final pointSizeAttenuated:ShaderUniform;
	final clipPlanes:ShaderUniform;
	final clipPlaneCount:ShaderUniform;
	final fogged:ShaderUniform;
	final toneMapped:ShaderUniform;
	final skinned:ShaderUniform;
	final boneOffset:ShaderUniform;
	final boneMatrices:ShaderUniform;
	final textureTransform:ShaderUniform;
	final vertexColors:ShaderUniform;
	final colorSpaceSrgb:ShaderUniform;
	final alphaCutoff:ShaderUniform;
	final baseColorTextureSrgb:ShaderUniform;
	final morphTargetCount:ShaderUniform;
	final viewNames:Array<ShaderUniform>;
	final baseColorTexture:ShaderSampler;
	final alphaTexture:ShaderSampler;
	final boneTexture:ShaderSampler;

	static final scratch = [for (_ in 0...16) 0.];

	function new(shader:Shader) {
		this.shader = shader;
		values = new ShaderValues(shader);
		model = shader.reserveUniform("model");
		normalMatrix = shader.reserveUniform("normalMatrix");
		modelViewProjection = shader.reserveUniform("modelViewProjection");
		baseColor = shader.reserveUniform("baseColor");
		fontKind = shader.reserveUniform("fontKind");
		lineWidth = shader.reserveUniform("lineWidth");
		pointSize = shader.reserveUniform("pointSize");
		pointSizeAttenuated = shader.reserveUniform("pointSizeAttenuated");
		clipPlanes = shader.reserveUniform("clipPlanes");
		clipPlaneCount = shader.reserveUniform("clipPlaneCount");
		fogged = shader.reserveUniform("fogged");
		toneMapped = shader.reserveUniform("toneMapped");
		skinned = shader.reserveUniform("skinned");
		boneOffset = shader.reserveUniform("boneOffset");
		boneMatrices = shader.reserveUniform("boneMatrices");
		textureTransform = shader.reserveUniform("textureTransform");
		vertexColors = shader.reserveUniform("vertexColors");
		colorSpaceSrgb = shader.reserveUniform("colorSpaceSrgb");
		alphaCutoff = shader.reserveUniform("alphaCutoff");
		baseColorTextureSrgb = shader.reserveUniform("baseColorTextureSrgb");
		morphTargetCount = shader.reserveUniform("morphTargetCount");
		viewNames = [
			for (n in [
				"viewMatrix",
				"projectionMatrix",
				"viewProjection",
				"cameraPosition",
				"viewportSize",
				"linearTarget",
				"exposure",
				"toneMapping",
				"fogColor",
				"fogParams"
			])
				shader.reserveUniform(n)
		];
		baseColorTexture = shader.reserveSampler("baseColorTexture");
		alphaTexture = shader.reserveSampler("alphaTexture");
		boneTexture = shader.reserveSampler("boneTexture");
	}

	/** Whether the draw's own values hold a name: declared, and not in a shared block. */
	static inline function holds(u:ShaderUniform):Bool
		return u.declared && !u.shared;

	function matrix(u:ShaderUniform, m:Matrix3D):Void
		if (holds(u))
			values.writeMatrix(u, m);

	function integer(u:ShaderUniform, v:Int):Void
		if (holds(u))
			values.writeInt(u, v);

	function float(u:ShaderUniform, v:Float):Void
		if (holds(u))
			values.writeFloat(u, v);

	function color(u:ShaderUniform, c:Int):Void
		if (holds(u))
			values.writeColor(u, c);

	function texture(s:ShaderSampler, handle:Int, sampling:Sampling):Void
		if (s.declared)
			values.writeTexture(s, handle, sampling);

	/** Writes a 2D matrix as a `mat3`, by columns. */
	function matrix2D(u:ShaderUniform, m:Matrix2D):Void {
		if (!holds(u))
			return;
		var f = scratch;
		f.resize(9);
		f[0] = m.a;
		f[1] = m.b;
		f[2] = 0;
		f[3] = m.c;
		f[4] = m.d;
		f[5] = 0;
		f[6] = m.tx;
		f[7] = m.ty;
		f[8] = 1;
		values.writeFloats(u, f);
	}

	/** Writes the clip planes, a, b, c and d each, at most 4. */
	function planes(list:Array<Float>):Void {
		var count = Std.int(Math.min(4, list.length / 4));
		integer(clipPlaneCount, count);
		if (!holds(clipPlanes) || count == 0)
			return;
		var f = scratch;
		f.resize(count * 4);
		for (i in 0...count * 4)
			f[i] = list[i];
		values.writeFloats(clipPlanes, f);
	}

	/** Writes the view's names a shader declares loose, which no shared block gives it. */
	function view(v:RenderView):Void {
		var n = viewNames;
		matrix(n[0], v.view);
		matrix(n[1], v.projection);
		matrix(n[2], v.viewProjection);
		if (holds(n[3]))
			values.writeVector(n[3], v.eyeX, v.eyeY, v.eyeZ, 1);
		if (holds(n[4]))
			values.writeVector(n[4], v.width, v.height, 1 / v.width, 1 / v.height);
		integer(n[5], v.linearTarget ? 1 : 0);
		float(n[6], v.exposure);
		integer(n[7], v.toneMapping);
		color(n[8], v.fogColor);
		if (holds(n[9]))
			values.writeVector(n[9], v.fogMode, v.fogNear, v.fogFar, v.fogDensity);
	}
}
