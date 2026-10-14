package helix.adapters.graphics.sokol;

import helix.adapters.graphics.sokol.internal.GraphicsBridge;
import helix.graphics.BlendMode;
import helix.graphics.IGraphics;
import helix.graphics.IGraphics.ReadPixelsResult;
import helix.graphics.PipelineDesc;
import helix.graphics.Sampling;
import helix.graphics.ShaderSource;
import helix.graphics.TextureFormat;
import haxe.io.Bytes;

/** IGraphics on sokol_gfx for native hxcpp builds: what it is given (a ShaderSource's GLSL 410, a PipelineDesc) passed to the C bridge as
	plain data; it knows no program, layout or pipeline of HeliX's own. A call the bridge refuses throws. */
class SokolGraphicsAdapter implements IGraphics {
	/** Sets up sokol_gfx; the window and its GL context must already exist. */
	public function new() {
		GraphicsBridge.setup();
	}

	static function pointer(data:Bytes):cpp.RawPointer<cpp.UInt8>
		return cpp.Pointer.arrayElem(data.getData(), 0).raw;

	static function valid(handle:Int):Int {
		if (handle == 0)
			throw "Sokol resource creation failed";
		return handle;
	}

	public function createTexture(width:Int, height:Int, levels:Array<Bytes>, format:TextureFormat = Rgba8):Int {
		if (levels.length == 0 || !canSample(format))
			throw "Invalid texture";
		var packed = packLevels(levels);
		return valid(GraphicsBridge.texture(width, height, pointer(packed), packed.length, levels.length, format));
	}

