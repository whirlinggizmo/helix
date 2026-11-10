import helix.raylib.Raylib.*;
import sys.io.File;

/** A program calling Haxe's file calls and `sys.io.Process`, which doesn't build on any target: `helix.py test` builds it for JS and
	natively and checks each call's refusal (helix.raylib.internal.SysCalls). */
class FileCalls {
	static function main():Void {
		var text = File.getContent("best.txt");
		File.saveContent("best.txt", text);
		var bytes = File.getBytes("best.dat");
		File.saveBytes("best.dat", bytes);
		var found = sys.FileSystem.exists("best.txt");
		var names = sys.FileSystem.readDirectory(".");
		var process = new sys.io.Process("ls", []);
		InitWindow(320, 200, "refused");
		CloseWindow();
	}
}
