package helix.platform;

/** Specifies how a blend combines its two sides, each already multiplied by its factor.

	The source is the color a draw writes, and the destination the color already in the target. Min and Max take the two colors as they
	are, and their factors are ignored. */
@:build(helix.platform.macros.EnumNames.build())
enum abstract BlendOperation(Int) to Int {
	/** The source plus the destination. */
	var Add = 0;

	/** The source minus the destination. */
	var Subtract = 1;

	/** The destination minus the source. */
	var ReverseSubtract = 2;

	/** The smaller of the source and the destination, channel by channel. */
	var Min = 3;

	/** The larger of the source and the destination, channel by channel. */
	var Max = 4;
}
