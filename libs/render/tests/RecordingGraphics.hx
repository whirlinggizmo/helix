import haxe.io.Bytes;
import helix.platform.*;

/** Stands in for the GPU in helix-render's tests: what the renderer asks of it recorded as lines of text (passes, viewports, scissors,
	updates, draws), the textures, buffers and pipelines it holds, and each stream buffer's bytes as last uploaded, so a test reads the
	vertices a draw submitted, and its second buffer's (a run of sprites' records). */
class RecordingGraphics implements IGraphics {
	var next = 1;
	var appended = new Map<Int, Bool>();

	/** Gets what was asked, in order, one line each. */
	public final log:Array<String> = [];

	/** Gets the draws made, in order: their pipeline's description, buffers, range, textures and uniform blocks as submitted. */
	public final draws:Array<{
		pipeline:PipelineDesc,
		buffers:Array<Int>,
		bufferOffsets:Array<Int>,
		indexBuffer:Int,
		first:Int,
		count:Int,
		firstInstance:Int,
		instanceCount:Int,
		textures:Array<Int>,
		uniforms:Array<Null<Bytes>>,
		vertices:Null<Bytes>,
		instances:Null<Bytes>
	}> = [];

	/** Gets the textures held, by handle: their width and height. */
	public final textures = new Map<Int, {width:Int, height:Int, target:Bool}>();

	/** Gets each buffer's bytes as last uploaded or made, by handle. */
	public final buffers = new Map<Int, Bytes>();

	/** Gets the pipelines held, by handle. */
	public final pipelines = new Map<Int, PipelineDesc>();

	/** Gets the programs held, by handle. */
	public final shaders = new Map<Int, ShaderSource>();

	/** Creates the stand-in. */
	public function new() {}

	/** Gets 4. */
	public var msaaSampleCount(get, never):Int;

	function get_msaaSampleCount():Int
		return 4;

	/** Gets 4. */
	public var textureBytes(get, never):Float;

	function get_textureBytes():Float
		return 0;

	public var bufferBytes(get, never):Float;

	function get_bufferBytes():Float
		return 0;

	public var maxMsaaSampleCount(get, never):Int;

	function get_maxMsaaSampleCount():Int
		return 4;

	public var device(get, never):helix.platform.GraphicsDevice;

	function get_device():helix.platform.GraphicsDevice
		return {
			api: "",
			vendor: "",
			renderer: "",
			version: "",
			shadingLanguage: ""
		};

	/** Forgets what was recorded. */
	public function forget():Void {
		log.resize(0);
		draws.resize(0);
	}

	public function createTextureFromImage(image:helix.platform.IDecodedImage):Int
		return createTexture(image.width, image.height, [image.pixels()]);

	public function createTexture(width:Int, height:Int, levels:Array<Bytes>, format:TextureFormat = Rgba8):Int {
		textures.set(next, {width: width, height: height, target: false});
		return next++;
	}

	public function createCubeTexture(size:Int, levels:Array<Bytes>, format:TextureFormat):Int {
		textures.set(next, {width: size, height: size, target: false});
		return next++;
	}

	public function createDataTexture(width:Int, height:Int):Int {
		textures.set(next, {width: width, height: height, target: false});
		return next++;
	}

	public function updateTexture(handle:Int, x:Int, y:Int, width:Int, height:Int, data:Bytes):Void
		log.push('update $handle $x $y $width $height');

	public function canSample(format:TextureFormat):Bool
		return true;

	/** Gets 4 for every format. */
	public function getMaxRenderTargetMsaaSampleCount(format:TextureFormat):Int
		return 4;

	public function createRenderTarget(width:Int, height:Int, format:TextureFormat = Rgba8, depth:Bool = true, msaaSampleCount:Int = 0):Int {
		textures.set(next, {width: width, height: height, target: true});
		log.push('target $next $width $height samples $msaaSampleCount');
		return next++;
	}

	public function canRender(format:TextureFormat):Bool
		return true;

	public function createShadowMap(size:Int, layerCount:Int):Int {
		textures.set(next, {width: size, height: size, target: true});
		return next++;
	}

	public function disposeTexture(handle:Int):Void {
		if (!textures.exists(handle))
			throw 'unknown texture $handle';
		textures.remove(handle);
		log.push('dispose texture $handle');
	}

