package helix.platform.adapters.graphics.webgl2;

import haxe.io.Bytes;
import helix.platform.Blend;
import helix.platform.BlendFactor;
import helix.platform.BlendOperation;
import helix.platform.ColorChannels;
import helix.math.Color;
import helix.platform.IGraphics;
import helix.platform.PipelineDesc;
import helix.platform.DepthTest;
import helix.platform.ClipFlip;
import helix.platform.Sampling;
import helix.platform.ShaderSource;
import helix.platform.TextureFormat;
import helix.platform.adapters.shared.dom.DomPage;
import js.html.webgl.WebGL2RenderingContext;

/** Represents a render target: the framebuffer of its texture and its depth buffer (null without), its size and whether it holds half
	floats; when multisampled, the framebuffer drawn into and its color. */
private typedef Target = {
	framebuffer:Dynamic,
	cleared:Bool,
	depth:Dynamic,
	half:Bool,
	drawn:Dynamic,
	color:Dynamic,
	width:Int,
	height:Int
}

/** A program's uniform block: its binding point, which is its index in a draw's uniforms, its size, and whether the linked program kept
	it. */
private typedef ProgramBlock = {
	final point:Int;
	final size:Int;
	final bound:Bool;
}

/** Provides `IGraphics` on a canvas's WebGL2 context.

	It builds programs from a `ShaderSource`'s GLSL ES 300 and pipelines from a `PipelineDesc`. */
class WebGl2GraphicsAdapter implements IGraphics {
	var gl:WebGL2RenderingContext;

	var next = 1;
	var buffers:Map<Int, Dynamic> = [];
	var textures:Map<Int, Dynamic> = [];
	// One sampler object for each Sampling value used, made when first used.
	var samplers:Array<Dynamic> = [];
	// Whether each TextureFormat is sampled, and drawn into, once asked.
	var formats:Array<Null<Bool>> = [];
	var renderable:Array<Null<Bool>> = [];
	// Programs, by handle: the linked program, its uniform blocks' locations and sizes by slot, its textures' sampler locations by slot.
	// The placeholders for unbound slots, by kind (placeholder): 0 until made.
	var placeholders = [0, 0, 0];

	static inline final TEXTURE_PLACEHOLDER = 0;
	static inline final CUBE_PLACEHOLDER = 1;
	static inline final SHADOW_PLACEHOLDER = 2;

	var shaders:Map<Int, {
		program:Dynamic,
		blocks:Array<ProgramBlock>,
		textures:Array<Dynamic>,
		unfiltered:Array<Bool>,
		kinds:Array<Int>,
		attributeCount:Int,
		points:Bool
	}> = [];
	// Pipelines, by handle: their description.
	var pipelines:Map<Int, PipelineDesc> = [];
	// Cube textures' handles.
	var cubes:Map<Int, Bool> = [];
	// Data textures, by handle: their size.
	var dataTextures:Map<Int, {width:Int, height:Int}> = [];
	// createTexture's textures, by handle: their size and format.
	var plainTextures:Map<Int, {width:Int, height:Int, format:TextureFormat}> = [];
	var active = false;
	// In a target pass: drawn flipped, as GL's framebuffers' origin is the bottom left, so a target is stored top row first like any texture.
	var flipped = false;
	var inTarget = false;
	// The screen's size this frame, and whether endFrame has ended it (so it can be read back).
	var frameWidth = 0;
	var frameHeight = 0;
	var frameEnded = false;
	var passHeight = 0;
	// Render targets, by texture handle: their framebuffer, depth buffer and size; multisampled, the framebuffer drawn into (its color and
	// depth the screen's samples), resolved into the texture's at the pass's end.
	var targets:Map<Int, Target> = [];
	// The target a target pass draws into, or null.
	var drawing:Null<Target>;
	// Multisampling samples a pixel of the canvas, as the browser gave them.
	// Shadow maps, by texture handle: a framebuffer a layer, and their size.
	var shadowMaps:Map<Int, {framebuffers:Array<Dynamic>, size:Int}> = [];
	// The sampler shadow maps are read through: comparing, linear, clamped.
	var comparison:Dynamic = null;
	// A block's bytes with its flip uniform written, the caller's left as they are; grown as needed.
	var flippedBlock = new js.lib.Uint8Array(256);
	// A uniform buffer for each binding point (a vertex block's slot, a fragment block's 4 + its slot), and its size; made when first used.
	var blockBuffers:Array<Dynamic> = [];
	var blockBufferSizes:Array<Int> = [];
	// The texture the open target or shadow pass draws into, 0 for none: a draw may not sample it.
	var passTexture = 0;
	// The framebuffer a texture is read back through, made the first time.
	var reading:Dynamic = null;
	// Attribute slots enabled by the last draw: each draw enables its own and turns the rest off.
	var enabled:Array<Bool> = [];

	/** Creates the adapter on a canvas's WebGL2 context.

		The context has a depth buffer and no alpha or stencil. When antialiased, the browser chooses the number of samples, nearly always 4.
		@param options  The canvas's id, its samples and whether its drawing buffer is kept.
		@throws String  No canvas has that id.
		@throws GraphicsUnavailableException  The browser has no WebGL2. */
	public function new(options:WebGl2GraphicsAdapterOptions) {
		gl = cast DomPage.canvas(options.canvasId).getContext("webgl2", {
			alpha: false,
			antialias: options.msaaSampleCount > 1,
			depth: true,
			stencil: false,
			preserveDrawingBuffer: options.preserveDrawingBuffer
		});
		if (gl == null)
			throw new helix.platform.GraphicsUnavailableException("WebGL2 is required");
		this.msaaSampleCount = Std.int(Math.max(1, gl.getParameter(WebGL2RenderingContext.SAMPLES)));
	}

	@:isVar public var msaaSampleCount(get, null):Int = 1;

	function get_msaaSampleCount():Int
		return msaaSampleCount;

	// The canvas's own count when antialiased; otherwise the 4 browsers give, where the GPU has 4.
	public var maxMsaaSampleCount(get, never):Int;

	function get_maxMsaaSampleCount():Int
		return msaaSampleCount > 1 ? msaaSampleCount : gl.getParameter(WebGL2RenderingContext.MAX_SAMPLES) >= 4 ? 4 : 1;

