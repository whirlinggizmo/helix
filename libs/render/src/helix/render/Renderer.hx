package helix.render;

import haxe.io.Bytes;
import helix.platform.Blend;
import helix.platform.ColorChannels;
import helix.platform.CullFace;
import helix.platform.DepthTest;
import helix.platform.Primitive;
import helix.platform.Sampling;
import helix.render.RenderDraw.RenderPipeline;
import helix.render.RenderPass.RenderCommand;
import helix.services.shaders.Shader;
import helix.services.shaders.ShaderPipelineState;
import helix.services.shaders.ShaderPrograms;
import helix.services.shaders.ShaderValues;
import helix.services.shaders.ShaderVertexLayout;
import helix.geometry.Mesh3D;
import helix.platform.IGraphics;
import helix.platform.TextureFormat;
import helix.services.fonts.Font2D;
import helix.platform.IDecodedImage;
import helix.services.images.Image;
import helix.services.models.Model3D;

/** Provides drawing over the platform's graphics: the textures, meshes and fonts a program draws with, and the frame they are drawn in,
	pass by pass.

	A program constructs one over its `IGraphics`, then a `Batch2D` and a `Batch3D` over it for what it draws, and `DrawList2D`s and `DrawList3D`s for
	drawing it records once and replays. Each frame it calls
	`beginFrame`, draws through its batches (and into render targets between `beginTarget` and `endTarget`), and calls `endFrame`, then
	the platform's `IGraphics.present` itself. The renderer runs no loop and reads no clock.

	A frame is recorded as it is drawn and reaches the GPU at `endFrame`: every render target's pass first, in the order they were
	begun, then the screen's. In each pass, draws are drawn in the order they were called. A draw that reads a target (a sprite of it, a
	material's texture, a shader's sampler, `PostProcess.draw`) reads it as it is at that point of the recording: the passes into it
	begun before the draw, and none after. A target drawn into again after something read it is given a fresh texture for the new pass
	(`beginTarget`), so the earlier draw keeps the old, as raylib's render textures behave.

	**Shaders.** The renderer builds every shader its batches, materials and effects draw with on the GPU (helix-services'
	`ShaderPrograms`, its own), when the frame is drawn at `endFrame`, before the frame's first pass, so a shader drawn for the first
	time mid-frame is built then; a shader replaced in place (`Shaders.watch`) is built again there too. A program watching shader files
	calls `Shaders.prepareFrame` before `beginFrame`.

	What `createX` makes is the program's, and the program frees it with its `dispose()`. It may be made at any time, outside a frame or
	in one; made in a frame, it may be drawn in that frame. Nothing is counted or shared: a texture a
	material names is not owned by the material, and disposing one that a material still names makes that material's draws throw. Something
	disposed while the frame being recorded holds a draw of it is freed after `endFrame`. `dispose` frees everything still held.

	```haxe
	var renderer = new Renderer(graphics);
	var batch = new Batch2D(renderer);
	var ship = renderer.createTexture(shipImage);
	// each frame:
	renderer.beginFrame(window.framebufferWidth, window.framebufferHeight, 0xff101820);
	batch.begin();
	batch.drawTexture(ship, 100, 80);
	batch.end();
	renderer.endFrame();
	graphics.present();
	``` */
class Renderer {
	/** Gets the graphics it draws with. */
	public final graphics:IGraphics;

	/** Gets the width of the current pass's viewport, in pixels: the screen's framebuffer pixels or the target's texels. It is what a
		`Batch2D` without a camera measures in, and what a `Batch3D` takes its aspect from. 0 outside a frame. */
	public var viewportWidth(default, null):Int = 0;

	/** Gets the height of the current pass's viewport, in pixels. 0 outside a frame. */
	public var viewportHeight(default, null):Int = 0;

	/** Gets a value indicating whether a frame is being recorded: from `beginFrame` until `endFrame`. */
	public var inFrame(default, null):Bool = false;

	/** Gets or sets the exposure, in stops: each one doubles linear light before it is tone mapped. 0 until set.

		It and `toneMapping` are the one pair every lit draw is brought to the screen by. Into an sRGB target (RGBA8, the screen),
		`Batch3D`'s lit shaders apply them as they draw, read at each `Batch3D.begin`; into an RGBA16F target the batch writes linear
		light and `PostProcess.draw` applies them in its resolve, read at each call. A value that isn't finite is taken as 0. */
	public var exposure(default, set):Float = 0;

	/** Gets or sets how exposed linear light is brought into the 0 to 1 an sRGB target holds: Neutral until set. Read as `exposure` is. */
	public var toneMapping:ToneMapping = Neutral;

	/** Creates a renderer over the graphics.

		It makes only what every batch shares: a white texture, the vertex buffers, and the programs it builds shaders into. Each batch
		makes its own default shaders when it is constructed, so a program carries the shaders of the batches it uses.
		@param graphics  The graphics to draw with. */
	public function new(graphics:IGraphics) {
		this.graphics = graphics;
		programs = new ShaderPrograms(graphics);
		var texel = Bytes.alloc(4);
		texel.fill(0, 4, 255);
		white = new Texture2D(graphics.createTexture(1, 1, [texel]), 1, 1);
		white.renderer = this;
	}

