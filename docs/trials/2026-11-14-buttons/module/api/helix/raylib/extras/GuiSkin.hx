package helix.raylib.extras;

import helix.raylib.*;

/** Represents a skin: how one part of raygui's controls is drawn from a texture, a nine-patch for each state, in place of its style's flat
	colors.

	Made by `GuiSkinFromTexture` and set by `GuiSetSkin`, both in `helix.raylib.extras.GuiSkins`. */
@:structInit
class GuiSkin {
	/** Gets or sets the texture holding the patches, often one sheet for every skin. */
	public var texture:Texture2D;

	/** Gets or sets the patch drawn in `STATE_NORMAL`. */
	public var normal:NPatchInfo;

	/** Gets or sets the patch drawn in `STATE_FOCUSED`, with the pointer over the control, or null to draw `normal`. */
	public var focused:Null<NPatchInfo>;

	/** Gets or sets the patch drawn in `STATE_PRESSED`, or null to draw `focused`, or `normal` when that is null too. */
	public var pressed:Null<NPatchInfo>;

	/** Gets or sets the patch drawn in `STATE_DISABLED`, or null to draw `normal`. */
	public var disabled:Null<NPatchInfo>;

	/** Gets or sets the tint multiplying the patches, `WHITE` to draw them unchanged. */
	public var tint:Color;

	/** Gets or sets how the patches fill a control across: `NPATCH_MODE_STRETCH`, `NPATCH_MODE_TILE` or `NPATCH_MODE_TILE_FIT` from
		`Textures`. `NPATCH_MODE_STRETCH` in a skin made by `GuiSkinFromTexture` or `GuiSkinFromSheet`. */
	public var horizontalPatchMode:Int;

	/** Gets or sets how the patches fill a control down, as `horizontalPatchMode`. */
	public var verticalPatchMode:Int;

	/** Gets or sets how a `GUI_SKIN_FILL` skin is drawn: `GUI_SKIN_FILL_STRETCHED` over the filled part, or `GUI_SKIN_FILL_CLIPPED`
		over the whole control and shown up to the filled part. `GUI_SKIN_FILL_STRETCHED` in a made skin. Read for a progress bar's
		progress and `GuiSliderBar`'s bar. */
	public var fillMode:Int;

	/** Gets or sets the texture a `GUI_SKIN_FILL` skin draws at the moving end of its fill, a thermometer's rounded tip or a line, or
		null for none. Drawn whole at the texture's size, centered on the fill's end, over the fill, at every value from the minimum to
		the maximum. It isn't clipped to the control: at the minimum and the maximum, half of it lies outside the control. Null in a
		made skin. */
	public var fillEdge:Null<Texture2D>;

	/** Gets or sets how far a control's text and icon move from where raygui draws them, in pixels, x right and y down, in
		`STATE_NORMAL`: (0, -2) to center them on a face whose bottom 4 pixels are a lip. (0, 0) in a skin made by `GuiSkinFromTexture`,
		set from the lip in one made by `GuiSkinFromSheet`. */
	public var normalTextOffset:Vector2;

	/** Gets or sets how far a control's text and icon move in `STATE_FOCUSED`, as `normalTextOffset`: (0, -4) for that face lifted
		2 pixels more. */
	public var focusedTextOffset:Vector2;

	/** Gets or sets how far a control's text and icon move in `STATE_PRESSED`, as `normalTextOffset`: (0, 2) for that face pushed
		down 4 pixels onto its lip. */
	public var pressedTextOffset:Vector2;

	/** Gets or sets how far a control's text and icon move in `STATE_DISABLED`, as `normalTextOffset`. */
	public var disabledTextOffset:Vector2;
}
