import helix.raylib.Raylib.*;
import helix.raylib.extras.Textures.*;
import helix.raylib.extras.Device.*;
import helix.raylib.Vector2;
import helix.raylib.Color;
import helix.raylib.Texture2D;

/** A bunny, as raylib's bunnymark has it. */
class Bunny {
	/** The position. */
	public var position:Vector2;

	/** The speed, in pixels a frame. */
	public var speed:Vector2;

	/** The tint. */
	public var color:Color;

	/** Makes a bunny. */
	public function new(position:Vector2, speed:Vector2, color:Color) {
		this.position = position;
		this.speed = speed;
		this.color = color;
	}
}

/**
	raylib's textures_bunnymark on helix-raylib, for tools/bunnymark.py. It spawns from run options instead of the mouse: count=N spawns N bunnies,
	draws 120 frames to warm up and times 600, then prints one JSON line. ramp=1 starts at 1000 and adds 1000 each 60 frames while those held 59 fps,
	printing the largest count that did. Every bunny starts the same from a fixed xorshift32 seed, as in the C version.
**/
class Main {
	static var seed = 0x92D68CA2; // 2463534242

	// xorshift32, the same in every contender, so every bunny starts the same.
	static function rnd(min:Int, max:Int):Int {
		var x = seed;
		x ^= x << 13;
		x ^= x >>> 17;
		x ^= x << 5;
		seed = x;
		return min + (x >>> 8) % (max - min + 1);
	}

	static function spawn(bunnies:Array<Bunny>, n:Int):Void {
		for (i in 0...n) {
			var px = rnd(0, 800 - 32);
			var py = rnd(40, 450 - 32);
			var sx = rnd(-250, 250) / 60.0;
			var sy = rnd(-250, 250) / 60.0;
			var r = rnd(50, 240);
			var g = rnd(80, 240);
			var b = rnd(100, 240);
			bunnies.push(new Bunny(new Vector2(px, py), new Vector2(sx, sy), new Color(r, g, b, 255)));
		}
	}

	static function emit(line:String):Void {
		#if js
		js.Browser.console.log(line);
		#else
		Sys.println(line);
		#end
	}

	static function wallMs():Float {
		#if js
		return js.Browser.window.performance.now();
		#else
		return Sys.time() * 1000;
		#end
	}

	static function main():Void {
		var target = #if js "page" #elseif sdl_gpu "native-sdlgpu" #else "native-gl" #end;
		var countOption = GetRunOption("count");
		var ramp = GetRunOption("ramp") == "1";
		var count = ramp ? 1000 : (countOption == null ? 1000 : Std.parseInt(countOption));
		InitWindow(800, 450, "helix-raylib bunnymark");
		var texture:Null<Texture2D> = null;
		LoadTextureAsync("wabbit_alpha.png", t -> texture = t);
		var bunnies:Array<Bunny> = [];
		var frame = -1;
		var firstFrameMs = 0.0;
		var last = 0.0;
		var deltas:Array<Float> = [];
		var windowStart = 0.0;
		var held = 0;
		var done = false;
		while (!done && !WindowShouldClose()) {
			if (texture == null) {
				BeginDrawing();
				ClearBackground(RAYWHITE);
				EndDrawing();
				continue;
			}
			var now = GetTime() * 1000;
			if (frame < 0) {
				spawn(bunnies, count);
			} else {
				deltas.push(now - last);
			}
			last = now;
			frame++;
			var w = texture.width, h = texture.height;
			var sw = GetScreenWidth(), sh = GetScreenHeight();
			for (b in bunnies) {
				b.position.x += b.speed.x;
				b.position.y += b.speed.y;
				if (((b.position.x + w / 2) > sw) || ((b.position.x + w / 2) < 0))
					b.speed.x *= -1;
				if (((b.position.y + h / 2) > sh) || ((b.position.y + h / 2 - 40) < 0))
					b.speed.y *= -1;
			}
			BeginDrawing();
			ClearBackground(RAYWHITE);
			for (b in bunnies)
				DrawTexture(texture, Std.int(b.position.x), Std.int(b.position.y), b.color);
			EndDrawing();
			if (frame == 0)
				firstFrameMs = wallMs();
			if (!ramp) {
				if (deltas.length == 120 + 600) {
					var timed = deltas.slice(120);
					var sorted = timed.copy();
					sorted.sort((a, b) -> a < b ? -1 : a > b ? 1 : 0);
					var sum = 0.0;
					for (d in timed)
						sum += d;
					var mean = sum / timed.length;
					emit('{"contender":"helix-raylib","target":"$target","mode":"count","count":$count,"mean_ms":$mean,"median_ms":${sorted[300]},"p95_ms":${sorted[570]},"fps":${1000 / mean},"first_frame_ms":$firstFrameMs}');
					done = true;
				}
			} else if (deltas.length >= 120 && (deltas.length - 120) % 60 == 0) {
				// The last 60 frames, after a 120-frame warm-up.
				if (deltas.length > 120) {
					var fps = 60 * 1000 / (now - windowStart);
					if (fps >= 59 && bunnies.length < 2000000) {
						held = bunnies.length;
						spawn(bunnies, 1000);
					} else {
						emit('{"contender":"helix-raylib","target":"$target","mode":"ramp","ramp_max":$held,"last_fps":$fps,"first_frame_ms":$firstFrameMs}');
						done = true;
					}
				}
				windowStart = now;
			}
		}
		CloseWindow();
	}
}
