package helix.platform.adapters.shared;

import helix.platform.ColorChannels;
import helix.platform.IGraphics;
import helix.platform.PipelineDesc;
import helix.platform.Sampling;
import helix.platform.TextureFormat;
import haxe.io.Bytes;

/** Provides `IGraphics` for the native graphics adapters, passing each call as plain data to the C that each implements (graphics.h,
	through `GraphicsDeviceBridge`).

	A subclass sets up its C, builds programs from the dialect its C takes (`createShader`) and shuts down. A call the C refuses throws. */
@:noCompletion
abstract class NativeGraphics implements IGraphics {
	/** Returns a program's layout as the C reads it, a line each: its attributes (`a <slot> <name>`), its uniform blocks
		(`u <slot> <v|f|b> <size> <name>`, b for a block both stages read), each followed by its members (`m <type> <offset> <count>
		<stride> <path>`), and its textures (`t|s|c|d <slot> <v|f> <name>`). */
	static function layout(source:helix.platform.ShaderSource):String {
		// A matrix's later columns have no name: the C takes them by slot.
		var lines = [
			for (i in 0...source.attributes.length)
				if (source.attributes[i] != "") 'a $i ${source.attributes[i]}'
		];
		for (b in source.uniformBlocks) {
			lines.push('u ${b.slot} ${b.stage.charAt(0)} ${b.size} ${b.glslName}');
			for (m in b.members)
				lines.push('m ${m.type} ${m.offset} ${m.elementCount} ${m.stride} ${m.glslName}');
		}
		for (t in source.textures)
			lines.push('${t.shadow ? "s" : t.cube ? "c" : t.data ? "d" : "t"} ${t.slot} ${t.stage.charAt(0)} ${t.glslName}');
		return lines.join("\n");
	}

	static function pointer(data:Bytes):cpp.RawPointer<cpp.UInt8>
		return cpp.Pointer.arrayElem(data.getData(), 0).raw;

	static function valid(handle:Int):Int {
		if (handle == 0)
			throw "Native resource creation failed";
		return handle;
	}

	public function createTexture(width:Int, height:Int, levels:Array<Bytes>, format:TextureFormat = Rgba8):Int {
		if (levels.length == 0 || !canSample(format))
			throw "Invalid texture";
		var packed = packLevels(levels);
		return valid(GraphicsDeviceBridge.texture(width, height, pointer(packed), packed.length, levels.length, format));
	}

	public function createTextureFromImage(image:helix.platform.IDecodedImage):Int
		return createTexture(image.width, image.height, [image.pixels()]);

	public function createCubeTexture(size:Int, levels:Array<Bytes>, format:TextureFormat):Int {
		if (levels.length == 0 || !canSample(format))
			throw "Invalid cube texture";
		var packed = packLevels(levels);
		return valid(GraphicsDeviceBridge.cubeTexture(size, pointer(packed), packed.length, levels.length, format));
	}

	// Levels one after another in one buffer: the bridge points each mip level into it.
	static function packLevels(levels:Array<Bytes>):Bytes {
		var total = 0;
		for (level in levels)
			total += level.length;
		var packed = Bytes.alloc(total), at = 0;
		for (level in levels) {
			packed.blit(at, level, 0, level.length);
			at += level.length;
		}
		return packed;
	}

	public function createDataTexture(width:Int, height:Int):Int
		return valid(GraphicsDeviceBridge.dataTexture(width, height));

	public function updateTexture(handle:Int, x:Int, y:Int, width:Int, height:Int, data:Bytes):Void
		if (data.length == 0 || GraphicsDeviceBridge.updateTexture(handle, x, y, width, height, pointer(data), data.length) != 1)
			throw "Invalid native texture update";

	public function canSample(format:TextureFormat):Bool
		return GraphicsDeviceBridge.canSample(format) == 1;

	public var msaaSampleCount(get, never):Int;

