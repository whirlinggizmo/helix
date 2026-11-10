// helix-raylib's size ladder (tools/measure_sizes.py): each rung adds one thing to the one before; this one audio: a sound loaded with LoadSoundAsync and played once it is loaded.
import helix.raylib.Raylib.*;
import helix.raylib.Rlights.*;
import helix.raylib.Camera3D;
import helix.raylib.Model;
import helix.raylib.ModelAnimation;
import helix.raylib.Shader;
import helix.raylib.Sound;
import helix.raylib.Texture2D;
import helix.raylib.Vector2;
import helix.raylib.Vector3;

/** A program written in raylib on helix-raylib, as a game in raylib would be. Its image and sound are
	docs/trials/2026-10-30-async/assets/player.png and coin.wav, its model and animations engines/raylib/parity/assets/robot.glb. */
@:adds("helix.platform.adapters.audio.webaudio", "helix.platform.adapters.audiodecoder.webaudio", "helix.raylib.modules.RAudio",
	"helix.raylib.modules.RAudioAsync", "helix.services.audio")
class Main {
	static function main():Void {
		InitWindow(800, 450, "sizes");
		var lit:Null<Shader> = null;
		LoadCompiledShaderAsync("lighting.shader", loaded -> {
			lit = loaded;
			CreateLight(LIGHT_POINT, new Vector3(2, 4, 2), new Vector3(0, 0, 0), WHITE, loaded);
		});
		InitAudioDevice();
		var camera = new Camera3D(new Vector3(6, 4, 6), new Vector3(0, 1.5, 0), new Vector3(0, 1, 0), 45, CAMERA_PERSPECTIVE);
		var texture:Null<Texture2D> = null;
		var model:Null<Model> = null;
		var cube = LoadModelFromMesh(GenMeshCube(1, 1, 1));
		var animations:Null<Array<ModelAnimation>> = null;
		var sound:Null<Sound> = null;
		var frame = 0;
		var played = false;
		LoadTextureAsync("player.png", loaded -> texture = loaded);
		LoadModelAsync("robot.glb", loaded -> {
			model = loaded;
			for (m in loaded.materials)
				m.shader = lit;
		});
		LoadModelAnimationsAsync("robot.glb", loaded -> animations = loaded);
		LoadSoundAsync("coin.wav", loaded -> sound = loaded);
		while (!WindowShouldClose()) {
			if (sound != null && !played) {
				PlaySound(sound);
				played = true;
			}
			if (model != null && animations != null && animations.length > 0) {
				frame = (frame + 1) % animations[0].frameCount;
				UpdateModelAnimation(model, animations[0], frame);
			}
			BeginDrawing();
			ClearBackground(RAYWHITE);
			BeginMode3D(camera);
			DrawModel(cube, new Vector3(-3, 0.5, 0), 1, WHITE);
			if (model != null)
				DrawModel(model, new Vector3(0, 0, 0), 1, WHITE);
			EndMode3D();
			DrawRectangle(20, 20, 120, 60, MAROON);
			DrawCircle(220, 50, 30, DARKBLUE);
			DrawLine(20, 100, 260, 100, BLACK);
			DrawTriangle(new Vector2(300, 20), new Vector2(280, 80), new Vector2(340, 80), GOLD);
			DrawText("Hello, raylib", 20, 120, 20, DARKGRAY);
			if (texture != null)
				DrawTexture(texture, 20, 160, WHITE);
			EndDrawing();
		}
		CloseWindow();
	}
}
