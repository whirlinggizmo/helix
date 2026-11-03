package helix.render.effects;

import helix.render.Renderer;
import helix.render.Texture2D;

/** Provides post-processing: a frame drawn into a texture, carried through a chain of screen effects and resolved into the current pass.

	A program draws its scene into a render target, an RGBA16F one for HDR (`Renderer.createRenderTarget(width, height, Rgba16f)`), whose
	3D is then linear light neither exposed nor tone mapped (`Batch3D`), and calls `draw` with it where the result belongs: the screen's
	pass, usually, before the HUD. The chain runs in three steps:

	1. its **linear** effects (`ScreenEffect.linear`: `BloomEffect`, a linear `ShaderEffect`), in their order in `effects`, on linear light;
	2. the **resolve**: the renderer's `exposure`, then its `toneMapping`, then the sRGB encode, every chain's, so a chain with no
	   effects is the resolve alone; the same pair `Batch3D` applies drawing straight into an sRGB target, read at each `draw`;
	3. its **display** effects (`ColorGradeEffect`, `FxaaEffect`, a `ShaderEffect`), in their order, on encoded colors, the last drawn
	   into the current pass.

	An RGBA8 source is display colors already: it is decoded for the linear effects and not tone mapped. Each step but the last draws into
	an intermediate target the chain keeps, sized to the source, as a target pass recorded before the current one, so `draw` may be called
	in the middle of the screen's pass. It runs no loop and reads no clock: the time it is given is what effects animate by.

	```haxe
	var scene = renderer.createRenderTarget(width, height, Rgba16f);
	var post = new PostProcess(renderer);
	post.effects.push(new BloomEffect());
	renderer.toneMapping = AgX;
	// each frame:
	renderer.beginFrame(width, height, 0xff000000);
	renderer.beginTarget(scene, 0xff000000);
	batch3D.begin(camera);
	drawWorld();
	batch3D.end();
	renderer.endTarget();
	post.draw(scene, time.elapsed);
	batch2D.begin(); // the HUD, after the resolve, untouched by it
	drawHud();
	batch2D.end();
	renderer.endFrame();
	``` */
class PostProcess {
	/** Gets the effects, in order; the program adds, removes and reorders them. Each is drawn while its `enabled` is set. */
	public final effects:Array<ScreenEffect> = [];

	/** Creates a chain of no effects over a renderer: the resolve alone.

		@param renderer  The renderer it records into. */
	public function new(renderer:Renderer) {}

	/** Carries a frame through the chain and draws the result over the current pass's viewport.

		@param source  The frame: a render target drawn this frame, or any texture.
		@param time  Optional. Seconds the effects animate by; defaults to 0.
		@throws String  No frame being recorded, a batch open, or the source being the current pass's target. */
	public function draw(source:Texture2D, time = 0.):Void {
		throw "helix-render: PostProcess.draw is not yet built (stage 5, post-processing)";
	}

	/** Frees its intermediate targets; the effects stay their owner's. */
	public function dispose():Void {
		throw "helix-render: PostProcess.dispose is not yet built (stage 5, post-processing)";
	}
}
