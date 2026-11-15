import helix.raylib.Raylib.*;
import helix.raylib.*;

class Main {
	static function main() {
		var maxFrames = -1;
		for (a in Sys.args())
			if (StringTools.startsWith(a, "--frames="))
				maxFrames = Std.parseInt(a.substr(9));

		InitWindow(1280, 720, "Character viewer");
		InitAudioDevice();
		SetTargetFPS(60);

		var names = ["Body", "Head", "Legs", "Feet"];
		var models = [for (n in names) LoadModel("assets/characters/Adventurer_" + n + ".glb")];
		var animCount = [0];
		var anims:Array<ModelAnimation> = LoadModelAnimations("assets/characters/Animations.glb", animCount);
		var idle = null;
		for (a in anims)
			if (a.name == "CharacterArmature|Idle")
				idle = a;
		if (idle == null)
			idle = anims[0];

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
		var origin = new Vector3(0, 0, 0);
		while (!WindowShouldClose()) {
			UpdateMusicStream(music);
			if (IsKeyPressed(KEY_SPACE))
				PlaySound(slash);
			angle += 0.3 * GetFrameTime();
			cam.position.x = Math.sin(angle) * 6;
			cam.position.z = Math.cos(angle) * 6;
			if (idle != null)
				for (m in models)
					UpdateModelAnimation(m, idle, frame % idle.frameCount);
			frame++;

			BeginDrawing();
			ClearBackground(RAYWHITE);
			BeginMode3D(cam);
			DrawPlane(origin, new Vector2(20, 20), GRAY);
			for (m in models)
				DrawModel(m, origin, 1.0, WHITE);
			EndMode3D();
			DrawTexturePro(panel, new Rectangle(0, 0, panel.width, panel.height), new Rectangle(0, 720 - 120, 360, 120), new Vector2(0, 0), 0, WHITE);
			DrawTextEx(font, "THE WARDEN", new Vector2(20, 720 - 120 + 38), 40, 2, WHITE);
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
