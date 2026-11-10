import haxe.io.Bytes;
import helix.platform.*;

// Graphics that keeps nothing: handles counted up, every call accepted.
class StubGraphics implements IGraphics {
	var next = 1;

	public function new() {}

	public var msaaSampleCount(get, never):Int;

	function get_msaaSampleCount():Int
		return 1;

	public var textureBytes(get, never):Float;

	function get_textureBytes():Float
		return 0;

	public var bufferBytes(get, never):Float;

	function get_bufferBytes():Float
		return 0;

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

	function handle():Int
		return next++;

	public function createTextureFromImage(image:helix.platform.IDecodedImage):Int
		return createTexture(image.width, image.height, [image.pixels()]);

	public function createTexture(width:Int, height:Int, levels:Array<Bytes>, format:TextureFormat = Rgba8):Int
		return handle();

	public function createCubeTexture(size:Int, levels:Array<Bytes>, format:TextureFormat):Int
		return handle();

	public function createDataTexture(width:Int, height:Int):Int
		return handle();

	public function updateTexture(handle:Int, x:Int, y:Int, width:Int, height:Int, data:Bytes):Void {}

	public function canSample(format:TextureFormat):Bool
		return true;

	public function createRenderTarget(width:Int, height:Int, format:TextureFormat = Rgba8, depth:Bool = true, msaaSampleCount:Int = 0):Int
		return handle();

	public function getMaxRenderTargetMsaaSampleCount(format:TextureFormat):Int
		return 1;

	public function canRender(format:TextureFormat):Bool
		return true;

	public function createShadowMap(size:Int, layerCount:Int):Int
		return handle();

	public function disposeTexture(handle:Int):Void {}

	public function createBuffer(capacityBytes:Int):Int
		return handle();

	public function createStaticBuffer(data:Bytes, bytes:Int, index:Bool):Int
		return handle();

	public function updateBuffer(handle:Int, data:Bytes, usedBytes:Int):Void {}

	public function appendBuffer(handle:Int, data:Bytes, usedBytes:Int):Int
		return 0;

	public function disposeBuffer(handle:Int):Void {}

	public function createShader(source:ShaderSource):Int
		return handle();

	public function disposeShader(handle:Int):Void {}

	public function createPipeline(desc:PipelineDesc):Int
		return handle();

	public function disposePipeline(handle:Int):Void {}

	public function beginShadowPass(map:Int, layerIndex:Int):Void {}

	public function beginTargetPass(target:Int, red:Float, green:Float, blue:Float, alpha:Float):Void {}

	public function resumeTargetPass(target:Int):Void {}

	public function endTargetPass():Void {}

	public function beginFrame(width:Int, height:Int, clearColor:Int):Void {}

	public function applyViewport(x:Int, y:Int, w:Int, h:Int):Void {}

	public function applyScissor(x:Int, y:Int, w:Int, h:Int):Void {}

	public function resetScissor():Void {}

	public function draw(pipeline:Int, buffers:Array<Int>, bufferOffsets:Null<Array<Int>>, indexBuffer:Int, firstElementIndex:Int, elementCount:Int,
		firstInstanceIndex:Int, instanceCount:Int, textures:Array<Int>, samplings:Array<Sampling>, uniforms:Array<Null<Bytes>>):Void {}

	public function endFrame():Void {}

	public function present():Void {}

	public function readPixels(handle:Int, read:(pixels:Bytes, width:Int, height:Int) -> Void, failed:String->Void):Void {}

	public function dispose():Void {}
}
