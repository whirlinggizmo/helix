import helix.raylib.Raylib.*;
import helix.raylib.*;

class Main {
	static function main() {
		var maxFrames = -1;
		for (a in Sys.args())
			if (StringTools.startsWith(a, "--frames="))
				maxFrames = Std.parseInt(a.substr(9));

		InitWindow(1280, 720, "Character viewer");
		SetTargetFPS(60);
		InitAudioDevice();

		var names = ["Body", "Head", "Legs", "Feet"];
		var models = [for (n in names) LoadModel("assets/characters/Adventurer_" + n + ".glb")];
		var animCount = [0];
		var anims = LoadModelAnimations("assets/characters/Animations.glb", animCount);
		var clip = -1;
		for (i in 0...anims.length)
			if (anims[i].name == "CharacterArmature|Idle")
				clip = i;
		if (clip < 0)
			clip = 0;

		var panel = LoadTexture("assets/ui/panel.png");
		var font = LoadFontEx("assets/ui/font.ttf", 40, null, 0);
		var music = LoadMusicStream("assets/sound/music.ogg");
		music.looping = true;
		PlayMusicStream(music);
		var slash = LoadSound("assets/sound/slash.wav");

		var camera = new Camera3D();
		camera.position = new Vector3(0, 3, 6);
		camera.target = new Vector3(0, 1, 0);
		camera.up = new Vector3(0, 1, 0);
		camera.fovy = 45;
		camera.projection = CAMERA_PERSPECTIVE;

		var frame = 0;
		var angle = 0.0;
		var origin = new Vector3(0, 0, 0);
		while (!WindowShouldClose()) {
			UpdateMusicStream(music);
			if (IsKeyPressed(KEY_SPACE))
				PlaySound(slash);

			angle += 0.3 * GetFrameTime();
			camera.position = new Vector3(Math.sin(angle) * 6, 3, Math.cos(angle) * 6);

			if (anims.length > 0) {
				var a = anims[clip];
				for (m in models)
					UpdateModelAnimation(m, a, frame % a.frameCount);
			}

			BeginDrawing();
			ClearBackground(SKYBLUE);
			BeginMode3D(camera);
			DrawPlane(origin, new Vector2(20, 20), GRAY);
			for (m in models)
				DrawModel(m, origin, 1.0, WHITE);
			EndMode3D();

			DrawTexturePro(panel, new Rectangle(0, 0, panel.width, panel.height), new Rectangle(0, 720 - 120, 360, 120),
				new Vector2(0, 0), 0, WHITE);
			DrawTextEx(font, "THE WARDEN", new Vector2(24, 720 - 120 + 40), 40, 2, WHITE);
			var last = maxFrames > 0 && frame + 1 >= maxFrames;
			if (last)
				TakeScreenshot("shot.png");
			EndDrawing();

			frame++;
			if (last)
				break;
		}

		UnloadSound(slash);
		UnloadMusicStream(music);
		UnloadFont(font);
		UnloadTexture(panel);
		for (m in models)
			UnloadModel(m);
		CloseAudioDevice();
		CloseWindow();
	}
}
