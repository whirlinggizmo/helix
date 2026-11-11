import helix.raylib.Raylib.*;

/** A program writing with `Sys.println`, built for JS without `-D helix-raylib-portable-sys` by `helix.py test`: the page has no `Sys`,
	as Haxe has none for JS, so the call is Haxe's error. */
class PageSys {
	static function main():Void {
		InitWindow(10, 10, "PageSys");
		Sys.println("written");
		CloseWindow();
	}
}
