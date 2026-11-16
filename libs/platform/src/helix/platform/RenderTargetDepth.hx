package helix.platform;

/** Specifies the depth a render target has (`IGraphics.createRenderTarget`). */
@:build(helix.platform.macros.EnumNames.build())
enum abstract RenderTargetDepth(Int) to Int {
	/** No depth: for a pass that draws over the whole target, as a screen effect does, or 2D. */
	var None = 0;

	/** A depth buffer its passes test and write, for 3D drawn into it. */
	var Buffer = 1;

	/** A depth texture its passes test and write, which a shader samples after them (`IGraphics.getRenderTargetDepth`), for a shadow map
		or an effect that reads depth. The target has one sample. */
	var Texture = 2;
}