	public function createTexture(width:Int, height:Int, levels:Array<Bytes>, format:TextureFormat = Rgba8):Int {
		if (width <= 0 || height <= 0 || levels.length == 0 || !canSample(format))
			throw "Invalid texture";
		var tex = gl.createTexture();
		gl.bindTexture(WebGL2RenderingContext.TEXTURE_2D, tex);
		gl.pixelStorei(WebGL2RenderingContext.UNPACK_ALIGNMENT, 1);
		var lw = width, lh = height;
		for (i in 0...levels.length) {
			if (levels[i].length != format.levelBytes(lw, lh)) {
				gl.deleteTexture(tex);
				throw "Invalid texture";
			}
			upload(WebGL2RenderingContext.TEXTURE_2D, i, format, lw, lh, levels[i], 0);
			lw = lw > 1 ? Std.int(lw / 2) : 1;
			lh = lh > 1 ? Std.int(lh / 2) : 1;
		}
		gl.texParameteri(WebGL2RenderingContext.TEXTURE_2D, WebGL2RenderingContext.TEXTURE_MAX_LEVEL, levels.length - 1);
		var id = next++;
		textures[id] = tex;
		plainTextures[id] = {width: width, height: height, format: format};
		return id;
	}

	public function createDataTexture(width:Int, height:Int):Int {
		var largest:Int = gl.getParameter(WebGL2RenderingContext.MAX_TEXTURE_SIZE);
		if (width <= 0 || height <= 0 || width > largest || height > largest)
			throw "Invalid data texture";
		var tex = gl.createTexture();
		gl.bindTexture(WebGL2RenderingContext.TEXTURE_2D, tex);
		// One immutable level: complete under any sampler, as texelFetch reads it.
		gl.texStorage2D(WebGL2RenderingContext.TEXTURE_2D, 1, WebGL2RenderingContext.RGBA32F, width, height);
		var id = next++;
		textures[id] = tex;
		dataTextures[id] = {width: width, height: height};
		return id;
	}

	public function updateTexture(handle:Int, x:Int, y:Int, width:Int, height:Int, data:Bytes):Void {
		var d = dataTextures[handle];
		if (d != null) {
			if (x != 0 || y != 0 || width != d.width || height != d.height || data.length < d.width * d.height * 16)
				throw "Invalid data texture update";
			gl.bindTexture(WebGL2RenderingContext.TEXTURE_2D, textures[handle]);
			gl.pixelStorei(WebGL2RenderingContext.UNPACK_ALIGNMENT, 4);
			gl.texSubImage2D(WebGL2RenderingContext.TEXTURE_2D, 0, 0, 0, d.width, d.height, WebGL2RenderingContext.RGBA, WebGL2RenderingContext.FLOAT,
				new js.lib.Float32Array(data.getData(), 0, d.width * d.height * 4));
			return;
		}
		var p = plainTextures[handle];
		if (p == null
			|| active
			|| p.format != Rgba8
			&& p.format != Rgba16f
			|| x < 0
			|| y < 0
			|| width <= 0
			|| height <= 0
			|| x + width > p.width
			|| y + height > p.height
			|| data.length < p.format.levelBytes(width, height))
			throw "Invalid texture update";
		gl.bindTexture(WebGL2RenderingContext.TEXTURE_2D, textures[handle]);
		gl.pixelStorei(WebGL2RenderingContext.UNPACK_ALIGNMENT, 1);
		// The texture's first row is its top, as uploaded: GL's y counts from it.
		if (p.format == Rgba8)
			gl.texSubImage2D(WebGL2RenderingContext.TEXTURE_2D, 0, x, y, width, height, WebGL2RenderingContext.RGBA, WebGL2RenderingContext.UNSIGNED_BYTE,
				new js.lib.Uint8Array(data.getData(), 0, width * height * 4));
		else
			gl.texSubImage2D(WebGL2RenderingContext.TEXTURE_2D, 0, x, y, width, height, WebGL2RenderingContext.RGBA, WebGL2RenderingContext.HALF_FLOAT,
				new js.lib.Uint16Array(data.getData(), 0, width * height * 4));
	}

	public function createCubeTexture(size:Int, levels:Array<Bytes>, format:TextureFormat):Int {
		if (size <= 0 || levels.length == 0 || !canSample(format))
			throw "Invalid cube texture";
		var tex = gl.createTexture();
		gl.bindTexture(WebGL2RenderingContext.TEXTURE_CUBE_MAP, tex);
		gl.pixelStorei(WebGL2RenderingContext.UNPACK_ALIGNMENT, 1);
		var s = size;
		for (i in 0...levels.length) {
			var face = format.levelBytes(s, s);
			if (levels[i].length != face * 6) {
				gl.deleteTexture(tex);
				throw "Invalid cube texture";
			}
			for (f in 0...6)
				upload(WebGL2RenderingContext.TEXTURE_CUBE_MAP_POSITIVE_X + f, i, format, s, s, levels[i], f * face);
			s = s > 1 ? Std.int(s / 2) : 1;
		}
		gl.texParameteri(WebGL2RenderingContext.TEXTURE_CUBE_MAP, WebGL2RenderingContext.TEXTURE_MAX_LEVEL, levels.length - 1);
		var id = next++;
		textures[id] = tex;
		cubes[id] = true;
		return id;
	}

	// Uploads level `level` of the bound texture at target (a 2D texture or a cube's face), width x height of format, from bytes at offset.
	function upload(target:Int, level:Int, format:TextureFormat, width:Int, height:Int, bytes:Bytes, offset:Int):Void {
		var length = format.levelBytes(width, height);
		switch format {
			case Rgba8:
				gl.texImage2D(target, level, WebGL2RenderingContext.RGBA, width, height, 0, WebGL2RenderingContext.RGBA, WebGL2RenderingContext.UNSIGNED_BYTE,
					new js.lib.Uint8Array(bytes.getData(), offset, length));
			case Rgba16f:
				gl.texImage2D(target, level, WebGL2RenderingContext.RGBA16F, width, height, 0, WebGL2RenderingContext.RGBA, WebGL2RenderingContext.HALF_FLOAT,
					new js.lib.Uint16Array(bytes.getData(), offset, Std.int(length / 2)));
			case _:
				gl.compressedTexImage2D(target, level, glFormat(format), width, height, 0, new js.lib.Uint8Array(bytes.getData(), offset, length));
		}
	}

	// The GL internal format of a compressed one, from its extension.
	static function glFormat(format:TextureFormat):Int
		return switch format {
			case Bc7: 0x8E8C; // COMPRESSED_RGBA_BPTC_UNORM_EXT
			case Astc4x4: 0x93B0; // COMPRESSED_RGBA_ASTC_4x4_KHR
			case Etc2Rgba8: 0x9278; // COMPRESSED_RGBA8_ETC2_EAC
			case Rgba8: WebGL2RenderingContext.RGBA8;
			case Rgba16f: WebGL2RenderingContext.RGBA16F;
		}

