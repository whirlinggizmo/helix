import helix.raylib.Raylib.*;
import helix.raylib.*;
import helix.raylib.extras.Debug.*;
import helix.raylib.Rlgl.*;

class Main {
	static inline var GRID = 20;
	static inline var SETTLE = 2.0;
	static inline var MEASURE = 10.0;

	static function main():Void {
		var args = Sys.args();
		var autoQuit = args.indexOf("--bench") >= 0;

		InitWindow(1280, 720, "bench");
		SetTargetFPS(60);

		var camera = new Camera3D(new Vector3(0, 20, 30), new Vector3(0, 0, 0), new Vector3(0, 1, 0), 45, CAMERA_PERSPECTIVE);

		var colors:Array<Color> = [];
		for (i in 0...GRID * GRID)
			colors.push(ColorFromHSV((i * 360.0 / (GRID * GRID)), 0.8, 0.95));

		// 0 = off, 1 = settling, 2 = measuring
		var phase = autoQuit ? 1 : 0;
		var phaseTime = 0.0;
		var result = "";
		var finished = false;
		if (autoQuit)
			StartFrameStatsRecording();

		var time = 0.0;
		while (!WindowShouldClose() && !finished) {
			var dt = GetFrameTime();
			time += dt;

			if (IsKeyPressed(KEY_B)) {
				if (phase == 0) {
					phase = 1;
					phaseTime = 0;
					result = "";
				} else {
					phase = 0;
					result = "";
				}
			}

			if (phase != 0) {
				phaseTime += dt;
				if (phase == 1 && phaseTime >= SETTLE) {
					phase = 2;
					phaseTime = 0;
					StartFrameStatsRecording();
				} else if (phase == 2 && phaseTime >= MEASURE) {
					var s = StopFrameStatsRecording();
					result = format(s);
					Sys.println(result);
					phase = 0;
					if (autoQuit)
						finished = true;
				}
			}

			var a = time * 0.3;
			camera.position = new Vector3(Math.cos(a) * 30, 20, Math.sin(a) * 30);

			BeginDrawing();
			ClearBackground(RAYWHITE);
			BeginMode3D(camera);
			for (i in 0...GRID * GRID) {
				var x = (i % GRID - GRID / 2) * 2.0;
				var z = (Std.int(i / GRID) - GRID / 2) * 2.0;
				// spin each cube about Y by drawing a rotated model matrix would need rlgl; use push/rotate
				rlPushMatrix();
				rlTranslatef(x, 0, z);
				rlRotatef(time * 90 + i * 7, 0, 1, 0);
				DrawCube(new Vector3(0, 0, 0), 1.2, 1.2, 1.2, colors[i]);
				rlPopMatrix();
			}
			EndMode3D();

			var s = GetFrameStats();
			DrawText("frame mean " + fmt(s.meanFrameTime * 1000) + " ms  p95 " + fmt(s.p95FrameTime * 1000) + " ms", 10, 10, 20, DARKGRAY);
			DrawText("draw calls " + fmt(s.drawCalls), 10, 34, 20, DARKGRAY);
			if (phase == 1)
				DrawText("benchmark: settling", 10, 58, 20, ORANGE);
			else if (phase == 2)
				DrawText("benchmark: measuring", 10, 58, 20, RED);
			else if (result != "")
				DrawText(result, 10, 58, 14, DARKBLUE);
			EndDrawing();
		}
		CloseWindow();
	}

	static function fmt(v:Float):String {
		return Std.string(Math.round(v * 100) / 100);
	}

	static function format(s:FrameStats):String {
		var mb = 1024.0 * 1024.0;
		return "frames=" + s.frames + " fps=" + fmt(s.fps) + " mean_ms=" + fmt(s.meanFrameTime * 1000) + " p95_ms=" + fmt(s.p95FrameTime * 1000)
			+ " slowest_ms=" + fmt(s.slowestFrameTime * 1000) + " draw_calls=" + fmt(s.drawCalls) + " triangles=" + fmt(s.triangles)
			+ " gpu_texture_mb=" + fmt(s.gpuTextureBytes / mb) + " gpu_buffer_mb=" + fmt(s.gpuBufferBytes / mb) + " memory_mb=" + fmt(s.memoryBytes / mb);
	}
}