	function set_exposure(value:Float):Float {
		return exposure = Math.isFinite(value) ? value : 0;
	}

	/** Uploads an image as a texture, without mipmaps.

		@param image  The image. Its pixels are copied, so it may be changed or dropped after.
		@return  The texture, sampled linearly and clamped until its `sampling` is set; `Sampling`'s anisotropy sharpens it at grazing
			angles. `createTextureMipmapped` makes one that shrinks without shimmering.
		@throws String  An image larger than this GPU allows. */
	public function createTexture(image:Image):Texture2D {
		return own(new Texture2D(graphics.createTexture(image.width, image.height, [image.pixels]), image.width, image.height));
	}

	/** Uploads an image decoded for the GPU (helix-services' `Images.decodeForGpu`) as a texture, without mipmaps: in a page the browser's
		image goes to the GPU as it is, its pixels never held here.

		@param image  The decoded image. It is left to the caller, who disposes it once uploaded.
		@return  The texture, sampled linearly and clamped until its `sampling` is set, as `createTexture` gives one.
		@throws String  An image larger than this GPU allows. */
	public function createTextureFromImage(image:IDecodedImage):Texture2D {
		return own(new Texture2D(graphics.createTextureFromImage(image), image.width, image.height));
	}

	/** Uploads an image as a texture with its mipmaps, made on the CPU (helix-services' `Image.getMipmaps`), so it shrinks without
		shimmering.

		@param image  The image. Its pixels are copied, so it may be changed or dropped after.
		@return  The texture, sampled linearly and clamped until its `sampling` is set, its mipmaps blended (`MipmapFilter.Linear`);
			`Sampling`'s anisotropy sharpens it at grazing angles.
		@throws String  An image larger than this GPU allows. */
	public function createTextureMipmapped(image:Image):Texture2D {
		var levels = [image.pixels];
		for (level in image.getMipmaps())
			levels.push(level.pixels);
		var texture = new Texture2D(graphics.createTexture(image.width, image.height, levels), image.width, image.height);
		texture.mipmapped = true;
		texture.sampling = new Sampling(Linear, Clamp, Clamp, Linear);
		return own(texture);
	}

	/** Creates a render target: a texture that draws can go into, between `beginTarget` and `endTarget`.

		@param width  The width, in texels.
		@param height  The height, in texels.
		@param format  Optional. The texels' format: Rgba8, holding sRGB values as the screen does, or Rgba16f, holding linear light, where
			`IGraphics.canRender` allows it; defaults to Rgba8.
		@param depth  Optional. Its depth: none, a buffer, or a buffer sampled after the pass; defaults to a buffer.
		@param msaaSampleCount  Optional. The multisampling samples per pixel it is drawn with, resolved into the texture at the end of
			each pass, whatever its depth: 1 for none; the screen's (`IGraphics.msaaSampleCount`) when omitted, so its edges are smooth
			where the screen's are. Clamped to 1 to `IGraphics.maxMsaaSampleCount`, and to 1 where this GPU cannot multisample the
			format. raylib's render textures are 1, with depth.
		@return  The render target, holding transparent black until drawn into.
		@throws String  A size of 0 or less, or a format this GPU cannot draw into. */
	public function createRenderTarget(width:Int, height:Int, format:TextureFormat = Rgba8, depth:TargetDepth = Buffer, ?msaaSampleCount:Int):RenderTarget2D {
		if (width <= 0 || height <= 0)
			throw 'helix-render: a render target of ${width} x ${height}; its size is above 0';
		if (!graphics.canRender(format))
			throw 'helix-render: this GPU can\'t draw into a render target of format ${(format : Int)}';
		if (depth == Texture)
			throw "helix-render: TargetDepth.Texture waits on the platform's sampled depth (queued in docs/ROADMAP.md); use Buffer or None";
		// The count asked for, or the screen's, held to 1 to what this GPU draws the format with, a power of two as the platform rounds it.
		var asked = msaaSampleCount == null ? graphics.msaaSampleCount : msaaSampleCount;
		var most = Std.int(Math.min(graphics.maxMsaaSampleCount, graphics.getMaxRenderTargetMsaaSampleCount(format)));
		var samples = 1;
		while (samples * 2 <= asked && samples * 2 <= most)
			samples *= 2;
		var handle = graphics.createRenderTarget(width, height, format, depth != None, samples);
		var target = new RenderTarget2D(handle, width, height, format, depth, samples, null);
		return own(target);
	}

	/** Uploads six square images as a cube texture, without mipmaps, for a program's own shader to sample by direction (`samplerCube`).

		@param faces  The faces, in the order +X, -X, +Y, -Y, +Z, -Z, as a cube's faces are seen from inside it, each the same size. Their
			pixels are copied.
		@return  The cube texture, sampled linearly. `createCubeTextureMipmapped` makes one with mipmaps.
		@throws String  Not six faces, faces not square and alike, or larger than this GPU allows. */
	public function createCubeTexture(faces:Array<Image>):CubeTexture3D {
		checkFaces(faces);
		var levels:Array<Bytes> = [];
		levels.push(cubeLevel(faces));
		return cubeOf(levels, faces[0].width);
	}