	public function canSample(format:TextureFormat):Bool {
		var known = formats[format];
		if (known == null) {
			// Asking for an extension also turns it on.
			known = switch format {
				// WebGL2 filters half floats without an extension.
				case Rgba8 | Rgba16f: true;
				case Bc7: gl.getExtension("EXT_texture_compression_bptc") != null;
				case Astc4x4: gl.getExtension("WEBGL_compressed_texture_astc") != null;
				case Etc2Rgba8: gl.getExtension("WEBGL_compressed_texture_etc") != null;
			}
			formats[format] = known;
		}
		return known;
	}

	// The sampler object for sampling: linear or nearest; the mipmaps not read (their levels clamped to the top), the nearest, or the two
	// nearest blended; each axis's wrap; and the anisotropy, where the browser has EXT_texture_filter_anisotropic, only with every filter
	// linear, as the native adapters take it.
	function sampler(sampling:Sampling):Dynamic {
		var index:Int = sampling;
		if (samplers[index] == null) {
			var wraps = [
				WebGL2RenderingContext.CLAMP_TO_EDGE,
				WebGL2RenderingContext.REPEAT,
				WebGL2RenderingContext.MIRRORED_REPEAT
			];
			var linear = sampling.filter == helix.platform.Filter.Linear,
				made = gl.createSampler();
			var minify = switch sampling.mipmapFilter {
				case Linear: linear ? WebGL2RenderingContext.LINEAR_MIPMAP_LINEAR : WebGL2RenderingContext.NEAREST_MIPMAP_LINEAR;
				case Nearest: linear ? WebGL2RenderingContext.LINEAR_MIPMAP_NEAREST : WebGL2RenderingContext.NEAREST_MIPMAP_NEAREST;
				case None: linear ? WebGL2RenderingContext.LINEAR : WebGL2RenderingContext.NEAREST;
			}
			gl.samplerParameteri(made, WebGL2RenderingContext.TEXTURE_MIN_FILTER, minify);
			gl.samplerParameteri(made, WebGL2RenderingContext.TEXTURE_MAG_FILTER, linear ? WebGL2RenderingContext.LINEAR : WebGL2RenderingContext.NEAREST);
			gl.samplerParameteri(made, WebGL2RenderingContext.TEXTURE_WRAP_S, wraps[(sampling.wrapU : Int) % 3]);
			gl.samplerParameteri(made, WebGL2RenderingContext.TEXTURE_WRAP_T, wraps[(sampling.wrapV : Int) % 3]);
			if (linear && sampling.mipmapFilter == Linear && sampling.anisotropy > 1) {
				var extension = gl.getExtension("EXT_texture_filter_anisotropic");
				if (extension != null) {
					var most:Float = gl.getParameter(0x84FF); // MAX_TEXTURE_MAX_ANISOTROPY_EXT
					gl.samplerParameterf(made, 0x84FE, Math.min(sampling.anisotropy, most)); // TEXTURE_MAX_ANISOTROPY_EXT
				}
			}
			samplers[index] = made;
		}
		return samplers[index];
	}

	public function createBuffer(capacityBytes:Int):Int {
		if (capacityBytes <= 0 || capacityBytes % 4 != 0)
			throw "Invalid buffer capacity";
		var buffer = gl.createBuffer();
		gl.bindBuffer(WebGL2RenderingContext.ARRAY_BUFFER, buffer);
		gl.bufferData(WebGL2RenderingContext.ARRAY_BUFFER, capacityBytes, WebGL2RenderingContext.DYNAMIC_DRAW);
		var id = next++;
		buffers[id] = {
			buffer: buffer,
			capacity: capacityBytes,
			used: 0,
			index: false,
			isStatic: false
		};
		return id;
	}

	public function createStaticBuffer(data:Bytes, bytes:Int, index:Bool):Int {
		if (bytes <= 0 || bytes % 4 != 0 || bytes > data.length)
			throw "Invalid static buffer";
		var target = index ? WebGL2RenderingContext.ELEMENT_ARRAY_BUFFER : WebGL2RenderingContext.ARRAY_BUFFER;
		var buffer = gl.createBuffer();
		gl.bindBuffer(target, buffer);
		gl.bufferData(target, new js.lib.Uint8Array(data.getData(), 0, bytes), WebGL2RenderingContext.STATIC_DRAW);
		var id = next++;
		buffers[id] = {
			buffer: buffer,
			capacity: bytes,
			used: bytes,
			index: index,
			isStatic: true
		};
		return id;
	}

	public function updateBuffer(handle:Int, data:Bytes, usedBytes:Int):Void {
		var b = buffers[handle];
		if (!active
			|| b == null
			|| b.isStatic
			|| usedBytes < 0
			|| usedBytes % 4 != 0
			|| usedBytes > b.capacity
			|| usedBytes > data.length)
			throw "Invalid upload";
		gl.bindBuffer(WebGL2RenderingContext.ARRAY_BUFFER, b.buffer);
		gl.bufferSubData(WebGL2RenderingContext.ARRAY_BUFFER, 0, new js.lib.Uint8Array(data.getData(), 0, usedBytes));
		b.used = usedBytes;
	}

	function compile(type:Int, source:String):Dynamic {
		var s = gl.createShader(type);
		gl.shaderSource(s, source);
		gl.compileShader(s);
		if (!gl.getShaderParameter(s, WebGL2RenderingContext.COMPILE_STATUS)) {
			var log = gl.getShaderInfoLog(s);
			gl.deleteShader(s);
			throw log;
		}
		return s;
	}

	public function createShader(source:ShaderSource):Int {
		var v = compile(WebGL2RenderingContext.VERTEX_SHADER, source.glsl300es.vertex);
		var f = try compile(WebGL2RenderingContext.FRAGMENT_SHADER, source.glsl300es.fragment) catch (e:Dynamic) {
			gl.deleteShader(v);
			throw e;
		};
		var p = gl.createProgram();
		gl.attachShader(p, v);
		gl.attachShader(p, f);
		// A matrix is bound at its first column's slot, its other columns following it; they have no name of their own.
		for (i in 0...source.attributes.length)
			if (source.attributes[i] != "")
				gl.bindAttribLocation(p, i, source.attributes[i]);
		gl.linkProgram(p);
		gl.deleteShader(v);
		gl.deleteShader(f);
		if (!gl.getProgramParameter(p, WebGL2RenderingContext.LINK_STATUS)) {
			var log = gl.getProgramInfoLog(p);
			gl.deleteProgram(p);
			throw log;
		}
		var blocks:Array<ProgramBlock> = [],
			samplerLocations:Array<Dynamic> = [],
			unfiltered:Array<Bool> = [],
			kinds:Array<Int> = [];
		// Each block at a binding point of its own: a vertex block's slot, a fragment block's 4 + its slot (a block both read, the vertex
		// stage's), its bytes the draw's at that index.
		for (b in source.uniformBlocks) {
			var point = b.stage == "fragment" ? 4 + b.slot : b.slot;
			var index = gl.getUniformBlockIndex(p, b.glslName);
			if (index != WebGL2RenderingContext.INVALID_INDEX)
				gl.uniformBlockBinding(p, index, point);
			blocks.push({point: point, size: b.size, bound: index != WebGL2RenderingContext.INVALID_INDEX});
		}
		gl.useProgram(p);
		for (t in source.textures) {
			samplerLocations[t.slot] = gl.getUniformLocation(p, t.glslName);
			unfiltered[t.slot] = t.data;
			kinds[t.slot] = t.shadow ? SHADOW_PLACEHOLDER : t.cube ? CUBE_PLACEHOLDER : TEXTURE_PLACEHOLDER;
			// Texture slot i samples unit i.
			gl.uniform1i(samplerLocations[t.slot], t.slot);
		}
		var id = next++;
		shaders[id] = {
			program: p,
			blocks: blocks,
			textures: samplerLocations,
			unfiltered: unfiltered,
			kinds: kinds,
			attributeCount: source.attributes.length,
			points: source.points == true
		};
		return id;
	}

