import haxe.io.Bytes;
import helix.graphics.IGraphics;
import helix.graphics.PipelineDesc;
import helix.graphics.Sampling;
import helix.graphics.ShaderSource;
import helix.graphics.TextureFormat;
import helix.render3d.Camera3D;
import helix.render3d.DirectionalLight;
import helix.render3d.Material;
import helix.render3d.Mesh;
import helix.render3d.Model;
import helix.render3d.PointLight;
import helix.render3d.Stage3D;

/** A Stage3D's work on the CPU, frame after frame, against a GPU that does nothing (after libwgf's shadowbench): `StageBench <case> <models>
	<frames>`. tools/bench_stage.py runs each case under perf and takes its setup's run (0 frames) away. Cases:
	look        models on a grid in view, sharing a mesh and a material; a sun and four lamps
	away        the same, the camera turned away from them
	away-nocull the same, culling off
	each        in view, a mesh each
	lights      in view, 64 lamps among them
	shadows     in view, the sun casting
	pick        a pick through the middle of the grid each frame, no draw */
class StageBench {
	static function main():Void {
		var args = commandLine(),
			kind = args[0],
			models = Std.parseInt(args[1]),
			frames = Std.parseInt(args[2]);
		var stage = new Stage3D(new NullGraphics()),
			side = Math.ceil(Math.sqrt(models));
		var shared = Mesh.cube(1, 1, 1), material = new Material();
		for (i in 0...models) {
			var node = new Model(kind == "each" ? Mesh.cube(1, 1, 1) : shared, material);
			node.setPosition((i % side - side / 2) * 2, 0, (Std.int(i / side) - side / 2) * 2);
			stage.add(node);
		}
		var sun = new DirectionalLight();
		sun.shadowCasting = kind == "shadows";
		sun.lookAt(-.3, -1, -.2);
		stage.add(sun);
		var lamps = kind == "lights" ? 64 : 4;
		for (k in 0...lamps) {
			var lamp = new PointLight();
			lamp.range = 8;
			lamp.setPosition((k % 8 - 4) * side / 4, 2, (Std.int(k / 8) % 8 - 4) * side / 4);
			stage.add(lamp);
		}
		stage.culling = kind != "away-nocull";
		var camera = new Camera3D();
		camera.setViewport(1280, 720);
		camera.fovY = Math.PI / 3;
		camera.near = .1;
		camera.far = side * 4.;
		var far = side * 1.2;
		if (kind == "away" || kind == "away-nocull")
			camera.setView(0, far, far, 0, far * 2, far * 3);
		else
			camera.setView(0, far, far, 0, 0, 0);
		var picked = 0;
		for (f in 0...frames) {
			if (kind == "pick") {
				if (stage.pick(camera, 640, 360) != null)
					picked++;
				continue;
			}
			if (kind == "shadows")
				stage.drawShadows(camera);
			stage.draw(camera);
		}
		var line = '$kind $models $frames drawn ${stage.drawnNodeCount} draws ${stage.drawCallCount} picked $picked';
		#if js js.Syntax.code("console.log({0})", line); #else Sys.println(line); #end
	}

	// The command line's arguments, under Node3D or natively.
	static function commandLine():Array<String> {
		#if js
		return js.Syntax.code("process.argv.slice(2)");
		#else
		return Sys.args();
		#end
	}
}

/** A GPU that does nothing: handles counted up, every call accepted. */
class NullGraphics implements IGraphics {
	var next = 1;

	public function new() {}

	public function createTexture(width:Int, height:Int, levels:Array<Bytes>, format:TextureFormat = Rgba8):Int
		return next++;

	public function createCubeTexture(size:Int, levels:Array<Bytes>, format:TextureFormat):Int
		return next++;

	public function createDataTexture(width:Int, height:Int):Int
		return next++;

	public function updateDataTexture(handle:Int, data:Bytes):Void {}

	public function canSample(format:TextureFormat):Bool
		return true;

	public var msaaSamples(get, never):Int;

	function get_msaaSamples():Int
		return 1;

	public var maxMsaaSamples(get, never):Int;

	function get_maxMsaaSamples():Int
		return 1;

	public function createRenderTarget(width:Int, height:Int):Int
		return next++;

	public function createShadowMap(size:Int, layers:Int):Int
		return next++;

	public function destroyTexture(handle:Int):Void {}

	public function createBuffer(capacityBytes:Int):Int
		return next++;

	public function createStaticBuffer(data:Bytes, bytes:Int, index:Bool):Int
		return next++;

	public function updateBuffer(handle:Int, data:Bytes, usedBytes:Int):Void {}

	public function destroyBuffer(handle:Int):Void {}

	public function createShader(source:ShaderSource):Int
		return next++;

	public function destroyShader(handle:Int):Void {}

	public function createPipeline(desc:PipelineDesc):Int
		return next++;

	public function destroyPipeline(handle:Int):Void {}

	public function beginShadowPass(map:Int, layer:Int):Void {}

	public function beginTargetPass(target:Int, clearColor:Int):Void {}

	public function endTargetPass():Void {}

	public function beginFrame(width:Int, height:Int, clearColor:Int):Void {}

	public function applyScissor(x:Int, y:Int, w:Int, h:Int):Void {}

	public function resetScissor():Void {}

	public function applyViewport(x:Int, y:Int, w:Int, h:Int):Void {}

	public function draw(pipeline:Int, buffers:Array<Int>, indices:Int, first:Int, count:Int, firstInstance:Int, instanceCount:Int, textures:Array<Int>,
		samplings:Array<Sampling>, uniforms:Array<Null<Bytes>>):Void {}

	public function endFrame():Void {}

	public function readPixels(target:Int, done:ReadPixelsResult->Void):Void
		done(Failed("No GPU"));

	public function shutdown():Void {}
}
