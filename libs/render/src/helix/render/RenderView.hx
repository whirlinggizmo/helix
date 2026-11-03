package helix.render;

import helix.geometry.Frustum3D;
import helix.math.Matrix3D;
import helix.services.shaders.Shader;
import helix.services.shaders.ShaderBlockValues;
import helix.services.shaders.ShaderScene;
import helix.services.shaders.ShaderUniform;

/** A view as a batch draws through it: its matrices, the rectangle of the pass it fills, its frustum, and the `View` block written for
	it and shared with every draw in it through its scene. */
@:noCompletion
@:allow(helix.render)
class RenderView {
	final view = new Matrix3D();
	final projection = new Matrix3D();
	final viewProjection = new Matrix3D();
	final frustum = new Frustum3D();
	// The rectangle it fills, in the pass's pixels from its top left.
	var x = 0;
	var y = 0;
	var width = 1;
	var height = 1;
	var eyeX = 0.;
	var eyeY = 0.;
	var eyeZ = 0.;
	var linearTarget = false;
	var exposure = 1.;
	var toneMapping = 0;
	var fogMode = 0;
	var fogColor = 0;
	var fogNear = 0.;
	var fogFar = 0.;
	var fogDensity = 0.;
	final block:ShaderBlockValues;
	final scene = new ShaderScene();
	final names:Array<ShaderUniform>;

	static final inverse = new Matrix3D();

	/** Makes a view whose block is laid out as a shader naming `View` shared lays it out. */
	function new(shader:Shader) {
		block = new ShaderBlockValues(shader, "View");
		scene.shareBlock(block);
		names = [
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
				shader.getUniform(n)
		];
	}

	/** Takes the matrices and the rectangle, and works out the rest. */
	function set(view:Matrix3D, projection:Matrix3D, x:Int, y:Int, width:Int, height:Int):Void {
		this.view.copyFrom(view);
		this.projection.copyFrom(projection);
		Matrix3D.compose(view, projection, viewProjection);
		Frustum3D.fromMatrix(viewProjection, frustum);
		this.x = x;
		this.y = y;
		this.width = width;
		this.height = height;
		if (view.invert(inverse) != null) {
			var m = inverse.values;
			eyeX = m[12];
			eyeY = m[13];
			eyeZ = m[14];
		} else
			eyeX = eyeY = eyeZ = 0;
	}

	/** Takes what the target, the renderer and the fog say. */
	function setLook(linearTarget:Bool, exposureStops:Float, toneMapping:ToneMapping, fog:Null<Fog3D>):Void {
		this.linearTarget = linearTarget;
		exposure = Math.pow(2, exposureStops);
		this.toneMapping = cast toneMapping;
		fogMode = fog == null ? 0 : fog.mode == Linear ? 1 : 2;
		if (fog != null) {
			fogColor = fog.color;
			fogNear = fog.near;
			fogFar = fog.far;
			fogDensity = fog.density;
		}
	}

	/** Writes the block. */
	function write():Void {
		block.writeMatrix(names[0], view);
		block.writeMatrix(names[1], projection);
		block.writeMatrix(names[2], viewProjection);
		block.writeVector(names[3], eyeX, eyeY, eyeZ, 1);
		block.writeVector(names[4], width, height, 1 / width, 1 / height);
		block.writeInt(names[5], linearTarget ? 1 : 0);
		block.writeFloat(names[6], exposure);
		block.writeInt(names[7], toneMapping);
		block.writeColor(names[8], fogColor);
		block.writeVector(names[9], fogMode, fogNear, fogFar, fogDensity);
	}
}