	public function disposeShader(handle:Int):Void {
		var s = shaders[handle];
		if (s == null)
			throw "Invalid shader";
		for (id => desc in pipelines)
			if (desc.shader == handle)
				pipelines.remove(id);
		gl.deleteProgram(s.program);
		shaders.remove(handle);
	}

	public function createPipeline(desc:PipelineDesc):Int {
		if (!shaders.exists(desc.shader))
			throw "Invalid pipeline shader";
		if (desc.primitive == Points && !shaders[desc.shader].points)
			throw "Invalid pipeline: Points over a program compiled without ShaderCompileOptions.points";
		// The limits every adapter takes (PipelineDesc), though WebGL2 may allow more, so a pipeline made here is made natively too.
		var attributes = 0;
		for (b in desc.buffers)
			attributes += b.attributes.length;
		if (desc.buffers.length > 8 || attributes > 16)
			throw "Invalid pipeline layout: more than 8 buffers or 16 attributes";
		for (b in desc.buffers)
			for (a in b.attributes)
				if (a.slot < 0
					|| a.slot > 15
					|| a.componentCount < 1
					|| a.componentCount > 4
					|| a.offset < 0
					|| a.offset + a.componentCount * 4 > b.stride)
					throw "Invalid pipeline layout";
		if (!validBlend(desc.blend) || desc.colorWrite != null && ((desc.colorWrite : Int) < 0 || (desc.colorWrite : Int) > 15))
			throw "Invalid pipeline blend or color write";
		if (desc.attributeConstants != null)
			for (c in desc.attributeConstants)
				if (c.slot < 0
					|| c.slot > 15
					|| c.values.length > 4
					|| Lambda.exists(desc.buffers, b -> Lambda.exists(b.attributes, a -> a.slot == c.slot)))
					throw "Invalid pipeline attribute constant: a slot from 0 to 15 no buffer feeds, at most four values";
		var flipSlot = desc.flipBlockSlot == null ? 0 : desc.flipBlockSlot,
			flipOffset = desc.flipOffset == null ? 0 : desc.flipOffset;
		if (desc.flip != None && (flipSlot < 0 || flipSlot > 3 || flipOffset < 0 || flipOffset % 4 != 0))
			throw "Invalid pipeline flip place";
		var id = next++;
		pipelines[id] = desc;
		return id;
	}

	public function disposePipeline(handle:Int):Void {
		if (!pipelines.exists(handle))
			throw "Invalid pipeline";
		pipelines.remove(handle);
	}

	public function canRender(format:TextureFormat):Bool {
		var known = renderable[format];
		if (known == null) {
			// Asking for the extension also turns it on: half floats then draw, blend and (WebGL2's own) filter.
			known = switch format {
				case Rgba8: true;
				case Rgba16f: gl.getExtension("EXT_color_buffer_float") != null;
				case _: false;
			}
			renderable[format] = known;
		}
		return known;
	}

	public function createRenderTarget(width:Int, height:Int, format:TextureFormat = Rgba8, depth:Bool = true):Int {
		if (width <= 0 || height <= 0 || !canRender(format))
			throw "Invalid render target";
		var half = format == Rgba16f,
			internal = half ? WebGL2RenderingContext.RGBA16F : WebGL2RenderingContext.RGBA8;
		var tex = gl.createTexture();
		gl.bindTexture(WebGL2RenderingContext.TEXTURE_2D, tex);
		gl.texImage2D(WebGL2RenderingContext.TEXTURE_2D, 0, internal, width, height, 0, WebGL2RenderingContext.RGBA,
			half ? WebGL2RenderingContext.HALF_FLOAT : WebGL2RenderingContext.UNSIGNED_BYTE, null);
		gl.texParameteri(WebGL2RenderingContext.TEXTURE_2D, WebGL2RenderingContext.TEXTURE_MAX_LEVEL, 0);
		// With depth, the screen's samples (at most what this GPU gives the format), so a target is drawn as smooth as the screen; without, one.
		var count = 1;
		if (depth) {
			var most:js.lib.Int32Array = gl.getInternalformatParameter(WebGL2RenderingContext.RENDERBUFFER, internal, WebGL2RenderingContext.SAMPLES);
			count = Std.int(Math.min(msaaSampleCount, most != null && most.length > 0 ? most[0] : 1));
		}
		var depthBuffer:Dynamic = null;
		if (depth) {
			depthBuffer = gl.createRenderbuffer();
			gl.bindRenderbuffer(WebGL2RenderingContext.RENDERBUFFER, depthBuffer);
			if (count > 1)
				gl.renderbufferStorageMultisample(WebGL2RenderingContext.RENDERBUFFER, count, WebGL2RenderingContext.DEPTH_COMPONENT24, width, height);
			else
				gl.renderbufferStorage(WebGL2RenderingContext.RENDERBUFFER, WebGL2RenderingContext.DEPTH_COMPONENT24, width, height);
		}
		var framebuffer = gl.createFramebuffer();
		gl.bindFramebuffer(WebGL2RenderingContext.FRAMEBUFFER, framebuffer);
		gl.framebufferTexture2D(WebGL2RenderingContext.FRAMEBUFFER, WebGL2RenderingContext.COLOR_ATTACHMENT0, WebGL2RenderingContext.TEXTURE_2D, tex, 0);
		if (depth && count <= 1)
			gl.framebufferRenderbuffer(WebGL2RenderingContext.FRAMEBUFFER, WebGL2RenderingContext.DEPTH_ATTACHMENT, WebGL2RenderingContext.RENDERBUFFER,
				depthBuffer);
		var complete = gl.checkFramebufferStatus(WebGL2RenderingContext.FRAMEBUFFER) == WebGL2RenderingContext.FRAMEBUFFER_COMPLETE;
		var drawn:Dynamic = null, color:Dynamic = null;
		if (count > 1) {
			color = gl.createRenderbuffer();
			gl.bindRenderbuffer(WebGL2RenderingContext.RENDERBUFFER, color);
			gl.renderbufferStorageMultisample(WebGL2RenderingContext.RENDERBUFFER, count, internal, width, height);
			drawn = gl.createFramebuffer();
			gl.bindFramebuffer(WebGL2RenderingContext.FRAMEBUFFER, drawn);
			gl.framebufferRenderbuffer(WebGL2RenderingContext.FRAMEBUFFER, WebGL2RenderingContext.COLOR_ATTACHMENT0, WebGL2RenderingContext.RENDERBUFFER,
				color);
			gl.framebufferRenderbuffer(WebGL2RenderingContext.FRAMEBUFFER, WebGL2RenderingContext.DEPTH_ATTACHMENT, WebGL2RenderingContext.RENDERBUFFER,
				depthBuffer);
			complete = complete
				&& gl.checkFramebufferStatus(WebGL2RenderingContext.FRAMEBUFFER) == WebGL2RenderingContext.FRAMEBUFFER_COMPLETE;
		}
		gl.bindFramebuffer(WebGL2RenderingContext.FRAMEBUFFER, null);
		if (!complete) {
			gl.deleteFramebuffer(framebuffer);
			if (depthBuffer != null)
				gl.deleteRenderbuffer(depthBuffer);
			if (drawn != null) {
				gl.deleteFramebuffer(drawn);
				gl.deleteRenderbuffer(color);
			}
			gl.deleteTexture(tex);
			throw "Render target incomplete";
		}
		var id = next++;
		textures[id] = tex;
		targets[id] = {
			framebuffer: framebuffer,
			cleared: false,
			depth: depthBuffer,
			half: half,
			drawn: drawn,
			color: color,
			width: width,
			height: height
		};
		return id;
	}

