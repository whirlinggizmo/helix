// helix-raylib's size ladder (tools/measure_sizes.py): each rung adds one thing to the one before; this one a game: what a real game uses, its file formats one of each.
import helix.raylib.Raylib.*;
import helix.raylib.Raymath.*;
import helix.raylib.BoundingBox;
import helix.raylib.Camera2D;
import helix.raylib.Camera3D;
import helix.raylib.Font;
import helix.raylib.Model;
import helix.raylib.ModelAnimation;
import helix.raylib.Music;
import helix.raylib.Rectangle;
import helix.raylib.RenderTexture2D;
import helix.raylib.Shader;
import helix.raylib.Sound;
import helix.raylib.Texture2D;
import helix.raylib.Vector2;
import helix.raylib.Vector3;

/** A game written in raylib on helix-raylib, with a full set of a game's features and one file format of each kind: a skinned glTF model
	whose animations are blended, PNG textures and a sprite sheet, a TTF font and the default one, 2D and 3D drawing with a camera of
	each, a shader of its own, a render texture, sound effects (WAV) and music (Ogg), the keyboard, mouse, gamepad and touch, a save
	kept with SaveFileTextAsync and read back with LoadFileTextAsync, collisions and raymath, fullscreen and the window's size. What a game
	doesn't usually carry is left to the next rung: the other readers (OBJ, GIF, QOA, MP3, BMFont, image fonts), VR, ExportFontAsCodeAsync,
	automation events, the clipboard. It is built and measured, never run: its files aren't there. */
@:adds("helix.formats.audio.AudioHeader", "helix.formats.bmfont", "helix.formats.qoi", "helix.formats.truetype", "helix.geometry.Camera2D",
	"helix.geometry.Ray3D", "helix.math.Matrix2D", "helix.math.RectPacker2D", "helix.math.Transform2D", "helix.math.Vector2D",
	"helix.platform.adapters.fontrasterizer.canvas", "helix.platform.adapters.gamepads.dom", "helix.platform.adapters.keyboard.dom",
	"helix.platform.adapters.mouse.dom", "helix.platform.adapters.touch.dom", "helix.raylib.internal.AudioStreams", "helix.raylib.internal.Automation",
	"helix.raylib.internal.FrameConverter", "helix.services.fonts", "helix.services.input.Gamepads", "helix.services.input.Gestures",
	"helix.services.input.Mouse", "helix.services.input.Touch")
