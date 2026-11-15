import helix.raylib.*;
import helix.raylib.Raylib.*;

class Main {
	static function main() {
		var maxFrames = -1;
		for (a in Sys.args())
			if (StringTools.startsWith(a, "--frames="))
				maxFrames = Std.parseInt(a.substr(9));

		InitWindow(1280, 720, "THE WARDEN");
		SetTargetFPS(60);
		InitAudioDevice();

		var parts = ["Body", "Head", "Legs", "Feet"];
		var models = [for (p in parts) LoadModel("assets/characters/Adventurer_" + p + ".glb")];

		var cnt = [0];
		var anims = LoadModelAnimations("assets/characters/Animations.glb", cnt);
		var idx = -1;
		for (i in 0...cnt[0]) {
			if (anims[i].name == "CharacterArmature|Idle") idx = i;
		}
		if (idx < 0) idx = 0;
		var anim = anims[idx];

		var panel = LoadTexture("assets/ui/panel.png");
		var font = LoadFontEx("assets/ui/font.ttf", 40, null, 0);
		var music = LoadMusicStream("assets/sound/music.ogg");
		music.looping = true;
		PlayMusicStream(music);
		var slash = LoadSound("assets/sound/slash.wav");

		var cam = new Camera3D();
		cam.position = new Vector3(0, 3, 6);
		cam.target = new Vector3(0, 1, 0);
		cam.up = new Vector3(0, 1, 0);
		cam.fovy = 45;
		cam.projection = CAMERA_PERSPECTIVE;

		var frame = 0;
		var angle = 0.0;
		var count = 0;
		while (!WindowShouldClose()) {
			UpdateMusicStream(music);
			if (IsKeyPressed(KEY_SPACE)) PlaySound(slash);

			frame++;
			for (m in models) UpdateModelAnimation(m, anim, frame % anim.frameCount);

			angle += 0.3 * GetFrameTime();
			cam.position.x = Math.sin(angle) * 6.708;
			cam.position.z = Math.cos(angle) * 6.708;

			BeginDrawing();
			ClearBackground(SKYBLUE);
			BeginMode3D(cam);
			DrawPlane(new Vector3(0, 0, 0), new Vector2(20, 20), GRAY);
			for (m in models) DrawModel(m, new Vector3(0, 0, 0), 1.0, WHITE);
			EndMode3D();

			DrawTexturePro(panel, new Rectangle(0, 0, panel.width, panel.height),
				new Rectangle(10, 720 - 120 - 10, 360, 120), new Vector2(0, 0), 0, WHITE);
			DrawTextEx(font, "THE WARDEN", new Vector2(10 + 20, 720 - 120 - 10 + 40), 40, 2, WHITE);
			count++;
			var last = maxFrames > 0 && count >= maxFrames;
			if (last) TakeScreenshot("shot.png");
			EndDrawing();
			if (last) break;
		}
		CloseAudioDevice();
		CloseWindow();
	}
}