	function get_msaaSampleCount():Int
		return GraphicsDeviceBridge.msaaSamples();

	public var maxMsaaSampleCount(get, never):Int;

	function get_maxMsaaSampleCount():Int
		return GraphicsDeviceBridge.maxMsaaSamples();

	public var device(get, never):helix.platform.GraphicsDevice;

	function get_device():helix.platform.GraphicsDevice
		return {
			api: GraphicsDeviceBridge.deviceInfo(0).toString(),
			vendor: GraphicsDeviceBridge.deviceInfo(1).toString(),
			renderer: GraphicsDeviceBridge.deviceInfo(2).toString(),
			version: GraphicsDeviceBridge.deviceInfo(3).toString(),
			shadingLanguage: GraphicsDeviceBridge.deviceInfo(4).toString()
		};

	public function createBuffer(capacityBytes:Int):Int
		return valid(GraphicsDeviceBridge.buffer(capacityBytes));

	public function createStaticBuffer(data:Bytes, bytes:Int, index:Bool):Int {
		if (bytes <= 0 || bytes > data.length)
			throw "Invalid static buffer";
		return valid(GraphicsDeviceBridge.staticBuffer(pointer(data), bytes, index ? 1 : 0));
	}

	// A draw's arguments as the bridge reads them, kept from draw to draw and grown as needed, so a draw allocates nothing: the texture
	// handles and their samplings, the buffer handles and their offsets, and the uniform blocks' bytes one after another by their index in
	// uniforms (stage and slot: the vertex stage's 0 to 3, the fragment stage's 4 to 7), a block both read at both. The bridge reads them
	// during the call and keeps nothing of them.
	var textureHandles = new haxe.ds.Vector<cpp.UInt32>(16);
	var textureModes = new haxe.ds.Vector<Int>(16);
	var bufferHandles = new haxe.ds.Vector<cpp.UInt32>(8);
	var bufferOffsetsPacked = new haxe.ds.Vector<Int>(8);
	var packed = Bytes.alloc(1024);

	// Packs the uniform blocks into `packed`, grown when they outgrow it, and returns their total bytes.
	function pack(uniforms:Array<Null<Bytes>>):Int {
		var total = 0;
		for (block in uniforms)
			if (block != null)
				total += block.length;
		if (packed.length < total) {
			var size = packed.length;
			while (size < total)
				size *= 2;
			packed = Bytes.alloc(size);
		}
		var at = 0;
		for (block in uniforms)
			if (block != null) {
				packed.blit(at, block, 0, block.length);
				at += block.length;
			}
		return total;
	}

	// The programs, by handle, as their sources describe them: whether Points pipelines may draw one, and its attributes' types, which
	// a pipeline's layout must feed. Set by a subclass's createShader.
	final programs = new Map<Int, helix.platform.ShaderSource>();