	public function createBuffer(capacityBytes:Int):Int {
		buffers.set(next, Bytes.alloc(capacityBytes));
		return next++;
	}

	public function createStaticBuffer(data:Bytes, bytes:Int, index:Bool):Int {
		buffers.set(next, data.sub(0, bytes));
		return next++;
	}

	public function updateBuffer(handle:Int, data:Bytes, usedBytes:Int):Void {
		if (!active)
			throw 'updateBuffer outside a pass';
		buffers.set(handle, data.sub(0, usedBytes));
	}

	public function appendBuffer(handle:Int, data:Bytes, usedBytes:Int):Int {
		if (!active)
			throw 'appendBuffer outside a pass';
		var before = appended.exists(handle) ? buffers.get(handle) : Bytes.alloc(0),
			grown = Bytes.alloc(before.length + usedBytes);
		grown.blit(0, before, 0, before.length);
		grown.blit(before.length, data, 0, usedBytes);
		buffers.set(handle, grown);
		appended.set(handle, true);
		return before.length;
	}

	public function disposeBuffer(handle:Int):Void
		buffers.remove(handle);

	public function createShader(source:ShaderSource):Int {
		shaders.set(next, source);
		return next++;
	}

	public function disposeShader(handle:Int):Void
		shaders.remove(handle);

	public function createPipeline(desc:PipelineDesc):Int {
		pipelines.set(next, desc);
		return next++;
	}

	public function disposePipeline(handle:Int):Void
		pipelines.remove(handle);

	var active = false;

	public function beginShadowPass(map:Int, layerIndex:Int):Void {
		active = true;
		log.push('shadow $map $layerIndex');
	}

	public function beginTargetPass(target:Int, red:Float, green:Float, blue:Float, alpha:Float):Void {
		active = true;
		log.push('begin target $target clear ${Math.round(red * 255)} ${Math.round(green * 255)} ${Math.round(blue * 255)} ${Math.round(alpha * 255)}');
	}

	public function resumeTargetPass(target:Int):Void {
		active = true;
		log.push('resume target $target');
	}

	public function endTargetPass():Void {
		active = false;
		log.push('end target');
	}

	public function beginFrame(width:Int, height:Int, clearColor:Int):Void {
		active = true;
		appended.clear();
		log.push('begin screen $width $height clear ${StringTools.hex(clearColor, 8)}');
	}

	public function applyViewport(x:Int, y:Int, w:Int, h:Int):Void
		log.push('viewport $x $y $w $h');

	public function applyScissor(x:Int, y:Int, w:Int, h:Int):Void
		log.push('scissor $x $y $w $h');

	public function resetScissor():Void
		log.push('reset scissor');

	public function draw(pipeline:Int, buffers:Array<Int>, bufferOffsets:Null<Array<Int>>, indexBuffer:Int, firstElementIndex:Int, elementCount:Int,
			firstInstanceIndex:Int, instanceCount:Int, textures:Array<Int>, samplings:Array<Sampling>, uniforms:Array<Null<Bytes>>):Void {
		if (!active)
			throw 'draw outside a pass';
		for (t in textures)
			if (t != 0 && !this.textures.exists(t))
				throw 'draw of unknown texture $t';
		draws.push({
			pipeline: pipelines.get(pipeline),
			buffers: buffers.copy(),
			bufferOffsets: bufferOffsets == null ? [] : bufferOffsets.copy(),
			indexBuffer: indexBuffer,
			first: firstElementIndex,
			count: elementCount,
			firstInstance: firstInstanceIndex,
			instanceCount: instanceCount,
			textures: textures.copy(),
			uniforms: [for (u in uniforms) u == null ? null : u.sub(0, u.length)],
			vertices: buffers.length > 0 && this.buffers.exists(buffers[0]) ? this.buffers.get(buffers[0]) : null,
			instances: buffers.length > 1 && this.buffers.exists(buffers[1]) ? this.buffers.get(buffers[1]) : null});
		log.push('draw ${pipelines.get(pipeline).primitive} $elementCount textures ${textures.join(",")}');
	}

	public function endFrame():Void {
		active = false;
		log.push('end screen');
	}

	public function present():Void {}

	public function readPixels(handle:Int, read:(pixels:Bytes, width:Int, height:Int) -> Void, failed:String->Void):Void
		failed("no pixels here");

	public function dispose():Void {}
}