	/** Uploads six square images as a cube texture with each face's mipmaps, made on the CPU, for a program's own shader to sample by
		direction (`samplerCube`).

		@param faces  The faces, in the order +X, -X, +Y, -Y, +Z, -Z, as a cube's faces are seen from inside it, each the same size. Their
			pixels are copied.
		@return  The cube texture, sampled linearly.
		@throws String  Not six faces, faces not square and alike, or larger than this GPU allows. */
	public function createCubeTextureMipmapped(faces:Array<Image>):CubeTexture3D {
		checkFaces(faces);
		var mips = [for (f in faces) f.getMipmaps()];
		var levels = [cubeLevel(faces)];
		for (level in 0...mips[0].length)
			levels.push(cubeLevel([for (m in mips) m[level]]));
		return cubeOf(levels, faces[0].width);
	}

	// Refuses faces that aren't six, square and alike.
	static function checkFaces(faces:Array<Image>):Void {
		if (faces.length != 6)
			throw 'helix-render: a cube texture of ${faces.length} faces; it takes six, +X, -X, +Y, -Y, +Z, -Z';
		var size = faces[0].width;
		for (f in faces)
			if (f.width != size || f.height != size)
				throw "helix-render: a cube texture's faces are square and alike";
	}

	// One level of a cube texture: its six faces' pixels, one after another.
	static function cubeLevel(faces:Array<Image>):Bytes {
		var bytes = Bytes.alloc(faces[0].width * faces[0].height * 4 * 6);
		for (i in 0...6)
			bytes.blit(i * faces[i].pixels.length, faces[i].pixels, 0, faces[i].pixels.length);
		return bytes;
	}

	function cubeOf(levels:Array<Bytes>, size:Int):CubeTexture3D {
		var cube = new CubeTexture3D(graphics.createCubeTexture(size, levels, Rgba8), size);
		cube.renderer = this;
		live.set(cube, cube.dispose);
		return cube;
	}

	/** Uploads a mesh's vertices and indices.

		The mesh's arrays are copied, so it may be changed or dropped after; `GpuMesh3D.update` sends it again. Its positions are kept on
		the CPU, and a skinned mesh's joints and weights, with each joint's box of the vertices it moves, for culling and
		`GpuMesh3D.computeBounds`.
		@param mesh  The mesh: positions, and its normals, texture coordinates, tangents, colors, joints and weights when it has them.
		@param updatedOften  Optional. Whether it will be updated often, as each frame for vertices moved on the CPU; defaults to false.
		@return  The uploaded mesh.
		@throws String  A mesh without positions, or whose arrays do not match its vertex count. */
	public function createMesh(mesh:Mesh3D, updatedOften = false):GpuMesh3D {
		var gpu = new GpuMesh3D();
		gpu.renderer = this;
		gpu.upload(mesh);
		live.set(gpu, gpu.dispose);
		return gpu;
	}

	/** Uploads a model: each mesh, each image as a texture without mipmaps, as raylib's `LoadModel` makes them, and each material as a
		`Material3D` over them; `createModelMipmapped` makes its textures with mipmaps.

		An image that is null (one the model couldn't read) gives no texture, and a material naming it draws without it. A mesh without a
		material in the file is given one more material, white, at the end of `materials`. Each texture's `colorSpace` is set from the
		slot it fills. Where
		helix-formats' `GltfMaterial` gives them, its alpha mode, cutoff and double-sidedness become `blend`, `alphaCutoff` and `cull`,
		its textures' samplers their `sampling`, its texture transform `textureTransform`, and its KHR_materials_clearcoat, sheen,
		specular, ior and emissive_strength values the material's; otherwise opaque, uncut, back faces culled, linear and repeated, and
		none of the extensions. An OBJ file's materials are shaded `Phong` from their Ks and Ns. Meshes keep their morph targets.

		Each image goes to the GPU once, taken from the model (`ModelImage3D.takeDecoded`) and disposed once sent: a second GpuModel3D of
		the same model has no textures. One GpuModel3D is drawn as often as wanted.
		@param model  The model, as helix-services' `Models` reads it.
		@param colorSpace  Optional. How the file's color factors and vertex colors are taken. `Auto`, the default, as the format says:
			glTF's are linear, its factors encoded to sRGB for the materials' 0xAARRGGBB colors and its vertex colors read as linear
			(`Material3D.colorSpace` Linear); an OBJ file's are sRGB. `Srgb` takes them as stored, as raylib does: each factor times 255
			into the color unconverted, and the materials' `colorSpace` Srgb, so base color, texture and vertex color are multiplied as
			stored and an unlit model with `toneMapped` off shows the file's numbers in an sRGB target as raylib does. `Linear` takes
			every file's as linear.
		@return  The uploaded model, which owns its meshes and textures. */
	public function createModel(model:Model3D, colorSpace:ColorSpace = Auto):GpuModel3D {
		return GpuModel3D.make(this, model, false, colorSpace);
	}

	/** Uploads a model as `createModel` does, its textures made with mipmaps (`createTextureMipmapped`, from each image's pixels), as
		three.js makes them.

		@param model  The model, as helix-services' `Models` reads it.
		@param colorSpace  Optional. How the file's color factors and vertex colors are taken, as `createModel` takes it; `Auto` by
			default.
		@return  The uploaded model, which owns its meshes and textures. */
	public function createModelMipmapped(model:Model3D, colorSpace:ColorSpace = Auto):GpuModel3D {
		return GpuModel3D.make(this, model, true, colorSpace);
	}

