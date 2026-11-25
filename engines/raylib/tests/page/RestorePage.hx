import helix.raylib.*;
import helix.raylib.Raylib.*;
import helix.raylib.extras.Screen.*;
import js.Browser;

/** Checks a page drawing again once the browser loses its WebGL2 context and restores it (tools/test_raylib_pages.py), each frame the
	same scene under a screen fit: a file's texture, a texture made from pixels, a render texture drawn into each frame, a mesh, shapes and
	text. The context is lost and restored by `WEBGL_lose_context` between frames, as a browser does, and the screen read once the page
	has drawn again matches the one read before, pixel for pixel; the tool checks the scene's colors on the page's screenshot
	(RestorePage.check.json). Leaves {passed, checks, failures} in `window.helixResult`. */
class RestorePage {
	static var checks = 0;
	static final failures:Array<String> = [];

	static function check(value:Bool, message:String):Void {
		if (value)
			checks++;
		else
			failures.push(message);
	}

	static function sample(image:Image):String {
		var out = [];
		for (p in [[62, 62], [300, 100], [500, 100], [700, 100], [400, 300], [10, 590]]) {
			var at = (p[1] * image.width + p[0]) * 4;
			out.push('${image.data.get(at)},${image.data.get(at + 1)},${image.data.get(at + 2)},${image.data.get(at + 3)}');
		}
		return out.join(" ");
	}

	static function main():Void {
		Reflect.setField(Browser.window, "helixResult", null);
		var lost = 0, restored = 0;
		SetTraceLogCallback((level, text) -> {
			if (text.indexOf("GPU context lost") >= 0)
				lost++;
			if (text.indexOf("GPU context restored") >= 0)
				restored++;
		});
		InitWindow(320, 240, "restore");
		SetScreenFit(320, 240, SCREEN_STRETCH_CANVAS, SCREEN_FIT_KEEP, false);
		var file:Texture2D = null;
		LoadTextureAsync("checker.png", t -> file = t, e -> failures.push('checker.png: $e'));
		var pixels = LoadTextureFromImage(GenImageColor(4, 4, GREEN));
		var target = LoadRenderTexture(32, 32);
		var cube = LoadModelFromMesh(GenMeshCube(2, 2, 2));
		var camera = new Camera3D(new Vector3(4, 3, 4), new Vector3(0, 0, 0), new Vector3(0, 1, 0), 45, CAMERA_PERSPECTIVE);
		var context:Dynamic = null;
		var before:Image = null, after:Image = null;
		var frames = 0, lostAt = -1, restoredAt = -1;
		while (!WindowShouldClose() && frames < 600) {
			BeginTextureMode(target);
			ClearBackground(ORANGE);
			DrawRectangle(0, 0, 16, 32, PURPLE);
			EndTextureMode();
			BeginDrawing();
			ClearBackground(RAYWHITE);
			if (file != null)
				DrawTexturePro(file, new Rectangle(0, 0, 2, 2), new Rectangle(10, 10, 60, 60), new Vector2(0, 0), 0, WHITE);
			DrawTexturePro(pixels, new Rectangle(0, 0, 4, 4), new Rectangle(90, 10, 60, 60), new Vector2(0, 0), 0, WHITE);
			DrawTexturePro(target.texture, new Rectangle(0, 0, 32, -32), new Rectangle(170, 10, 60, 60), new Vector2(0, 0), 0, WHITE);
			DrawRectangle(250, 10, 60, 60, DARKBLUE);
			DrawText("Restored", 10, 200, 20, BLACK);
			BeginMode3D(camera);
			DrawModel(cube, new Vector3(0, 0, 0), 1, MAROON);
			EndMode3D();
			// The screen read part way through a frame, everything drawn: once loaded, before the loss, and once drawn again after the restore.
			var read = file != null && (before == null && frames >= 30 || restoredAt >= 0 && restored > 0 && frames >= restoredAt + 60);
			if (read) {
				if (before == null)
					before = LoadImageFromScreen();
				else
					after = LoadImageFromScreen();
			}
			EndDrawing();
			frames++;
			if (after != null)
				break;
			if (read) {
				var canvas:js.html.CanvasElement = cast Browser.document.getElementById("canvas");
				context = (cast canvas.getContext("webgl2") : Dynamic).getExtension("WEBGL_lose_context");
				context.loseContext();
				lostAt = frames;
			} else if (before != null && restoredAt < 0 && lost > 0 && frames >= lostAt + 10) {
				context.restoreContext();
				restoredAt = frames;
			}
		}
		check(lost == 1 && restored == 1, 'the context lost once and restored once: lost $lost, restored $restored');
		if (after != null) {
			var differ = 0;
			for (i in 0...before.width * before.height * 4)
				if (before.data.get(i) != after.data.get(i))
					differ++;
			check(after.width == before.width && after.height == before.height && differ == 0,
				'the screen after the restore as before it: ${after.width} x ${after.height}, $differ bytes differ; before ${sample(before)}; after ${sample(after)}');
		} else
			check(false, before == null ? "the scene never loaded" : "the scene never drawn again");
		var result:Dynamic = {passed: failures.length == 0, checks: checks, failures: failures};
		Reflect.setField(Browser.window, "helixResult", result);
	}
}
