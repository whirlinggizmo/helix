import helix.raylib.*;
import helix.raylib.Raylib.*;
import helix.raylib.extras.Assets.*;

class Main {
	static var ready = false;

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
		EnsureAssetsAsync(files, function() ready = true);

		var models:Array<Model> = [];
		var anims:Array<ModelAnimation> = [];
		var animCount = 0;
		var animIdx = 0;
		var panel:Texture2D = null;
		var font:Font = null;
		var music:Music = null;
		var slash:Sound = null;
		var loaded = false;

		var camera = new Camera3D();
		camera.position = new Vector3(0, 3, 6);
		camera.target = new Vector3(0, 1, 0);
		camera.up = new Vector3(0, 1, 0);
		camera.fovy = 45;
		camera.projection = CAMERA_PERSPECTIVE;

		var angle = 0.0;
		var frame = 0;
		var animFrame = 0;

		while (!WindowShouldClose()) {
			if (ready && !loaded) {
				loaded = true;
				for (f in files.slice(0, 4))
					models.push(LoadModel(f));
				var counter = [0];
				anims = LoadModelAnimations("assets/characters/Animations.glb", counter);
				animCount = counter[0];
				for (i in 0...animCount)
					if (anims[i].name == "CharacterArmature|Idle")
						animIdx = i;
				panel = LoadTexture("assets/ui/panel.png");
				font = LoadFontEx("assets/ui/font.ttf", 40, null, 0);
				music = LoadMusicStream("assets/sound/music.ogg");
				music.looping = true;
				PlayMusicStream(music);
				slash = LoadSound("assets/sound/slash.wav");
			}

			if (loaded) {
				UpdateMusicStream(music);
				if (IsKeyPressed(KEY_SPACE))
					PlaySound(slash);
				angle += 0.2 * GetFrameTime();
				camera.position = new Vector3(Math.sin(angle) * 6, 3, Math.cos(angle) * 6);
				var anim = anims[animIdx];
				animFrame = (animFrame + 1) % anim.frameCount;
				for (m in models)
					UpdateModelAnimation(m, anim, animFrame);
			}

			BeginDrawing();
			ClearBackground(new Color(40, 44, 52, 255));
			if (loaded) {
				BeginMode3D(camera);
				DrawPlane(new Vector3(0, 0, 0), new Vector2(20, 20), GRAY);
				for (m in models)
					DrawModel(m, new Vector3(0, 0, 0), 1.0, WHITE);
				EndMode3D();
				DrawTexturePro(panel, new Rectangle(0, 0, panel.width, panel.height),
					new Rectangle(0, 720 - 120, 360, 120), new Vector2(0, 0), 0, WHITE);
				DrawTextEx(font, "THE WARDEN", new Vector2(20, 720 - 120 + 38), 40, 2, WHITE);
			} else {
				DrawText("Loading...", 20, 20, 20, WHITE);
			}
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
