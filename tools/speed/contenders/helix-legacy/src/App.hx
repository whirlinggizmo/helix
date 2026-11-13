import helix.host.Host;
import helix.host.Window;
import helix.render2d.Sprite2D;
import helix.render2d.Stage;
import helix.texture.Texture2D;
import helix.texture.Textures;

/** raylib's textures_bunnymark on helix-legacy, a Sprite2D per bunny (count=N, or incrementCount=N startCount=M), for helix's tools/gen_speed.py, which builds it
	as a helix-legacy example. */
class App extends helix.App {
	static var seed = 0x92D68CA2;

	var count = 1000;
	var ramp = false;
	var texture:Null<Texture2D>;
	var bunnies:Array<Sprite2D> = [];
	var sx:Array<Float> = [];
	var sy:Array<Float> = [];
	var frame = -1;
	var firstFrameMs = 0.;
	var last = 0.;
	var deltas:Array<Float> = [];
	var windowStart = 0.;
	var maxCount = 0;
	var incrementCount = 0;
	var done = false;

	static function rnd(min:Int, max:Int):Int {
		var x = seed;
		x ^= x << 13;
		x ^= x >>> 17;
		x ^= x << 5;
		seed = x;
		return min + (x >>> 8) % (max - min + 1);
	}

	override public function init():Void {
		Window.requestSize(800, 450);
		Stage.color = 0xfff5f5f5;
		// incrementCount=N adds N bunnies each 60 frames, from startCount=M bunnies (N without it).
		incrementCount = Host.getOptionInt("incrementCount", 0);
		ramp = incrementCount > 0;
		count = ramp ? Host.getOptionInt("startCount", incrementCount) : Host.getOptionInt("count", 1000);
		Textures.load("bunnymark/wabbit_alpha.png", Nearest, t -> texture = t);
	}

	function spawn(n:Int):Void {
		for (i in 0...n) {
			var px = rnd(0, 800 - 32), py = rnd(40, 450 - 32);
			var vx = rnd(-250, 250) / 60.0, vy = rnd(-250, 250) / 60.0;
			var r = rnd(50, 240), g = rnd(80, 240), b = rnd(100, 240);
			var s = new Sprite2D(texture, 0xff000000 | r << 16 | g << 8 | b);
			s.setPivot(0, 0);
			s.setPosition(px, py);
			Stage.addChild(s);
			bunnies.push(s);
			sx.push(vx);
			sy.push(vy);
		}
	}

	static function emit(line:String):Void
		js.Browser.console.log(line);

	override public function update(dt:Float):Void {
		if (texture == null || done)
			return;
		var now = js.Browser.window.performance.now();
		if (frame < 0)
			spawn(count);
		else
			deltas.push(now - last);
		last = now;
		frame++;
		var w = 32., h = 32.;
		for (i in 0...bunnies.length) {
			var b = bunnies[i];
			var x = b.x + sx[i], y = b.y + sy[i];
			b.setPosition(x, y);
			if (x + w / 2 > 800 || x + w / 2 < 0)
				sx[i] *= -1;
			if (y + h / 2 > 450 || y + h / 2 - 40 < 0)
				sy[i] *= -1;
		}
		if (frame == 0)
			firstFrameMs = now;
		if (!ramp) {
			if (deltas.length == 720) {
				var timed = deltas.slice(120);
				var sorted = timed.copy();
				sorted.sort((a, b) -> a < b ? -1 : a > b ? 1 : 0);
				var sum = 0.;
				for (d in timed)
					sum += d;
				var mean = sum / timed.length;
				emit('{"contender":"helix","target":"page","mode":"count","count":$count,"mean_ms":$mean,"median_ms":${sorted[300]},"p95_ms":${sorted[570]},"fps":${1000 / mean},"first_frame_ms":$firstFrameMs}');
				done = true;
			}
		} else if (deltas.length >= 120 && (deltas.length - 120) % 60 == 0) {
			if (deltas.length > 120) {
				var fps = 60 * 1000 / (now - windowStart);
				if (fps >= 59) {
					maxCount = bunnies.length;
					spawn(incrementCount);
				} else {
					emit('{"contender":"helix","target":"page","mode":"ramp","max_count":$maxCount,"last_fps":$fps,"first_frame_ms":$firstFrameMs}');
					done = true;
				}
			}
			windowStart = now;
		}
	}
}
