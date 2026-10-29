package helix.platform;

/** Specifies which faces of a pipeline's triangles are not drawn. */
@:build(helix.platform.macros.EnumNames.build())
enum abstract CullFace(Int) to Int {
	/** No faces are culled: both sides are drawn. */
	var None = 0;

	/** Back faces, those facing away, are culled: the far side of a closed surface. */
	var Back = 1;

	/** Front faces are culled: only a surface's far side is drawn, as for an outline's shell. */
	var Front = 2;
}
