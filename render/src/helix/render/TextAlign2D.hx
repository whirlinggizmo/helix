package helix.render;

/** Specifies where each line of a `TextLayout2D` sits across its box. */
#if !macro
@:build(helix.platform.macros.EnumNames.build())
#end
enum abstract TextAlign2D(Int) {
	/** Each line starts at the box's left edge. */
	var Left = 0;

	/** Each line is centered in the box. */
	var Center = 1;

	/** Each line ends at the box's right edge. */
	var Right = 2;
}
