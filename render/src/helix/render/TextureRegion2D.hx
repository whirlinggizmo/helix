package helix.render;

/** Represents a rectangle of a texture drawn as a sprite: a frame of a sprite sheet, an image on an atlas, or the whole texture, with the
	point it is placed and turned by.

	It is a plain value, made once and drawn often (`Batch2D.drawSprite`, `Batch3D.drawBillboard`); it holds the texture without owning
	it. Its origin is the point `drawSprite` places at the position given and turns about when the call gives none: its top left until
	given, as a texture is placed by `drawTexture`, so a sheet's frames of one character, which share their feet's place, are given it
	once.

	```haxe
	var walk = TextureRegion2D.split(sheet, 32, 48, 0, 0, 6, 16, 46); // six frames, placed by their feet
	var coin = TextureRegion2D.fromTexture(coinTexture, 8, 8); // the whole texture, turned about its middle
	batch.drawSprite(walk[frame], x, y);
	batch.drawSprite(coin, coinX, coinY, spin);
	``` */
class TextureRegion2D {
	/** Gets the texture. */
	public final texture:Texture2D;

	/** Gets the region's left edge, in texels from the texture's left. */
	public final regionX:Float;

	/** Gets the region's top edge, in texels from the texture's top. */
	public final regionY:Float;

	/** Gets the region's width, in texels. */
	public final regionWidth:Float;

	/** Gets the region's height, in texels. */
	public final regionHeight:Float;

	/** Gets the point it is placed and turned by when a draw gives none, across, in texels from the region's left: 0 until given. */
	public final originX:Float;

	/** Gets the point it is placed and turned by when a draw gives none, down, in texels from the region's top: 0 until given. */
	public final originY:Float;

	/** Returns the frames of a sprite sheet laid out in a grid: row by row, left to right, top to bottom.

		@param texture  The sheet.
		@param frameWidth  Each frame's width, in texels.
		@param frameHeight  Each frame's height, in texels.
		@param margin  Optional. The texels around the grid, at the sheet's edges; defaults to 0.
		@param spacing  Optional. The texels between two frames; defaults to 0.
		@param frameCount  Optional. How many frames there are, for a last row not full; every whole frame that fits when omitted.
		@param originX  Optional. Each frame's origin across, in texels from its left; defaults to 0.
		@param originY  Optional. Each frame's origin down, in texels from its top; defaults to 0.
		@return  The frames' regions.
		@throws String  A frame size of 0 or less. */
	public static function split(texture:Texture2D, frameWidth:Float, frameHeight:Float, margin = 0., spacing = 0., ?frameCount:Int, originX = 0.,
			originY = 0.):Array<TextureRegion2D> {
		if (frameWidth <= 0 || frameHeight <= 0)
			throw 'helix-render: frames of ${frameWidth} x ${frameHeight}; a frame\'s size is above 0';
		var frames = [];
		var y = margin;
		while (y + frameHeight <= texture.height - margin + 1e-9) {
			var x = margin;
			while (x + frameWidth <= texture.width - margin + 1e-9) {
				if (frameCount != null && frames.length >= frameCount)
					return frames;
				frames.push(new TextureRegion2D(texture, x, y, frameWidth, frameHeight, originX, originY));
				x += frameWidth + spacing;
			}
			y += frameHeight + spacing;
		}
		return frames;
	}

	/** Returns a region of a whole texture, placed and turned by a point of it.

		@param texture  The texture.
		@param originX  Optional. The origin across, in texels from the texture's left; defaults to 0. Half its width centers it.
		@param originY  Optional. The origin down, in texels from the texture's top; defaults to 0.
		@return  The region. */
	public static function fromTexture(texture:Texture2D, originX = 0., originY = 0.):TextureRegion2D {
		return new TextureRegion2D(texture, 0, 0, texture.width, texture.height, originX, originY);
	}

	/** Creates a region of a texture.

		@param texture  The texture.
		@param regionX  The left edge, in texels from the texture's left.
		@param regionY  The top edge, in texels from the texture's top.
		@param regionWidth  The width, in texels.
		@param regionHeight  The height, in texels.
		@param originX  Optional. The origin across, in texels from the region's left; defaults to 0. Half the width centers it.
		@param originY  Optional. The origin down, in texels from the region's top; defaults to 0. */
	public function new(texture:Texture2D, regionX:Float, regionY:Float, regionWidth:Float, regionHeight:Float, originX = 0., originY = 0.) {
		this.texture = texture;
		this.regionX = regionX;
		this.regionY = regionY;
		this.regionWidth = regionWidth;
		this.regionHeight = regionHeight;
		this.originX = originX;
		this.originY = originY;
	}
}
