// helix-raylib's size ladder (tools/measure_sizes.py): each rung adds one thing to the one before; this one a texture loaded with LoadTextureAsync and drawn.
import helix.raylib.Raylib.*;
import helix.raylib.extras.Textures.*;
import helix.raylib.Texture2D;
import helix.raylib.Vector2;

/** A program written in raylib on helix-raylib, as a game in raylib would be. Its image is docs/trials/2026-10-30-async/assets/player.png. */
@:adds("helix.log", "helix.platform.adapters.filesystem.browser", "helix.platform.adapters.http.fetchapi", "helix.platform.adapters.imagedecoder.canvas",
	"helix.raylib.internal.Answers", "helix.raylib.internal.CallbackFiles", "helix.raylib.internal.MemoryFiles", "helix.raylib.modules.RTexturesAsync",
	"helix.services.assets.AssetCache", "helix.services.assets.AssetRequest", "helix.services.assets.AssetSource", "helix.services.assets.Assets",
	"helix.services.assets.CacheDecision", "helix.services.assets.FileSystemSource", "helix.services.assets.KeptCopies",
	"helix.services.assets.RevalidateCache", "helix.services.assets.ServerSource", "helix.services.images")
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
