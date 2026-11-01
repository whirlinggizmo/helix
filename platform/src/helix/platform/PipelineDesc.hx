package helix.platform;

import helix.platform.DepthTest;
import helix.platform.ClipFlip;

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
	final blend:BlendMode;

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

	/** What uniform block 0 holds, for drawing render targets the right way up. */
	final flip:ClipFlip;
}
