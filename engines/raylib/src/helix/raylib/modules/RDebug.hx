package helix.raylib.modules;

#if !macro
import helix.raylib.*;
import helix.raylib.modules.RCore.*;
import helix.raylib.modules.RMath.*;
import helix.raylib.modules.RModels.*;
import helix.raylib.modules.RModelsPosed.*;
import helix.raylib.modules.RShapes.*;
import helix.raylib.modules.RText.*;
import helix.raylib.internal.Frame;
import helix.raylib.internal.Runtime;
#end

/** Holds helix-raylib's drawing for looking at what a program does: a model's skeleton and bounds as posed, and the frame's cost. Each
	is written here, and `helix.raylib.extras.Debug` forwards to each (`tools/gen_raylib.py`). */
@:noCompletion
@:allow(helix.raylib)
class RDebug {
	#if !macro
	// The frame times of the last half second, newest last, in a ring made once: RING frames at most, so a program running above 2000
	// frames a second keeps the last RING of them.
	static inline final RING = 1024;

	static inline final WINDOW = .5;

	// The slowest 1/20th of the window is at most RING / 20 frames, kept in TOP.
	static inline final TOP = 64;

	static final times = [for (_ in 0...RING) 0.];

	static final slowest = [for (_ in 0...TOP) 0.];

	static var head = 0;

	static var count = 0;

	// The frame whose drawing records each frame's time, once a program draws the stats (a frame made again is hooked again).
	static var hooked:Null<Frame> = null;

	/** Draws a model's skeleton in the pose it has at the call, as DrawModel draws the model: a line from each bone to its parent, and
		a small cross at each joint, placed as DrawModel places the model. A model never posed draws its bind pose; one without bones draws
		nothing. Drawn in 3D mode (BeginMode3D), over what's drawn before it, as DrawLine3D is.

		One model drawn as several copies, each posed apart, is posed, drawn and looked at copy by copy:

		```haxe
		for (i in 0...copies) {
			UpdateModelAnimation(model, anim, frame + i * 10);
			var at = new Vector3(i * 2, 0, 0);
			DrawModel(model, at, 1, WHITE);
			DrawModelSkeleton(model, at, 1, YELLOW);
			DrawModelBoundingBoxPosed(model, at, 1, RED);
		}
		```

		@param model  The model.
		@param position  Where the model is drawn, as DrawModel's.
		@param scale  Its scale, as DrawModel's.
		@param color  The lines' color. */
	static function DrawModelSkeleton(model:Model, position:Vector3, scale:Float, color:Color):Void {
		var bones = model.bones;
		var pose = posed(model) ? model.pose : model.bindPose;
		if (bones == null || pose == null)
			return;
		var n = bones.length < pose.length ? bones.length : pose.length;
		// The joints, as DrawModel places a point: the model's own transform, then the scale, then the position.
		var joints = [
			for (i in 0...n) {
				var p = Vector3Transform(pose[i].translation, model.transform);
				new Vector3(p.x * scale + position.x, p.y * scale + position.y, p.z * scale + position.z);
			}
		];
		var box = GetModelBoundingBoxPosed(model);
		var dx = box.max.x - box.min.x,
			dy = box.max.y - box.min.y,
			dz = box.max.z - box.min.z;
		var arm = Math.abs(scale) * .02 * Math.sqrt(dx * dx + dy * dy + dz * dz);
		for (i in 0...n) {
			var at = joints[i], parent = bones[i].parent;
			if (parent >= 0 && parent < n)
				DrawLine3D(joints[parent], at, color);
			DrawLine3D(new Vector3(at.x - arm, at.y, at.z), new Vector3(at.x + arm, at.y, at.z), color);
			DrawLine3D(new Vector3(at.x, at.y - arm, at.z), new Vector3(at.x, at.y + arm, at.z), color);
			DrawLine3D(new Vector3(at.x, at.y, at.z - arm), new Vector3(at.x, at.y, at.z + arm), color);
		}
	}

