package helix.services.screen;

/** Specifies how `Screen` fits its design size to the window. The design is centred in the window under each, and its scale is a whole
	number when `Screen.integerScale` is set. */
#if !macro
@:build(helix.platform.macros.EnumNames.build())
#end
enum abstract ScreenFit(Int) {
	/** Scaled as large as it fits whole, keeping its shape; bars fill the rest. */
	var Keep = 0;

	/** Scaled as `Keep` is, then grown down and up to fill a window taller than the design, so more of the world shows above and below;
		bars beside it on a wider window. */
	var KeepWidth = 1;

	/** Scaled as `Keep` is, then grown across to fill a window wider than the design, so more of the world shows beside it; bars above
		and below on a taller window. */
	var KeepHeight = 2;

	/** Scaled as `Keep` is, then grown on its short side to fill the window, so more of the world shows on a wider or taller window and
		there are no bars. */
	var Expand = 3;

	/** Scaled as small as covers the window, keeping its shape; the design's edges past the window are cut off, and there are no bars. */
	var Cover = 4;

	/** Scaled to fill the window, its shape stretched to the window's. */
	var Stretch = 5;
}
