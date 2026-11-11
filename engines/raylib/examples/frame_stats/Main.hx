import helix.raylib.*;
import helix.raylib.Raylib.*;
import helix.raylib.extras.Debug.*;

/** Reads the frame stats (`helix.raylib.extras.Debug`): the last half second's at the top left, in the program's own text, and a
	recording printed as one line. It records frames 30 to 50 as it starts, and R starts a recording of its own, R again stops and
	prints it. The `quit_after_frame` option (`--quit_after_frame=60` natively, `?quit_after_frame=60` in a page) quits it after that
	frame. */
class Main {
	static function main():Void {
		InitWindow(800, 450, "helix-raylib: frame stats");
		SetTargetFPS(60);
		var camera = new Camera3D(new Vector3(10, 10, 10), new Vector3(0, 0, 0), new Vector3(0, 1, 0), 45, CAMERA_PERSPECTIVE);
		var frame = 0;
		var recording = false;
		while (!WindowShouldClose()) {
			if (frame == 30 || (IsKeyPressed(KEY_R) && !recording)) {
				StartFrameStatsRecording();
				recording = true;
			} else if (recording && (frame == 50 || IsKeyPressed(KEY_R))) {
				Sys.println(line(StopFrameStatsRecording()));
				recording = false;
			}
			BeginDrawing();
			ClearBackground(RAYWHITE);
			BeginMode3D(camera);
			for (x in -5...6)
				for (z in -5...6)
					DrawCube(new Vector3(x, Math.sin(GetTime() * 2 + x + z) * .5, z), .8, .8, .8, ColorFromHSV((x + z + 10) * 18, .7, .9));
			EndMode3D();
			var last = GetFrameStats();
			DrawText('mean ${ms(last.meanFrameTime)} ms  p95 ${ms(last.p95FrameTime)} ms  ${Math.round(last.drawCalls)} draws', 10, 10, 20, DARKGRAY);
			DrawText(recording ? "recording: R stops" : "R records", 10, 36, 20, recording ? MAROON : GRAY);
			EndDrawing();
			frame++;
		}
		CloseWindow();
	}

	// A recording's stats as one line: the frames, their rate, the frame times in milliseconds, the draws and the memory in megabytes.
	static function line(s:FrameStats):String {
		var mb = (bytes:Float) -> Math.round(bytes / (1024 * 1024) * 10) / 10;
		return 'frames ${s.frames}, ${Math.round(s.fps)} fps, mean ${ms(s.meanFrameTime)} ms, p95 ${ms(s.p95FrameTime)} ms, '
			+ 'slowest ${ms(s.slowestFrameTime)} ms, ${Math.round(s.drawCalls)} draws, ${Math.round(s.triangles)} triangles, '
			+ 'GPU ${mb(s.gpuTextureBytes + s.gpuBufferBytes)} MB, memory ${mb(s.memoryBytes)} MB';
	}

	// Seconds as milliseconds with two decimals.
	static function ms(seconds:Float):String
		return Std.string(Math.round(seconds * 100000) / 100);
}
