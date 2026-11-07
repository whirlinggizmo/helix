import helix.raylib.*;
import helix.raylib.Raylib.*;
import helix.raylib.extras.Window.*;
import helix.raylib.extras.Models.*;
import helix.raylib.extras.Shaders.*;

// scene.c's crowd, drawn by helix-raylib: one greenman posed and drawn 240 times in a frame, the last row through raylib's example
// skinning shader and the one before, and a model never posed, through a shader of its own including
// <helix/raylib/shaders/skinning.glsl>, both compiled ahead of time; the third frame
// after its loads saved as helix.png.
class Main {
	static function main():Void {
		InitWindow(640, 360, "crowd");
		var camera = new Camera(new Vector3(0, 14, 16), new Vector3(0, 0, 1), new Vector3(0, 1, 0), 45, CAMERA_PERSPECTIVE);
		var models:Array<Model> = [];
		var anims:Array<ModelAnimation> = null;
		for (_ in 0...4)
			LoadModelAsync("greenman.glb", m -> models.push(m));
		LoadModelAnimationsAsync("greenman.glb", a -> anims = a);
		var skinning:Shader = null, own:Shader = null;
		LoadCompiledShaderAsync("skinning.shader", s -> skinning = s);
		LoadCompiledShaderAsync("own.shader", s -> own = s);
		var frame = -1;
		while (!WindowShouldClose()) {
			var ready = models.length == 4 && anims != null && skinning != null && own != null;
			if (ready && frame < 0) {
				frame = 0;
				models[1].materials[1].shader = skinning;
				models[2].materials[1].shader = own;
				models[3].materials[1].shader = own;
			}
			BeginDrawing();
			ClearBackground(RAYWHITE);
			BeginMode3D(camera);
			if (ready)
				for (i in 0...240) {
					var row = Std.int(i / 16), column = i % 16;
					var m = row == 14 ? models[1] : row == 13 ? models[2] : models[0];
					UpdateModelAnimation(m, anims[1 + i % 3], 0.75 * i + frame);
					DrawModel(m, new Vector3((column - 7.5) * 1.2, 0, (row - 7) * 1.2), 0.6, WHITE);
				}
			// Never posed, through the include: its bind pose, as raylib's skinning shader draws one.
			if (ready)
				DrawModel(models[3], new Vector3(0, 0, 9), 0.6, WHITE);
			EndMode3D();
			if (frame == 2)
				TakeScreenshotAsync("helix.png");
			EndDrawing();
			if (frame >= 0)
				frame++;
		}
		CloseWindow();
	}
}