	public function createCubeTexture(size:Int, levels:Array<Bytes>, format:TextureFormat):Int {
		if (levels.length == 0 || !canSample(format))
			throw "Invalid cube texture";
		var packed = packLevels(levels);
		return valid(GraphicsBridge.cubeTexture(size, pointer(packed), packed.length, levels.length, format));
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
		return valid(GraphicsBridge.dataTexture(width, height));

	public function updateDataTexture(handle:Int, data:Bytes):Void
		if (data.length == 0 || GraphicsBridge.updateData(handle, pointer(data), data.length) != 1)
			throw "Invalid native data texture update";

	public function canSample(format:TextureFormat):Bool
		return GraphicsBridge.canSample(format) == 1;

	public function createBuffer(capacityBytes:Int):Int
		return valid(GraphicsBridge.buffer(capacityBytes));

	public function createStaticBuffer(data:Bytes, bytes:Int, index:Bool):Int {
		if (bytes <= 0 || bytes > data.length)
			throw "Invalid static buffer";
		return valid(GraphicsBridge.staticBuffer(pointer(data), bytes, index ? 1 : 0));
	}

	// Textures, samplings and uniform blocks by slot as the bridge reads them: two arrays, and the blocks' bytes one after another.
	static function pack(textures:Array<Int>, samplings:Array<Sampling>, uniforms:Array<Null<Bytes>>):{
		handles:haxe.ds.Vector<cpp.UInt32>,
		modes:haxe.ds.Vector<Int>,
		uniforms:Bytes,
		bytes:Int
	} {
		var total = 0;
		for (block in uniforms)
			if (block != null)
				total += block.length;
		var packed = Bytes.alloc(total < 4 ? 4 : total), at = 0;
		for (block in uniforms)
			if (block != null) {
				packed.blit(at, block, 0, block.length);
				at += block.length;
			}
		var handles = new haxe.ds.Vector<cpp.UInt32>(textures.length < 1 ? 1 : textures.length),
			modes = new haxe.ds.Vector<Int>(textures.length < 1 ? 1 : textures.length);
		for (i in 0...textures.length) {
			handles[i] = textures[i];
			modes[i] = samplings[i];
		}
		return {
			handles: handles,
			modes: modes,
			uniforms: packed,
			bytes: total
		};
	}

	public function createPipeline(desc:PipelineDesc):Int {
		// The description as the bridge reads it: the state, then each buffer's stride, step and attributes.
		var ints = [
			desc.shader,
			desc.primitive,
			desc.indexed ? 1 : 0,
			desc.blend,
			desc.depthTest ? 1 : 0,
			desc.depthWrite ? 1 : 0,
			desc.cullBack ? 1 : 0,
			desc.clockwise ? 1 : 0,
			desc.depthOnly ? 1 : 0,
			desc.flip,
			desc.buffers.length
		];
		for (b in desc.buffers) {
			ints.push(b.stride);
			ints.push(b.instanced ? 1 : 0);
			ints.push(b.attributes.length);
			for (a in b.attributes) {
				ints.push(a.slot);
				ints.push(a.components);
				ints.push(a.offset);
			}
		}
		var packed = haxe.ds.Vector.fromArrayCopy(ints);
		return valid(GraphicsBridge.pipeline(cpp.Pointer.ofArray(packed.toData()).raw, ints.length));
	}

	public function createShader(source:ShaderSource):Int {
		// The layout the bridge reads, a line each: attributes, uniform blocks, textures.
		var lines = [for (i in 0...source.attributes.length) 'a $i ${source.attributes[i]}'];
		for (b in source.uniformBlocks)
			lines.push('u ${b.slot} ${b.stage.charAt(0)} ${b.size} ${b.vec4s} ${b.glslName}');
		for (t in source.textures)
			lines.push('${t.shadow ? "s" : t.cube ? "c" : t.data ? "d" : "t"} ${t.slot} ${t.stage.charAt(0)} ${t.glslName}');
		// Typed first: an anonymous structure's fields reach C++ as variants.
		var vertex:String = source.glsl410.vertex,
			fragment:String = source.glsl410.fragment,
			layout:String = lines.join("\n");
		var handle = GraphicsBridge.shader(cpp.ConstCharStar.fromString(vertex), cpp.ConstCharStar.fromString(fragment), cpp.ConstCharStar.fromString(layout));
		if (handle == 0)
			throw "The shader didn't build (see the log)";
		return handle;
	}

	public function destroyShader(handle:Int):Void
		if (GraphicsBridge.destroy(3, handle) != 1)
			throw "Invalid native shader";

	public function updateBuffer(handle:Int, data:Bytes, usedBytes:Int):Void {
		if (usedBytes > data.length || usedBytes < 0 || GraphicsBridge.update(handle, pointer(data), usedBytes) != 1)
			throw "Invalid native upload";
	}

	public function createRenderTarget(width:Int, height:Int):Int
		return valid(GraphicsBridge.target(width, height));

	public function createShadowMap(size:Int, layers:Int):Int
		return valid(GraphicsBridge.shadowMap(size, layers));

	public function beginShadowPass(map:Int, layer:Int):Void
		if (GraphicsBridge.beginShadow(map, layer) != 1)
			throw "Invalid native shadow pass";

	public function beginTargetPass(target:Int, clearColor:Int):Void
		if (GraphicsBridge.beginTarget(target, clearColor) != 1)
			throw "Invalid native target pass";

	public function endTargetPass():Void
		if (GraphicsBridge.endTarget() != 1)
			throw "No native target pass open";

	public function beginFrame(width:Int, height:Int, clearColor:Int):Void {
		if (GraphicsBridge.begin(width, height, clearColor) != 1)
			throw "Invalid native pass";
	}

	public function setViewport(x:Int, y:Int, w:Int, h:Int):Void {
		if (GraphicsBridge.viewport(x, y, w, h) != 1)
			throw "Invalid native viewport";
	}

	public function draw(pipeline:Int, buffers:Array<Int>, indices:Int, first:Int, count:Int, firstInstance:Int, instanceCount:Int, textures:Array<Int>,
			samplings:Array<Sampling>, uniforms:Array<Null<Bytes>>):Void {
		var args = pack(textures, samplings, uniforms),
			handles = new haxe.ds.Vector<cpp.UInt32>(buffers.length < 1 ? 1 : buffers.length);
		for (i in 0...buffers.length)
			handles[i] = buffers[i];
		if (GraphicsBridge.draw(pipeline, cpp.Pointer.ofArray(handles.toData()).raw, buffers.length, indices, first, count, firstInstance, instanceCount,
			cpp.Pointer.ofArray(args.handles.toData()).raw, cpp.Pointer.ofArray(args.modes.toData()).raw, textures.length, pointer(args.uniforms),
			args.bytes) != 1)
			throw "Invalid native draw";
	}

	public function endFrame():Void
		GraphicsBridge.end();

	public function readPixels(target:Int, done:ReadPixelsResult->Void):Void {
		var width = GraphicsBridge.readWidth(target),
			height = GraphicsBridge.readHeight(target);
		if (target != 0 && width == 0)
			throw "Invalid render target";
		if (width == 0) {
			done(Failed("No frame has ended"));
			return;
		}
		var rgba = Bytes.alloc(width * height * 4);
		if (GraphicsBridge.readPixels(target, cpp.Pointer.arrayElem(rgba.getData(), 0).raw) != 1)
			throw "Native read back failed";
		done(Read(width, height, rgba));
	}

	public function destroyBuffer(handle:Int):Void
		if (GraphicsBridge.destroy(0, handle) != 1)
			throw "Invalid buffer";

	public function destroyTexture(handle:Int):Void
		if (GraphicsBridge.destroy(1, handle) != 1)
			throw "Invalid texture";

	public function destroyPipeline(handle:Int):Void
		if (GraphicsBridge.destroy(2, handle) != 1)
			throw "Invalid pipeline";

	public function shutdown():Void
		GraphicsBridge.shutdown();
}