	/** Uploads a finished environment bake: its prefiltered and background cubes, and its irradiance.

		The first also makes the BRDF table every environment map shares.
		@param bake  The bake, `done`.
		@return  The environment map.
		@throws String  A bake not done, or a GPU that can't sample half floats (`IGraphics.canSample(Rgba16f)`). */
	public function createEnvironmentMap(bake:EnvironmentBake3D):EnvironmentMap3D {
		throw "helix-render: Renderer.createEnvironmentMap is not yet built (stage 4, environment maps)";
	}

	/** Uploads a font's atlas, so its text can be drawn.

		A bitmap font's atlas is sampled nearest, the others' linearly.
		@param font  The font, as helix-services' `Fonts` makes it.
		@return  The font, ready to draw and measure with. */
	public function createFont(font:Font2D):GpuFont2D {
		var atlas = createTexture(font.atlas);
		live.remove(atlas);
		if (font.kind == Bitmap)
			atlas.sampling = Sampling.NEAREST;
		var gpu = new GpuFont2D(font, atlas);
		live.set(gpu, gpu.dispose);
		return gpu;
	}

	/** Starts recording a frame, with the screen's pass.

		Given a color, the screen is cleared to it and the farthest depth. Omitted, the program clears nothing: the screen starts as the
		platform starts a frame, opaque black with the farthest depth (`IGraphics.beginFrame` clears every frame, and a swap chain need
		not keep the last frame's pixels), so a raylib layer's `ClearBackground` is `clearTarget`, and one recorded before any draw of the pass
		costs nothing past the platform's own clear. The viewport is all of it.

		A frame may draw only into render targets, with nothing in the screen's pass: `endFrame` draws them, and `IGraphics.present`, if
		the program calls it, shows the screen as cleared, its color or black.
		@param width  The framebuffer's width, in framebuffer pixels (`IWindow.framebufferWidth`).
		@param height  The framebuffer's height, in framebuffer pixels.
		@param clearColor  Optional. The color the screen is cleared to, as 0xAARRGGBB; opaque black when omitted.
		@throws String  A frame already being recorded, or a size of 0 or less. */
	public function beginFrame(width:Int, height:Int, ?clearColor:Int):Void {
		if (inFrame)
			throw "helix-render: beginFrame with a frame already being recorded; endFrame first";
		if (width <= 0 || height <= 0)
			throw 'helix-render: beginFrame of ${width} x ${height}; the framebuffer\'s size is above 0';
		inFrame = true;
		frameNumber++;
		passes.resize(0);
		reads.clear();
		screen = new RenderPass(null, 0, width, height, clearColor);
		pass = screen;
		resetViewportState();
		scissored = false;
	}

	/** Ends the frame and draws it: the shaders it draws with built where they aren't, then each shadow pass, each render target's pass, in
		the order begun, and the screen's, then `IGraphics.endFrame`.

		The frame is then submitted but not shown: the program calls `IGraphics.present`, and may read it back first
		(`IGraphics.readPixels(0, ...)`, or helix-services' `Screenshots.frameEnded`).
		@throws String  No frame being recorded, a batch still open, a target pass not ended, or a shader the GPU refused, with the
			compiler's log. */
	public function endFrame():Void {
		if (!inFrame)
			throw "helix-render: endFrame with no frame being recorded; beginFrame first";
		if (openBatch != null)
			throw "helix-render: endFrame with a batch still open; end it first";
		if (pass != screen)
			throw "helix-render: endFrame with a target pass not ended; endTarget first";
		var all = passes.concat([screen]);
		// The shaders and pipelines the frame draws with, built before its first pass.
		for (p in all)
			for (c in p.commands)
				switch c {
					case Draw(d):
						var spec = d.pipeline;
						if (spec.built == null || spec.built.handle == 0)
							spec.built = programs.getPipeline(spec.shader, spec.state, spec.layout);
					case _:
				}
		for (s in streams)
			s.prepare();
		programs.prepareFrame();
		try {
			for (p in all)
				run(p);
		} catch (e:Dynamic) {
			programs.finishFrame();
			finish();
			throw e;
		}
		programs.finishFrame();
		finish();
	}