	public function createShadowMap(size:Int, layerCount:Int):Int {
		var largest:Int = gl.getParameter(WebGL2RenderingContext.MAX_TEXTURE_SIZE),
			most:Int = gl.getParameter(WebGL2RenderingContext.MAX_ARRAY_TEXTURE_LAYERS);
		if (size <= 0 || layerCount <= 0 || size > largest || layerCount > most)
			throw "Invalid shadow map";
		var tex = gl.createTexture();
		gl.bindTexture(WebGL2RenderingContext.TEXTURE_2D_ARRAY, tex);
		gl.texStorage3D(WebGL2RenderingContext.TEXTURE_2D_ARRAY, 1, WebGL2RenderingContext.DEPTH_COMPONENT24, size, size, layerCount);
		var framebuffers = [];
		for (layer in 0...layerCount) {
			var framebuffer = gl.createFramebuffer();
			gl.bindFramebuffer(WebGL2RenderingContext.FRAMEBUFFER, framebuffer);
			gl.framebufferTextureLayer(WebGL2RenderingContext.FRAMEBUFFER, WebGL2RenderingContext.DEPTH_ATTACHMENT, tex, 0, layer);
			// Depth only: nothing to draw colors into.
			gl.drawBuffers([WebGL2RenderingContext.NONE]);
			gl.readBuffer(WebGL2RenderingContext.NONE);
			framebuffers.push(framebuffer);
		}
		// Checked once here, never at a pass (a check at every pass stalls the browser).
		var complete = gl.checkFramebufferStatus(WebGL2RenderingContext.FRAMEBUFFER) == WebGL2RenderingContext.FRAMEBUFFER_COMPLETE;
		gl.bindFramebuffer(WebGL2RenderingContext.FRAMEBUFFER, null);
		if (!complete) {
			for (framebuffer in framebuffers)
				gl.deleteFramebuffer(framebuffer);
			gl.deleteTexture(tex);
			throw "Shadow map incomplete";
		}
		var id = next++;
		textures[id] = tex;
		shadowMaps[id] = {framebuffers: framebuffers, size: size};
		return id;
	}

	// The sampler for shadow maps: each read compares with the map's depth (less or equal), filtered linearly over its texels.
	function comparisonSampler():Dynamic {
		if (comparison == null) {
			comparison = gl.createSampler();
			gl.samplerParameteri(comparison, WebGL2RenderingContext.TEXTURE_MIN_FILTER, WebGL2RenderingContext.LINEAR);
			gl.samplerParameteri(comparison, WebGL2RenderingContext.TEXTURE_MAG_FILTER, WebGL2RenderingContext.LINEAR);
			gl.samplerParameteri(comparison, WebGL2RenderingContext.TEXTURE_WRAP_S, WebGL2RenderingContext.CLAMP_TO_EDGE);
			gl.samplerParameteri(comparison, WebGL2RenderingContext.TEXTURE_WRAP_T, WebGL2RenderingContext.CLAMP_TO_EDGE);
			gl.samplerParameteri(comparison, WebGL2RenderingContext.TEXTURE_COMPARE_MODE, WebGL2RenderingContext.COMPARE_REF_TO_TEXTURE);
			gl.samplerParameteri(comparison, WebGL2RenderingContext.TEXTURE_COMPARE_FUNC, WebGL2RenderingContext.LEQUAL);
		}
		return comparison;
	}

	public function beginShadowPass(map:Int, layerIndex:Int):Void {
		var m = shadowMaps[map];
		if (active || m == null || layerIndex < 0 || layerIndex >= m.framebuffers.length)
			throw "Invalid shadow pass";
		gl.bindFramebuffer(WebGL2RenderingContext.FRAMEBUFFER, m.framebuffers[layerIndex]);
		// Not flipped: a shadow map's rows run bottom first, as its lookups expect.
		inTarget = true;
		flipped = false;
		passTexture = map;
		open(m.size, m.size, true, 0, 0, 0, 0);
	}

	public function beginTargetPass(target:Int, red:Float, green:Float, blue:Float, alpha:Float):Void
		beginTarget(target, true, red, green, blue, alpha);

	public function resumeTargetPass(target:Int):Void
		beginTarget(target, false, 0, 0, 0, 0);

