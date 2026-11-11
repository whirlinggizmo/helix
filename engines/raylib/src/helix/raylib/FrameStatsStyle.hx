package helix.raylib;

import helix.raylib.Raylib.*;

/** Represents how `DrawFrameStatsEx` (`helix.raylib.extras.Debug`) draws the frame's cost: which stats it shows, and their look.

	Every field has a default, so a style sets only what it changes: `{fontSize: 24, triangles: true}`.

	Each stat shown is a line of its own. */
@:structInit class FrameStatsStyle {
	/** Gets or sets a value indicating whether the frames a second show. Defaults to true. */
	public var fps:Bool = true;

	/** Gets or sets a value indicating whether the frame time shows: its mean and its slowest 5% (p95) over the last half second, in
		milliseconds. Defaults to true. */
	public var frameTime:Bool = true;

	/** Gets or sets a value indicating whether the last frame's draw calls show: how many draws it sent the GPU. Defaults to true. */
	public var drawCalls:Bool = true;

	/** Gets or sets a value indicating whether the last frame's triangles drawn show. Defaults to false. */
	public var triangles:Bool = false;

	/** Gets or sets a value indicating whether the last frame's state changes show: how often its draws switched shader, render state or
		textures. Defaults to false. */
	public var stateChanges:Bool = false;

	/** Gets or sets a value indicating whether the megabytes of textures helix-raylib holds on the GPU show. Defaults to false.

		Counts textures, cubemaps, render textures with their samples and depth, and the skinning palettes, as the graphics reports them,
		without the GPU's own padding. The screen's own aren't counted. */
	public var gpuTextures:Bool = false;

	/** Gets or sets a value indicating whether the megabytes of buffers helix-raylib holds on the GPU show. Defaults to false.

		Counts meshes' vertices and indices, the frame's batch and its quad indices, and a frame's instances, as the graphics reports them. */
	public var gpuBuffers:Bool = false;

	/** Gets or sets a value indicating whether the megabytes of memory the program holds show. Defaults to false.

		Natively, the process's resident memory.

		In a page, the script heap where the browser reports it, and nothing where it doesn't. */
	public var memory:Bool = false;

	/** Gets or sets the frame rate that sets the stats' color, in frames a second. Defaults to 0, for the target `SetTargetFPS` set, or the
		monitor's refresh rate when none is set. */
	public var targetFps:Int = 0;

	/** Gets or sets the text's color when the frame rate is at or above the target. Defaults to `GREEN`. */
	public var onTargetColor:Color = GREEN;

	/** Gets or sets the text's color when the frame rate is below the target. Defaults to `YELLOW`. */
	public var belowTargetColor:Color = YELLOW;

	/** Gets or sets the text's color when the frame rate is below half the target. Defaults to `RED`. */
	public var farBelowTargetColor:Color = RED;

	/** Gets or sets the font. Defaults to null, for raylib's default font. */
	public var font:Null<Font> = null;

	/** Gets or sets the text's height, in pixels. Defaults to null, which scales the text to the window.

		Null draws at a 36th of the screen's height (20 at 720 lines, as `DrawFPS` draws), so the stats read alike at any window size.

		A size provided is used unchanged. One under 1 is refused. */
	public var fontSize:Null<Int> = null;

	/** Gets or sets the space between letters, in pixels at the font's size, as `DrawTextEx`'s. Defaults to 1. */
	public var spacing:Float = 1;

	/** Gets or sets the space around the text inside its background, in pixels. Defaults to 4. */
	public var padding:Int = 4;

	/** Gets or sets the background's color behind the text and its padding. Defaults to `BLANK`, for none. */
	public var backgroundColor:Color = BLANK;
}
