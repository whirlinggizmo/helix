import helix.ray.*;
import helix.ray.Raylib.*;

// scene.c's Adventurer woman holding the sword, drawn by helix-ray: the third frame after her loads saved as helix.png.
class Main {
	static function main():Void {
		InitWindow(640, 360, "modular");
		var camera = new Camera(new Vector3(2.2, 1.6, 3.2), new Vector3(0, 0.9, 0), new Vector3(0, 1, 0), 45, CAMERA_PERSPECTIVE);
		var files = [
			"Adventurer_Head.glb",
			"Adventurer_Body.glb",
			"Adventurer_Legs.glb",
			"Adventurer_Feet.glb",
			"Sword.glb"
		];
		var parts:Array<Model> = [for (_ in files) null];
		for (i => file in files)
			LoadModelAsync(file, m -> parts[i] = m);
		var anims:Array<ModelAnimation> = null;
		LoadModelAnimationsAsync("Animations.glb", a -> anims = a);
		var frame = -1;
		while (!WindowShouldClose()) {
			var ready = anims != null && !parts.contains(null);
			if (ready) {
				if (frame < 0)
					frame = 0;
				var clip = anims.filter(a -> a.name == "CharacterArmature|Sword_Slash")[0];
				for (p in parts)
					UpdateModelAnimation(p, clip, 20);
			}
			BeginDrawing();
			ClearBackground(RAYWHITE);
			BeginMode3D(camera);
			DrawGrid(10, 0.5);
			if (ready)
				for (p in parts)
					DrawModel(p, new Vector3(0, 0, 0), 1, WHITE);
			EndMode3D();
			if (frame == 2)
				TakeScreenshot("helix.png");
			EndDrawing();
			if (frame >= 0)
				frame++;
		}
		CloseWindow();
	}
}
