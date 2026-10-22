package helix.render2d;

import helix.graphics.IGraphics;
import helix.graphics.PostProcess;
import helix.scene.Node;

/** What a frame's views hand the stage as the walk reaches them, as functions, so the stage names no view and a program that makes none
	carries none of their code (docs/DISPLAY_MODEL.md); and a chain's calls, made only when one is set. The engine's, not a game's. */
@:noCompletion
class ViewFrame {
	/** The 3D views' draws, under the 2D, before the batch ends: this frame's. */
	public static var drawsUnder:Array<Void->Void> = [];

	/** The 3D views' shadows, drawn before the next frame opens. */
	public static var shadows:Array<Void->Void> = [];

	/** The views with a chain, drawn into their textures before the next frame opens. */
	public static var renders:Array<(IGraphics, Float) -> Void> = [];

	/** The 3D views a pick passed over the point in, the topmost last: what each has under x, y, the hit filled. */
	public static var picks3D:Array<(Float, Float, Any) -> Null<Node>> = [];

	/** Whether the frame's 3D is drawn into an HDR scene (the chain it's drawn into wants it): the 3D views write their light untone-mapped. */
	public static var hdr = false;

	/** chain's calls, or null for none: made only where a chain is set, so a program setting none carries none of PostProcess. */
	public static function callsOf(chain:Null<PostProcess>):Null<ChainCalls> {
		if (chain == null)
			return null;
		return {
			begin: (width, height, color) -> chain.beginScene(width, height, color),
			end: time -> chain.endScene(time),
			present: () -> chain.present(),
			hdr: () -> chain.hdr
		};
	}
}

/** A chain's calls (PostProcess's beginScene, endScene, present and hdr), through the object, so a hot reload reaches the new code. */
@:noCompletion
typedef ChainCalls = {
	var begin:(Int, Int, Int) -> Void;
	var end:Float->Void;
	var present:Void->Void;
	var hdr:Void->Bool;
}
