// helix-ray's size ladder (tools/measure_sizes.py): each rung adds one thing to the one before; this one a window cleared each frame: raylib's loop and frame, and what helix-ray builds before main.
import helix.ray.Raylib.*;

/** A program written in raylib on helix-ray, as a game in raylib would be. It links the saves and the keyboard, which it doesn't name:
	services' `Screen` tests its saves each poll, and helix-ray's poll its keyboard (docs/CONVENTIONS.md's known exceptions). */
@:adds("helix.log", "helix.math.Matrix3D", "helix.math.Random", "helix.platform", "helix.platform.adapters.events.dom",
	"helix.platform.adapters.graphics.webgl2", "helix.platform.adapters.window.dom", "helix.platform.adapters.shared", "helix.platform.adapters.shared.dom",
	"helix.platform.adapters.system.dom", "helix.ray", "helix.ray.raylib.RCore", "helix.ray.internal.Frame", "helix.ray.internal.Program",
	"helix.ray.internal.Runtime", "helix.ray.internal.Textures", "helix.services.input.Keyboard", "helix.services.saves", "helix.services.screen",
	"helix.services.shaders", "helix.services.shaders.compiled", "helix.services.time")
class Main {
	static function main():Void {
		InitWindow(800, 450, "sizes");
		while (!WindowShouldClose()) {
			BeginDrawing();
			ClearBackground(RAYWHITE);
			EndDrawing();
		}
		CloseWindow();
	}
}
