package;

import lime.app.Application;
import lime.graphics.Image;
import lime.graphics.RenderContext;
import lime.utils.Assets;
import render.GLRenderer;

/** raylib's textures_bunnymark on Lime, for tools/compare/compare.py: Lime's own BunnyMark demo (lime-samples 7.0.0) with raylib's bunnies,
	a `count=N` query spawning N (`ramp=1` adding 1000 each 60 frames while those held 59 fps), 120 frames to warm up and 600 timed, one JSON
	line on the console, as the helix-raylib contender prints it. Every bunny starts the same from a fixed xorshift32 seed. */
class Main extends Application {
	static var seed = 0x92D68CA2;

	static function rnd(min:Int, max:Int):Int {
		var x = seed;
		x ^= x << 13;
		x ^= x >>> 17;
		x ^= x << 5;
		seed = x;
		return min + (x >>> 8) % (max - min + 1);
	}

	var bunnies:Array<Bunny> = [];
	var glRenderer:GLRenderer;
	var image:Image;
	var count = 1000;
	var ramp = false;
	var frame = -1;
	var last = 0.;
	var deltas:Array<Float> = [];
	var windowStart = 0.;
	var held = 0;
	var done = false;
	var firstFrameMs = 0.;

	public function new() {
		super();
		var query = new js.html.URLSearchParams(js.Browser.window.location.search);
		var c = query.get("count");
		ramp = query.get("ramp") == "1";
		count = ramp ? 1000 : c == null ? 1000 : Std.parseInt(c);
	}

	function spawn(n:Int):Void {
		for (i in 0...n) {
			var px = rnd(0, 800 - 32);
			var py = rnd(40, 450 - 32);
			var sx = rnd(-250, 250) / 60.0;
			var sy = rnd(-250, 250) / 60.0;
			var r = rnd(50, 240), g = rnd(80, 240), b = rnd(100, 240);
			bunnies.push(new Bunny(px, py, sx, sy, r / 255, g / 255, b / 255));
		}
	}

	public override function onPreloadComplete():Void {
		image = Assets.getImage("assets/wabbit_alpha.png");
		glRenderer = new GLRenderer(window.context.webgl, image, window.width, window.height);
	}

	public override function render(context:RenderContext):Void {
		if (!preloader.complete || glRenderer == null || done)
			return;
		var now = js.Browser.window.performance.now();
		if (frame < 0)
			spawn(count);
		else
			deltas.push(now - last);
		last = now;
		frame++;
		var w = image.width, h = image.height;
		var sw = window.width, sh = window.height;
		for (b in bunnies) {
			b.x += b.speedX;
			b.y += b.speedY;
			if (b.x + w / 2 > sw || b.x + w / 2 < 0)
				b.speedX *= -1;
			if (b.y + h / 2 > sh || b.y + h / 2 - 40 < 0)
				b.speedY *= -1;
		}
		glRenderer.updateBuffer(bunnies);
		glRenderer.render();
		if (frame == 0)
			firstFrameMs = now;
		if (!ramp) {
			if (deltas.length == 120 + 600) {
				var timed = deltas.slice(120);
				var sorted = timed.copy();
				sorted.sort((a, b) -> a < b ? -1 : a > b ? 1 : 0);
				var sum = 0.;
				for (d in timed)
					sum += d;
				var mean = sum / timed.length;
				js.Browser.console.log('{"contender":"lime","target":"page","mode":"count","count":$count,"mean_ms":$mean,"median_ms":${sorted[300]},"p95_ms":${sorted[570]},"fps":${1000 / mean},"first_frame_ms":$firstFrameMs}');
				done = true;
			}
		} else if (deltas.length >= 120 && (deltas.length - 120) % 60 == 0) {
			if (deltas.length > 120) {
				var fps = 60 * 1000 / (now - windowStart);
				if (fps >= 59 && bunnies.length < 2000000) {
					held = bunnies.length;
					spawn(1000);
				} else {
					js.Browser.console.log('{"contender":"lime","target":"page","mode":"ramp","ramp_max":$held,"last_fps":$fps,"first_frame_ms":$firstFrameMs}');
					done = true;
				}
			}
			windowStart = now;
		}
	}
}
