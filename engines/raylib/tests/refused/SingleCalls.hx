import helix.raylib.Raylib.*;

/** A program naming Haxe's `Single`, which a page doesn't have, so with `-D helix-raylib-portable-sys` it doesn't build on any target:
	`helix.py test` builds it for JS and natively and checks the refusal (helix.raylib.internal.SysCalls). */
class SingleCalls {
	static var weights:Array<Single> = [0.5, 0.5];

	static function scaled(value:Single):Float {
		return value * 2;
	}

	static function main():Void {
		var weight:Single = 1.0;
		InitWindow(320, 200, "refused");
		CloseWindow();
	}
}
