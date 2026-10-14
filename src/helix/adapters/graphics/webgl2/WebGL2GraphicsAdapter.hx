package helix.adapters.graphics.webgl2;

import helix.graphics.BlendMode;
import helix.graphics.IGraphics;
import helix.graphics.PipelineKind;
import helix.graphics.Sampling;
import helix.graphics.ShaderSource;
import helix.graphics.TextureFormat;
import haxe.io.Bytes;
import js.html.CanvasElement;
import js.html.webgl.WebGL2RenderingContext;

/** IGraphics on a canvas's WebGL2 context: raw browser API calls only; geometry and batching stay in Batch2D and Batch3D. One program per framework
	shader, shared by every pipeline that uses it. */
class WebGL2GraphicsAdapter implements IGraphics {
	var gl:WebGL2RenderingContext;

	/** The canvas's WebGL2 context. */
	public function getContext():WebGL2RenderingContext
		return gl;

	var next = 1;
	var buffers:Map<Int, Dynamic> = [];
	var textures:Map<Int, Dynamic> = [];
	// One sampler object for each Sampling value used, made when first used.
	var samplers:Array<Dynamic> = [];
	// Whether each TextureFormat is sampled, once asked.
	var formats:Array<Null<Bool>> = [];
	var pipelines:Map<Int, Dynamic> = [];
	// Apps' programs (createShader), by handle: the linked program, its uniform blocks' locations and sizes, its textures' sampler locations.
	var appShaders:Map<Int, {program:Dynamic, blocks:Array<Null<{location:Dynamic, size:Int}>>, textures:Array<Dynamic>}> = [];
	// The programs, by shader: sprite2d, color3d (shared by Color3D and Lines3D), lit3d. Made on first use.
	var programs:Array<Dynamic> = [null, null, null, null, null];
	var active = false;
	// In a target pass: drawn flipped, as GL's framebuffers' origin is the bottom left, so a target is stored top row first like any texture.
	var flipped = false;
	var inTarget = false;
	var passHeight = 0;
	// Render targets, by texture handle: their framebuffer, depth buffer and size.
	var targets:Map<Int, {
		framebuffer:Dynamic,
		depth:Dynamic,
		width:Int,
		height:Int
	}> = [];
	var uniformData = new js.lib.Float32Array(16);

	// Attribute slots any program uses: each draw enables its own and leaves the rest off, every divisor 0 but an instance attribute's.
	static inline var SLOTS = 11;