	/** Draws a model's bounds in the pose it has at the call, GetModelBoundingBoxPosed's box (helix.raylib.extras.Models), placed as
		DrawModel places the model. Drawn in 3D mode, as DrawBoundingBox is.

		@param model  The model.
		@param position  Where the model is drawn, as DrawModel's.
		@param scale  Its scale, as DrawModel's.
		@param color  The box's color. */
	static function DrawModelBoundingBoxPosed(model:Model, position:Vector3, scale:Float, color:Color):Void {
		// The box is already moved by the model's transform, as GetModelBoundingBox's; the scale and the position follow, as DrawModel's.
		var box = GetModelBoundingBoxPosed(model);
		var ax = box.min.x * scale + position.x,
			bx = box.max.x * scale + position.x;
		var ay = box.min.y * scale + position.y,
			by = box.max.y * scale + position.y;
		var az = box.min.z * scale + position.z,
			bz = box.max.z * scale + position.z;
		DrawBoundingBox(new BoundingBox(new Vector3(Math.min(ax, bx), Math.min(ay, by), Math.min(az, bz)),
			new Vector3(Math.max(ax, bx), Math.max(ay, by), Math.max(az, bz))),
			color);
	}

	/** Draws the frame's cost at a point on the screen, as DrawFPS draws the rate, in FrameStatsStyle's default look at a size: the
		frames a second, the frame time's mean and its slowest 5% (p95) over the last half second, in milliseconds, and the last frame's
		draw calls, a line each. It is `DrawFrameStatsEx(new Vector2(posX, posY), {fontSize: fontSize})`: every other field the
		style's default, so its color is judged against SetTargetFPS's target, or the monitor's refresh rate without one.

		@param posX  The text's left, in pixels.
		@param posY  The text's top, in pixels.
		@param fontSize  The text's height, in pixels, as DrawText's; DrawFPS draws at 20. */
	static function DrawFrameStats(posX:Int, posY:Int, fontSize:Int):Void {
		DrawFrameStatsEx(new Vector2(posX, posY), {fontSize: fontSize});
	}

	/** Draws the frame's cost at a point on the screen as a style says: which stats, in what font, size, spacing and colors, over what
		background. Each stat is a line, so the text's height follows what's shown (MeasureFrameStats).

		```haxe
		DrawFrameStatsEx(new Vector2(10, 10), {fontSize: 24, backgroundColor: Fade(BLACK, 0.5), triangles: true});
		```

		@param position  The text's top left, in pixels (its background's, padding around the text).
		@param style  What to show and how; each field left out takes its default. */
	static function DrawFrameStatsEx(position:Vector2, style:FrameStatsStyle):Void {
		hook();
		var size = fontSizeOf(style);
		var lines = linesOf(style);
		if (lines.length == 0)
			return;
		var font = style.font != null ? style.font : GetFontDefault();
		var measured = measure(style, lines, font, size);
		if (style.backgroundColor.a > 0)
			DrawRectangleRec(new Rectangle(position.x, position.y, measured.x, measured.y), style.backgroundColor);
		var color = colorOf(style);
		for (i in 0...lines.length)
			DrawTextEx(font, lines[i], new Vector2(position.x + style.padding, position.y + style.padding + i * size), size, style.spacing, color);
	}

	/** Returns the size DrawFrameStatsEx draws in with a style, its padding included, for placing it (at a corner, say).

		@param style  What to show and how.
		@return  The width and height, in pixels. */
	static function MeasureFrameStats(style:FrameStatsStyle):Vector2 {
		var size = fontSizeOf(style);
		var lines = linesOf(style);
		if (lines.length == 0)
			return new Vector2(0, 0);
		return measure(style, lines, style.font != null ? style.font : GetFontDefault(), size);
	}

	// Whether a model has been posed: its pose holds a rotation, which an unposed model's zeros (raylib 6.2's currentPose at rest) don't.
	static function posed(model:Model):Bool {
		var pose = model.pose;
		if (pose == null)
			return false;
		for (t in pose)
			if (t.rotation.x != 0 || t.rotation.y != 0 || t.rotation.z != 0 || t.rotation.w != 0)
				return true;
		return false;
	}