	// A pass into a target, cleared or keeping what it holds (cleared to transparent black the first time): its multisampled framebuffer
	// when it has one, which keeps its samples from pass to pass, resolved into the texture at each pass's end.
	function beginTarget(target:Int, clear:Bool, red:Float, green:Float, blue:Float, alpha:Float):Void {
		var t = targets[target];
		if (active || t == null)
			throw "Invalid target pass";
		gl.bindFramebuffer(WebGL2RenderingContext.FRAMEBUFFER, t.drawn != null ? t.drawn : t.framebuffer);
		drawing = t;
		passTexture = target;
		inTarget = flipped = true;
		open(t.width, t.height, clear || !t.cleared, red, green, blue, alpha);
		t.cleared = true;
	}

	public function endTargetPass():Void {
		if (!inTarget)
			throw "No target pass";
		// Multisampled: its samples resolved into the texture (a blit, which the scissor would cut).
		var t = drawing;
		if (t != null && t.drawn != null) {
			gl.disable(WebGL2RenderingContext.SCISSOR_TEST);
			gl.bindFramebuffer(WebGL2RenderingContext.READ_FRAMEBUFFER, t.drawn);
			gl.bindFramebuffer(WebGL2RenderingContext.DRAW_FRAMEBUFFER, t.framebuffer);
			gl.blitFramebuffer(0, 0, t.width, t.height, 0, 0, t.width, t.height, WebGL2RenderingContext.COLOR_BUFFER_BIT, WebGL2RenderingContext.NEAREST);
		}
		drawing = null;
		passTexture = 0;
		gl.bindFramebuffer(WebGL2RenderingContext.FRAMEBUFFER, null);
		active = inTarget = flipped = false;
	}

	public function beginFrame(width:Int, height:Int, clearColor:Int):Void {
		if (active || width <= 0 || height <= 0)
			throw "Invalid pass";
		inTarget = flipped = frameEnded = false;
		frameWidth = width;
		frameHeight = height;
		open(width, height, true, Color.getRed(clearColor) / 255, Color.getGreen(clearColor) / 255, Color.getBlue(clearColor) / 255,
			Color.getAlpha(clearColor) / 255);
	}

	// Opens a pass on the bound framebuffer, width x height, cleared or not.
	function open(width:Int, height:Int, clear:Bool, red:Float, green:Float, blue:Float, alpha:Float):Void {
		active = true;
		passHeight = height;
		gl.disable(WebGL2RenderingContext.SCISSOR_TEST);
		gl.disable(WebGL2RenderingContext.CULL_FACE);
		if (clear) {
			gl.depthMask(true);
			// A depth-only draw or a color write mask before may have masked the colors off: a clear writes them all.
			gl.colorMask(true, true, true, true);
			gl.clearColor(red, green, blue, alpha);
			gl.clearDepth(1);
			gl.clear(WebGL2RenderingContext.COLOR_BUFFER_BIT | WebGL2RenderingContext.DEPTH_BUFFER_BIT);
		}
		gl.viewport(0, 0, width, height);
	}

	public function applyScissor(x:Int, y:Int, w:Int, h:Int):Void {
		if (!active || w < 0 || h < 0)
			throw "Invalid scissor";
		gl.enable(WebGL2RenderingContext.SCISSOR_TEST);
		// From the bottom left, as asked; a flipped pass's rows are upside down.
		gl.scissor(x, flipped ? passHeight - y - h : y, w, h);
	}

	public function resetScissor():Void {
		if (!active)
			throw "No pass";
		gl.disable(WebGL2RenderingContext.SCISSOR_TEST);
	}

	public function applyViewport(x:Int, y:Int, w:Int, h:Int):Void {
		if (!active || w <= 0 || h <= 0)
			throw "Invalid viewport";
		// From the bottom left, as asked; a flipped pass's rows are upside down.
		gl.viewport(x, flipped ? passHeight - y - h : y, w, h);
	}

	// GL's blend factors and equations, by BlendFactor's and BlendOperation's values.
	static final FACTORS = [
		WebGL2RenderingContext.ZERO,
		WebGL2RenderingContext.ONE,
		WebGL2RenderingContext.SRC_COLOR,
		WebGL2RenderingContext.ONE_MINUS_SRC_COLOR,
		WebGL2RenderingContext.DST_COLOR,
		WebGL2RenderingContext.ONE_MINUS_DST_COLOR,
		WebGL2RenderingContext.SRC_ALPHA,
		WebGL2RenderingContext.ONE_MINUS_SRC_ALPHA,
		WebGL2RenderingContext.DST_ALPHA,
		WebGL2RenderingContext.ONE_MINUS_DST_ALPHA,
		WebGL2RenderingContext.SRC_ALPHA_SATURATE
	];

	static final OPERATIONS = [
		WebGL2RenderingContext.FUNC_ADD,
		WebGL2RenderingContext.FUNC_SUBTRACT,
		WebGL2RenderingContext.FUNC_REVERSE_SUBTRACT,
		WebGL2RenderingContext.MIN,
		WebGL2RenderingContext.MAX
	];

	// Whether a blend's every field is one GL has: four factors of 4 bits, below 11, and two operations of 3, below 5.
	static function validBlend(blend:Int):Bool {
		for (shift in [0, 4, 8, 12, 16, 19])
			if ((blend >> shift & (shift < 16 ? 15 : 7)) >= (shift < 16 ? 11 : 5))
				return false;
		return blend >>> 22 == 0;
	}

	function blend(mode:Blend):Void
		if (mode == Blend.OPAQUE)
			gl.disable(WebGL2RenderingContext.BLEND);
		else {
			gl.enable(WebGL2RenderingContext.BLEND);
			gl.blendFuncSeparate(FACTORS[mode.colorSource], FACTORS[mode.colorDestination], FACTORS[mode.alphaSource], FACTORS[mode.alphaDestination]);
			gl.blendEquationSeparate(OPERATIONS[mode.colorOperation], OPERATIONS[mode.alphaOperation]);
		}

