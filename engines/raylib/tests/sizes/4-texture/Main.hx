// helix-ray's size ladder (tools/measure_sizes.py): each rung adds one thing to the one before; this one a texture loaded with LoadTextureAsync and drawn.
import helix.ray.Raylib.*;
import helix.ray.Texture2D;
import helix.ray.Vector2;

/** A program written in raylib on helix-ray, as a game in raylib would be. Its image is docs/trials/2026-10-30-async/assets/player.png. */
@:adds("helix.platform.adapters.filesystem.browser", "helix.platform.adapters.http.fetchapi", "helix.platform.adapters.imagedecoder.canvas",
	"helix.ray.internal.CallbackFiles", "helix.ray.internal.MemoryFiles", "helix.ray.raylib.RAsync", "helix.services.assets.AssetCache",
	"helix.services.assets.AssetRequest", "helix.services.assets.AssetSource", "helix.services.assets.Assets", "helix.services.assets.CacheDecision",
	"helix.services.assets.FileSystemSource", "helix.services.assets.KeptCopies", "helix.services.assets.RevalidateCache",
	"helix.services.assets.ServerSource", "helix.services.images")
class Main {
	static function main():Void {
		InitWindow(800, 450, "sizes");
		var texture:Null<Texture2D> = null;
		LoadTextureAsync("player.png", loaded -> texture = loaded);
		while (!WindowShouldClose()) {
			BeginDrawing();
			ClearBackground(RAYWHITE);
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