	public function createPipeline(desc:PipelineDesc):Int {
		var program = programs.get(desc.shader);
		if (program == null)
			throw "Invalid pipeline shader";
		if (desc.primitive == helix.platform.Primitive.Points && program.points != true)
			throw "Invalid pipeline: Points over a program compiled without ShaderCompileOptions.points";
		PipelineLayout.check(desc, program.attributeTypes);
		// The description as the bridge reads it: the state, then each buffer's stride, step and attributes.
		var colorWrite:Int = desc.colorWrite == null ? (All : ColorChannels) : desc.colorWrite;
		var ints:Array<Int> = [
			desc.shader,
			desc.primitive,
			desc.indexed ? 1 : 0,
			desc.blend,
			desc.depthTest,
			desc.depthWrite ? 1 : 0,
			desc.cull,
			desc.clockwise ? 1 : 0,
			desc.depthOnly ? 1 : 0,
			desc.flip,
			colorWrite,
			desc.flipBlockSlot == null ? 0 : desc.flipBlockSlot,
			desc.flipOffset == null ? 0 : desc.flipOffset,
			desc.buffers.length
		];
		for (b in desc.buffers) {
			ints.push(b.stride);
			ints.push(b.instanced ? 1 : 0);
			ints.push(b.attributes.length);
			for (a in b.attributes) {
				ints.push(a.slot);
				ints.push(a.format);
				ints.push(a.offset);
			}
		}
		// The constants no buffer feeds: each slot, then its four floats' bits, the missing ones 0, 0, 1 as (0, 0, 0, 1) has them.
		var constants = desc.attributeConstants == null ? [] : desc.attributeConstants;
		ints.push(constants.length);
		for (c in constants) {
			ints.push(c.slot);
			for (i in 0...4)
				ints.push(haxe.io.FPHelper.floatToI32(i < c.values.length ? c.values[i] : i == 3 ? 1 : 0));
		}
		// The depth biases, as their floats' bits.
		ints.push(haxe.io.FPHelper.floatToI32(desc.depthBias == null ? 0 : desc.depthBias));
		ints.push(haxe.io.FPHelper.floatToI32(desc.depthSlopeBias == null ? 0 : desc.depthSlopeBias));
		var packed = haxe.ds.Vector.fromArrayCopy(ints);
		return valid(GraphicsDeviceBridge.pipeline(cpp.Pointer.ofArray(packed.toData()).raw, ints.length));
	}

	public function disposeShader(handle:Int):Void {
		if (GraphicsDeviceBridge.disposeResource(3, handle) != 1)
			throw "Invalid native shader";
		programs.remove(handle);
	}

	public function updateBuffer(handle:Int, data:Bytes, usedBytes:Int):Void {
		if (usedBytes > data.length || usedBytes < 0 || GraphicsDeviceBridge.update(handle, pointer(data), usedBytes) != 1)
			throw "Invalid native upload";
	}

	public function appendBuffer(handle:Int, data:Bytes, usedBytes:Int):Int {
		var at = usedBytes > data.length || usedBytes < 0 ? -1 : GraphicsDeviceBridge.append(handle, pointer(data), usedBytes);
		if (at < 0)
			throw "Invalid native append";
		return at;
	}

	public function getMaxRenderTargetMsaaSampleCount(format:TextureFormat):Int
		return GraphicsDeviceBridge.maxTargetSamples(format);

	public function createRenderTarget(width:Int, height:Int, format:TextureFormat = Rgba8, depth:Bool = true, msaaSampleCount:Int = 0):Int {
		if (msaaSampleCount < 0)
			throw "Invalid native render target";
		// The count asked (0: the screen's), which the C rounds down to one the GPU takes for the format.
		return valid(GraphicsDeviceBridge.target(width, height, format, depth ? 1 : 0,
			msaaSampleCount == 0 ? GraphicsDeviceBridge.msaaSamples() : msaaSampleCount));
	}

	public function canRender(format:TextureFormat):Bool
		return GraphicsDeviceBridge.canRender(format) == 1;

	public function createShadowMap(size:Int, layerCount:Int):Int
		return valid(GraphicsDeviceBridge.shadowMap(size, layerCount));

	public function beginShadowPass(map:Int, layerIndex:Int):Void
		if (GraphicsDeviceBridge.beginShadow(map, layerIndex) != 1)
			throw "Invalid native shadow pass";

	public function beginTargetPass(target:Int, red:Float, green:Float, blue:Float, alpha:Float):Void
		if (GraphicsDeviceBridge.beginTarget(target, red, green, blue, alpha) != 1)
			throw "Invalid native target pass";

	public function resumeTargetPass(target:Int):Void
		if (GraphicsDeviceBridge.resumeTarget(target) != 1)
			throw "Invalid native target pass";

	public function endTargetPass():Void
		if (GraphicsDeviceBridge.endTarget() != 1)
			throw "No native target pass open";

	public function beginFrame(width:Int, height:Int, clearColor:Int):Void {
		if (GraphicsDeviceBridge.begin(width, height, clearColor) != 1)
			throw "Invalid native pass";
	}

