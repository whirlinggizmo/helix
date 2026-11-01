package helix.platform;

/** Specifies what one side of a blend is multiplied by.

	The source is the color a draw writes, and the destination the color already in the target. Each factor is a value per channel. */
@:build(helix.platform.macros.EnumNames.build())
enum abstract BlendFactor(Int) to Int {
	/** 0: the side adds nothing. */
	var Zero = 0;

	/** 1: the side as it is. */
	var One = 1;

	/** The source color, channel by channel. */
	var SourceColor = 2;

	/** 1 minus the source color, channel by channel. */
	var OneMinusSourceColor = 3;

	/** The destination color, channel by channel. */
	var DestinationColor = 4;

	/** 1 minus the destination color, channel by channel. */
	var OneMinusDestinationColor = 5;

	/** The source's alpha. */
	var SourceAlpha = 6;

	/** 1 minus the source's alpha. */
	var OneMinusSourceAlpha = 7;

	/** The destination's alpha. */
	var DestinationAlpha = 8;

	/** 1 minus the destination's alpha. */
	var OneMinusDestinationAlpha = 9;

	/** The smaller of the source's alpha and 1 minus the destination's alpha for red, green and blue, and 1 for alpha. */
	var SourceAlphaSaturated = 10;
}
