import haxe.io.Bytes;
import helix.platform.*;

// Graphics that keeps nothing but which textures and buffers are live: handles counted up, every call accepted, a texture or buffer
// disposed twice (or never made) counted in `doubles`.
class CountingGraphics implements IGraphics {
	var next = 1;

	/** The textures made and not yet disposed. */
	public final textures = new Map<Int, Bool>();

	/** The buffers made and not yet disposed. */
	public final buffers = new Map<Int, Bool>();

	/** How many disposals were of a handle not live. */
	public var doubles = 0;

	function made(live:Map<Int, Bool>):Int {
		var h = next++;
		live.set(h, true);
		return h;
	}

	function gone(live:Map<Int, Bool>, h:Int):Void
		if (!live.remove(h))
			doubles++;

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
		return made(textures);

	public function createCubeTexture(size:Int, levels:Array<Bytes>, format:TextureFormat):Int
		return handle();

	public function createDataTexture(width:Int, height:Int):Int
		return handle();

	public function updateDataTexture(handle:Int, data:Bytes):Void {}

	public function canSample(format:TextureFormat):Bool
		return true;

	public function createRenderTarget(width:Int, height:Int, format:TextureFormat = Rgba8, depth:Bool = true):Int
		return made(textures);

	public function canRender(format:TextureFormat):Bool
		return true;

	public function createShadowMap(size:Int, layers:Int):Int
		return handle();

	public function disposeTexture(handle:Int):Void
		gone(textures, handle);

	public function createBuffer(capacityBytes:Int):Int
		return made(buffers);

	public function createStaticBuffer(data:Bytes, bytes:Int, index:Bool):Int
		return made(buffers);

	public function updateBuffer(handle:Int, data:Bytes, usedBytes:Int):Void {}

	public function disposeBuffer(handle:Int):Void
		gone(buffers, handle);

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
