package helix.render.effects;

/** Represents FXAA: edges smoothed by their contrast in the encoded frame, an antialiasing for a frame drawn without multisampling.

	A render target is multisampled as the screen is unless made with another count (`RenderTarget2D.msaaSampleCount`), so a frame drawn
	into one needs FXAA only where its count is 1: a phone, a program asking for no multisampling, a target made with 1. It works after
	the resolve, best last. */
class FxaaEffect extends ScreenEffect {
	/** Creates the effect. */
	public function new() {
		super(false);
	}
}
