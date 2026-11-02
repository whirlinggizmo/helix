package helix.services.screen;

/** Specifies how `Screen` fits its design size to the window. */
#if !macro
@:build(helix.platform.macros.EnumNames.build())
#end
enum abstract ScreenFit(Int) {
	/** Scaled as large as it fits whole, keeping its shape; bars fill the rest. */
	var Letterbox = 0;

	/** Scaled by the largest whole number that fits, keeping its shape and every pixel square and alike; bars fill the rest. */
	var PixelPerfect = 1;

	/** Scaled to fill the window, its shape stretched to the window's. */
	var Stretch = 2;

	/** Scaled as large as it fits whole, keeping its shape, then grown on its short side to fill the window, so more of the world shows
		on a wider or taller window and there are no bars. */
	var Expand = 3;
}
