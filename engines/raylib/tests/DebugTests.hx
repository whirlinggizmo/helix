import helix.raylib.*;
import helix.raylib.Raylib.*;
import helix.raylib.extras.Debug.*;
import helix.raylib.extras.Models.*;
import helix.raylib.internal.Frame;
import helix.raylib.internal.Models;
import helix.raylib.internal.Runtime;
import helix.raylib.modules.RDebug;
import helix.services.screen.Screen;
import helix.services.time.Time;

/** Checks helix-raylib's debug drawing (`helix.raylib.extras.Debug`), on graphics that keep nothing: a skeleton's lines end where a
	two-bone model's bones are, posed and unposed, scaled and moved as DrawModel places it; the posed box drawn at its corners; the
	stats' size following the style's fields, the font size scaling with the screen's height and a size under 1 refused; what is drawn
	matching what is measured; the frame time's mean and p95 over a half second of a ring that wraps; the draws, triangles and state
	changes of a frame with known draws; the colors against a target, a given one, SetTargetFPS's and the monitor's; and the stats read,
	over the last half second and over a recording, which starts at the EndDrawing after its start, starts again at a second start and
	keeps its latest 65536 frames. */
@:access(helix.raylib.internal.Runtime)
@:access(helix.raylib.internal.Frame)
@:access(helix.raylib.internal.Models)
@:access(helix.raylib.modules.RDebug)
@:access(helix.raylib.Model)
class DebugTests {
	static var checks = 0;

	static function check(value:Bool, message:String):Void {
		if (!value)
			throw message;
		checks++;
	}

	static function near(a:Float, b:Float):Bool
		return Math.abs(a - b) < 1e-4;

	// A cube of two bones, every vertex the root's: the root at the origin, the child above it by one.
	static function twoBones():Model {
		var mesh = GenMeshCube(1, 1, 1);
		mesh.boneIds = [for (k in 0...mesh.vertexCount * 4) 0];
		mesh.boneWeights = [for (k in 0...mesh.vertexCount * 4) k % 4 == 0 ? 1. : 0.];
		var model = LoadModelFromMesh(mesh);
		model.boneCount = 2;
		model.bones = [new BoneInfo("root", -1), new BoneInfo("child", 0)];
		model.bindPose = [bone(0, 0, 0), bone(0, 1, 0)];
		Models.animated(model);
		return model;
	}

	static function bone(x:Float, y:Float, z:Float):Transform
		return new Transform(new Vector3(x, y, z), new Quaternion(0, 0, 0, 1), new Vector3(1, 1, 1));

	// An animation of one frame: the root raised by one, the child three along x.
	static function moved():ModelAnimation {
		var anim = new ModelAnimation();
		anim.boneCount = 2;
		anim.bones = [new BoneInfo("root", -1), new BoneInfo("child", 0)];
		anim.frameCount = 1;
		anim.framePoses = [[bone(0, 1, 0), bone(3, 1, 0)]];
		return anim;
	}

	// The vertices drawn since the last draw, of the primitive (lines or triangles), quads read through their indices; then the frame
	// drawn, which empties it.
	static function drawn(lines:Bool):Array<Vector3> {
		var f = Runtime.frame, out = [];
		f.flush();
		for (d in f.pass.draws) {
			if (d.buffers != null || (d.primitive == helix.platform.Primitive.Lines) != lines)
				continue;
			if (d.sprite) {
				// A sprite run: each record's four corners, flat.
				for (i in d.firstInstance...d.firstInstance + d.instances)
					for (c in 0...4)
						out.push(new Vector3(f.spriteData.getFloat(i * 52 + c * 8), f.spriteData.getFloat(i * 52 + c * 8 + 4), 0));
				continue;
			}
			for (k in d.first...d.first + d.count) {
				var i = d.indices == 0 ? k : Std.int(k / 6) * 4 + [0, 1, 2, 0, 2, 3][k % 6];
				out.push(new Vector3(f.data.getFloat(i * 36), f.data.getFloat(i * 36 + 4), f.data.getFloat(i * 36 + 8)));
			}
		}
		f.draw(64, 64, true);
		return out;
	}

	// Whether a line from one point to another was drawn, in either direction.
	static function hasLine(v:Array<Vector3>, ax:Float, ay:Float, az:Float, bx:Float, by:Float, bz:Float):Bool {
		var k = 0;
		while (k + 1 < v.length) {
			var p = v[k], q = v[k + 1];
			var forward = near(p.x, ax) && near(p.y, ay) && near(p.z, az) && near(q.x, bx) && near(q.y, by) && near(q.z, bz);
			var back = near(q.x, ax) && near(q.y, ay) && near(q.z, az) && near(p.x, bx) && near(p.y, by) && near(p.z, bz);
			if (forward || back)
				return true;
			k += 2;
		}
		return false;
	}

