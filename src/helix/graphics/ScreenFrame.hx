package helix.graphics;

import helix.render2d.Texture2D;

/** What a screen effect draws from in a PostProcess chain, this frame: the frame it changes, its size, the time, and the intermediates it asked
	for (ScreenEffect.intermediates), made by PostProcess at their sizes in the frame's format. */
class ScreenFrame {
	/** The frame the effect changes: the scene, or the effect before's result. */
	public final source:Texture2D;

	/** The size of the frame the effect draws, in framebuffer pixels. */
	public final width:Int;

	/** The size of the frame the effect draws, in framebuffer pixels. */
	public final height:Int;

	/** Seconds since the effect began (the time PostProcess.endScene was given). */
	public final time:Float;

	/** The effect's intermediates, in the order of its ScreenEffect.intermediates: textures without depth, each that fraction of width and
		height (at least a pixel), half floats where source is. */
	public final intermediates:Array<Texture2D>;

	/** A frame for an effect: source, width x height framebuffer pixels, time seconds, its intermediates. */
	public function new(source:Texture2D, width:Int, height:Int, time:Float, intermediates:Array<Texture2D>) {
		this.source = source;
		this.width = width;
		this.height = height;
		this.time = time;
		this.intermediates = intermediates;
	}
}
