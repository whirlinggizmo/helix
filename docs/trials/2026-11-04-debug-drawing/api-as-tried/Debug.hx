package helix.raylib.extras;

import helix.raylib.*;

/** Provides drawing for looking at what a program does: a model's skeleton as posed, its posed bounds, and the frame's cost.
	helix-raylib's own. raylib's DrawModelWires, DrawBoundingBox, DrawGrid and DrawFPS draw the rest.
	Imported apart: `import helix.raylib.extras.Debug.*;`. */
class Debug {
	/** Draws a model's skeleton as its last UpdateModelAnimation posed it: a line from each bone to its parent, and a small cross at
		each joint, placed as DrawModel places the model. A model never posed draws its bind pose; one without bones draws nothing.
		Drawn in 3D mode (BeginMode3D), over what's drawn before it, as DrawLine3D is.

		@param model  The model.
		@param position  Where the model is drawn, as DrawModel's.
		@param scale  Its scale, as DrawModel's.
		@param color  The lines' color. */
	public static function DrawModelSkeleton(model:Model, position:Vector3, scale:Float, color:Color):Void {
		throw "not built yet";
	}

	/** Draws a model's bounds as posed, GetModelBoundingBoxPosed's box (helix.raylib.extras.Models), placed as DrawModel places the
		model. Drawn in 3D mode, as DrawBoundingBox is.

		@param model  The model.
		@param position  Where the model is drawn, as DrawModel's.
		@param scale  Its scale, as DrawModel's.
		@param color  The box's color. */
	public static function DrawModelBoundingBoxPosed(model:Model, position:Vector3, scale:Float, color:Color):Void {
		throw "not built yet";
	}

	/** Draws the frame's cost at a point on the screen, as DrawFPS draws the rate, in FrameStatsStyle's default look at a size: the
		frames a second, the frame time's mean and its slowest 5% (p95) over the last half second, in milliseconds, and the last frame's
		draw calls, a line each. Its color is judged against the target frame rate (FrameStatsStyle.targetFps). The same as
		`DrawFrameStatsEx(new Vector2(posX, posY), {fontSize: fontSize})`.

		@param posX  The text's left, in pixels.
		@param posY  The text's top, in pixels.
		@param fontSize  The text's height, in pixels, as DrawText's; DrawFPS draws at 20. */
	public static function DrawFrameStats(posX:Int, posY:Int, fontSize:Int):Void {
		throw "not built yet";
	}

	/** Draws the frame's cost at a point on the screen as a style says: which stats, in what font, size, spacing and colors, over what
		background. Each stat is a line, so the text's height follows what's shown (MeasureFrameStats).

		```haxe
		DrawFrameStatsEx(new Vector2(10, 10), {fontSize: 24, backgroundColor: Fade(BLACK, 0.5), triangles: true});
		```

		@param position  The text's top left, in pixels (its background's, padding around the text).
		@param style  What to show and how; each field left out takes its default. */
	public static function DrawFrameStatsEx(position:Vector2, style:FrameStatsStyle):Void {
		throw "not built yet";
	}

	/** Returns the size DrawFrameStatsEx draws in with a style, its padding included, for placing it (at a corner, say).

		@param style  What to show and how.
		@return  The width and height, in pixels. */
	public static function MeasureFrameStats(style:FrameStatsStyle):Vector2 {
		throw "not built yet";
	}
}
