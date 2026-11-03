package helix.raylib;

/** Represents raylib's `NPatchInfo`: how `DrawTextureNPatch` cuts a texture into a nine-patch or a three-patch. */
@:structInit
class NPatchInfo {
	/** Gets or sets the patch's rectangle on the texture, in texels. */
	public var source:Rectangle;

	/** Gets or sets the left border's width, in texels. */
	public var left:Int;

	/** Gets or sets the top border's height, in texels. */
	public var top:Int;

	/** Gets or sets the right border's width, in texels. */
	public var right:Int;

	/** Gets or sets the bottom border's height, in texels. */
	public var bottom:Int;

	/** Gets or sets the layout (`NPATCH_*`): nine patches, or three across or down. */
	public var layout:Int;

	/** Creates a patch's record.

		@param source  Optional. The patch's rectangle on the texture; an empty one when omitted.
		@param left  The left border's width.
		@param top  The top border's height.
		@param right  The right border's width.
		@param bottom  The bottom border's height.
		@param layout  The layout (`NPATCH_*`). */
	public function new(?source:Rectangle, left:Int = 0, top:Int = 0, right:Int = 0, bottom:Int = 0, layout:Int = 0) {
		this.source = source == null ? new Rectangle() : source;
		this.left = left;
		this.top = top;
		this.right = right;
		this.bottom = bottom;
		this.layout = layout;
	}
}
