package helix.platform;

/** Specifies what a pipeline's draws make. */
@:build(helix.platform.macros.EnumNames.build())
enum abstract Primitive(Int) to Int {
	/** Triangles, three vertices or indices each. */
	var Triangles = 0;

	/** Lines, two vertices or indices each. */
	var Lines = 1;

	/** Points, one vertex or index each, drawn one pixel in size on every backend; culling ignores them.

		The pipeline's program must be compiled with `ShaderCompileOptions.points` (`ShaderSource.points`); `IGraphics.createPipeline`
		refuses any other. */
	var Points = 2;
}
