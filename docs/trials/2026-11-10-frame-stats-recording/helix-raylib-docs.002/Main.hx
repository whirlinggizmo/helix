import helix.raylib.Raylib.*;
import helix.raylib.*;
import helix.raylib.extras.Debug.*;

class Main {
	static inline var GRID = 20;
	static inline var SETTLE = 2.0;
	static inline var MEASURE = 10.0;

	static function main():Void {
		var autoBench = Sys.args().indexOf("--bench") >= 0;

		InitWindow(1280, 720, "bench");
		SetTargetFPS(60);

		var camera = new Camera3D(new Vector3(30, 20, 30), new Vector3(0, 0, 0), new Vector3(0, 1, 0), 45.0, CAMERA_PERSPECTIVE);

		var cube = LoadModelFromMesh(GenMeshCube(1, 1, 1));

		// 0 idle, 1 settling, 2 measuring
		var phase = autoBench ? 1 : 0;
		var phaseStart = GetTime();
		var result:Null<FrameStats> = null;
		var resultLine = "";
		var quit = false;

		while (!WindowShouldClose() && !quit) {
			var now = GetTime();

			if (IsKeyPressed(KEY_B)) {
				if (phase == 0) {
					phase = 1;
					phaseStart = now;
					result = null;
				} else if (phase == 3) {
					phase = 0;
					result = null;
				}
			}

			if (phase == 1 && now - phaseStart >= SETTLE) {
				StartFrameStatsRecording();
				phase = 2;
				phaseStart = now;
			} else if (phase == 2 && now - phaseStart >= MEASURE) {
				result = StopFrameStatsRecording();
				resultLine = format(result);
				Sys.println(resultLine);
				if (autoBench)
					quit = true;
				else
					phase = 3;
			}

			var t = now;
			camera.position = new Vector3(Math.cos(t * 0.3) * 40, 20, Math.sin(t * 0.3) * 40);

			BeginDrawing();
			ClearBackground(RAYWHITE);

			BeginMode3D(camera);
			for (i in 0...GRID * GRID) {
				var gx = i % GRID;
				var gz = Std.int(i / GRID);
				var pos = new Vector3((gx - GRID / 2) * 2.0, 0, (gz - GRID / 2) * 2.0);
				var c = ColorFromHSV(i * 360.0 / (GRID * GRID), 0.8, 0.9);
				DrawModelEx(cube, pos, new Vector3(0, 1, 0), t * 90 + i * 5, new Vector3(1, 1, 1), c);
			}
			EndMode3D();

			var s = GetFrameStats();
			DrawText("frame mean " + fixed(s.meanFrameTime * 1000) + " ms  p95 " + fixed(s.p95FrameTime * 1000) + " ms  draws " + Std.int(s.drawCalls), 10, 10, 20, BLACK);
			switch (phase) {
				case 1: DrawText("benchmark: settling", 10, 35, 20, DARKGRAY);
				case 2: DrawText("benchmark: measuring", 10, 35, 20, DARKGRAY);
				case 3: DrawText(resultLine, 10, 35, 20, DARKGRAY);
				default: DrawText("press B to benchmark", 10, 35, 20, DARKGRAY);
			}
			EndDrawing();
		}

		UnloadModel(cube);
		CloseWindow();
	}

	static function fixed(v:Float):String {
		return Std.string(Math.round(v * 100) / 100);
	}

	static function format(s:FrameStats):String {
		var mb = 1.0 / (1024 * 1024);
		return "frames=" + s.frames + " fps=" + fixed(s.fps) + " mean_ms=" + fixed(s.meanFrameTime * 1000) + " p95_ms=" + fixed(s.p95FrameTime * 1000)
			+ " slowest_ms=" + fixed(s.slowestFrameTime * 1000) + " draws=" + fixed(s.drawCalls) + " tris=" + Std.int(s.triangles)
			+ " gpu_tex_mb=" + fixed(s.gpuTextureBytes * mb) + " gpu_buf_mb=" + fixed(s.gpuBufferBytes * mb) + " mem_mb=" + fixed(s.memoryBytes * mb);
	}
}
