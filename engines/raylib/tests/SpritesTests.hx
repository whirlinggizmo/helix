import helix.raylib.*;
import helix.raylib.Raylib.*;
import helix.raylib.Raymath.*;
import helix.raylib.extras.Sprites.*;
import helix.raylib.internal.Frame;
import helix.raylib.internal.Runtime;
import helix.services.time.Time;

/** Checks `extras.Sprites`: `DrawTextureInstanced` writes, for each matrix, the sprite record `DrawTexturePro` writes for the same
	placement, in the same order, and nothing for a texture that isn't one. Run by helix.py test on the interpreter and Node. */
@:access(helix.raylib.internal.Runtime)
@:access(helix.raylib.internal.Frame)
class SpritesTests {
	static var checks = 0;

	static function check(value:Bool, message:String):Void {
		if (!value)
			throw message;
		checks++;
	}

	// The frame's sprite records so far, each its 12 floats then its color's four bytes, and the frame emptied for the next draws.
	static function records():Array<Float> {
		var frame = Runtime.frame;
		var out = [];
		for (s in 0...frame.spriteCount) {
			var at = s * 52;
			for (i in 0...12)
				out.push(frame.spriteData.getFloat(at + i * 4));
			for (i in 0...4)
				out.push(frame.spriteData.get(at + 48 + i));
		}
		frame.draw(64, 64, true);
		return out;
	}

	static function same(a:Array<Float>, b:Array<Float>, message:String):Void {
		check(a.length == b.length, '$message: ${a.length} numbers, not ${b.length}');
		for (i in 0...a.length)
			check(Math.abs(a[i] - b[i]) < 1e-3 || a[i] == b[i], '$message: number $i is ${a[i]}, not ${b[i]}');
	}

	static function main():Void {
		SetTraceLogLevel(LOG_NONE);
		var graphics = new CountingGraphics();
		Runtime.graphics = graphics;
		Runtime.frame = new Frame(graphics);
		Runtime.system = new FakeSystem();
		Runtime.time = new Time(Runtime.system);
		Runtime.frame.begin(64, 64);
		var image = GenImageColor(16, 8, RED);
		var texture = LoadTextureFromImage(image);
		UnloadImage(image);
		var part = new Rectangle(4, 2, 8, 4);

		// Placed, turned about its top left and scaled: each copy is DrawTexturePro's quad for the same placement.
		DrawTextureInstanced(texture, part, [
			MatrixTranslate(10, 20, 0),
			MatrixMultiply(MatrixRotateZ(30 * Math.PI / 180), MatrixTranslate(5, 7, 0)),
			MatrixMultiply(MatrixScale(2, 3, 1), MatrixTranslate(1, 1, 0))
		], BLUE);
		check(Runtime.frame.spriteCount == 3, 'three copies are three records, not ${Runtime.frame.spriteCount}');
		var instanced = records();
		DrawTexturePro(texture, part, new Rectangle(10, 20, 8, 4), new Vector2(0, 0), 0, BLUE);
		DrawTexturePro(texture, part, new Rectangle(5, 7, 8, 4), new Vector2(0, 0), 30, BLUE);
		DrawTexturePro(texture, part, new Rectangle(1, 1, 16, 12), new Vector2(0, 0), 0, BLUE);
		same(instanced, records(), "each copy is DrawTexturePro's record");

		// A flipped part flips the texture coordinates as DrawTexturePro does.
		var flipped = new Rectangle(4, 2, -8, 4);
		DrawTextureInstanced(texture, flipped, [MatrixTranslate(3, 3, 0)], WHITE);
		var one = records();
		DrawTexturePro(texture, flipped, new Rectangle(3, 3, 8, 4), new Vector2(0, 0), 0, WHITE);
		same(one, records(), "a negative width flips the part");

		// No matrices draw nothing; a texture that isn't one draws nothing.
		DrawTextureInstanced(texture, part, [], WHITE);
		check(Runtime.frame.spriteCount == 0, "no copies, no records");
		DrawTextureInstanced(new Texture2D(), part, [MatrixIdentity()], WHITE);
		check(Runtime.frame.spriteCount == 0, "an empty texture draws nothing");
		UnloadTexture(texture);

		var report = haxe.Json.stringify({passed: true, checks: checks});
		#if js
		js.Syntax.code("console.log({0})", report);
		#else
		Sys.println(report);
		#end
	}
}
