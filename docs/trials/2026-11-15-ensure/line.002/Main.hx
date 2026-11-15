import helix.raylib.*;
import helix.raylib.Raylib.*;
import helix.raylib.extras.Assets.*;

class Main {
	static var ready = false;
	static var parts:Array<Model> = [];
	static var anims:ModelAnimation = null;
	static var panel:Texture2D;
	static var font:Font;
	static var music:Music;
	static var slash:Sound;

	static function main() {
		var maxFrames = -1;
		for (a in Sys.args())
			if (StringTools.startsWith(a, "--frames="))
				maxFrames = Std.parseInt(a.substr(9));

		InitWindow(1280, 720, "Character viewer");
		InitAudioDevice();
		SetTargetFPS(60);

		var files = [
			"assets/characters/Adventurer_Body.glb",
			"assets/characters/Adventurer_Head.glb",
			"assets/characters/Adventurer_Legs.glb",
			"assets/characters/Adventurer_Feet.glb",
			"assets/characters/Animations.glb",
			"assets/ui/panel.png",
			"assets/ui/font.ttf",
			"assets/sound/music.ogg",
			"assets/sound/slash.wav"
		];
		EnsureAssetsAsync(files, function() {
			for (f in ["Body", "Head", "Legs", "Feet"])
				parts.push(LoadModel("assets/characters/Adventurer_" + f + ".glb"));
			var cnt = [0];
			var list:Array<ModelAnimation> = LoadModelAnimations("assets/characters/Animations.glb", cnt);
			for (a in list)
				if (a.name == "CharacterArmature|Idle")
					anims = a;
			if (anims == null && list.length > 0)
				anims = list[0];
			panel = LoadTexture("assets/ui/panel.png");
			font = LoadFontEx("assets/ui/font.ttf", 40, null, 0);
			music = LoadMusicStream("assets/sound/music.ogg");
			music.looping = true;
			PlayMusicStream(music);
			slash = LoadSound("assets/sound/slash.wav");
			ready = true;
		});

		var camera = new Camera3D();
		camera.position = new Vector3(0, 3, 6);
		camera.target = new Vector3(0, 1, 0);
		camera.up = new Vector3(0, 1, 0);
		camera.fovy = 45;
		camera.projection = CAMERA_PERSPECTIVE;

		var frame = 0;
		var angle = 0.0;
		var animFrame = 0;
		while (!WindowShouldClose()) {
			if (ready) {
				UpdateMusicStream(music);
				if (IsKeyPressed(KEY_SPACE))
					PlaySound(slash);
				angle += 0.2 * GetFrameTime();
				camera.position.x = Math.sin(angle) * 6;
				camera.position.z = Math.cos(angle) * 6;
				if (anims != null) {
					animFrame = (animFrame + 1) % anims.frameCount;
					for (p in parts)
						UpdateModelAnimation(p, anims, animFrame);
				}
			}

			BeginDrawing();
			ClearBackground(RAYWHITE);
			BeginMode3D(camera);
			DrawPlane(new Vector3(0, 0, 0), new Vector2(20, 20), GRAY);
			if (ready)
				for (p in parts)
					DrawModel(p, new Vector3(0, 0, 0), 1.0, WHITE);
			EndMode3D();
			if (ready) {
				DrawTexturePro(panel, new Rectangle(0, 0, panel.width, panel.height), new Rectangle(0, 720 - 120, 360, 120),
					new Vector2(0, 0), 0, WHITE);
				DrawTextEx(font, "THE WARDEN", new Vector2(20, 720 - 120 + 40), 40, 2, WHITE);
			} else
				DrawText("Loading...", 20, 20, 20, DARKGRAY);
			frame++;
			var last = maxFrames > 0 && frame >= maxFrames;
			if (last)
				TakeScreenshot("shot.png");
			EndDrawing();
			if (last)
				break;
		}
		CloseAudioDevice();
		CloseWindow();
	}
}