	public function applyScissor(x:Int, y:Int, w:Int, h:Int):Void
		if (GraphicsDeviceBridge.scissor(x, y, w, h, 1) != 1)
			throw "Invalid native scissor";

	public function resetScissor():Void
		if (GraphicsDeviceBridge.scissor(0, 0, 0, 0, 0) != 1)
			throw "No native pass";

	public function applyViewport(x:Int, y:Int, w:Int, h:Int):Void {
		if (GraphicsDeviceBridge.viewport(x, y, w, h) != 1)
			throw "Invalid native viewport";
	}

	public function draw(pipeline:Int, buffers:Array<Int>, bufferOffsets:Null<Array<Int>>, indexBuffer:Int, firstElementIndex:Int, elementCount:Int,
			firstInstanceIndex:Int, instanceCount:Int, textures:Array<Int>, samplings:Array<Sampling>, uniforms:Array<Null<Bytes>>):Void {
		var bytes = pack(uniforms);
		if (textureHandles.length < textures.length) {
			textureHandles = new haxe.ds.Vector<cpp.UInt32>(textures.length);
			textureModes = new haxe.ds.Vector<Int>(textures.length);
		}
		for (i in 0...textures.length) {
			textureHandles[i] = textures[i];
			textureModes[i] = i < samplings.length ? samplings[i] : 0;
		}
		if (bufferHandles.length < buffers.length) {
			bufferHandles = new haxe.ds.Vector<cpp.UInt32>(buffers.length);
			bufferOffsetsPacked = new haxe.ds.Vector<Int>(buffers.length);
		}
		for (i in 0...buffers.length) {
			bufferHandles[i] = buffers[i];
			bufferOffsetsPacked[i] = bufferOffsets != null && i < bufferOffsets.length ? bufferOffsets[i] : 0;
		}
		var drawn = GraphicsDeviceBridge.draw(pipeline, cpp.Pointer.ofArray(bufferHandles.toData()).raw,
			cpp.Pointer.ofArray(bufferOffsetsPacked.toData()).raw, buffers.length, indexBuffer, firstElementIndex, elementCount, firstInstanceIndex,
			instanceCount, cpp.Pointer.ofArray(textureHandles.toData()).raw, cpp.Pointer.ofArray(textureModes.toData()).raw, textures.length, pointer(packed),
			bytes);
		if (drawn == -1)
			throw "Invalid native draw: a texture is the pass's own target, which a draw into it can't sample";
		if (drawn != 1)
			throw "Invalid native draw";
	}

	public function endFrame():Void
		GraphicsDeviceBridge.end();

	public function present():Void
		GraphicsDeviceBridge.present();

	public function readPixels(handle:Int, read:(pixels:Bytes, width:Int, height:Int) -> Void, failed:String->Void):Void {
		var width = GraphicsDeviceBridge.readWidth(handle),
			height = GraphicsDeviceBridge.readHeight(handle);
		if (handle != 0 && width == 0)
			throw "Invalid texture to read";
		if (width == 0) {
			failed("No frame has ended");
			return;
		}
		var rgba = Bytes.alloc(width * height * 4);
		if (GraphicsDeviceBridge.readPixels(handle, cpp.Pointer.arrayElem(rgba.getData(), 0).raw) != 1)
			throw "Native read back failed";
		read(rgba, width, height);
	}

	public function disposeBuffer(handle:Int):Void
		if (GraphicsDeviceBridge.disposeResource(0, handle) != 1)
			throw "Invalid buffer";

	public function disposeTexture(handle:Int):Void
		if (GraphicsDeviceBridge.disposeResource(1, handle) != 1)
			throw "Invalid texture";

	public function disposePipeline(handle:Int):Void
		if (GraphicsDeviceBridge.disposeResource(2, handle) != 1)
			throw "Invalid pipeline";
}