	/** Starts a pass into a render target: the draws after it go into the target, until `endTarget`.

		Given a color, the target is cleared to it (decoded to linear light in an RGBA16F target, so it shows as given once resolved
		without tone mapping), and its depth to the farthest; omitted, the target keeps what it holds, its texels and its depth, as a
		painting, trails or raylib's render textures do. The viewport is all of it and nothing is clipped. Drawing the target into itself
		throws.

		**A target read earlier in the frame is copied on write.** When a draw recorded before this call reads the target, the pass goes
		into a fresh texture of the same size and format, which takes the target's place (`Texture2D.handle` and `sharedTexture` follow
		it): holding a copy of what the target held when omitted a color, or cleared to the color given. The earlier draw reads the old
		texture, so a screen draw shows the target as it was when the draw was recorded, as raylib's frame does. The old texture is
		freed after the frame; a target read and redrawn each frame costs one more texture of its size, and a copy when not cleared.
		@param target  The render target.
		@param clearColor  Optional. The color it is cleared to, as 0xAARRGGBB; it keeps what it holds when omitted.
		@throws String  No frame being recorded, a target pass already open, a batch open, or a disposed target. */
	public function beginTarget(target:RenderTarget2D, ?clearColor:Int):Void {
		if (!inFrame)
			throw "helix-render: beginTarget with no frame being recorded";
		if (pass != screen)
			throw "helix-render: beginTarget with a target pass already open; endTarget first";
		if (openBatch != null)
			throw "helix-render: beginTarget with a batch open; end it first";
		if (target.disposed)
			throw "helix-render: beginTarget into a disposed render target";
		flushOpen();
		screenViewport = [viewportX, viewportY, viewportWidth, viewportHeight];
		screenScissored = scissored;
		var copied = false;
		if (reads.exists(target.handle)) {
			// Read earlier in the frame: the pass goes into a fresh texture, the earlier draws keeping the old.
			var old = target.handle;
			var fresh = takeTarget(target);
			retire(target, old);
			target.moveTo(fresh);
			copied = clearColor == null;
			if (copied)
				copyFrom = old;
		}
		pass = new RenderPass(target, target.handle, target.width, target.height, copied ? 0x00000000 : clearColor);
		passes.push(pass);
		if (copied)
			recordCopy(copyFrom);
		resetViewportState();
		scissored = false;
	}

	/** Ends the target pass, going back to the screen's: its viewport and clip as they were before `beginTarget`.

		@throws String  No target pass open, or a batch still open. */
	public function endTarget():Void {
		if (pass == screen || !inFrame)
			throw "helix-render: endTarget with no target pass open";
		if (openBatch != null)
			throw "helix-render: endTarget with a batch still open; end it first";
		pass = screen;
		viewportX = screenViewport[0];
		viewportY = screenViewport[1];
		viewportWidth = screenViewport[2];
		viewportHeight = screenViewport[3];
		scissored = screenScissored;
	}

	/** Clears the current pass to a color: what was drawn into it before is dropped, and its depth is the farthest again.

		It is recorded where it is called, a batch open or not: the draws before it, the open batch's among them, are dropped, and those
		after it are drawn over the color, as raylib's `ClearBackground` between two draws. An open batch stays open, its draw state
		unchanged. The whole pass is cleared, whatever the viewport.
		@param color  The color, as 0xAARRGGBB.
		@throws String  No frame being recorded. */
	public function clearTarget(color:Int):Void {
		if (!inFrame)
			throw "helix-render: clearTarget with no frame being recorded";
		flushOpen();
		var kept:Array<RenderCommand> = [];
		for (c in pass.commands)
			switch c {
				case Draw(_):
				case _:
					kept.push(c);
			}
		pass.commands.resize(0);
		for (c in kept)
			pass.commands.push(c);
		pass.clear = color;
	}

	/** Sets the rectangle of the current pass that the following draws fill, until `resetViewport` or the pass's end.

		A `Batch2D` without a camera then measures from the viewport's top left, and a `Batch3D` takes its aspect from it, so a split
		screen or a design size fitted to the window (helix-services' `Screen.viewportX` and the rest) is drawn by setting it. It takes
		effect at the next `begin` of a batch, and setting it while a batch is open throws.
		@param x  The left edge, in the pass's pixels from its left.
		@param y  The top edge, in the pass's pixels from its top.
		@param width  The width, in pixels.
		@param height  The height, in pixels.
		@throws String  No frame being recorded, a batch open, or a size of 0 or less. */
	public function applyViewport(x:Int, y:Int, width:Int, height:Int):Void {
		if (!inFrame)
			throw "helix-render: applyViewport with no frame being recorded";
		if (openBatch != null)
			throw "helix-render: applyViewport with a batch open; it takes effect at a batch's begin";
		if (width <= 0 || height <= 0)
			throw 'helix-render: a viewport of ${width} x ${height}; its size is above 0';
		viewportX = x;
		viewportY = y;
		viewportWidth = width;
		viewportHeight = height;
	}

	/** Sets the viewport back to the whole pass.

		@throws String  No frame being recorded, or a batch open. */
	public function resetViewport():Void {
		if (!inFrame)
			throw "helix-render: resetViewport with no frame being recorded";
		if (openBatch != null)
			throw "helix-render: resetViewport with a batch open";
		resetViewportState();
	}

	/** Clips the following draws to a rectangle of the current pass, until `resetScissor` or the pass's end.

		It may be set while a batch is open; the draws before it are not clipped by it.
		@param x  The left edge, in the pass's pixels from its left.
		@param y  The top edge, in the pass's pixels from its top.
		@param width  The width, in pixels; 0 clips everything.
		@param height  The height, in pixels; 0 clips everything.
		@throws String  No frame being recorded, or a size below 0. */
	public function applyScissor(x:Int, y:Int, width:Int, height:Int):Void {
		if (!inFrame)
			throw "helix-render: applyScissor with no frame being recorded";
		if (width < 0 || height < 0)
			throw 'helix-render: a scissor of ${width} x ${height}; its size is 0 or more';
		flushOpen();
		scissored = true;
		pass.commands.push(Scissor(x, y, width, height));
	}

