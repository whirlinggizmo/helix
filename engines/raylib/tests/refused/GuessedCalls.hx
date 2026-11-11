import helix.raylib.Raylib.*;

/** A program calling refused functions with guessed arguments, which doesn't build on any target: `helix.py test` builds it for JS and
	natively and checks that each call is refused with its own message, whether given raylib's arguments, too few, too many or the wrong
	types. */
class GuessedCalls {
	static function main():Void {
		var count = [0];
		InitWindow(320, 200, "refused");
		var animations = LoadModelAnimations("hero.glb");
		var counted = LoadModelAnimations("hero.glb", count);
		var materials = LoadMaterials("hero.mtl");
		var bytes = LoadFileData("best.dat", count, "extra");
		var frames = LoadImageAnim(42);
		SetWindowSize("wide");
		CloseWindow();
	}
}
