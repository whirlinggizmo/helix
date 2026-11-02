package helix.render;

/** Specifies the depth a render target has; its multisampling is chosen apart (`Renderer.createRenderTarget`'s `msaaSampleCount`). */
enum abstract TargetDepth(Int) {
	/** No depth: for a pass that draws over the whole target, as a screen effect does, or 2D. */
	var None = 0;

	/** A depth buffer, for 3D drawn into it. */
	var Buffer = 1;

	/** A depth buffer that can be sampled after the pass (`RenderTarget2D.depthTexture`), for effects that read depth: fog, depth of
		field, ambient occlusion, soft particles. */
	var Texture = 2;
}