	/** Removes the clip that `applyScissor` set.

		@throws String  No frame being recorded. */
	public function resetScissor():Void {
		if (!inFrame)
			throw "helix-render: resetScissor with no frame being recorded";
		flushOpen();
		scissored = false;
		pass.commands.push(ResetScissor);
	}

	/** Frees everything made through it that the program hasn't disposed, then its own textures and buffers.

		It is called before `IGraphics.dispose`, outside a frame. */
	public function dispose():Void {
		if (inFrame)
			throw "helix-render: dispose inside a frame; after endFrame";
		var held = [for (k => f in live) f];
		for (f in held)
			f();
		live.clear();
		for (f in afterFrame)
			f();
		afterFrame.resize(0);
		for (_ => list in pool)
			for (entry in list)
				graphics.disposeTexture(entry.handle);
		pool.clear();
		for (s in streams)
			s.dispose();
		for (b in staticBuffers)
			graphics.disposeBuffer(b);
		staticBuffers.resize(0);
		for (d in dataTextures)
			graphics.disposeTexture(d);
		dataTextures.resize(0);
		white.dispose();
		programs.dispose();
	}

	// The shaders built on the GPU, the white texture every batch draws shapes and missing textures with.
	@:allow(helix.render)
	final programs:ShaderPrograms;

	@:allow(helix.render)
	final white:Texture2D;

	// What was made through it and not disposed, each with its dispose.
	@:allow(helix.render)
	final live = new haxe.ds.ObjectMap<{}, () -> Void>();
	// What is freed once the frame being recorded is drawn.
	final afterFrame:Array<() -> Void> = [];
	// The frame: its target passes in the order begun, the screen's, the pass being recorded, and the textures its draws read so far.
	final passes:Array<RenderPass> = [];
	var screen:Null<RenderPass> = null;

	// A pass's handle when it is a pass of updates alone, no pass on the GPU.
	static inline final UPDATES = -1;

	@:allow(helix.render)
	var pass:Null<RenderPass> = null;

	final reads = new Map<Int, Bool>();
	@:allow(helix.render)
	var frameNumber = 0;
	// The viewport, in the pass's pixels from its top left; the screen's while a target pass is open; whether a scissor is set.
	@:allow(helix.render)
	var viewportX = 0;

	@:allow(helix.render)
	var viewportY = 0;

	var screenViewport = [0, 0, 0, 0];
	var scissored = false;
	var screenScissored = false;
	var copyFrom = 0;
	// The batch open, and how its waiting draws are recorded.
	@:allow(helix.render)
	var openBatch:Null<{}> = null;

	@:allow(helix.render)
	var openFlush:Null<() -> Void> = null;

	// The frame's vertex streams, by name; static buffers the renderer made; data textures (bones).
	final streamsByName = new Map<String, RenderStream>();
	final streams:Array<RenderStream> = [];
	final staticBuffers:Array<Int> = [];
	final dataTextures:Array<Int> = [];
	// Draws made from the pool, reused frame to frame.
	final drawPool:Array<RenderDraw> = [];
	var drawsUsed = 0;
	// Pipelines' specs by shader, layout and state; states by their values.
	final specs = new haxe.ds.ObjectMap<Shader, haxe.ds.ObjectMap<ShaderVertexLayout, haxe.ds.ObjectMap<ShaderPipelineState, RenderPipeline>>>();
	final states = new Map<Int, Map<Int, ShaderPipelineState>>();
	// Render targets' textures retired by a copy on write or a resize, by size and format, each with the frame it was last used in.
	final pool = new Map<String, Array<{handle:Int, frame:Int}>>();
	final retiring:Array<{key:String, handle:Int}> = [];
	// The copy pass's shader, values and corner buffer, made when a target is first copied on write.
	var copyFill:Null<RenderFill> = null;
	var copyCorners = 0;

	static var copyLayout:Null<ShaderVertexLayout> = null;

	// Registers what it made, for dispose.
	function own<T:Texture2D>(texture:T):T {
		texture.renderer = this;
		live.set(texture, texture.dispose);
		return texture;
	}

	// Forgets what the program disposed.

	@:allow(helix.render)
	function forget(made:{}):Void
		live.remove(made);

	// Runs a release now, or after the frame being recorded when one is.

	@:allow(helix.render)
	function release(free:() -> Void):Void {
		if (inFrame)
			afterFrame.push(free);
		else
			free();
	}

	// Runs a texture update before the pass being recorded, or now outside a frame.

	@:allow(helix.render)
	function updateBeforePass(update:() -> Void):Void {
		if (!inFrame)
			update();
		else if (pass != screen)
			pass.updates.push(update);
		else {
			// The screen's pass runs last: a pass of updates alone keeps the update ahead of the target passes begun after it.
			var last = passes.length > 0 ? passes[passes.length - 1] : null;
			if (last == null || last.handle != UPDATES) {
				last = new RenderPass(null, UPDATES, 0, 0, null);
				passes.push(last);
			}
			last.updates.push(update);
		}
	}

	function resetViewportState():Void {
		viewportX = 0;
		viewportY = 0;
		viewportWidth = pass.width;
		viewportHeight = pass.height;
	}