	static function screenOf(height:Int):Void {
		var window = new FakeWindow();
		window.logicalHeight = height;
		Runtime.window = window;
		Runtime.screen = new Screen(window, new FakeEvents());
	}

	static function main():Void {
		SetTraceLogLevel(LOG_NONE);
		var graphics = new CountingGraphics();
		Runtime.graphics = graphics;
		Runtime.frame = new Frame(graphics);
		Runtime.system = new FakeSystem();
		Runtime.time = new Time(Runtime.system);
		screenOf(600);
		var model = twoBones();
		var at = new Vector3(10, 0, 0);

		// The skeleton: a model never posed draws its bind pose, a posed one where the bones are now, scaled and moved as DrawModel.
		check(model.pose == null, "a model never posed has no pose");
		DrawModelSkeleton(model, new Vector3(1, 2, 3), 2, YELLOW);
		var lines = drawn(true);
		check(lines.length == 2 * (1 + 2 * 3), 'a root, its child, a cross on each: 7 lines, not ${lines.length / 2}');
		check(hasLine(lines, 1, 2, 3, 1, 4, 3), "the unposed bone's line runs from the root to the child at its bind pose, scaled by 2 and moved");
		UpdateModelAnimation(model, moved(), 0);
		DrawModelSkeleton(model, at, 1, YELLOW);
		lines = drawn(true);
		check(hasLine(lines, 10, 1, 0, 13, 1, 0), "the posed bone's line runs from the root raised to the child moved along x");
		check(!hasLine(lines, 10, 0, 0, 10, 1, 0), "the bind pose's line isn't drawn once posed");
		var box = GetModelBoundingBoxPosed(model);
		var arm = .02 * Math.sqrt(Math.pow(box.max.x - box.min.x, 2) + Math.pow(box.max.y - box.min.y, 2) + Math.pow(box.max.z - box.min.z, 2));
		check(hasLine(lines, 10 - arm, 1, 0, 10 + arm, 1, 0), "a cross at the root, 2% of the bounds' diagonal across each way");
		var bare = LoadModelFromMesh(GenMeshCube(1, 1, 1));
		DrawModelSkeleton(bare, at, 1, YELLOW);
		check(drawn(true).length == 0, "a model without bones draws nothing");

		// The posed box: the cube raised by one, scaled by 2 and moved, at its eight corners.
		DrawModelBoundingBoxPosed(model, at, 2, RED);
		var corners = drawn(true);
		check(corners.length == 24, '12 lines, not ${corners.length / 2}');
		var least = new Vector3(1e9, 1e9, 1e9),
			most = new Vector3(-1e9, -1e9, -1e9);
		for (c in corners) {
			least = new Vector3(Math.min(least.x, c.x), Math.min(least.y, c.y), Math.min(least.z, c.z));
			most = new Vector3(Math.max(most.x, c.x), Math.max(most.y, c.y), Math.max(most.z, c.z));
		}
		check(near(least.x, 9) && near(most.x, 11) && near(least.y, 1) && near(most.y, 3) && near(least.z, -1) && near(most.z, 1),
			'the box is x 9 to 11, y 1 to 3, z -1 to 1, not ${least.x}..${most.x}, ${least.y}..${most.y}, ${least.z}..${most.z}');

		// The stats' size follows the fields.
		var base = MeasureFrameStats({fontSize: 10, padding: 0});
		check(near(base.y, 30), 'three lines at 10: 30 high, not ${base.y}');
		check(base.x > 0, "the lines have a width");
		var padded = MeasureFrameStats({fontSize: 10, padding: 4});
		check(near(padded.x, base.x + 8) && near(padded.y, 38), "padding is on each side");
		check(near(MeasureFrameStats({
			fontSize: 10,
			padding: 0,
			triangles: true,
			stateChanges: true
		}).y, 50), "five lines at 10");
		check(near(MeasureFrameStats({fontSize: 10, padding: 0, fps: false}).y, 20), "a stat left out is a line fewer");
		var none = MeasureFrameStats({fps: false, frameTime: false, drawCalls: false});
		check(none.x == 0 && none.y == 0, "no stat shown measures nothing");
		check(MeasureFrameStats({fontSize: 10, padding: 0, spacing: 4}).x > base.x, "wider spacing is wider");
		check(near(MeasureFrameStats({}).y, 17 * 3 + 8), "no font size scales to a 36th of 600 lines, 17");
		screenOf(720);
		check(near(MeasureFrameStats({}).y, 20 * 3 + 8), "no font size is 20 at 720 lines");
		var refused = "";
		try
			MeasureFrameStats({fontSize: 0})
		catch (e:String)
			refused = e;
		check(refused.indexOf("fontSize") >= 0, 'a font size under 1 is refused naming the field: "$refused"');
		refused = "";
		try
			DrawFrameStats(0, 0, -3)
		catch (e:String)
			refused = e;
		check(refused.indexOf("fontSize") >= 0, "DrawFrameStats refuses one too");
		Runtime.frame.draw(64, 64, true);

		// The GPU memory lines: a 512 x 512 texture is a megabyte of textures once drawn (sent at its first draw), and none once unloaded;
		// the frame's own buffers (its batch, constants and quad indices) are what the buffers line shows.
		var memory:FrameStatsStyle = {
			fps: false,
			frameTime: false,
			drawCalls: false,
			gpuTextures: true,
			gpuBuffers: true
		};
		var before = RDebug.plain(memory);
		check(before[0] == "GPU textures: 0.0 MB", 'no texture of size yet: "${before[0]}"');
		check(StringTools.startsWith(before[1], "GPU buffers: ")
			&& StringTools.endsWith(before[1], " MB")
			&& Runtime.graphics.bufferBytes > 0,
			'the frame\'s own buffers, under a megabyte: "${before[1]}"');
		var big = GenImageColor(512, 512, RED);
		var texture = LoadTextureFromImage(big);
		UnloadImage(big);
		check(RDebug.plain(memory)[0] == "GPU textures: 0.0 MB", "a texture not yet drawn isn't on the GPU");
		DrawTexture(texture, 0, 0, WHITE);
		Runtime.frame.draw(64, 64, true);
		check(RDebug.plain(memory)[0] == "GPU textures: 1.0 MB", 'drawn, its megabyte is counted: "${RDebug.plain(memory)[0]}"');
		UnloadTexture(texture);
		check(RDebug.plain(memory)[0] == "GPU textures: 0.0 MB", 'unloaded, it is not: "${RDebug.plain(memory)[0]}"');
		check(MeasureFrameStats({
			fontSize: 10,
			padding: 0,
			fps: false,
			frameTime: false,
			drawCalls: false,
			gpuTextures: true
		}).y == 10, "a memory stat is a line");
		// The program's memory, as the platform tells it: a line of megabytes where it can (natively, Chromium), no line where it can't.
		var held = RDebug.plain({
			fps: false,
			frameTime: false,
			drawCalls: false,
			memory: true
		});
		check(held.length == 0
			|| held.length == 1
			&& StringTools.startsWith(held[0], "Memory: ")
			&& StringTools.endsWith(held[0], " MB")
			&& Std.parseFloat(held[0].substr(8)) > 0,
			'the memory line, or none where the platform can\'t tell: ${held}');

		// What is drawn is what is measured: the background and the text within it span the measured size from the position.
		var style:FrameStatsStyle = {fontSize: 12, backgroundColor: BLACK, triangles: true};
		var size = MeasureFrameStats(style);
		DrawFrameStatsEx(new Vector2(5, 7), style);
		var all = drawn(false);
		var maxX = -1e9, maxY = -1e9, minX = 1e9, minY = 1e9;
		for (v in all) {
			minX = Math.min(minX, v.x);
			minY = Math.min(minY, v.y);
			maxX = Math.max(maxX, v.x);
			maxY = Math.max(maxY, v.y);
		}
		check(near(minX, 5) && near(minY, 7), 'drawn from the position, not $minX, $minY');
		check(near(maxX, 5 + size.x) && near(maxY, 7 + size.y), 'drawn as measured ${size.x} by ${size.y}, not ${maxX - 5} by ${maxY - 7}');

		// The numbers keep their places: very different counts draw the same box, measured as drawn with the widest values, and a
		// number ending alike ends at the same x.
		var fixed:FrameStatsStyle = {
			fontSize: 12,
			backgroundColor: BLACK,
			fps: false,
			frameTime: false
		};
		var plainText:FrameStatsStyle = {fontSize: 12, fps: false, frameTime: false};
		var extent = (v:Array<Vector3>) -> {
			var most = -1e9, least = 1e9, low = 1e9, high = -1e9;
			for (p in v) {
				most = Math.max(most, p.x);
				least = Math.min(least, p.x);
				high = Math.max(high, p.y);
				low = Math.min(low, p.y);
			}
			[least, most, low, high];
		};
		var measuredBox = MeasureFrameStats(fixed);
		var ends = [];
		var boxes = [];
		for (n in [5, 55, 9999999]) {
			RDebug.draws = n;
			DrawFrameStatsEx(new Vector2(3, 4), fixed);
			boxes.push(extent(drawn(false)));
			RDebug.draws = n;
			DrawFrameStatsEx(new Vector2(3, 4), plainText);
			ends.push(extent(drawn(false))[1]);
		}
		check(boxes[0].join(",") == boxes[1].join(",")
			&& boxes[1].join(",") == boxes[2].join(","), 'the box is the same for each count: $boxes');
		check(near(boxes[2][1] - 3, measuredBox.x)
			&& near(boxes[2][3] - 4, measuredBox.y), "the measured size is what is drawn with the widest values");
		check(near(ends[0], ends[1]) && near(ends[1], ends[2]), 'a number\'s last digit is at the same x: $ends');
		check(MeasureFrameStats(fixed).x == measuredBox.x && MeasureFrameStats(fixed).y == measuredBox.y, "measured the same each time");

		// The frame times: a ring that wraps, then a half second of them.
		for (_ in 0...2000)
			RDebug.record(.0001);
		RDebug.window();
		check(RDebug.used == RDebug.RING && near(RDebug.mean, .0001), "a ring's worth of the fastest frames, whose sum is under a half second");
		for (_ in 0...60)
			RDebug.record(.011);
		for (_ in 0...5)
			RDebug.record(.05);
		RDebug.window();
		check(RDebug.used == 28, 'a half second is the 5 slow frames and 23 of the others, not ${RDebug.used}');
		check(RDebug.ms(RDebug.mean) == "17.96", 'the mean is 17.96 ms, not ${RDebug.ms(RDebug.mean)}');
		check(RDebug.ms(RDebug.p95) == "50.00", 'the p95 is the second slowest of 28, 50.00 ms, not ${RDebug.ms(RDebug.p95)}');
		var text = RDebug.plain({});
		check(text[1] == "Frame: 17.96 ms (p95 50.00 ms)", 'the frame line: ${text[1]}');
		RDebug.record(5);
		check(RDebug.plain({})[1] == "Frame: 999.99 ms (p95 999.99 ms)", "times past 999.99 are shown as it");

		// The counts: a frame of two rectangles (one draw), a texture (a second, a change), a rectangle again (a third, a second change).
		var texture = LoadTextureFromImage(GenImageColor(2, 2, RED));
		DrawRectangle(0, 0, 4, 4, WHITE);
		DrawRectangle(5, 0, 4, 4, WHITE);
		DrawTexture(texture, 10, 0, WHITE);
		DrawRectangle(20, 0, 4, 4, WHITE);
		Runtime.frame.draw(64, 64, true);
		var f = Runtime.frame;
		check(RDebug.draws == 3, 'three draws, not ${RDebug.draws}');
		check(RDebug.triangles == 8, 'eight triangles, not ${RDebug.triangles}');
		check(RDebug.changes == 2, 'two changes of texture, not ${RDebug.changes}');
		text = RDebug.plain({triangles: true, stateChanges: true});
		check(text.length == 5 && text[2] == "Draw calls: 3" && text[3] == "Triangles: 8" && text[4] == "State changes: 2", 'the lines: $text');
		DrawRectangle(0, 0, 4, 4, WHITE);
		Runtime.frame.draw(64, 64, true);
		check(RDebug.draws == 1 && RDebug.triangles == 2 && RDebug.changes == 0, "the next frame's counts are its own");

		// The colors: the frame rate against a target. 60 polls 0.02 s apart make 50 frames a second.
		var system:FakeSystem = cast Runtime.system;
		for (_ in 0...60) {
			system.now += .02;
			Runtime.time.poll();
		}
		check(GetFPS() == 50, 'fifty frames a second, not ${GetFPS()}');
		var colors = (s:FrameStatsStyle) -> RDebug.colorOf(s);
		var is = (a:Color, b:Color) -> a.r == b.r && a.g == b.g && a.b == b.b && a.a == b.a;
		check(is(colors({targetFps: 50}), GREEN), "at the target is on target");
		check(is(colors({targetFps: 51}), YELLOW), "below it is below");
		check(is(colors({targetFps: 100}), YELLOW), "half the target is still below");
		check(is(colors({targetFps: 101}), RED), "under half is far below");
		var custom:FrameStatsStyle = {targetFps: 101, farBelowTargetColor: BLUE};
		check(is(colors(custom), BLUE), "the style's own color");
		SetTargetFPS(60);
		check(is(colors({}), YELLOW), "SetTargetFPS's 60 is the target without one given");
		SetTargetFPS(200);
		check(is(colors({}), RED), "and 200");
		SetTargetFPS(0);
		var refresh = GetMonitorRefreshRate(GetCurrentMonitor());
		check(is(colors({}), 50 >= refresh ? GREEN : 100 < refresh ? RED : YELLOW), 'with none the monitor\'s $refresh is');
		DrawFrameStatsEx(new Vector2(0, 0), {targetFps: 50, onTargetColor: BLUE, fontSize: 8});
		var f = Runtime.frame;
		f.flush();
		var d = f.pass.draws[0];
		// The text's glyphs are a sprite run: its first record's color.
		var at = d.firstInstance * 52 + 48;
		check(d.sprite && f.spriteData.get(at) == BLUE.r && f.spriteData.get(at + 3) == BLUE.a && f.spriteData.get(at + 2) == BLUE.b,
			"the text is drawn in that color");
		f.draw(64, 64, true);

		// The stats read: frames an eighth of a second apart, so the last half second is four of them, each a rectangle (a draw of two
		// triangles).
		var frameOf = (seconds:Float, rectangles:Int) -> {
			for (k in 0...rectangles)
				DrawRectangle(k * 5, 0, 4, 4, WHITE);
			system.now += seconds;
			Runtime.frame.draw(64, 64, true);
		};
		var stats = GetFrameStats();
		check(stats.frames == 0 && stats.meanFrameTime == 0 && stats.gpuTextureBytes == 0, 'all zero at the first call: $stats');
		for (_ in 0...8)
			frameOf(.125, 1);
		stats = GetFrameStats();
		check(stats.frames == 4 && near(stats.meanFrameTime, .125) && near(stats.fps, 8), 'the last half second is 4 frames of 0.125 s: $stats');
		check(near(stats.drawCalls, 1) && near(stats.triangles, 2) && near(stats.stateChanges, 0), 'a draw of two triangles a frame: $stats');
		check(stats.gpuTextureBytes == Runtime.graphics.textureBytes && stats.memoryBytes == system.getMemoryBytes(),
			"the memory held as the graphics and the system count it");

		// A recording: its first frame starts at the EndDrawing after the call, so the frame ending there isn't recorded.
		check(StopFrameStatsRecording().frames == 0, "nothing recorded without a start");
		StartFrameStatsRecording();
		frameOf(.5, 1);
		frameOf(.1, 1);
		frameOf(.2, 2);
		frameOf(.3, 3);
		stats = GetFrameStats();
		check(stats.frames == 2 && near(stats.slowestFrameTime, .3), 'the last half second goes on while recording, 0.3 and 0.2 s: $stats');
		stats = StopFrameStatsRecording();
		check(stats.frames == 3 && near(stats.meanFrameTime, .2) && near(stats.fps, 5), 'three frames of 0.1, 0.2 and 0.3 s: $stats');
		check(near(stats.p95FrameTime, .3) && near(stats.slowestFrameTime, .3), 'the p95 of three is the slowest: $stats');
		check(near(stats.drawCalls, 1) && near(stats.triangles, 4), 'one draw a frame, and 2, 4 and 6 triangles: $stats');
		frameOf(.1, 1);
		check(StopFrameStatsRecording().frames == 0, "a second stop returns nothing");

		// A second start drops the frames recorded.
		StartFrameStatsRecording();
		frameOf(.1, 1);
		frameOf(.1, 1);
		StartFrameStatsRecording();
		frameOf(.1, 1);
		frameOf(.4, 1);
		stats = StopFrameStatsRecording();
		check(stats.frames == 1 && near(stats.meanFrameTime, .4), 'only the frame after the second start: $stats');

		// The p95 of 40 frames is the second slowest, and a recording keeps its latest 65536 frames.
		StartFrameStatsRecording();
		RDebug.recordingStarts = false;
		for (k in 0...40)
			RDebug.record(k == 0 ? .9 : k == 1 ? .8 : .01);
		stats = StopFrameStatsRecording();
		check(stats.frames == 40 && near(stats.p95FrameTime, .8) && near(stats.slowestFrameTime, .9), 'the p95 of 40: $stats');
		StartFrameStatsRecording();
		RDebug.recordingStarts = false;
		RDebug.record(5);
		for (_ in 0...RDebug.RECORDED)
			RDebug.record(.01);
		stats = StopFrameStatsRecording();
		check(stats.frames == 65536 && near(stats.slowestFrameTime, .01), 'the latest 65536, the oldest dropped: ${stats.frames}');

		var report = haxe.Json.stringify({passed: true, checks: checks});
		#if js
		js.Syntax.code("console.log({0})", report);
		#else
		Sys.println(report);
		#end
	}
}
