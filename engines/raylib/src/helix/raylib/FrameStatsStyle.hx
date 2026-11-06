package helix.raylib;

import helix.raylib.Raylib.*;

/** Represents how DrawFrameStatsEx (helix.raylib.extras.Debug) draws the frame's cost: which stats, and in what look. Every field has a
	default, so a style sets only what it changes: `{fontSize: 24, triangles: true}`. Each stat shown is a line of its own. */
@:structInit class FrameStatsStyle {
	/** Whether it shows the frames a second. On by default. */
	public var fps:Bool = true;

	/** Whether it shows the frame time's mean and its slowest 5% (p95) over the last half second, in milliseconds. On by default. */
	public var frameTime:Bool = true;

	/** Whether it shows the last frame's draw calls: how many draws it sent the GPU. On by default. */
	public var drawCalls:Bool = true;

	/** Whether it shows the last frame's triangles drawn. Off by default. */
	public var triangles:Bool = false;

	/** Whether it shows the last frame's state changes: how often its draws switched shader, render state or textures. Off by default. */
	public var stateChanges:Bool = false;

	/** Whether it shows the megabytes of textures helix-raylib holds on the GPU: textures, cubemaps, render textures and the skinning
		palettes, as their levels' bytes, without the GPU's own padding. Off by default. */
	public var gpuTextures:Bool = false;

	/** Whether it shows the megabytes of buffers helix-raylib holds on the GPU: meshes' vertices and indices, the frame's batch and its
		quad indices, a frame's instances. Off by default. */
	public var gpuBuffers:Bool = false;

	/** Whether it shows the megabytes of memory the program holds, as the platform tells it (`ISystem.getMemoryBytes`): natively the
		process's resident memory, in a page the script heap where the browser reports it, and nothing where it doesn't. Off by default. */
	public var memory:Bool = false;

	/** The frame rate the stats are judged against, frames a second: 0 by default, for the target SetTargetFPS set, or the monitor's
		refresh rate when none is set. */
	public var targetFps:Int = 0;

	/** The text's color when the frame rate is at or above the target. GREEN by default. */
	public var onTargetColor:Color = GREEN;

	/** The text's color when the frame rate is below the target. YELLOW by default. */
	public var belowTargetColor:Color = YELLOW;

	/** The text's color when the frame rate is below half the target. RED by default. */
	public var farBelowTargetColor:Color = RED;

	/** The font, or null by default for raylib's default font. */
	public var font:Null<Font> = null;

	/** The text's height, in pixels, or null by default to scale it to the window: a 36th of the screen's height (20 at 720 lines, as
		DrawFPS draws), so the stats read alike at any window size. A size given is used as it is; one under 1 is refused. */
	public var fontSize:Null<Int> = null;

	/** The space between letters, in pixels at the font's size, as DrawTextEx's. 1 by default. */
	public var spacing:Float = 1;

	/** The space around the text inside its background, in pixels. 4 by default. */
	public var padding:Int = 4;

	/** The background's color behind the text and its padding. BLANK by default, for none. */
	public var backgroundColor:Color = BLANK;
}
