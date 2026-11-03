package helix.platform;

import helix.platform.DepthTest;
import helix.platform.ClipFlip;
import helix.platform.Blend;
import helix.platform.ColorChannels;

/** Represents everything a pipeline fixes for the draws through it.

	`IGraphics.createPipeline` makes a pipeline from it. An adapter makes what the description specifies and knows nothing else about the
	program. */
typedef PipelineDesc = {
	/** The program, as an `IGraphics.createShader` handle. */
	final shader:Int;

	/** The vertex buffers' layouts, by their index in a draw's buffers: at most 8, with at most 16 attributes across them, each at a slot
		from 0 to 15, as every adapter takes them. */
	final buffers:Array<VertexBuffer>;

	/** The primitive the draws make. */
	final primitive:Primitive;

	/** Whether the draws are indexed, by uint32 indices. */
	final indexed:Bool;

	/** How the colors are combined with the target's. */
	final blend:Blend;

	/** The color channels the draws write; omitted, all of them. A channel left out keeps the target's value, blended or not. Depth is
		written as `depthWrite` specifies, and a depth-only pipeline writes no color whatever this holds. */
	final ?colorWrite:ColorChannels;

	/** The depth test. */
	final depthTest:DepthTest;

	/** Whether the draws write depth. */
	final depthWrite:Bool;

	/** Which faces are culled. */
	final cull:CullFace;

	/** Whether clockwise winding is the front face. */
	final clockwise:Bool;

	/** Whether the draws write depth alone, for a shadow pass. */
	final depthOnly:Bool;

	/** How a draw into a render target is turned the right way up, and through which uniform: the one at `flipBlockSlot` and
		`flipOffset`. */
	final flip:ClipFlip;

	/** The slot of the vertex stage's block holding the uniform `flip` reads. Optional; 0 when omitted. */
	final ?flipBlockSlot:Int;

	/** The byte offset in its block of the uniform `flip` reads. Optional; 0 when omitted. The adapter flips its own copy of the bytes
		as it uploads them, never the caller's, and reverses the winding with it, so `clockwise` and `cull` hold in a target and on the
		screen alike. */
	final ?flipOffset:Int;

	/** What attributes no buffer feeds read, by slot: up to four floats each, the rest 0, 0, 1 as (0, 0, 0, 1) has them, the same for
		every vertex and instance. Optional; a slot not given reads (0, 0, 0, 1). A constant for a slot a buffer feeds is refused. */
	final ?attributeConstants:Array<{slot:Int, values:Array<Float>}>;
}