	// Records the open batch's waiting draws.

	@:allow(helix.render)
	function flushOpen():Void
		if (openFlush != null)
			openFlush();

	// Opens a batch: none other may be.

	@:allow(helix.render)
	function opening(batch:{}, flush:() -> Void):Void {
		if (!inFrame)
			throw "helix-render: a batch's begin with no frame being recorded; Renderer.beginFrame first";
		if (openBatch != null)
			throw "helix-render: a batch's begin with a batch already open; end it first";
		openBatch = batch;
		openFlush = flush;
	}

	@:allow(helix.render)
	function closing(batch:{}):Void {
		if (openBatch != batch)
			throw "helix-render: a batch's end with the batch not open";
		openBatch = null;
		openFlush = null;
	}

	// The frame's stream of a name, made the first time.

	@:allow(helix.render)
	function stream(name:String, stride:Int, layout:ShaderVertexLayout):RenderStream {
		var s = streamsByName.get(name);
		if (s == null) {
			s = new RenderStream(graphics, stride, layout);
			streamsByName.set(name, s);
			streams.push(s);
		}
		return s;
	}

	// What helix-render's attributes read where a draw's buffers don't feed them, as its layouts' constants (the pipeline's): a normal
	// toward +z, a tangent along +x, white, a copy placed where it is, and 0 for joints, weights and custom data; the rest read
	// (0, 0, 0, 1) as the platform has it.
	@:allow(helix.render)
	static final unfedAttributes:Array<helix.services.shaders.ShaderVertexConstant> = [
		{name: "vertexNormal", values: [0, 0, 1]},
		{name: "vertexTangent", values: [1, 0, 0, 1]},
		{name: "vertexColor", values: [1, 1, 1, 1]},
		{name: "vertexCustomData", values: [0, 0, 0, 0]},
		{name: "vertexJoints", values: [0, 0, 0, 0]},
		{name: "vertexWeights", values: [0, 0, 0, 0]},
		{name: "instanceModel", values: [1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1]},
		{name: "instanceColor", values: [1, 1, 1, 1]}
	];

	// A static buffer the renderer keeps until it is disposed.

	@:allow(helix.render)
	function staticBuffer(data:Bytes, index:Bool):Int {
		var b = graphics.createStaticBuffer(data, data.length, index);
		staticBuffers.push(b);
		return b;
	}

	// A draw from the pool.

	@:allow(helix.render)
	function makeDraw(pipeline:RenderPipeline):RenderDraw {
		if (drawsUsed == drawPool.length)
			drawPool.push(new RenderDraw());
		var d = drawPool[drawsUsed++];
		d.pipeline = pipeline;
		d.resetBuffers();
		return d;
	}

	// Refuses a texture the pass being recorded draws into.

	@:allow(helix.render)
	function checkReadable(handle:Int):Void
		if (pass != null && pass.target != null && handle == pass.handle)
			throw "helix-render: a draw reads the render target its pass draws into; draw it into another target, or after endTarget";

	// Records a draw in the pass, noting the textures it reads; one reading the target drawn into is refused.

	@:allow(helix.render)
	function record(draw:RenderDraw):Void {
		for (t in draw.snapshot.textures)
			if (t != 0) {
				if (pass.target != null && t == pass.handle)
					throw "helix-render: a draw reads the render target its pass draws into; draw it into another target, or after endTarget";
				reads.set(t, true);
			}
		pass.addDraw(draw);
	}

	// Records a command other than a draw.

	@:allow(helix.render)
	function command(c:RenderCommand):Void
		pass.commands.push(c);

	// Whether the pass being recorded holds linear light: an RGBA16F target.

	@:allow(helix.render)
	function linearPass():Bool
		return pass.target != null && pass.target.format == Rgba16f;

	// The spec of a shader, a state and a layout, the same object each time.

	@:allow(helix.render)
	function pipelineFor(shader:Shader, state:ShaderPipelineState, layout:ShaderVertexLayout):RenderPipeline {
		var byLayout = specs.get(shader);
		if (byLayout == null)
			specs.set(shader, byLayout = new haxe.ds.ObjectMap());
		var byState = byLayout.get(layout);
		if (byState == null)
			byLayout.set(layout, byState = new haxe.ds.ObjectMap());
		var spec = byState.get(state);
		if (spec == null)
			byState.set(state, spec = new RenderPipeline(shader, state, layout));
		return spec;
	}

	// The state of these values, the same object each time; every helix-render shader is flipped by its clip scale.

	@:allow(helix.render)
	function stateFor(primitive:Primitive, indexed:Bool, blend:Blend, depthTest:DepthTest, depthWrite:Bool, cull:CullFace,
			colorWrite:ColorChannels):ShaderPipelineState {
		var code = (primitive : Int) | (indexed ? 4 : 0) | (depthTest : Int) << 3 | (depthWrite ? 32 : 0) | (cull : Int) << 6 | (colorWrite : Int) << 8;
		var byCode = states.get((blend : Int));
		if (byCode == null)
			states.set((blend : Int), byCode = new Map());
		var state = byCode.get(code);
		if (state == null)
			byCode.set(code, state = ShaderPipelineState.CLIP_SCALE.with({
				primitive: primitive,
				indexed: indexed,
				blend: blend,
				depthTest: depthTest,
				depthWrite: depthWrite,
				cull: cull,
				colorWrite: colorWrite
			}));
		return state;
	}

