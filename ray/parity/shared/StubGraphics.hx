import haxe.io.Bytes;
import helix.platform.*;

// Graphics that keeps nothing: handles counted up, every call accepted.
class StubGraphics implements IGraphics {
	var next = 1;

	public function new() {}

	public var msaaSamples(get, never):Int;

	function get_msaaSamples():Int
		return 1;

	public var maxMsaaSamples(get, never):Int;

	function get_maxMsaaSamples():Int
		return 1;

	function handle():Int
		return next++;

	public function createTexture(width:Int, height:Int, levels:Array<Bytes>, format:TextureFormat = Rgba8):Int
		return handle();

	public function createCubeTexture(size:Int, levels:Array<Bytes>, format:TextureFormat):Int
		return handle();

	public function createDataTexture(width:Int, height:Int):Int
		return handle();

	public function updateDataTexture(handle:Int, data:Bytes):Void {}

	public function canSample(format:TextureFormat):Bool
		return true;

	public function createRenderTarget(width:Int, height:Int, format:TextureFormat = Rgba8, depth:Bool = true):Int
		return handle();

	public function canRender(format:TextureFormat):Bool
		return true;

	public function createShadowMap(size:Int, layers:Int):Int
		return handle();

	public function disposeTexture(handle:Int):Void {}

	public function createBuffer(capacityBytes:Int):Int
		return handle();

	public function createStaticBuffer(data:Bytes, bytes:Int, index:Bool):Int
		return handle();

	public function updateBuffer(handle:Int, data:Bytes, usedBytes:Int):Void {}

	public function disposeBuffer(handle:Int):Void {}

	public function createShader(source:ShaderSource):Int
		return handle();

	public function disposeShader(handle:Int):Void {}

	public function createPipeline(desc:PipelineDesc):Int
		return handle();

	public function disposePipeline(handle:Int):Void {}

	public function beginShadowPass(map:Int, layer:Int):Void {}

	public function beginTargetPass(target:Int, red:Float, green:Float, blue:Float, alpha:Float):Void {}

	public function endTargetPass():Void {}

	public function beginFrame(width:Int, height:Int, clearColor:Int):Void {}

	public function applyViewport(x:Int, y:Int, w:Int, h:Int):Void {}

	public function applyScissor(x:Int, y:Int, w:Int, h:Int):Void {}

	public function resetScissor():Void {}

	public function draw(pipeline:Int, buffers:Array<Int>, indices:Int, first:Int, count:Int, firstInstance:Int, instanceCount:Int, textures:Array<Int>,
		samplings:Array<Sampling>, uniforms:Array<Null<Bytes>>):Void {}

	public function endFrame():Void {}

	public function present():Void {}

	public function readPixels(target:Int, read:(pixels:Bytes, width:Int, height:Int) -> Void, failed:String->Void):Void {}

	public function dispose():Void {}
}
