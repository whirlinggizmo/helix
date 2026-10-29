package helix.platform;

/** Specifies what a pipeline's draws make. */
@:build(helix.platform.macros.EnumNames.build())
enum abstract Primitive(Int) to Int {
	/** Triangles, three vertices or indices each. */
	var Triangles = 0;

	/** Lines, two vertices or indices each. */
	var Lines = 1;
}