	/** Takes canvas's WebGL2 context, without alpha, antialiasing or stencil, with a depth buffer; preserve keeps the drawing buffer between
		frames. Throws without WebGL2. */
	public function new(canvas:CanvasElement, preserve:Bool) {
		gl = cast canvas.getContext("webgl2", {
			alpha: false,
			antialias: false,
			depth: true,
			stencil: false,
			preserveDrawingBuffer: preserve
		});
		if (gl == null)
			throw "WebGL2 is required";
		#if hotreload live.push(this); #end
	}

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
			var data = new js.lib.Uint8Array(levels[i].getData(), 0, levels[i].length);
			if (format == Rgba8)
				gl.texImage2D(WebGL2RenderingContext.TEXTURE_2D, i, WebGL2RenderingContext.RGBA, lw, lh, 0, WebGL2RenderingContext.RGBA,
					WebGL2RenderingContext.UNSIGNED_BYTE, data);
			else
				gl.compressedTexImage2D(WebGL2RenderingContext.TEXTURE_2D, i, glFormat(format), lw, lh, 0, data);
			lw = lw > 1 ? Std.int(lw / 2) : 1;
			lh = lh > 1 ? Std.int(lh / 2) : 1;
		}
		gl.texParameteri(WebGL2RenderingContext.TEXTURE_2D, WebGL2RenderingContext.TEXTURE_MAX_LEVEL, levels.length - 1);
		var id = next++;
		textures[id] = tex;
		return id;
	}

	// The GL internal format of a compressed one, from its extension.
	static function glFormat(format:TextureFormat):Int
		return switch format {
			case Bc7: 0x8E8C; // COMPRESSED_RGBA_BPTC_UNORM_EXT
			case Astc4x4: 0x93B0; // COMPRESSED_RGBA_ASTC_4x4_KHR
			case Etc2Rgba8: 0x9278; // COMPRESSED_RGBA8_ETC2_EAC
			case Rgba8: WebGL2RenderingContext.RGBA8;
		}

	public function canSample(format:TextureFormat):Bool {
		var known = formats[format];
		if (known == null) {
			// Asking for an extension also turns it on.
			known = switch format {
				case Rgba8: true;
				case Bc7: gl.getExtension("EXT_texture_compression_bptc") != null;
				case Astc4x4: gl.getExtension("WEBGL_compressed_texture_astc") != null;
				case Etc2Rgba8: gl.getExtension("WEBGL_compressed_texture_etc") != null;
			}
			formats[format] = known;
		}
		return known;
	}

	// The sampler object for sampling: linear (through the mipmaps, when there are any) or nearest, and each axis's wrap.
	function sampler(sampling:Sampling):Dynamic {
		var index:Int = sampling;
		if (samplers[index] == null) {
			var wraps = [
				WebGL2RenderingContext.CLAMP_TO_EDGE,
				WebGL2RenderingContext.REPEAT,
				WebGL2RenderingContext.MIRRORED_REPEAT
			];
			var linear = sampling.isLinear(), made = gl.createSampler();
			gl.samplerParameteri(made, WebGL2RenderingContext.TEXTURE_MIN_FILTER,
				linear ? WebGL2RenderingContext.LINEAR_MIPMAP_LINEAR : WebGL2RenderingContext.NEAREST_MIPMAP_NEAREST);
			gl.samplerParameteri(made, WebGL2RenderingContext.TEXTURE_MAG_FILTER, linear ? WebGL2RenderingContext.LINEAR : WebGL2RenderingContext.NEAREST);
			gl.samplerParameteri(made, WebGL2RenderingContext.TEXTURE_WRAP_S, wraps[(sampling.getWrapU() : Int) % 3]);
			gl.samplerParameteri(made, WebGL2RenderingContext.TEXTURE_WRAP_T, wraps[(sampling.getWrapV() : Int) % 3]);
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

	function shader(type:Int, source:String):Dynamic {
		var s = gl.createShader(type);
		gl.shaderSource(s, source);
		gl.compileShader(s);
		if (!gl.getShaderParameter(s, WebGL2RenderingContext.COMPILE_STATUS))
			throw gl.getShaderInfoLog(s);
		return s;
	}

	/** The framework shader's sources, attribute bindings and uniforms: 0 sprite2d, 1 color3d, 2 lit3d, 3 sprite3d, 4 particle3d. */
	static function sources(index:Int):Dynamic {
		if (index == 0)
			return {
				vertex: GeneratedShader.sprite2dVertex(),
				fragment: GeneratedShader.sprite2dFragment(),
				attributes: [
					{slot: Sprite2DLayout.positionSlot, name: Sprite2DLayout.positionName},
					{slot: Sprite2DLayout.uvSlot, name: Sprite2DLayout.uvName},
					{slot: Sprite2DLayout.colorSlot, name: Sprite2DLayout.colorName}
				],
				texture: Sprite2DLayout.atlasUniform,
				normalTexture: null,
				vertexUniform: Sprite2DLayout.vertexUniformName,
				fragmentUniform: null
			};
		if (index == 1)
			return {
				vertex: GeneratedShader.color3dVertex(),
				fragment: GeneratedShader.color3dFragment(),
				attributes: [
					{slot: Color3DLayout.positionSlot, name: Color3DLayout.positionName},
					{slot: Color3DLayout.colorSlot, name: Color3DLayout.colorName}
				],
				texture: null,
				normalTexture: null,
				vertexUniform: Color3DLayout.vertexUniformName,
				fragmentUniform: null
			};
		if (index == 4)
			return {
				vertex: GeneratedShader.particle3dVertex(),
				fragment: GeneratedShader.particle3dFragment(),
				attributes: [
					{slot: Particle3DLayout.cornerSlot, name: Particle3DLayout.cornerName},
					{slot: Particle3DLayout.bornSlot, name: Particle3DLayout.bornName},
					{slot: Particle3DLayout.motionSlot, name: Particle3DLayout.motionName},
					{slot: Particle3DLayout.shapeSlot, name: Particle3DLayout.shapeName}
				],
				texture: Particle3DLayout.atlasUniform,
				normalTexture: null,
				vertexUniform: Particle3DLayout.vertexUniformName,
				fragmentUniform: null
			};
		if (index == 3)
			return {
				vertex: GeneratedShader.sprite3dVertex(),
				fragment: GeneratedShader.sprite3dFragment(),
				attributes: [
					{slot: Sprite3DLayout.cornerSlot, name: Sprite3DLayout.cornerName},
					{slot: Sprite3DLayout.positionSlot, name: Sprite3DLayout.positionName},
					{slot: Sprite3DLayout.sizeSlot, name: Sprite3DLayout.sizeName},
					{slot: Sprite3DLayout.regionSlot, name: Sprite3DLayout.regionName},
					{slot: Sprite3DLayout.rightSlot, name: Sprite3DLayout.rightName},
					{slot: Sprite3DLayout.upSlot, name: Sprite3DLayout.upName},
					{slot: Sprite3DLayout.tintSlot, name: Sprite3DLayout.tintName}
				],
				texture: Sprite3DLayout.atlasUniform,
				normalTexture: null,
				vertexUniform: Sprite3DLayout.vertexUniformName,
				fragmentUniform: null
			};
		return {
			vertex: GeneratedShader.lit3dVertex(),
			fragment: GeneratedShader.lit3dFragment(),
			attributes: [
				{slot: Lit3DLayout.positionSlot, name: Lit3DLayout.positionName},
				{slot: Lit3DLayout.normalSlot, name: Lit3DLayout.normalName},
				{slot: Lit3DLayout.uvSlot, name: Lit3DLayout.uvName},
				{slot: Lit3DLayout.tangentSlot, name: Lit3DLayout.tangentName},
				{slot: Lit3DLayout.model0Slot, name: Lit3DLayout.model0Name},
				{slot: Lit3DLayout.model1Slot, name: Lit3DLayout.model1Name},
				{slot: Lit3DLayout.model2Slot, name: Lit3DLayout.model2Name},
				{slot: Lit3DLayout.normal0Slot, name: Lit3DLayout.normal0Name},
				{slot: Lit3DLayout.normal1Slot, name: Lit3DLayout.normal1Name},
				{slot: Lit3DLayout.normal2Slot, name: Lit3DLayout.normal2Name},
				{slot: Lit3DLayout.tintSlot, name: Lit3DLayout.tintName}
			],
			texture: Lit3DLayout.baseUniform,
			normalTexture: Lit3DLayout.normalUniform,
			vertexUniform: Lit3DLayout.vertexUniformName,
			fragmentUniform: Lit3DLayout.fragmentUniformName
		};
	}

	function link(index:Int):Dynamic {
		var source = sources(index),
			v = shader(WebGL2RenderingContext.VERTEX_SHADER, source.vertex),
			f = shader(WebGL2RenderingContext.FRAGMENT_SHADER, source.fragment),
			p = gl.createProgram();
		gl.attachShader(p, v);
		gl.attachShader(p, f);
		var attributes:Array<{slot:Int, name:String}> = source.attributes;
		for (attribute in attributes)
			gl.bindAttribLocation(p, attribute.slot, attribute.name);
		gl.linkProgram(p);
		gl.deleteShader(v);
		gl.deleteShader(f);
		if (!gl.getProgramParameter(p, WebGL2RenderingContext.LINK_STATUS))
			throw gl.getProgramInfoLog(p);
		function location(name:String):Dynamic {
			if (name == null)
				return null;
			var found = gl.getUniformLocation(p, name);
			if (found == null)
				throw 'Missing generated uniform $name';
			return found;
		}
		return {
			program: p,
			texture: location(source.texture),
			normalTexture: location(source.normalTexture),
			vertexUniform: location(source.vertexUniform),
			fragmentUniform: location(source.fragmentUniform),
			vertex: source.vertex,
			fragment: source.fragment
		};
	}

	function program(index:Int):Dynamic {
		if (programs[index] == null)
			programs[index] = link(index);
		return programs[index];
	}

	public function createPipeline(kind:PipelineKind, blend:BlendMode, shader:Int = 0, doubleSided:Bool = false, clockwise:Bool = false):Int {
		// Screen takes an app's program; Lit3D may (a surface shader).
		if (kind == Screen && shader == 0 || shader != 0 && (kind != Screen && kind != Lit3D || !appShaders.exists(shader)))
			throw "Invalid pipeline shader";
		var index = kind == Sprite2D ? 0 : kind == Lit3D ? 2 : kind == Sprite3D ? 3 : kind == Particle3D ? 4 : 1;
		if (kind != Screen)
			program(index);
		var id = next++;
		pipelines[id] = {
			kind: kind,
			shader: index,
			app: shader,
			alpha: blend,
			doubleSided: doubleSided,
			clockwise: clockwise
		};
		return id;
	}

	public function createShader(source:ShaderSource):Int {
		var v = shader(WebGL2RenderingContext.VERTEX_SHADER, source.glsl300es.vertex),
			f = shader(WebGL2RenderingContext.FRAGMENT_SHADER, source.glsl300es.fragment),
			p = gl.createProgram();
		gl.attachShader(p, v);
		gl.attachShader(p, f);
		for (i in 0...source.attributes.length)
			gl.bindAttribLocation(p, i, source.attributes[i]);
		gl.linkProgram(p);
		gl.deleteShader(v);
		gl.deleteShader(f);
		if (!gl.getProgramParameter(p, WebGL2RenderingContext.LINK_STATUS)) {
			var log = gl.getProgramInfoLog(p);
			gl.deleteProgram(p);
			throw log;
		}
		var blocks:Array<Null<{location:Dynamic, size:Int}>> = [],
			textures:Array<Dynamic> = [];
		for (b in source.uniformBlocks)
			blocks[b.slot] = {location: gl.getUniformLocation(p, b.glslName), size: b.size};
		gl.useProgram(p);
		for (t in source.textures) {
			textures[t.slot] = gl.getUniformLocation(p, t.glslName);
			// Texture slot i samples unit i.
			gl.uniform1i(textures[t.slot], t.slot);
		}
		var id = next++;
		appShaders[id] = {program: p, blocks: blocks, textures: textures};
		return id;
	}

	// The framework's particle program as an app's is described: its block and texture slot.
	function particleProgram():{program:Dynamic, blocks:Array<Null<{location:Dynamic, size:Int}>>, textures:Array<Dynamic>} {
		var particle = program(4);
		return {
			program: particle.program,
			blocks: [{location: particle.vertexUniform, size: Particle3DLayout.vertexUniformBytes}],
			textures: [particle.texture]
		};
	}

	// The framework's sprite program as an app's is described: its block and texture slot.
	function spriteProgram():{program:Dynamic, blocks:Array<Null<{location:Dynamic, size:Int}>>, textures:Array<Dynamic>} {
		var sprite = program(3);
		return {
			program: sprite.program,
			blocks: [{location: sprite.vertexUniform, size: Sprite3DLayout.vertexUniformBytes}],
			textures: [sprite.texture]
		};
	}

	// The framework's lit program as an app's is described: its blocks and texture slots.
	function litProgram():{program:Dynamic, blocks:Array<Null<{location:Dynamic, size:Int}>>, textures:Array<Dynamic>} {
		var lit = program(2);
		return {
			program: lit.program,
			blocks: [
				{location: lit.vertexUniform, size: Lit3DLayout.vertexUniformBytes},
				{location: lit.fragmentUniform, size: Lit3DLayout.fragmentUniformBytes}
			],
			textures: [lit.texture, lit.normalTexture]
		};
	}

	/** Uses program, binding textures (by slot; each slot it samples needs one) and its uniform blocks (by slot, each its size); block 0 is turned
		over in a flipped pass: a screen program's clip scale, or a lit one's view-projection's y row. Throws for a mismatch. */
	function bindProgram(program:{program:Dynamic, blocks:Array<Null<{location:Dynamic, size:Int}>>, textures:Array<Dynamic>}, textures:Array<Int>,
			samplings:Array<Sampling>, uniforms:Array<Null<Bytes>>, screen:Bool):Void {
		gl.useProgram(program.program);
		for (slot in 0...program.textures.length) {
			var location = program.textures[slot];
			if (location == null)
				continue;
			var t = slot < textures.length ? this.textures[textures[slot]] : null;
			if (t == null)
				throw "Invalid draw texture";
			gl.uniform1i(location, slot);
			gl.activeTexture(WebGL2RenderingContext.TEXTURE0 + slot);
			gl.bindTexture(WebGL2RenderingContext.TEXTURE_2D, t);
			gl.bindSampler(slot, sampler(samplings[slot]));
		}
		for (slot in 0...program.blocks.length) {
			var block = program.blocks[slot];
			if (block == null)
				continue;
			var data = slot < uniforms.length ? uniforms[slot] : null;
			if (data == null || data.length != block.size)
				throw "Invalid draw uniforms";
			var floats = new js.lib.Float32Array(Std.int(block.size / 4));
			for (i in 0...floats.length)
				floats[i] = data.getFloat(i * 4);
			if (slot == 0 && screen) {
				floats[0] = 1;
				floats[1] = flipped ? -1 : 1;
			} else if (slot == 0 && flipped)
				for (i in [1, 5, 9, 13])
					floats[i] = -floats[i];
			if (block.location != null)
				gl.uniform4fv(block.location, floats);
		}
	}

	public function destroyShader(handle:Int):Void {
		var s = appShaders[handle];
		if (s == null)
			throw "Invalid shader";
		gl.deleteProgram(s.program);
		appShaders.remove(handle);
	}

	public function drawScreen(pipeline:Int, textures:Array<Int>, samplings:Array<Sampling>, uniforms:Array<Null<Bytes>>):Void {
		var p = pipelines[pipeline];
		if (!active || p == null || p.kind != Screen)
			throw "Invalid screen draw";
		var app = appShaders[p.app];
		if (app == null)
			throw "Invalid screen draw";
		bindProgram(app, textures, samplings, uniforms, true);
		resetAttributes();
		gl.disable(WebGL2RenderingContext.CULL_FACE);
		gl.disable(WebGL2RenderingContext.DEPTH_TEST);
		gl.depthMask(false);
		blend(p.alpha);
		gl.drawArrays(WebGL2RenderingContext.TRIANGLES, 0, 3);
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

	public function createRenderTarget(width:Int, height:Int):Int {
		if (width <= 0 || height <= 0)
			throw "Invalid render target";
		var tex = gl.createTexture();
		gl.bindTexture(WebGL2RenderingContext.TEXTURE_2D, tex);
		gl.texImage2D(WebGL2RenderingContext.TEXTURE_2D, 0, WebGL2RenderingContext.RGBA8, width, height, 0, WebGL2RenderingContext.RGBA,
			WebGL2RenderingContext.UNSIGNED_BYTE, null);
		gl.texParameteri(WebGL2RenderingContext.TEXTURE_2D, WebGL2RenderingContext.TEXTURE_MAX_LEVEL, 0);
		var depth = gl.createRenderbuffer();
		gl.bindRenderbuffer(WebGL2RenderingContext.RENDERBUFFER, depth);
		gl.renderbufferStorage(WebGL2RenderingContext.RENDERBUFFER, WebGL2RenderingContext.DEPTH_COMPONENT24, width, height);
		var framebuffer = gl.createFramebuffer();
		gl.bindFramebuffer(WebGL2RenderingContext.FRAMEBUFFER, framebuffer);
		gl.framebufferTexture2D(WebGL2RenderingContext.FRAMEBUFFER, WebGL2RenderingContext.COLOR_ATTACHMENT0, WebGL2RenderingContext.TEXTURE_2D, tex, 0);
		gl.framebufferRenderbuffer(WebGL2RenderingContext.FRAMEBUFFER, WebGL2RenderingContext.DEPTH_ATTACHMENT, WebGL2RenderingContext.RENDERBUFFER, depth);
		var complete = gl.checkFramebufferStatus(WebGL2RenderingContext.FRAMEBUFFER) == WebGL2RenderingContext.FRAMEBUFFER_COMPLETE;
		gl.bindFramebuffer(WebGL2RenderingContext.FRAMEBUFFER, null);
		if (!complete) {
			gl.deleteFramebuffer(framebuffer);
			gl.deleteRenderbuffer(depth);
			gl.deleteTexture(tex);
			throw "Render target incomplete";
		}
		var id = next++;
		textures[id] = tex;
		targets[id] = {
			framebuffer: framebuffer,
			depth: depth,
			width: width,
			height: height
		};
		return id;
	}

	public function beginTargetPass(target:Int, clearColor:Int):Void {
		var t = targets[target];
		if (active || t == null)
			throw "Invalid target pass";
		gl.bindFramebuffer(WebGL2RenderingContext.FRAMEBUFFER, t.framebuffer);
		inTarget = flipped = true;
		open(t.width, t.height, clearColor);
	}

	public function endTargetPass():Void {
		if (!inTarget)
			throw "No target pass";
		gl.bindFramebuffer(WebGL2RenderingContext.FRAMEBUFFER, null);
		active = inTarget = flipped = false;
	}

	public function beginFrame(width:Int, height:Int, clearColor:Int):Void {
		if (active || width <= 0 || height <= 0)
			throw "Invalid pass";
		inTarget = flipped = false;
		open(width, height, clearColor);
	}

	// Opens a pass on the bound framebuffer, width x height, cleared.
	function open(width:Int, height:Int, clearColor:Int):Void {
		active = true;
		passHeight = height;
		gl.disable(WebGL2RenderingContext.SCISSOR_TEST);
		gl.disable(WebGL2RenderingContext.CULL_FACE);
		gl.depthMask(true);
		gl.clearColor((clearColor >>> 24) / 255, ((clearColor >>> 16) & 255) / 255, ((clearColor >>> 8) & 255) / 255, (clearColor & 255) / 255);
		gl.clearDepth(1);
		gl.clear(WebGL2RenderingContext.COLOR_BUFFER_BIT | WebGL2RenderingContext.DEPTH_BUFFER_BIT);
		gl.viewport(0, 0, width, height);
	}

	public function setViewport(x:Int, y:Int, w:Int, h:Int):Void {
		if (!active || w <= 0 || h <= 0)
			throw "Invalid viewport";
		// From the bottom left, as asked; a flipped pass's rows are upside down.
		gl.viewport(x, flipped ? passHeight - y - h : y, w, h);
	}

	function attribute(slot:Int, components:Int, stride:Int, offset:Int, divisor = 0):Void {
		gl.enableVertexAttribArray(slot);
		gl.vertexAttribPointer(slot, components, WebGL2RenderingContext.FLOAT, false, stride, offset);
		gl.vertexAttribDivisor(slot, divisor);
	}

	function resetAttributes():Void
		for (slot in 0...SLOTS) {
			gl.disableVertexAttribArray(slot);
			gl.vertexAttribDivisor(slot, 0);
		}

	function blend(mode:BlendMode):Void
		if (mode == Opaque)
			gl.disable(WebGL2RenderingContext.BLEND);
		else {
			gl.enable(WebGL2RenderingContext.BLEND);
			// Added: the source times its alpha, plus what's there.
			var additive = mode == Additive;
			gl.blendFuncSeparate(WebGL2RenderingContext.SRC_ALPHA, additive ? WebGL2RenderingContext.ONE : WebGL2RenderingContext.ONE_MINUS_SRC_ALPHA,
				WebGL2RenderingContext.ONE, additive ? WebGL2RenderingContext.ONE : WebGL2RenderingContext.ONE_MINUS_SRC_ALPHA);
		}

	public function draw(pipeline:Int, buffer:Int, texture:Int, sampling:Sampling, vertices:Int, firstVertex:Int, ?uniforms:Bytes):Void {
		var p = pipelines[pipeline], b = buffers[buffer];
		if (!active || p == null || b == null || b.index || p.kind == Lit3D || p.kind == Sprite3D || p.kind == Particle3D || p.kind == Screen)
			throw "Invalid draw";
		var kind:PipelineKind = p.kind,
			sprite = kind == Sprite2D,
			stride = sprite ? Sprite2DLayout.stride : Color3DLayout.stride,
			group = kind == Lines3D ? 2 : 3,
			t = sprite ? textures[texture] : null;
		if (vertices <= 0
			|| vertices % group != 0
			|| firstVertex < 0
			|| firstVertex % group != 0
			|| firstVertex > b.used / stride - vertices
			|| (sprite ? t == null || uniforms != null : uniforms == null || uniforms.length != Color3DLayout.vertexUniformBytes))
			throw "Invalid draw";
		var shader = programs[p.shader];
		gl.useProgram(shader.program);
		gl.bindBuffer(WebGL2RenderingContext.ARRAY_BUFFER, b.buffer);
		resetAttributes();
		gl.disable(WebGL2RenderingContext.CULL_FACE);
		if (sprite) {
			gl.uniform1i(shader.texture, Sprite2DLayout.atlasUnit);
			// Clip space's y scale: -1 in a flipped pass.
			gl.uniform4f(shader.vertexUniform, 1, flipped ? -1 : 1, 0, 0);
			attribute(Sprite2DLayout.positionSlot, Sprite2DLayout.positionComponents, stride, Sprite2DLayout.positionOffset);
			attribute(Sprite2DLayout.uvSlot, Sprite2DLayout.uvComponents, stride, Sprite2DLayout.uvOffset);
			attribute(Sprite2DLayout.colorSlot, Sprite2DLayout.colorComponents, stride, Sprite2DLayout.colorOffset);
			gl.activeTexture(WebGL2RenderingContext.TEXTURE0 + Sprite2DLayout.atlasUnit);
			gl.bindTexture(WebGL2RenderingContext.TEXTURE_2D, t);
			gl.bindSampler(Sprite2DLayout.atlasUnit, sampler(sampling));
			gl.disable(WebGL2RenderingContext.DEPTH_TEST);
			gl.depthMask(false);
		} else {
			for (i in 0...16)
				uniformData[i] = uniforms.getFloat(i * 4);
			flipRows();
			gl.uniform4fv(shader.vertexUniform, uniformData);
			attribute(Color3DLayout.positionSlot, Color3DLayout.positionComponents, stride, Color3DLayout.positionOffset);
			attribute(Color3DLayout.colorSlot, Color3DLayout.colorComponents, stride, Color3DLayout.colorOffset);
			gl.enable(WebGL2RenderingContext.DEPTH_TEST);
			gl.depthFunc(WebGL2RenderingContext.LEQUAL);
			gl.depthMask(true);
		}
		blend(p.alpha);
		gl.drawArrays(kind == Lines3D ? WebGL2RenderingContext.LINES : WebGL2RenderingContext.TRIANGLES, firstVertex, vertices);
	}

	public function drawMesh(pipeline:Int, vertices:Int, indices:Int, indexCount:Int, instances:Int, firstInstance:Int, instanceCount:Int,
			textures:Array<Int>, samplings:Array<Sampling>, uniforms:Array<Null<Bytes>>):Void {
		var p = pipelines[pipeline],
			v = buffers[vertices],
			ix = buffers[indices],
			n = buffers[instances];
		if (!active
			|| p == null
			|| p.kind != Lit3D
			&& p.kind != Sprite3D
			&& p.kind != Particle3D
			|| v == null
			|| v.index
			|| !v.isStatic
			|| ix == null
			|| !ix.index
			|| n == null
			|| n.isStatic
			|| indexCount <= 0
			|| indexCount % 3 != 0
			|| indexCount * 4 > ix.used
			|| firstInstance < 0
			|| instanceCount <= 0
			|| (firstInstance +
				instanceCount) * (p.kind == Sprite3D ? Sprite3DLayout.instanceStride : p.kind == Particle3D ? Particle3DLayout.instanceStride : Lit3DLayout.instanceStride) > n.used)
			throw "Invalid mesh draw";
		// The framework's lit program, or an app's surface shader.
		var app = p.app != 0 ? appShaders[p.app] : p.kind == Sprite3D ? spriteProgram() : p.kind == Particle3D ? particleProgram() : litProgram();
		if (app == null)
			throw "Invalid mesh draw";
		bindProgram(app, textures, samplings, uniforms, false);
		resetAttributes();
		if (p.kind == Particle3D) {
			var record = Particle3DLayout.instanceStride,
				base = firstInstance * record;
			gl.bindBuffer(WebGL2RenderingContext.ARRAY_BUFFER, v.buffer);
			attribute(Particle3DLayout.cornerSlot, Particle3DLayout.cornerComponents, Particle3DLayout.stride, Particle3DLayout.cornerOffset);
			gl.bindBuffer(WebGL2RenderingContext.ARRAY_BUFFER, n.buffer);
			attribute(Particle3DLayout.bornSlot, 4, record, base + Particle3DLayout.bornOffset, 1);
			attribute(Particle3DLayout.motionSlot, 4, record, base + Particle3DLayout.motionOffset, 1);
			attribute(Particle3DLayout.shapeSlot, 4, record, base + Particle3DLayout.shapeOffset, 1);
		} else if (p.kind == Sprite3D) {
			var record = Sprite3DLayout.instanceStride,
				base = firstInstance * record;
			gl.bindBuffer(WebGL2RenderingContext.ARRAY_BUFFER, v.buffer);
			attribute(Sprite3DLayout.cornerSlot, Sprite3DLayout.cornerComponents, Sprite3DLayout.stride, Sprite3DLayout.cornerOffset);
			gl.bindBuffer(WebGL2RenderingContext.ARRAY_BUFFER, n.buffer);
			// No base instance in WebGL2: the instance attributes start at the draw's first record instead.
			attribute(Sprite3DLayout.positionSlot, 4, record, base + Sprite3DLayout.positionOffset, 1);
			attribute(Sprite3DLayout.sizeSlot, 4, record, base + Sprite3DLayout.sizeOffset, 1);
			attribute(Sprite3DLayout.regionSlot, 4, record, base + Sprite3DLayout.regionOffset, 1);
			attribute(Sprite3DLayout.rightSlot, 4, record, base + Sprite3DLayout.rightOffset, 1);
			attribute(Sprite3DLayout.upSlot, 4, record, base + Sprite3DLayout.upOffset, 1);
			attribute(Sprite3DLayout.tintSlot, 4, record, base + Sprite3DLayout.tintOffset, 1);
		} else {
			var stride = Lit3DLayout.stride,
				record = Lit3DLayout.instanceStride,
				base = firstInstance * record;
			gl.bindBuffer(WebGL2RenderingContext.ARRAY_BUFFER, v.buffer);
			attribute(Lit3DLayout.positionSlot, Lit3DLayout.positionComponents, stride, Lit3DLayout.positionOffset);
			attribute(Lit3DLayout.normalSlot, Lit3DLayout.normalComponents, stride, Lit3DLayout.normalOffset);
			attribute(Lit3DLayout.uvSlot, Lit3DLayout.uvComponents, stride, Lit3DLayout.uvOffset);
			attribute(Lit3DLayout.tangentSlot, Lit3DLayout.tangentComponents, stride, Lit3DLayout.tangentOffset);
			gl.bindBuffer(WebGL2RenderingContext.ARRAY_BUFFER, n.buffer);
			// No base instance in WebGL2: the instance attributes start at the draw's first record instead.
			attribute(Lit3DLayout.model0Slot, 4, record, base + Lit3DLayout.model0Offset, 1);
			attribute(Lit3DLayout.model1Slot, 4, record, base + Lit3DLayout.model1Offset, 1);
			attribute(Lit3DLayout.model2Slot, 4, record, base + Lit3DLayout.model2Offset, 1);
			attribute(Lit3DLayout.normal0Slot, 4, record, base + Lit3DLayout.normal0Offset, 1);
			attribute(Lit3DLayout.normal1Slot, 4, record, base + Lit3DLayout.normal1Offset, 1);
			attribute(Lit3DLayout.normal2Slot, 4, record, base + Lit3DLayout.normal2Offset, 1);
			attribute(Lit3DLayout.tintSlot, 4, record, base + Lit3DLayout.tintOffset, 1);
		}
		gl.bindBuffer(WebGL2RenderingContext.ELEMENT_ARRAY_BUFFER, ix.buffer);
		gl.enable(WebGL2RenderingContext.DEPTH_TEST);
		gl.depthFunc(WebGL2RenderingContext.LEQUAL);
		// Lit models write depth; sprites only when opaque (see-through and added ones show what's behind them, drawn after).
		gl.depthMask(p.kind == Lit3D || p.alpha == Opaque);
		if (p.doubleSided || p.kind == Sprite3D || p.kind == Particle3D)
			gl.disable(WebGL2RenderingContext.CULL_FACE);
		else
			gl.enable(WebGL2RenderingContext.CULL_FACE);
		gl.cullFace(WebGL2RenderingContext.BACK);
		// Clockwise fronts for a mirrored model's pipeline; flipped, the front faces wind the other way again.
		gl.frontFace(flipped != p.clockwise ? WebGL2RenderingContext.CW : WebGL2RenderingContext.CCW);
		blend(p.alpha);
		gl.drawElementsInstanced(WebGL2RenderingContext.TRIANGLES, indexCount, WebGL2RenderingContext.UNSIGNED_INT, 0, instanceCount);
	}

	public function endFrame():Void {
		if (!active || inTarget)
			throw "No screen pass";
		active = false;
	}

	// In a flipped pass, the view-projection in uniformData has its y row negated.
	function flipRows():Void
		if (flipped)
			for (i in [1, 5, 9, 13])
				uniformData[i] = -uniformData[i];

	public function destroyBuffer(handle:Int):Void {
		var b = buffers[handle];
		if (b == null)
			throw "Invalid buffer";
		gl.deleteBuffer(b.buffer);
		buffers.remove(handle);
	}

	public function destroyTexture(handle:Int):Void {
		var t = textures[handle];
		if (t == null)
			throw "Invalid texture";
		gl.deleteTexture(t);
		textures.remove(handle);
		var target = targets[handle];
		if (target != null) {
			gl.deleteFramebuffer(target.framebuffer);
			gl.deleteRenderbuffer(target.depth);
			targets.remove(handle);
		}
	}

	public function destroyPipeline(handle:Int):Void {
		if (pipelines[handle] == null)
			throw "Invalid pipeline";
		pipelines.remove(handle);
	}

	public function shutdown():Void {
		for (i in 0...programs.length)
			if (programs[i] != null) {
				gl.deleteProgram(programs[i].program);
				programs[i] = null;
			}
		for (made in samplers)
			if (made != null)
				gl.deleteSampler(made);
		samplers = [];
		#if hotreload live.remove(this); #end
	}

	#if hotreload
	// Development only (hotreload-hx): a reload brings new generated shader source; programs are relinked in place so pipeline handles stay valid.
	static var live:Array<WebGL2GraphicsAdapter> = [];

	@:afterHotReload static function reloadShaders():Void
		for (adapter in live)
			adapter.rebuildPrograms();

	function rebuildPrograms():Void
		for (i in 0...programs.length) {
			var old:Dynamic = programs[i], source = sources(i);
			if (old == null || old.vertex == source.vertex && old.fragment == source.fragment)
				continue;
			programs[i] = link(i);
			gl.deleteProgram(old.program);
		}
	#end
}