class Main {
	static function main():Void {
		InitWindow(800, 450, "sizes");
		InitAudioDevice();
		SetTargetFPS(60);
		var camera = new Camera3D(new Vector3(6, 4, 6), new Vector3(0, 1.5, 0), new Vector3(0, 1, 0), 45, CAMERA_PERSPECTIVE);
		var camera2D = new Camera2D(new Vector2(400, 225), new Vector2(0, 0), 0, 1);
		var hero:Null<Model> = null;
		var animations:Null<Array<ModelAnimation>> = null;
		var tiles:Null<Texture2D> = null;
		var sprites:Null<Texture2D> = null;
		var font:Null<Font> = null;
		var jump:Null<Sound> = null;
		var coin:Null<Sound> = null;
		var music:Music = LoadMusicStream("theme.ogg");
		var target:RenderTexture2D = LoadRenderTexture(400, 225);
		var shader:Shader = LoadShaderFromMemory(null, "#version 330
in vec2 fragTexCoord;
in vec4 fragColor;
out vec4 finalColor;
uniform sampler2D texture0;
uniform vec4 colDiffuse;
uniform float time;
void main() {
    vec4 texel = texture(texture0, fragTexCoord);
    finalColor = vec4(texel.rgb*(0.75 + 0.25*sin(time)), texel.a)*colDiffuse*fragColor;
}
");
		var timeLocation = GetShaderLocation(shader, "time");
		var best = 0;
		LoadModelAsync("hero.glb", loaded -> hero = loaded);
		LoadModelAnimationsAsync("hero.glb", loaded -> animations = loaded);
		LoadTextureAsync("tiles.png", loaded -> tiles = loaded);
		LoadTextureAsync("sprites.png", loaded -> sprites = loaded);
		LoadFontAsync("font.ttf", loaded -> font = loaded);
		LoadSoundAsync("jump.wav", loaded -> jump = loaded);
		LoadSoundAsync("coin.wav", loaded -> coin = loaded);
		LoadFileTextAsync("save.txt", text -> best = Std.parseInt(text) ?? 0);
		PlayMusicStream(music);
		var player = new Vector3(0, 0, 0);
		var coinAt = new Vector3(3, 0.5, 0);
		var score = 0;
		var time = 0.0;
		var blend = 0.0;
		while (!WindowShouldClose()) {
			var dt = GetFrameTime();
			time += dt;
			UpdateMusicStream(music);
			if (IsKeyPressed(KEY_F))
				ToggleFullscreenAsync();
			if (IsKeyPressed(KEY_R))
				SetWindowSizeAsync(1280, 720);
			// Input: the keyboard, a gamepad's stick, the mouse and touch all move the player.
			var move = new Vector3(0, 0, 0);
			if (IsKeyDown(KEY_RIGHT))
				move.x += 1;
			if (IsKeyDown(KEY_LEFT))
				move.x -= 1;
			if (IsGamepadAvailable(0)) {
				move.x += GetGamepadAxisMovement(0, GAMEPAD_AXIS_LEFT_X);
				move.z += GetGamepadAxisMovement(0, GAMEPAD_AXIS_LEFT_Y);
			}
			var pointer = GetTouchPointCount() > 0 ? GetTouchPosition(0) : GetMousePosition();
			if (IsMouseButtonDown(MOUSE_BUTTON_LEFT) || GetTouchPointCount() > 0) {
				var ray = GetScreenToWorldRay(pointer, camera);
				var hit = GetRayCollisionBox(ray, new BoundingBox(new Vector3(-10, -0.1, -10), new Vector3(10, 0, 10)));
				if (hit.hit)
					move = Vector3Normalize(Vector3Subtract(hit.point, player));
			}
			var jumping = IsKeyPressed(KEY_SPACE) || IsGamepadButtonPressed(0, GAMEPAD_BUTTON_RIGHT_FACE_DOWN);
			if (jumping && jump != null)
				PlaySound(jump);
			player = Vector3Add(player, Vector3Scale(move, 4 * dt));
			blend = Clamp(Lerp(blend, Vector3Length(move) > 0 ? 1 : 0, 8 * dt), 0, 1);
			if (CheckCollisionSpheres(player, 0.5, coinAt, 0.5)) {
				score++;
				coinAt = new Vector3(GetRandomValue(-5, 5), 0.5, GetRandomValue(-5, 5));
				if (coin != null)
					PlaySound(coin);
				if (score > best) {
					best = score;
					SaveFileTextAsync("save.txt", Std.string(best));
				}
			}
			// The hero's idle and run blended by how fast it moves.
			if (hero != null && animations != null && animations.length > 1)
				UpdateModelAnimationEx(hero, animations[0], time * 30 % animations[0].frameCount, animations[1], time * 30 % animations[1].frameCount, blend);
			camera.target = Vector3Lerp(camera.target, player, 4 * dt);
			// The world drawn into a render texture, then to the screen through the shader.
			BeginTextureMode(target);
			ClearBackground(SKYBLUE);
			BeginMode3D(camera);
			DrawGrid(20, 1);
			if (hero != null)
				DrawModelEx(hero, player, new Vector3(0, 1, 0), 0, new Vector3(1, 1, 1), WHITE);
			DrawSphere(coinAt, 0.5, GOLD);
			EndMode3D();
			EndTextureMode();
			BeginDrawing();
			ClearBackground(BLACK);
			SetShaderValue(shader, timeLocation, time, SHADER_UNIFORM_FLOAT);
			BeginShaderMode(shader);
			DrawTexturePro(target.texture, new Rectangle(0, 0, 400, -225), new Rectangle(0, 0, GetScreenWidth(), GetScreenHeight()), new Vector2(0, 0), 0,
				WHITE);
			EndShaderMode();
			// The 2D layer: tiles and a sprite from the sheet with a 2D camera, then the text.
			BeginMode2D(camera2D);
			if (tiles != null)
				DrawTextureRec(tiles, new Rectangle(0, 0, 32, 32), new Vector2(-400, 193), WHITE);
			if (sprites != null) {
				var frame = Std.int(time * 10) % 8;
				var source = new Rectangle(frame * 32, 0, 32, 32);
				var dest = new Rectangle(pointer.x - 400, pointer.y - 225, 32, 32);
				if (CheckCollisionRecs(dest, new Rectangle(-400, 193, 32, 32)))
					DrawRectangleLinesEx(dest, 2, RED);
				DrawTexturePro(sprites, source, dest, new Vector2(16, 16), 0, WHITE);
			}
			EndMode2D();
			if (font != null)
				DrawTextEx(font, 'Score $score', new Vector2(20, 20), 32, 1, WHITE);
			DrawText('Best $best', 20, 60, 20, LIGHTGRAY);
			DrawFPS(GetScreenWidth() - 100, 20);
			EndDrawing();
		}
		UnloadRenderTexture(target);
		UnloadMusicStream(music);
		CloseAudioDevice();
		CloseWindow();
	}
}
