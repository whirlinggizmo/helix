import haxe.io.Bytes;
import helix.platform.*;

/** Stands in for the GPU in the services' tests: programs and pipelines kept as made (each pipeline's description), disposing a program
	disposes its pipelines, and a program refused while `refuseShaders` is set. Textures and buffers are handles alone; draws are counted. */
class FakeGraphics implements IGraphics {
	var next = 1;

	/** Gets the programs made and not disposed, by handle. */
	public final shaders = new Map<Int, ShaderSource>();

	/** Gets the pipelines made and not disposed, by handle. */
	public final pipelines = new Map<Int, PipelineDesc>();

	/** Gets how many programs have been made. */
	public var shaderCount(default, null) = 0;

	/** Gets how many pipelines have been made. */
	public var pipelineCount(default, null) = 0;

	/** Gets or sets whether `createShader` refuses, as a GPU refusing a program does. */
	public var refuseShaders = false;

	/** Gets the draws made: their pipeline and uniforms' bytes, copied. */
	public final draws:Array<{pipeline:Int, uniforms:Array<Null<Bytes>>, textures:Array<Int>}> = [];

	/** Creates the stand-in. */
	public function new() {}

	/** Gets 1: no multisampling. */
	public var msaaSampleCount(get, never):Int;

	function get_msaaSampleCount():Int
		return 1;

	/** Gets 1. */
	public var maxMsaaSampleCount(get, never):Int;

	function get_maxMsaaSampleCount():Int
		return 1;

	public var device(get, never):helix.platform.GraphicsDevice;

	function get_device():helix.platform.GraphicsDevice
		return {
			api: "",
			vendor: "",
			renderer: "",
			version: "",
			shadingLanguage: ""
		};

	public function createTexture(width:Int, height:Int, levels:Array<Bytes>, format:TextureFormat = Rgba8):Int
		return next++;

	public function createCubeTexture(size:Int, levels:Array<Bytes>, format:TextureFormat):Int
		return next++;

	public function createDataTexture(width:Int, height:Int):Int
		return next++;

	public function updateTexture(handle:Int, x:Int, y:Int, width:Int, height:Int, data:Bytes):Void {}

	public function canSample(format:TextureFormat):Bool
		return true;

	public function createRenderTarget(width:Int, height:Int, format:TextureFormat = Rgba8, depth:Bool = true, msaaSampleCount:Int = 0):Int
		return next++;

	public function getMaxRenderTargetMsaaSampleCount(format:TextureFormat):Int
		return 1;

	public function canRender(format:TextureFormat):Bool
		return true;

	public function createShadowMap(size:Int, layerCount:Int):Int
		return next++;

	public function disposeTexture(handle:Int):Void {}

	public function createBuffer(capacityBytes:Int):Int
		return next++;

	public function createStaticBuffer(data:Bytes, bytes:Int, index:Bool):Int
		return next++;

	public function updateBuffer(handle:Int, data:Bytes, usedBytes:Int):Void {}

	public function appendBuffer(handle:Int, data:Bytes, usedBytes:Int):Int
		return 0;

	public function disposeBuffer(handle:Int):Void {}

	public function createShader(source:ShaderSource):Int {
		if (refuseShaders)
			throw "the program doesn't build";
		shaderCount++;
		var h = next++;
		shaders.set(h, source);
		return h;
	}

	public function disposeShader(handle:Int):Void {
		if (!shaders.remove(handle))
			throw "Invalid shader";
		for (h => p in pipelines)
			if (p.shader == handle)
				pipelines.remove(h);
	}

	public function createPipeline(desc:PipelineDesc):Int {
		if (!shaders.exists(desc.shader))
			throw "Invalid pipeline shader";
		pipelineCount++;
		var h = next++;
		pipelines.set(h, desc);
		return h;
	}

	public function disposePipeline(handle:Int):Void
		pipelines.remove(handle);

	public function beginShadowPass(map:Int, layerIndex:Int):Void {}

	public function beginTargetPass(target:Int, red:Float, green:Float, blue:Float, alpha:Float):Void {}

	public function resumeTargetPass(target:Int):Void {}

	public function endTargetPass():Void {}

	public function beginFrame(width:Int, height:Int, clearColor:Int):Void {}

	public function applyViewport(x:Int, y:Int, w:Int, h:Int):Void {}

	public function applyScissor(x:Int, y:Int, w:Int, h:Int):Void {}

	public function resetScissor():Void {}

	public function draw(pipeline:Int, buffers:Array<Int>, bufferOffsets:Null<Array<Int>>, indexBuffer:Int, firstElementIndex:Int, elementCount:Int,
			firstInstanceIndex:Int, instanceCount:Int, textures:Array<Int>, samplings:Array<Sampling>, uniforms:Array<Null<Bytes>>):Void {
		if (!pipelines.exists(pipeline))
			throw "Invalid draw";
		draws.push({pipeline: pipeline, uniforms: [for (u in uniforms) u == null ? null : u.sub(0, u.length)], textures: textures.copy()});
	}

	public function endFrame():Void {}

	public function present():Void {}

	public function readPixels(handle:Int, read:(pixels:Bytes, width:Int, height:Int) -> Void, failed:String->Void):Void
		failed("no pixels here");

	public function dispose():Void {}
}