	// A data texture of a size, made once and kept.

	@:allow(helix.render)
	function dataTexture(width:Int, height:Int):Int {
		var handle = graphics.createDataTexture(width, height);
		dataTextures.push(handle);
		return handle;
	}

	// Frees a data texture made by dataTexture, after the frame being recorded when there is one.

	@:allow(helix.render)
	function disposeData(handle:Int):Void
		release(() -> {
			if (dataTextures.remove(handle))
				graphics.disposeTexture(handle);
		});

	// A fresh texture for a target copied on write: one the pool holds of its size and format, or a new one.
	function takeTarget(target:RenderTarget2D):Int {
		var list = pool.get(poolKey(target));
		if (list != null && list.length > 0)
			return list.pop().handle;
		return graphics.createRenderTarget(target.width, target.height, target.format, target.depth != None, target.msaaSampleCount);
	}

	@:allow(helix.render)
	static function poolKey(target:RenderTarget2D):String
		return '${target.width} ${target.height} ${(target.format : Int)} ${target.depth != None}';

	// A target's old texture, kept until the frame is drawn, then pooled.

	@:allow(helix.render)
	function retire(target:RenderTarget2D, handle:Int):Void
		retiring.push({key: poolKey(target), handle: handle});

	// The copy of a target's old texture into its new one, the pass's first draw.
	function recordCopy(from:Int):Void {
		if (copyFill == null) {
			var shader = RenderShaders.compileOwn("copy.vert", "copy.frag");
			copyFill = new RenderFill(shader);
			var corners = Bytes.alloc(24);
			for (i => v in [0., 0, 2, 0, 0, 2])
				corners.setFloat(i * 4, v);
			copyCorners = staticBuffer(corners, false);
			if (copyLayout == null)
				copyLayout = new ShaderVertexLayout([{stride: 8, placements: [{name: "corner", offset: 0}]}]);
		}
		var spec = pipelineFor(copyFill.shader, stateFor(Triangles, false, Blend.OPAQUE, Off, false, None, All), copyLayout);
		var d = makeDraw(spec);
		d.setBuffer(0, copyCorners);
		d.first = 0;
		d.count = 3;
		copyFill.values.writeTexture(copyFill.shader.getSampler("source"), from, Sampling.NEAREST);
		copyFill.values.capture(d.snapshot);
		pass.addDraw(d);
	}

	// Draws one pass of the frame.
	function run(p:RenderPass):Void {
		for (u in p.updates)
			u();
		if (p.handle == UPDATES)
			return;
		if (p.begin != null)
			p.begin(graphics);
		else if (p.target == null)
			graphics.beginFrame(p.width, p.height, p.clear == null ? 0xff000000 : p.clear);
		else if (p.clear == null)
			graphics.resumeTargetPass(p.handle);
		else {
			var c = p.clear, linear = p.target.format == Rgba16f;
			graphics.beginTargetPass(p.handle, channel(c >> 16 & 255, linear), channel(c >> 8 & 255, linear), channel(c & 255, linear), (c >>> 24) / 255);
		}
		for (s in p.streams)
			s.upload();
		for (c in p.commands)
			switch c {
				case Draw(d):
					graphics.draw(d.pipeline.built.handle, d.resolveBuffers(), null, d.indexBuffer, d.first, d.count, d.firstInstance, d.instanceCount,
						d.snapshot.textures, d.snapshot.samplings, d.snapshot.uniforms);
				case Viewport(x, y, w, h):
					graphics.applyViewport(x, p.height - y - h, w, h);
				case Scissor(x, y, w, h):
					graphics.applyScissor(x, p.height - y - h, w, h);
				case ResetScissor:
					graphics.resetScissor();
				case UpdateData(handle, w, h, data):
					graphics.updateTexture(handle, 0, 0, w, h, data);
			}
		if (p.target == null && p.begin == null)
			graphics.endFrame();
		else
			graphics.endTargetPass();
	}

	// A clear color's channel as the target holds it: as stored, or decoded to linear light in an RGBA16F target.
	static function channel(value:Int, linear:Bool):Float {
		var c = value / 255;
		return !linear ? c : c <= .04045 ? c / 12.92 : Math.pow((c + .055) / 1.055, 2.4);
	}

	// After the frame is drawn: what waited freed, retired targets pooled and those unused a frame freed, the streams emptied.
	function finish():Void {
		inFrame = false;
		pass = null;
		screen = null;
		for (f in afterFrame)
			f();
		afterFrame.resize(0);
		for (_ => list in pool) {
			var kept = [];
			for (entry in list)
				if (frameNumber - entry.frame > 1)
					graphics.disposeTexture(entry.handle);
				else
					kept.push(entry);
			list.resize(0);
			for (e in kept)
				list.push(e);
		}
		for (r in retiring) {
			var list = pool.get(r.key);
			if (list == null)
				pool.set(r.key, list = []);
			list.push({handle: r.handle, frame: frameNumber});
		}
		retiring.resize(0);
		for (s in streams)
			s.used = 0;
		drawsUsed = 0;
		passes.resize(0);
	}
}
