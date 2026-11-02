package helix.render;

import helix.platform.Sampling;
import helix.services.images.Image;
import helix.services.shaders.ShaderSharedTexture;

/** Represents an image on the GPU, drawn as a sprite, read by a material, or bound to a shader.

	`Renderer.createTexture` makes one from an `Image`; a `RenderTarget2D` is one that draws go into. The program frees it with `dispose`.
	Texture coordinates run from 0 at its left and top to 1 at its right and bottom, as its image's rows are stored; a render target's
	the same way, its top the top of what was drawn into it, on every backend.

	A program's own shader reads it through `sharedTexture`:

	```haxe
	values.shareTexture(shader.getSampler("noise"), noise.sharedTexture);
	``` */
class Texture2D {
	/** Gets the width, in texels. */
	public var width(default, null):Int;

	/** Gets the height, in texels. */
	public var height(default, null):Int;

	/** Gets or sets how its draws sample it: its filter, and how it wraps past its edges. Linear and clamped until set; `Sampling.NEAREST`
		suits pixel art. A change applies to the draws after it, a program's shader reading `sharedTexture` among them. */
	public var sampling(default, set):Sampling = Sampling.LINEAR;

	/** Gets or sets how helix-render's own shaders read its texels: Auto until set, as the slot it fills says (sRGB in a color slot,
		linear in a data slot). A custom shader is given its texels as they are, whatever this says. */
	public var colorSpace:ColorSpace = Auto;

	/** Gets the texture as helix-services' shared texture, for a program's own shader to read: shared on its values
		(`ShaderValues.shareTexture`), it reads this texture with its `sampling`.

		helix-render keeps it current: its handle follows the texture through a copy made when a render target is drawn into again
		(`Renderer.beginTarget`) and through `RenderTarget2D.resize`, and its sampling follows `sampling`. It reads 0, no texture, once
		the texture is disposed. A draw recorded reads it as it is when the draw is made. */
	public final sharedTexture:ShaderSharedTexture;

	/** Gets the platform's handle, for what only `IGraphics` does with it (`readPixels`, which reads any texture back); 0 once
		disposed. A render target's changes when a pass copies it on write (`Renderer.beginTarget`) and when it is resized; read it when
		it is used, and bind it to a shader through `sharedTexture`. */
	public var handle(default, null):Int;

	/** Gets a value indicating whether it has been disposed. */
	public var disposed(default, null):Bool = false;

	@:allow(helix.render)
	function new(handle:Int, width:Int, height:Int) {
		this.handle = handle;
		this.width = width;
		this.height = height;
		sharedTexture = new ShaderSharedTexture(handle, Sampling.LINEAR);
	}

	function set_sampling(value:Sampling):Sampling {
		sampling = value;
		sharedTexture.sampling = value;
		return value;
	}

	/** Replaces a rectangle of its texels with an image's pixels, for the draws after it.

		It is applied before the pass it is called in, so that pass's draws and the ones after read the new texels, and the passes before
		read the old (the platform's `updateTexture` goes between passes). Mipmaps are not made again.
		@param image  The pixels.
		@param x  Optional. The left edge of the rectangle replaced, in texels; defaults to 0.
		@param y  Optional. The top edge, in texels; defaults to 0.
		@throws String  A rectangle outside the texture, a render target, or a disposed texture. */
	public function update(image:Image, x = 0, y = 0):Void {
		if (disposed)
			throw "helix-render: update of a disposed texture";
		if (isTarget())
			throw "helix-render: update of a render target; draw into it instead";
		if (x < 0 || y < 0 || x + image.width > width || y + image.height > height || image.width <= 0 || image.height <= 0)
			throw 'helix-render: an update of ${image.width} x ${image.height} at ${x}, ${y} outside the ${width} x ${height} texture';
		var r = renderer, h = handle, pixels = image.pixels, w = image.width, hh = image.height;
		if (r == null)
			throw "helix-render: a texture made by no renderer";
		r.updateBeforePass(() -> r.graphics.updateTexture(h, x, y, w, hh, pixels));
	}

	/** Makes one of its texels opaque white and returns its region, for `Batch2D.shapeRegion`: shapes then draw from this texture, so
		they join one GPU draw with the sprites of a sheet or the text of a font's atlas, as raylib's `SetShapesTexture` has them.

		The program names a texel no sprite reads (a corner of the sheet's padding). Shapes read the texel's center alone, at full size,
		so one texel is enough whatever the sampling, and the mipmaps, which it leaves as they were, are never read for it.
		@param x  The texel's column, from the left.
		@param y  The texel's row, from the top.
		@return  The texel's region, one texel square.
		@throws String  A texel outside the texture, a render target, or a disposed texture. */
	public function writeWhiteTexel(x:Int, y:Int):TextureRegion2D {
		update(Image.filled(1, 1, 0xffffffff), x, y);
		return new TextureRegion2D(this, x, y, 1, 1);
	}

	/** Frees the texture on the GPU, after the frame being recorded when it holds a draw of it. A second call does nothing. */
	public function dispose():Void {
		if (disposed)
			return;
		disposed = true;
		var old = handle, r = renderer;
		handle = 0;
		sharedTexture.texture = 0;
		if (r != null) {
			r.forget(this);
			r.release(() -> r.graphics.disposeTexture(old));
		}
	}

	// The renderer that made it, and whether it was made with mipmaps.
	@:allow(helix.render)
	var renderer:Null<Renderer> = null;

	@:allow(helix.render)
	var mipmapped = false;

	// Whether it is a render target, which draws go into.
	function isTarget():Bool
		return false;

	// The handle a draw reads it by, refusing a disposed texture.

	@:allow(helix.render)
	function drawnHandle():Int {
		if (disposed)
			throw "helix-render: a draw of a disposed texture";
		return handle;
	}
}
