package helix.render;

import helix.platform.TextureFormat;

/** Represents a texture that draws go into: a pass between `Renderer.beginTarget` and `Renderer.endTarget` draws into it, and it is
	then drawn or sampled like any texture.

	`Renderer.createRenderTarget` makes one. Its format says what it holds: an RGBA8 target sRGB values, as the screen does, an RGBA16F
	one linear light, which may run past 1 and blends linearly; the batches' own shaders write each its kind (`Batch2D`, `Batch3D`). Drawn
	or sampled, its texels are what it holds, so an RGBA16F target reaches the screen through `PostProcess.draw`, which exposes, tone
	maps and encodes it. It is sampled the right way up, as an image is: v 0 at the top of what was drawn into it, on every backend.

	A pass into it starts cleared, or keeps what it holds (`Renderer.beginTarget`). Its multisampling is its own (`msaaSampleCount`,
	the screen's unless `Renderer.createRenderTarget` is given another), whatever its depth, and is resolved at the end of each pass;
	with `TargetDepth.Texture` its depth can be sampled after it.

	**Read, then drawn into again.** A draw reads the target as it is at that point of the frame's recording. A pass begun into it after
	something read it goes into a fresh copy that takes its place (copy on write, `Renderer.beginTarget`), so a screen draw recorded
	before shows it as it was, as raylib's frame does. Its `handle` changes then; `sharedTexture` follows.

	```haxe
	var minimap = renderer.createRenderTarget(256, 256);
	renderer.beginTarget(minimap, 0xff000000);
	batch.beginCamera(mapCamera);
	drawWorld(batch);
	batch.end();
	renderer.endTarget();
	batch.begin();
	batch.drawTexture(minimap, 16, 16);
	batch.end();
	``` */
class RenderTarget2D extends Texture2D {
	/** Gets the texels' format. */
	public final format:TextureFormat;

	/** Gets the depth it has. */
	public final depth:TargetDepth;

	/** Gets the number of multisampling samples per pixel it is drawn with, 1 for none: what `Renderer.createRenderTarget` was given,
		or the screen's, as this GPU allows it. It is kept through a copy and a resize. */
	public final msaaSampleCount:Int;

	/** Gets its depth as a texture, read as a float from 0 (near) to 1 (far) after each pass into it, for effects that read depth; null
		unless it was made with `TargetDepth.Texture`. It follows the target through a copy and a resize. */
	public final depthTexture:Null<Texture2D>;

	@:allow(helix.render)
	function new(handle:Int, width:Int, height:Int, format:TextureFormat, depth:TargetDepth, msaaSampleCount:Int, depthTexture:Null<Texture2D>) {
		super(handle, width, height);
		this.format = format;
		this.depth = depth;
		this.msaaSampleCount = msaaSampleCount;
		this.depthTexture = depthTexture;
	}

	/** Changes its size, as for a window resized: it then holds transparent black, and its depth the farthest.

		Draws recorded this frame before the call read it as it was; its old texture is freed after the frame. Its `handle` changes, and
		`sharedTexture` follows.
		@param width  The width, in texels.
		@param height  The height, in texels.
		@throws String  A size of 0 or less, a size this GPU can't make, a pass into it open, or a disposed target. */
	public function resize(width:Int, height:Int):Void {
		if (disposed)
			throw "helix-render: resize of a disposed render target";
		if (width <= 0 || height <= 0)
			throw 'helix-render: a render target resized to ${width} x ${height}; its size is above 0';
		var r = renderer;
		if (r == null)
			throw "helix-render: a render target made by no renderer";
		if (r.pass != null && r.pass.target == this)
			throw "helix-render: resize of a render target whose pass is open; endTarget first";
		var fresh = r.graphics.createRenderTarget(width, height, format, depth != None, msaaSampleCount);
		var old = handle;
		this.width = width;
		this.height = height;
		moveTo(fresh);
		r.release(() -> r.graphics.disposeTexture(old));
	}

	override function isTarget():Bool
		return true;

	// Takes another texture's place: a copy made on write, or a resize.

	@:allow(helix.render)
	function moveTo(fresh:Int):Void {
		handle = fresh;
		sharedTexture.texture = fresh;
	}
}
