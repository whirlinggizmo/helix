import helix.raylib.Raylib.*;
import helix.raylib.*;
import helix.raylib.extras.Assets.*;

class Main {
	static var parts:Array<Model> = [];
	static var anims:Array<ModelAnimation> = [];
	static var animCount:Int = 0;
	static var panel:Texture2D;
	static var font:Font;
	static var music:Music;
	static var slash:Sound;
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
		EnsureAssetsAsync(files, function() {
			for (i in 0...4)
				parts.push(LoadModel(files[i]));
			var cnt = [0];
			anims = LoadModelAnimations(files[4], cnt);
			animCount = cnt[0];
			panel = LoadTexture(files[5]);
			font = LoadFontEx(files[6], 40, null, 0);
			music = LoadMusicStream(files[7]);
			music.looping = true;
			PlayMusicStream(music);
			slash = LoadSound(files[8]);
			ready = true;
		});

		var camera = new Camera3D();
		camera.position = new Vector3(0, 3, 6);
		camera.target = new Vector3(0, 1, 0);
		camera.up = new Vector3(0, 1, 0);
		camera.fovy = 45;
		camera.projection = CAMERA_PERSPECTIVE;

		var angle = 0.0;
		var animIdx = 0;
		var animFrame = 0;
		var frames = 0;

		while (!WindowShouldClose()) {
			if (ready) {
				UpdateMusicStream(music);
				if (IsKeyPressed(KEY_SPACE))
					PlaySound(slash);
				angle += 0.4 * GetFrameTime();
				camera.position = new Vector3(Math.sin(angle) * 6, 3, Math.cos(angle) * 6);
				if (animIdx == 0)
					for (i in 0...animCount)
						if (anims[i].name == "CharacterArmature|Idle")
							animIdx = i;
				var anim = anims[animIdx];
				animFrame = (animFrame + 1) % anim.frameCount;
				for (p in parts)
					UpdateModelAnimation(p, anim, animFrame);
			}

			BeginDrawing();
			ClearBackground(SKYBLUE);
			BeginMode3D(camera);
			DrawPlane(new Vector3(0, 0, 0), new Vector2(20, 20), GRAY);
			if (ready)
				for (p in parts)
					DrawModel(p, new Vector3(0, 0, 0), 1.0, WHITE);
			EndMode3D();
			if (ready) {
				DrawTexturePro(panel, new Rectangle(0, 0, panel.width, panel.height), new Rectangle(10, 590, 360, 120),
					new Vector2(0, 0), 0, WHITE);
				DrawTextEx(font, "THE WARDEN", new Vector2(30, 630), 40, 2, WHITE);
			} else
				DrawText("Loading...", 20, 20, 20, WHITE);
			frames++;
			var last = maxFrames > 0 && frames >= maxFrames;
			if (last)
				TakeScreenshot("shot.png");
			EndDrawing();
			if (last)
				break;
		}
		CloseWindow();
	}
}
