package helix.services.shaders;

import haxe.io.Bytes;
import helix.platform.Sampling;

/** Represents a copy of values as a draw would read them now, for a batcher that records draws and submits them later.

	A draw through `IGraphics.draw` reads the values during the call, so a draw made at once needs none of this. A recorded draw does:
	`ShaderValues.capture` fills a snapshot with the bytes, textures and samplings as they are, and the recorded draw submits the
	snapshot's arrays. A snapshot reuses its bytes and arrays from one capture to the next, so a batcher keeping a pool of them
	allocates nothing per draw once they have grown.

	A snapshot is of the layout it was captured in. Replacements take effect only at a frame's start (`Shaders.prepareFrame`, then
	`ShaderPrograms.prepareFrame`), so a snapshot captured and submitted within one frame always meets the program it was captured for;
	one kept across frames is captured again. */
class ShaderSnapshot {
	/** Gets each block's bytes as captured, by slot, as `IGraphics.draw`'s `uniforms`. */
	public final uniforms:Array<Null<Bytes>> = [];

	/** Gets the textures as captured, by slot. */
	public final textures:Array<Int> = [];

	/** Gets the samplings as captured, by slot. */
	public final samplings:Array<Sampling> = [];

	/** Creates an empty snapshot. */
	public function new() {}
}
