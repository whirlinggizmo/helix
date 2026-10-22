package helix.render3d;

/** How a sprite (3D or 2D) or a particle uses its texels' alpha. */
enum abstract SpriteAlpha3D(Int) to Int {
	/** Ignored: drawn solid, with the opaque models. */
	var Opaque = 0;

	/** Texels below a cutoff are cut out, the rest solid: leaves, fences. Drawn with the opaque models. */
	var Mask = 1;

	/** Blended by it, among the see-through models back to front. */
	var Blend = 2;

	/** Added, times it, after everything else: light, fire, glows. */
	var Add = 3;
}
