package helix.raylib.modules;

#if !macro
import helix.raylib.*;
import helix.raylib.internal.GpuMemory;
import helix.raylib.modules.RCore.*;
import helix.raylib.modules.RMath.*;
import helix.raylib.modules.RModels.*;
import helix.raylib.modules.RModelsPosed.*;
import helix.raylib.modules.RShapes.*;
import helix.raylib.modules.RText.*;
import helix.raylib.internal.Frame;
import helix.raylib.internal.Runtime;
#end

/** Provides the drawing that shows what a program does: a model's skeleton and bounds as posed, and the frame's cost.

	Each member is written here. `helix.raylib.extras.Debug` forwards to it (`tools/gen_raylib.py`). */
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

	// The draws, triangles and state changes of the frame being drawn or drawn last, counted from its recorded draws as its drawing
	// starts (`tally`), so the stats of the next frame show it.
	static var draws = 0;

	static var triangles = 0;

	static var changes = 0;

	// The frame whose drawing records each frame's time, once a program draws the stats (a frame made again is hooked again).
	static var hooked:Null<Frame> = null;

	/** Draws a model's skeleton in the pose it has at the call, placed as DrawModel places the model. See `DrawModelBoundingBoxPosed` for drawing its bounds.

		Each bone is a line to its parent, and each joint a small cross.

		A model never posed draws its bind pose. A model without bones draws nothing.

		Draws in 3D mode (BeginMode3D) with depth, as DrawLine3D draws, so the model's surface hides the bones inside it.

		A model drawn as several copies, each posed apart, is posed and drawn copy by copy:

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
		var pose = model.pose != null ? model.pose : model.bindPose;
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

	/** Draws a model's bounds in the pose it has at the call, placed as DrawModel places the model. See `DrawModelSkeleton` for drawing its bones.

		The box is GetModelBoundingBoxPosed's (helix.raylib.extras.Models).

		Draws in 3D mode, as DrawBoundingBox does.

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

	/** Draws the frame's cost at a point on the screen in FrameStatsStyle's default look at a size, as DrawFPS draws the rate.
		See `DrawFrameStatsEx` for choosing the stats and their look.

		Draws a line each for:
		- the frames a second
		- the frame time's mean and its slowest 5% (p95) over the last half second, in milliseconds
		- the last frame's draw calls

		The text's color is judged against SetTargetFPS's target, or the monitor's refresh rate without one.

		The same as `DrawFrameStatsEx(new Vector2(posX, posY), {fontSize: fontSize})`, every other field the style's default.

		@param posX  The text's left, in pixels.
		@param posY  The text's top, in pixels.
		@param fontSize  The text's height, in pixels, as DrawText's; DrawFPS draws at 20. */
	static function DrawFrameStats(posX:Int, posY:Int, fontSize:Int):Void {
		DrawFrameStatsEx(new Vector2(posX, posY), {fontSize: fontSize});
	}

	/** Draws the frame's cost at a point on the screen in a style's stats, font, size, spacing, colors and background. See `DrawFrameStats` for drawing the default look at a size.

		Each stat is a line, so the text's height follows the stats shown. `MeasureFrameStats` returns the size.

		Each number is right-aligned in a slot of a fixed width, so the stats stay in place as the numbers change.

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
		var digit = widestDigit(font, size, style.spacing);
		for (i in 0...lines.length) {
			var x = position.x + style.padding,
				y = position.y + style.padding + i * size;
			for (part in lines[i]) {
				var advance = advanceOf(part, font, size, style.spacing, digit);
				if (part.template == null)
					DrawTextEx(font, part.text, new Vector2(x, y), size, style.spacing, color);
				else {
					// A number's right end is its slot's.
					var right = x + advance - style.spacing;
					DrawTextEx(font, part.text, new Vector2(right - MeasureTextEx(font, part.text, size, style.spacing).x, y), size, style.spacing, color);
				}
				x += advance;
			}
		}
	}

	/** Returns the size DrawFrameStatsEx draws a style's stats in, for placing them (at a corner, say).

		The size includes the padding.

		Sized for the widest values, so it is the same from frame to frame.

		@param style  What to show and how.
		@return  The width and height, in pixels. */
	static function MeasureFrameStats(style:FrameStatsStyle):Vector2 {
		var size = fontSizeOf(style);
		var lines = linesOf(style);
		if (lines.length == 0)
			return new Vector2(0, 0);
		return measure(style, lines, style.font != null ? style.font : GetFontDefault(), size);
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

	// The size of the lines: each part's width (a number's, its slot's) added up, the widest line's, so it is the same whatever the numbers.
	static function measure(style:FrameStatsStyle, lines:Array<Array<Part>>, font:Font, size:Int):Vector2 {
		var digit = widestDigit(font, size, style.spacing);
		var widest = 0.;
		for (line in lines) {
			var w = -style.spacing;
			for (part in line)
				w += advanceOf(part, font, size, style.spacing, digit);
			if (w > widest)
				widest = w;
		}
		return new Vector2(widest + style.padding * 2, lines.length * size + style.padding * 2);
	}

	// The font's widest digit at a size.
	static function widestDigit(font:Font, size:Int, spacing:Float):String {
		var widest = "0", most = -1.;
		for (c in 0...10) {
			var w = MeasureTextEx(font, String.fromCharCode(48 + c), size, spacing).x;
			if (w > most) {
				most = w;
				widest = String.fromCharCode(48 + c);
			}
		}
		return widest;
	}

	// A part's width and the space after it: its text's, or for a number its template's with the widest digit in each place.
	static function advanceOf(part:Part, font:Font, size:Int, spacing:Float, digit:String):Float {
		var text = part.template == null ? part.text : part.template.split("d").join(digit);
		return MeasureTextEx(font, text, size, spacing).x + spacing;
	}

	// A frame's time recorded each frame once the stats are drawn, so a window holds each frame, drawn or not.
	static function hook():Void {
		var frame = Runtime.frame;
		if (hooked == frame)
			return;
		hooked = frame;
		frame.drawing.push(() -> {
			record(GetFrameTime());
			tally(frame);
		});
	}

	// Counts a frame's recorded draws as Frame.draw submits them: each draw with something to draw, its triangles (each instance), and a
	// change from the draw before it when its pipeline or any texture differs.

	@:access(helix.raylib.internal.Frame)
	static function tally(frame:Frame):Void {
		var drawn = 0, tris = 0, switched = 0, pipeline = -1;
		var before:Null<Array<Int>> = null;
		for (p in frame.passes) {
			if (p.target == -1)
				continue;
			for (d in p.draws) {
				if (d.count == 0)
					continue;
				drawn++;
				if (d.primitive == helix.platform.Primitive.Triangles)
					tris += Std.int(d.count / 3) * (d.instances > 1 ? d.instances : 1);
				if (before != null) {
					var same = d.pipeline == pipeline && d.textures.length == before.length;
					var k = 0;
					while (same && k < before.length) {
						same = d.textures[k] == before[k];
						k++;
					}
					if (!same)
						switched++;
				}
				pipeline = d.pipeline;
				before = d.textures;
			}
		}
		draws = drawn;
		triangles = tris;
		changes = switched;
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

	// A number of seconds as milliseconds with 2 decimals, up to 999.99.
	static function ms(seconds:Float):String {
		var hundredths = Math.round(seconds * 100000);
		if (hundredths > 99999)
			hundredths = 99999;
		var h = hundredths % 100;
		return Std.int(hundredths / 100) + "." + (h < 10 ? "0" : "") + h;
	}

	// A count capped to its digits.
	static function whole(value:Int, digits:Int):String
		return Std.string(Std.int(Math.min(value, Math.pow(10, digits) - 1)));

	static inline function text(t:String):Part
		return {text: t, template: null};

	static inline function number(t:String, template:String):Part
		return {text: t, template: template};

	// The lines of the stats shown, each as parts: fixed text and numbers, whose templates give their slots (d for a digit). The frames a
	// second are GetFPS's: helix-raylib's own average over the last half second.
	static function linesOf(style:FrameStatsStyle):Array<Array<Part>> {
		var lines = [];
		if (style.fps)
			lines.push([text("FPS: "), number(whole(GetFPS(), 4), "dddd")]);
		if (style.frameTime) {
			window();
			lines.push([
				text("Frame: "),
				number(ms(mean), "ddd.dd"),
				text(" ms (p95 "),
				number(ms(p95), "ddd.dd"),
				text(" ms)")
			]);
		}
		if (style.drawCalls)
			lines.push([text("Draw calls: "), number(whole(draws, 7), "ddddddd")]);
		if (style.triangles)
			lines.push([text("Triangles: "), number(whole(triangles, 7), "ddddddd")]);
		if (style.stateChanges)
			lines.push([text("State changes: "), number(whole(changes, 7), "ddddddd")]);
		if (style.gpuTextures)
			lines.push([
				text("GPU textures: "),
				number(GpuMemory.megabytes(GpuMemory.textureBytes), "dddd.d"),
				text(" MB")
			]);
		if (style.gpuBuffers)
			lines.push([
				text("GPU buffers: "),
				number(GpuMemory.megabytes(GpuMemory.bufferBytes), "dddd.d"),
				text(" MB")
			]);
		if (style.memory) {
			var bytes = Runtime.system.getMemoryBytes();
			if (bytes > 0)
				lines.push([text("Memory: "), number(GpuMemory.megabytes(bytes), "dddd.d"), text(" MB")]);
		}
		return lines;
	}

	// The lines' texts as drawn, a number's as its digits, for a test to read.
	static function plain(style:FrameStatsStyle):Array<String>
		return [for (line in linesOf(style)) [for (part in line) part.text].join("")];

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

/** Represents a piece of a stats line, fixed text or a number with its slot's template. */
private typedef Part = {text:String, template:Null<String>};