	// The text's height: the style's, or a 36th of the screen's; a size under 1 is refused.
	static function fontSizeOf(style:FrameStatsStyle):Int {
		var size = style.fontSize;
		if (size == null)
			return Std.int(Math.max(1, Math.round(GetScreenHeight() / 36)));
		if (size < 1)
			throw 'FrameStatsStyle.fontSize must be at least 1, not $size';
		return size;
	}

	static function measure(style:FrameStatsStyle, lines:Array<String>, font:Font, size:Int):Vector2 {
		var widest = 0.;
		for (line in lines) {
			var w = MeasureTextEx(font, line, size, style.spacing).x;
			if (w > widest)
				widest = w;
		}
		return new Vector2(widest + style.padding * 2, lines.length * size + style.padding * 2);
	}

	// A frame's time recorded each frame once the stats are drawn, so a window holds each frame, drawn or not.
	static function hook():Void {
		var frame = Runtime.frame;
		if (hooked == frame)
			return;
		hooked = frame;
		frame.drawing.push(() -> record(GetFrameTime()));
	}

	// Adds a frame's time to the ring, over the oldest.
	static function record(seconds:Float):Void {
		times[head] = seconds;
		head = (head + 1) % RING;
		if (count < RING)
			count++;
	}

	// The frames' times of the last half second: how many, their mean and their p95 (the slowest 5%'s least), in seconds.
	static var used = 0;

	static var mean = 0.;

	static var p95 = 0.;

	static function window():Void {
		var sum = 0., n = 0;
		while (n < count && sum < WINDOW) {
			sum += times[(head - 1 - n + RING * 2) % RING];
			n++;
		}
		used = n;
		mean = n == 0 ? 0 : sum / n;
		// The slowest k of n, kept sorted slowest first as each is met: k is a twentieth of n, rounded up.
		var k = Std.int(Math.ceil(n / 20));
		var held = 0;
		for (j in 0...n) {
			var t = times[(head - 1 - j + RING * 2) % RING];
			if (held == k && t <= slowest[held - 1])
				continue;
			var at = held < k ? held++ : held - 1;
			while (at > 0 && slowest[at - 1] < t) {
				slowest[at] = slowest[at - 1];
				at--;
			}
			slowest[at] = t;
		}
		p95 = k == 0 ? 0 : slowest[k - 1];
	}

	// A number of milliseconds to a tenth.
	static function ms(seconds:Float):String {
		var tenths = Math.round(seconds * 10000);
		return Std.int(tenths / 10) + "." + tenths % 10;
	}

	// The frames a second as GetFPS reports them: helix-raylib's own average over the last half second.
	static function linesOf(style:FrameStatsStyle):Array<String> {
		var lines = [];
		var frame = Runtime.frame;
		if (style.fps)
			lines.push("FPS: " + GetFPS());
		if (style.frameTime) {
			window();
			lines.push("Frame: " + ms(mean) + " ms (p95 " + ms(p95) + ")");
		}
		if (style.drawCalls)
			lines.push("Draw calls: " + (frame == null ? 0 : frame.lastDraws));
		if (style.triangles)
			lines.push("Triangles: " + (frame == null ? 0 : frame.lastTriangles));
		if (style.stateChanges)
			lines.push("State changes: " + (frame == null ? 0 : frame.lastStateChanges));
		return lines;
	}

	// The text's color: the frame rate against the target, the style's or SetTargetFPS's or the monitor's.
	static function colorOf(style:FrameStatsStyle):Color {
		var target = style.targetFps;
		if (target <= 0) {
			var delta = Runtime.time == null ? 0 : Runtime.time.targetDelta;
			target = delta > 0 ? Math.round(1 / delta) : GetMonitorRefreshRate(GetCurrentMonitor());
		}
		var fps = GetFPS();
		return fps >= target ? style.onTargetColor : fps * 2 < target ? style.farBelowTargetColor : style.belowTargetColor;
	}
	#end
}
