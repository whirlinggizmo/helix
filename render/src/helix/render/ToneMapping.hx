package helix.render;

/** Specifies how linear light, which can run past 1, is brought into the 0 to 1 an sRGB target holds, after the exposure.

	`Renderer.toneMapping` holds the one in use: `Batch3D`'s lit shaders apply it to color drawn straight into an sRGB target, and
	`PostProcess.draw` when it resolves a linear frame. The curves are three.js's, by the same names. */
enum abstract ToneMapping(Int) {
	/** Neither exposed nor mapped: clamped to 1. */
	var None = 0;

	/** Exposed, then clamped to 1. */
	var Linear = 1;

	/** Reinhard's curve: x / (1 + x). */
	var Reinhard = 2;

	/** The Cineon film curve, as three.js has it. */
	var Cineon = 3;

	/** ACES's filmic fit: more contrast, highlights desaturated. */
	var Aces = 4;

	/** AgX: highlights rolled toward white without shifting their hue. */
	var AgX = 5;

	/** Khronos PBR Neutral: colors as given up to near 1, highlights rolled off. */
	var Neutral = 6;
}