	public function draw(pipeline:Int, buffers:Array<Int>, indexBuffer:Int, firstElementIndex:Int, elementCount:Int, firstInstanceIndex:Int,
			instanceCount:Int, textures:Array<Int>, samplings:Array<Sampling>, uniforms:Array<Null<Bytes>>):Void {
		var p = pipelines[pipeline];
		if (!active || p == null)
			throw "Invalid draw";
		var shader = shaders[p.shader],
			group = p.primitive == Points ? 1 : p.primitive == Lines ? 2 : 3,
			ix = p.indexed ? this.buffers[indexBuffer] : null;
		if (firstElementIndex < 0
			|| elementCount <= 0
			|| elementCount % group != 0
			|| firstInstanceIndex < 0
			|| instanceCount <= 0
			|| p.indexed
			&& (ix == null || !ix.index || (firstElementIndex + elementCount) * 4 > ix.used))
			throw "Invalid draw";
		// Each buffer's records must cover the draw: an instanced one's the instances, a vertex one's the vertices (indexed: GL checks them).
		for (i in 0...p.buffers.length) {
			var layout = p.buffers[i];
			if (layout.attributes.length == 0)
				continue;
			var b = i < buffers.length ? this.buffers[buffers[i]] : null;
			if (b == null
				|| b.index
				|| layout.instanced
				&& (firstInstanceIndex + instanceCount) * layout.stride > b.used
					|| !layout.instanced
					&& !p.indexed
					&& (firstElementIndex + elementCount) * layout.stride > b.used)
				throw "Invalid draw";
		}
		gl.useProgram(shader.program);
		bindTextures(shader, textures, samplings);
		bindBlocks(shader, uniforms, p);
		var used = [];
		for (i in 0...p.buffers.length) {
			var layout = p.buffers[i];
			if (layout.attributes.length == 0)
				continue;
			gl.bindBuffer(WebGL2RenderingContext.ARRAY_BUFFER, this.buffers[buffers[i]].buffer);
			// No base instance in WebGL2: an instanced buffer's attributes start at the draw's first record instead.
			var base = layout.instanced ? firstInstanceIndex * layout.stride : 0;
			for (a in layout.attributes) {
				gl.enableVertexAttribArray(a.slot);
				gl.vertexAttribPointer(a.slot, a.componentCount, WebGL2RenderingContext.FLOAT, false, layout.stride, base + a.offset);
				gl.vertexAttribDivisor(a.slot, layout.instanced ? 1 : 0);
				used[a.slot] = true;
			}
		}
		for (slot in 0...enabled.length)
			if (enabled[slot] && used[slot] != true) {
				gl.disableVertexAttribArray(slot);
				gl.vertexAttribDivisor(slot, 0);
			}
		enabled = used;
		// What no buffer feeds reads the pipeline's constant, or (0, 0, 0, 1).
		for (slot in 0...shader.attributeCount)
			if (used[slot] != true)
				gl.vertexAttrib4f(slot, 0, 0, 0, 1);
		if (p.attributeConstants != null)
			for (c in p.attributeConstants) {
				var v = c.values;
				gl.vertexAttrib4f(c.slot, v.length > 0 ? v[0] : 0, v.length > 1 ? v[1] : 0, v.length > 2 ? v[2] : 0, v.length > 3 ? v[3] : 1);
			}
		if (p.depthTest != DepthTest.Off) {
			gl.enable(WebGL2RenderingContext.DEPTH_TEST);
			gl.depthFunc(p.depthTest == DepthTest.Greater ? WebGL2RenderingContext.GREATER : WebGL2RenderingContext.LEQUAL);
		} else
			gl.disable(WebGL2RenderingContext.DEPTH_TEST);
		gl.depthMask(p.depthWrite);
		if (p.cull != CullFace.None) {
			gl.enable(WebGL2RenderingContext.CULL_FACE);
			gl.cullFace(p.cull == CullFace.Front ? WebGL2RenderingContext.FRONT : WebGL2RenderingContext.BACK);
		} else
			gl.disable(WebGL2RenderingContext.CULL_FACE);
		// The front faces as described; flipped, they wind the other way (gl_FrontFacing too).
		gl.frontFace(flipped != p.clockwise ? WebGL2RenderingContext.CW : WebGL2RenderingContext.CCW);
		var write:ColorChannels = p.depthOnly ? None : p.colorWrite == null ? All : p.colorWrite;
		gl.colorMask(write.hasChannels(Red), write.hasChannels(Green), write.hasChannels(Blue), write.hasChannels(Alpha));
		blend(p.blend);
		var mode = p.primitive == Points ? WebGL2RenderingContext.POINTS : p.primitive == Lines ? WebGL2RenderingContext.LINES : WebGL2RenderingContext.TRIANGLES;
		if (p.indexed) {
			gl.bindBuffer(WebGL2RenderingContext.ELEMENT_ARRAY_BUFFER, ix.buffer);
			gl.drawElementsInstanced(mode, elementCount, WebGL2RenderingContext.UNSIGNED_INT, firstElementIndex * 4, instanceCount);
		} else
			gl.drawArraysInstanced(mode, firstElementIndex, elementCount, instanceCount);
	}

	// What an unbound slot reads (a draw's texture 0 where the program declares one): a 1x1 texture of the slot's kind, clear, made when
	// first needed.
	function placeholder(kind:Int):Int {
		if (placeholders[kind] == 0)
			placeholders[kind] = kind == CUBE_PLACEHOLDER ? createCubeTexture(1, [Bytes.alloc(24)],
				Rgba8) : kind == SHADOW_PLACEHOLDER ? createShadowMap(1, 1) : createTexture(1, 1, [Bytes.alloc(4)]);
		return placeholders[kind];
	}

	// Binds textures by the program's slots, each sampled by its kind: a shadow map through the comparison sampler, a slot the program never
	// filters (it only fetches texels) and a data texture nearest, any other as its sampling says.
	function bindTextures(shader:{
		program:Dynamic,
		blocks:Array<ProgramBlock>,
		textures:Array<Dynamic>,
		unfiltered:Array<Bool>,
		kinds:Array<Int>,
		attributeCount:Int
	}, textures:Array<Int>, samplings:Array<Sampling>):Void
		for (slot in 0...shader.textures.length) {
			if (shader.textures[slot] == null)
				continue;
			// A slot the draw leaves unbound reads a placeholder of its kind.
			var handle = slot < textures.length && textures[slot] != 0 ? textures[slot] : placeholder(shader.kinds[slot]),
				t = this.textures[handle];
			if (t == null)
				throw "Invalid draw texture";
			if (handle == passTexture)
				throw "Invalid draw texture: it is the pass's own target, which a draw into it can't sample";
			gl.activeTexture(WebGL2RenderingContext.TEXTURE0 + slot);
			if (shadowMaps.exists(handle)) {
				gl.bindTexture(WebGL2RenderingContext.TEXTURE_2D_ARRAY, t);
				gl.bindSampler(slot, comparisonSampler());
			} else if (cubes.exists(handle)) {
				gl.bindTexture(WebGL2RenderingContext.TEXTURE_CUBE_MAP, t);
				gl.bindSampler(slot, sampler(slot < samplings.length ? samplings[slot] : Sampling.LINEAR));
			} else {
				gl.bindTexture(WebGL2RenderingContext.TEXTURE_2D, t);
				gl.bindSampler(slot,
					sampler(dataTextures.exists(handle)
						|| shader.unfiltered[slot]
						|| slot >= samplings.length ? Sampling.NEAREST : samplings[slot]));
			}
		}

