package helix.raylib.extras;

/** Represents a skin: how a part of raygui's controls is drawn from a texture, a nine-patch for each state, in place of its style's
	flat colors. Made by `GuiSkinFromTexture` and set by `GuiSetSkin` (`helix.raylib.extras.GuiSkins`). */
@:structInit
class GuiSkin {
	/** Gets or sets the texture the patches are cut from, often one sheet for every skin. */
	public var texture:Texture2D;

	/** Gets or sets the patch drawn in `STATE_NORMAL`. */
	public var normal:NPatchInfo;

	/** Gets or sets the patch drawn in `STATE_FOCUSED`, with the pointer over the control, or null to draw `normal`. */
	public var focused:Null<NPatchInfo>;

	/** Gets or sets the patch drawn in `STATE_PRESSED`, or null to draw `focused`, or `normal` when that is null too. */
	public var pressed:Null<NPatchInfo>;

	/** Gets or sets the patch drawn in `STATE_DISABLED`, or null to draw `normal`. */
	public var disabled:Null<NPatchInfo>;

	/** Gets or sets the color the patches are multiplied by, `WHITE` to draw them as they are. */
	public var tint:Color;
}
