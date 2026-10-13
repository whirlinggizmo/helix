package helix.adapters.graphics.webgl2;

import helix.graphics.IGraphics;
import helix.graphics.PipelineKind;
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
	var pipelines:Map<Int, Dynamic> = [];
	// The programs, by shader: sprite2d, color3d (shared by Color3D and Lines3D), lit3d. Made on first use.
	var programs:Array<Dynamic> = [null, null, null];
	var active = false;
	var uniformData = new js.lib.Float32Array(16);
	var fragmentData = new js.lib.Float32Array(Std.int(Lit3DLayout.fragmentUniformBytes / 4));

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

	public function createTexture(width:Int, height:Int, levels:Array<Bytes>, linear:Bool = false):Int {
		if (width <= 0 || height <= 0 || levels.length == 0)
			throw "Invalid texture";
		var tex = gl.createTexture();
		gl.bindTexture(WebGL2RenderingContext.TEXTURE_2D, tex);
		gl.pixelStorei(WebGL2RenderingContext.UNPACK_ALIGNMENT, 1);
		var lw = width, lh = height;
		for (i in 0...levels.length) {
			if (levels[i].length != lw * lh * 4)
				throw "Invalid texture";
			gl.texImage2D(WebGL2RenderingContext.TEXTURE_2D, i, WebGL2RenderingContext.RGBA, lw, lh, 0, WebGL2RenderingContext.RGBA,
				WebGL2RenderingContext.UNSIGNED_BYTE, new js.lib.Uint8Array(levels[i].getData()));
			lw = lw > 1 ? Std.int(lw / 2) : 1;
			lh = lh > 1 ? Std.int(lh / 2) : 1;
		}
		gl.texParameteri(WebGL2RenderingContext.TEXTURE_2D, WebGL2RenderingContext.TEXTURE_MAX_LEVEL, levels.length - 1);
		gl.texParameteri(WebGL2RenderingContext.TEXTURE_2D, WebGL2RenderingContext.TEXTURE_MIN_FILTER,
			linear ? (levels.length > 1 ? WebGL2RenderingContext.LINEAR_MIPMAP_LINEAR : WebGL2RenderingContext.LINEAR) : WebGL2RenderingContext.NEAREST);
		gl.texParameteri(WebGL2RenderingContext.TEXTURE_2D, WebGL2RenderingContext.TEXTURE_MAG_FILTER,
			linear ? WebGL2RenderingContext.LINEAR : WebGL2RenderingContext.NEAREST);
		gl.texParameteri(WebGL2RenderingContext.TEXTURE_2D, WebGL2RenderingContext.TEXTURE_WRAP_S, WebGL2RenderingContext.CLAMP_TO_EDGE);
		gl.texParameteri(WebGL2RenderingContext.TEXTURE_2D, WebGL2RenderingContext.TEXTURE_WRAP_T, WebGL2RenderingContext.CLAMP_TO_EDGE);
		var id = next++;
		textures[id] = tex;
		return id;
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

	/** The framework shader's sources, attribute bindings and uniforms: 0 sprite2d, 1 color3d, 2 lit3d. */
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
				vertexUniform: null,
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

	public function createPipeline(kind:PipelineKind, alpha:Bool):Int {
		var index = kind == Sprite2D ? 0 : kind == Lit3D ? 2 : 1;
		program(index);
		var id = next++;
		pipelines[id] = {kind: kind, shader: index, alpha: alpha};
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

	public function beginFrame(width:Int, height:Int, clearColor:Int):Void {
		if (active || width <= 0 || height <= 0)
			throw "Invalid pass";
		active = true;
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
		gl.viewport(x, y, w, h);
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

	function blend(alpha:Bool):Void
		if (alpha) {
			gl.enable(WebGL2RenderingContext.BLEND);
			gl.blendFuncSeparate(WebGL2RenderingContext.SRC_ALPHA, WebGL2RenderingContext.ONE_MINUS_SRC_ALPHA, WebGL2RenderingContext.ONE,
				WebGL2RenderingContext.ONE_MINUS_SRC_ALPHA);
		} else
			gl.disable(WebGL2RenderingContext.BLEND);

	public function draw(pipeline:Int, buffer:Int, texture:Int, vertices:Int, firstVertex:Int, ?uniforms:Bytes):Void {
		var p = pipelines[pipeline], b = buffers[buffer];
		if (!active || p == null || b == null || b.index || p.kind == Lit3D)
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
			attribute(Sprite2DLayout.positionSlot, Sprite2DLayout.positionComponents, stride, Sprite2DLayout.positionOffset);
			attribute(Sprite2DLayout.uvSlot, Sprite2DLayout.uvComponents, stride, Sprite2DLayout.uvOffset);
			attribute(Sprite2DLayout.colorSlot, Sprite2DLayout.colorComponents, stride, Sprite2DLayout.colorOffset);
			gl.activeTexture(WebGL2RenderingContext.TEXTURE0 + Sprite2DLayout.atlasUnit);
			gl.bindTexture(WebGL2RenderingContext.TEXTURE_2D, t);
			gl.disable(WebGL2RenderingContext.DEPTH_TEST);
			gl.depthMask(false);
		} else {
			for (i in 0...16)
				uniformData[i] = uniforms.getFloat(i * 4);
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

	public function drawMesh(pipeline:Int, vertices:Int, indices:Int, indexCount:Int, instances:Int, firstInstance:Int, instanceCount:Int, baseTexture:Int,
			normalTexture:Int, vertexUniforms:Bytes, fragmentUniforms:Bytes):Void {
		var p = pipelines[pipeline],
			v = buffers[vertices],
			ix = buffers[indices],
			n = buffers[instances],
			t = textures[baseTexture],
			nt = textures[normalTexture];
		if (!active
			|| p == null
			|| p.kind != Lit3D
			|| nt == null
			|| v == null
			|| v.index
			|| !v.isStatic
			|| ix == null
			|| !ix.index
			|| n == null
			|| n.isStatic
			|| t == null
			|| indexCount <= 0
			|| indexCount % 3 != 0
			|| indexCount * 4 > ix.used
			|| firstInstance < 0
			|| instanceCount <= 0
			|| (firstInstance + instanceCount) * Lit3DLayout.instanceStride > n.used
				|| vertexUniforms == null
				|| vertexUniforms.length != Lit3DLayout.vertexUniformBytes
				|| fragmentUniforms == null
				|| fragmentUniforms.length != Lit3DLayout.fragmentUniformBytes)
			throw "Invalid mesh draw";
		var shader = programs[2];
		gl.useProgram(shader.program);
		for (i in 0...16)
			uniformData[i] = vertexUniforms.getFloat(i * 4);
		gl.uniform4fv(shader.vertexUniform, uniformData);
		for (i in 0...fragmentData.length)
			fragmentData[i] = fragmentUniforms.getFloat(i * 4);
		gl.uniform4fv(shader.fragmentUniform, fragmentData);
		gl.uniform1i(shader.texture, Lit3DLayout.baseUnit);
		gl.activeTexture(WebGL2RenderingContext.TEXTURE0 + Lit3DLayout.baseUnit);
		gl.bindTexture(WebGL2RenderingContext.TEXTURE_2D, t);
		gl.uniform1i(shader.normalTexture, Lit3DLayout.normalUnit);
		gl.activeTexture(WebGL2RenderingContext.TEXTURE0 + Lit3DLayout.normalUnit);
		gl.bindTexture(WebGL2RenderingContext.TEXTURE_2D, nt);
		resetAttributes();
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
		gl.bindBuffer(WebGL2RenderingContext.ELEMENT_ARRAY_BUFFER, ix.buffer);
		gl.enable(WebGL2RenderingContext.DEPTH_TEST);
		gl.depthFunc(WebGL2RenderingContext.LEQUAL);
		gl.depthMask(true);
		gl.enable(WebGL2RenderingContext.CULL_FACE);
		gl.cullFace(WebGL2RenderingContext.BACK);
		gl.frontFace(WebGL2RenderingContext.CCW);
		blend(p.alpha);
		gl.drawElementsInstanced(WebGL2RenderingContext.TRIANGLES, indexCount, WebGL2RenderingContext.UNSIGNED_INT, 0, instanceCount);
	}

	public function endFrame():Void {
		if (!active)
			throw "No pass";
		active = false;
	}

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