	// Uploads the program's uniform blocks from uniforms by stage and slot, each its declared size, into their binding points' buffers; the
	// pipeline's flip uniform written into a copy as its flip says.
	function bindBlocks(shader:{
		program:Dynamic,
		blocks:Array<ProgramBlock>,
		textures:Array<Dynamic>,
		unfiltered:Array<Bool>,
		kinds:Array<Int>,
		attributeCount:Int
	}, uniforms:Array<Null<Bytes>>, p:PipelineDesc):Void
		for (block in shader.blocks) {
			var data = block.point < uniforms.length ? uniforms[block.point] : null;
			if (data == null || data.length < block.size)
				throw "Invalid draw uniforms: a block's bytes missing or short";
			if (!block.bound)
				continue;
			var bytes = new js.lib.Uint8Array(data.getData(), 0, block.size);
			var flipSlot = p.flipBlockSlot == null ? 0 : p.flipBlockSlot,
				flipOffset = p.flipOffset == null ? 0 : p.flipOffset;
			if (p.flip != None && block.point == flipSlot && (p.flip == ClipScale || flipped)) {
				if (flippedBlock.length < block.size)
					flippedBlock = new js.lib.Uint8Array(block.size);
				var copy = flippedBlock.subarray(0, block.size);
				copy.set(bytes);
				var floats = new js.lib.Float32Array(copy.buffer, 0, block.size >> 2),
					at = flipOffset >> 2;
				if (p.flip == ClipScale && at + 4 <= floats.length) {
					floats[at] = 1;
					floats[at + 1] = flipped ? -1 : 1;
					floats[at + 2] = 1;
					floats[at + 3] = 1;
				} else if (p.flip == ViewProjection && at + 16 <= floats.length)
					for (i in [1, 5, 9, 13])
						floats[at + i] = -floats[at + i];
				bytes = copy;
			}
			var buffer = blockBuffers[block.point];
			if (buffer == null || blockBufferSizes[block.point] < block.size) {
				if (buffer != null)
					gl.deleteBuffer(buffer);
				buffer = blockBuffers[block.point] = gl.createBuffer();
				blockBufferSizes[block.point] = block.size;
				gl.bindBuffer(WebGL2RenderingContext.UNIFORM_BUFFER, buffer);
				gl.bufferData(WebGL2RenderingContext.UNIFORM_BUFFER, block.size, WebGL2RenderingContext.DYNAMIC_DRAW);
			} else
				gl.bindBuffer(WebGL2RenderingContext.UNIFORM_BUFFER, buffer);
			gl.bufferSubData(WebGL2RenderingContext.UNIFORM_BUFFER, 0, bytes);
			gl.bindBufferRange(WebGL2RenderingContext.UNIFORM_BUFFER, block.point, buffer, 0, block.size);
		}

	public function endFrame():Void {
		if (!active || inTarget)
			throw "No screen pass";
		active = false;
		frameEnded = true;
	}

	public function present():Void {}

	public function readPixels(handle:Int, read:(pixels:Bytes, width:Int, height:Int) -> Void, failed:String->Void):Void {
		if (active)
			throw "Inside a pass";
		var t = targets[handle], p = plainTextures[handle];
		// Half floats read back only as floats in WebGL2: not this call's RGBA8.
		if (handle != 0 && (t == null || t.half) && (p == null || p.format != Rgba8))
			throw "Invalid texture to read";
		if (handle == 0 && !frameEnded) {
			failed("No frame has ended");
			return;
		}
		var width = handle == 0 ? frameWidth : t != null ? t.width : p.width,
			height = handle == 0 ? frameHeight : t != null ? t.height : p.height;
		if (p != null) {
			// A texture's top level, through a framebuffer of its own, made the first time.
			if (reading == null)
				reading = gl.createFramebuffer();
			gl.bindFramebuffer(WebGL2RenderingContext.FRAMEBUFFER, reading);
			gl.framebufferTexture2D(WebGL2RenderingContext.FRAMEBUFFER, WebGL2RenderingContext.COLOR_ATTACHMENT0, WebGL2RenderingContext.TEXTURE_2D,
				textures[handle], 0);
		} else
			gl.bindFramebuffer(WebGL2RenderingContext.FRAMEBUFFER, handle == 0 ? null : t.framebuffer);
		var pixels = new js.lib.Uint8Array(width * height * 4);
		gl.readPixels(0, 0, width, height, WebGL2RenderingContext.RGBA, WebGL2RenderingContext.UNSIGNED_BYTE, pixels);
		gl.bindFramebuffer(WebGL2RenderingContext.FRAMEBUFFER, null);
		var raw = Bytes.ofData(pixels.buffer);
		if (handle != 0) {
			// A texture's rows are its first first, as uploaded, and a target's top first, drawn flipped.
			read(raw, width, height);
			return;
		}
		// The screen's rows come bottom first (GL's origin).
		var rgba = Bytes.alloc(raw.length), row = width * 4;
		for (y in 0...height)
			rgba.blit(y * row, raw, (height - 1 - y) * row, row);
		read(rgba, width, height);
	}

	public function disposeBuffer(handle:Int):Void {
		var b = buffers[handle];
		if (b == null)
			throw "Invalid buffer";
		gl.deleteBuffer(b.buffer);
		buffers.remove(handle);
	}

	public function disposeTexture(handle:Int):Void {
		var t = textures[handle];
		if (t == null)
			throw "Invalid texture";
		gl.deleteTexture(t);
		textures.remove(handle);
		cubes.remove(handle);
		dataTextures.remove(handle);
		plainTextures.remove(handle);
		var map = shadowMaps[handle];
		if (map != null) {
			for (framebuffer in map.framebuffers)
				gl.deleteFramebuffer(framebuffer);
			shadowMaps.remove(handle);
		}
		var target = targets[handle];
		if (target != null) {
			gl.deleteFramebuffer(target.framebuffer);
			if (target.depth != null)
				gl.deleteRenderbuffer(target.depth);
			if (target.drawn != null) {
				gl.deleteFramebuffer(target.drawn);
				gl.deleteRenderbuffer(target.color);
			}
			targets.remove(handle);
		}
	}

	public function dispose():Void {
		for (made in placeholders)
			if (made != 0)
				disposeTexture(made);
		placeholders = [0, 0, 0];
		for (s in shaders)
			gl.deleteProgram(s.program);
		shaders.clear();
		pipelines.clear();
		for (made in samplers)
			if (made != null)
				gl.deleteSampler(made);
		samplers = [];
		if (comparison != null)
			gl.deleteSampler(comparison);
		comparison = null;
		if (reading != null)
			gl.deleteFramebuffer(reading);
		reading = null;
		for (made in blockBuffers)
			if (made != null)
				gl.deleteBuffer(made);
		blockBuffers = [];
		blockBufferSizes = [];
	}
}
