package helix.platform;

/** Specifies which faces of a pipeline's triangles are not drawn. */
@:build(helix.platform.macros.EnumNames.build())
enum abstract CullFace(Int) to Int {
	/** No faces are culled, so both sides are drawn. */
	var None = 0;

	/** Back faces, the ones facing away, are culled. This skips the far side of a closed surface. */
	var Back = 1;

	/** Front faces are culled, so only a surface's far side is drawn, as for an outline's shell. */
	var Front = 2;
}
