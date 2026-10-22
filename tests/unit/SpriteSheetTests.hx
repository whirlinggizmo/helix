import Render2DTests.CountingGraphics;
import haxe.io.Bytes;
import helix.render2d.Batch2D;
import helix.render2d.Camera2D;
import helix.render2d.Sprite2D;
import helix.render2d.SpriteAnimator;
import helix.render2d.SpriteSheet;
import helix.render2d.Renderer2D;
import helix.render2d.Texture2D;

/** Sprite sheets (helix.render2d.SpriteSheet) and their animations (SpriteAnimator): TexturePacker's hash with trimmed, rotated and pivoted
	frames in the file's order, animations from numbered names; Aseprite's array with tags, directions and durations; a hash's order on every
	target; a grid; refusals; playing forward, back and forth, once and looping, with the frames an update reached; and a trimmed, rotated frame
	drawn upright where it was, by the batch and by a sprite. */
class SpriteSheetTests {
	static var checks = 0;

	static function check(value:Bool, message:String):Void {
		if (!value)
			throw message;
		checks++;
	}

	static function near(a:Float, b:Float, e = 1e-5):Bool
		return Math.abs(a - b) < e;

	// TexturePacker's JSON Hash: run_02 (trimmed, rotated, pivoted at its feet) before run_01, a frame named "frame", and an idle without a number.
	static var packed = '{"frames": {
		"run_02.png": {"frame": {"x": 10, "y": 0, "w": 6, "h": 4}, "rotated": true, "trimmed": true,
			"spriteSourceSize": {"x": 1, "y": 2, "w": 6, "h": 4}, "sourceSize": {"w": 8, "h": 8}, "pivot": {"x": 0.5, "y": 1}},
		"run_01.png": {"frame": {"x": 0, "y": 0, "w": 8, "h": 8}, "rotated": false, "trimmed": false,
			"spriteSourceSize": {"x": 0, "y": 0, "w": 8, "h": 8}, "sourceSize": {"w": 8, "h": 8}},
		"frame": {"frame": {"x": 16, "y": 0, "w": 8, "h": 8}},
		"idle.png": {"frame": {"x": 24, "y": 0, "w": 8, "h": 8}}
	}, "meta": {"image": "hero.png", "size": {"w": 32, "h": 16}}}';

	// Aseprite's JSON Array: walk back and forth over three frames of their own durations, blink one frame.
	static var drawn = '{"frames": [
		{"filename": "hero 0.aseprite", "frame": {"x": 0, "y": 0, "w": 16, "h": 16}, "duration": 100},
		{"filename": "hero 1.aseprite", "frame": {"x": 16, "y": 0, "w": 16, "h": 16}, "duration": 200},
		{"filename": "hero 2.aseprite", "frame": {"x": 32, "y": 0, "w": 16, "h": 16}, "duration": 100},
		{"filename": "hero 3.aseprite", "frame": {"x": 48, "y": 0, "w": 16, "h": 16}, "duration": 100}
	], "meta": {"image": "hero.png", "frameTags": [
		{"name": "walk", "from": 0, "to": 2, "direction": "pingpong"},
		{"name": "back", "from": 0, "to": 2, "direction": "reverse"},
		{"name": "blink", "from": 3, "to": 3, "direction": "forward"}
	]}}';

	static function main():Void {
		var gpu = new CountingGraphics();
		var texture = Texture2D.fromRgba(gpu, 32, 16, Bytes.alloc(32 * 16 * 4));

		// TexturePacker's hash.
		var sheet = SpriteSheet.parse(texture, packed, .125);
		check(sheet.frameCount == 4 && sheet.getFrame(0).name == "run_02.png" && sheet.getFrame(2).name == "frame",
			"A hash's frames in the file's order, a frame named as a field too");
		var run2 = sheet.getFrame(0);
		check(run2.rotated && run2.x == 10 && run2.width == 6 && run2.height == 4 && run2.offsetX == 1 && run2.offsetY == 2 && run2.sourceWidth == 8
			&& run2.sourceHeight == 8,
			"A trimmed, rotated frame: its upright size and its place in its picture");
		check(run2.hasPivot && run2.pivotX == .5 && run2.pivotY == 1 && !sheet.getFrame(1).hasPivot, "A pivot when the file gives one");
		check(sheet.getFrame(3).sourceWidth == 8 && sheet.getFrame(3).duration == .125, "Untrimmed, its picture is its frame; no duration, the default");
		var run = sheet.findAnimation("run");
		check(run != null && run.frames.join(",") == "1,0" && sheet.animationNames.join(",") == "run",
			"Frames named alike but for a number animate, in their numbers' order");
		check(sheet.findFrame("idle.png") == 3 && sheet.findFrame("nothing") == -1 && sheet.getFrame(4) == null, "Frames found by name");

		// Aseprite's array.
		var hero = SpriteSheet.parse(texture, drawn);
		check(hero.animationNames.join(",") == "walk,back,blink,hero", "Tags, then the numbered frames' animation");
		check(near(hero.getFrame(1).duration, .2), "Aseprite's durations, in seconds");
		check(hero.findAnimation("walk").direction == PingPong && hero.findAnimation("back").direction == Reverse, "Tags' directions");

		// A hash's order: Aseprite's tags count frames in it.
		var ordered = SpriteSheet.parse(texture,
			'{"frames": {"zeta": {"frame": {"x": 0, "y": 0, "w": 1, "h": 1}}, "alpha \\"1\\"": {"frame": {"x": 1, "y": 0, "w": 1, "h": 1}}},
			"meta": {"frameTags": [{"name": "first", "from": 0, "to": 0}]}}');
		check(ordered.getFrame(0).name == "zeta"
			&& ordered.getFrame(1).name == 'alpha "1"'
			&& ordered.getFrame(ordered.findAnimation("first").frames[0]).name == "zeta",
			"A hash's order is the file's, escaped names read");

		// Refusals.
		var threw = 0;
		for (text in [
			"not json",
			'{"meta": {}}',
			'{"frames": [{"frame": {"x": 0}}]}',
			'{"frames": [{"frame": {"x": 0, "y": 0, "w": 1, "h": 1}}], "meta": {"frameTags": [{"name": "t", "from": 0, "to": 3}]}}'
		])
			try
				SpriteSheet.parse(texture, text)
			catch (e:Dynamic)
				threw++;
		check(threw == 4, "Not JSON, no frames, a frame without a rectangle and a tag past the frames are refused");

		// A grid: 1 texel in from the edges, 2 apart.
		var gridTexture = Texture2D.fromRgba(gpu, 34, 18, Bytes.alloc(34 * 18 * 4));
		var grid = SpriteSheet.grid(gridTexture, 8, 8, 0, .1, 1, 2);
		check(grid.frameCount == 3 && grid.getFrame(2).x == 21 && grid.getFrame(2).y == 1 && grid.getFrame(1).name == "1", "A grid's whole cells");
		check(SpriteSheet.grid(gridTexture, 8, 8, 2).frameCount == 2, "A grid's count");
		check(grid.addAnimation("spin", [2, 0], PingPong)
			&& !grid.addAnimation("bad", [3])
			&& !grid.addAnimation("none", [])
			&& grid.findAnimation("spin").frames.join(",") == "2,0",
			"Animations added by frame, refused past them");

		// Playing back and forth: 0 1 2 1, 0 for 0.1 s, 1 for 0.2, 2 for 0.1.
		var animator = new SpriteAnimator(hero);
		check(animator.frame == -1 && !animator.play("nothing"), "Nothing plays at first; an unknown name is refused");
		check(animator.play("walk") && animator.frame == 0 && animator.entered(0), "Playing starts on its first frame");
		animator.update(.05);
		check(animator.frame == 0 && !animator.entered(0), "Within its duration it holds");
		animator.update(.06);
		check(animator.frame == 1 && animator.entered(1), "Past it, the next");
		animator.update(.2);
		check(animator.frameIndex == 2 && animator.entered(2), "Each frame for its own duration");
		animator.update(.1);
		check(animator.frameIndex == 1, "And back");
		animator.update(.2);
		check(animator.frameIndex == 0 && !animator.finished, "Round again, looping");
		animator.update(.05);
		animator.update(1.);
		check(animator.entered(0) && animator.entered(1) && animator.entered(2), "A long update reaches every frame it passes");
		check(animator.play("walk") && !animator.finished, "Playing what plays goes on");
		animator.stop();
		animator.play("walk", false);
		animator.update(10);
		check(animator.finished && animator.frameIndex == 0, "Back and forth once ends where it began");
		animator.play("back", false);
		check(animator.frameIndex == 2, "Reverse starts at its last");
		animator.speed = 2;
		animator.update(.06);
		check(animator.frameIndex == 1, "Speed runs time faster");
		animator.speed = -1;
		animator.update(1);
		check(animator.speed == 0 && animator.frameIndex == 1, "A speed below 0 holds");

		// Drawn: the batch puts the trimmed, rotated frame upright where it was, pivoted at its feet.
		var batch = new Batch2D(gpu), camera = new Camera2D();
		camera.setViewport(400, 300);
		camera.pixels(1);
		gpu.beginFrame(400, 300, 0);
		batch.begin(camera);
		batch.sheetFrame(sheet, 0, 100, 100);
		checkRotated(batch, camera, "the batch");
		batch.end();

		// And by a sprite, which takes the frame's size and pivot; an animator given it shows its frames.
		var stage = new Renderer2D(), sprite = new Sprite2D(null);
		sprite.setPosition(100, 100);
		stage.add(sprite);
		check(sprite.setFrame(sheet, 0) && sprite.texture == texture && sprite.width == 8 && sprite.pivotY == 1, "A sprite showing a frame");
		check(!sprite.setFrame(sheet, 9) && sprite.frame == sheet.getFrame(0), "An index the sheet hasn't changes nothing");
		gpu.beginFrame(400, 300, 0);
		batch.begin(camera);
		stage.draw(batch, camera);
		checkRotated(batch, camera, "a sprite");
		batch.end();
		// Mirrored by a negative x scale: drawn (not culled), about its pivot.
		sprite.scaleX = -1;
		gpu.beginFrame(400, 300, 0);
		batch.begin(camera);
		stage.draw(batch, camera);
		var data:Bytes = @:privateAccess batch.data;
		check(stage.drawnNodeCount == 1 && near(data.getFloat(Sprite2DProgram.positionOffset), camera.clipX(103)),
			"A mirrored sprite draws, mirrored about its pivot");
		batch.end();
		sprite.scaleX = 1;
		var shown = new SpriteAnimator(sheet, sprite);
		shown.play("run");
		check(sprite.frame == sheet.getFrame(1), "An animator shows its frame on its sprite");
		sprite.setRegion(0, 0, 0, 0);
		check(sprite.frame == null && sprite.width == 32, "A region shows no frame");
		Sys.println(haxe.Json.stringify({passed: true, checks: checks}));
	}

	// The batch's first quad is the trimmed, rotated frame at 100, 100: 6 x 4 from 97, 94, its top-left sampled from the texture rectangle's top-right.
	static function checkRotated(batch:Batch2D, camera:Camera2D, by:String):Void {
		var data:Bytes = @:privateAccess batch.data;
		inline function at(vertex:Int, offset:Int, k:Int):Float
			return data.getFloat(vertex * Sprite2DProgram.stride + offset + k * 4);
		var p = Sprite2DProgram.positionOffset, uv = Sprite2DProgram.uvOffset;
		check(near(at(0, p, 0), camera.clipX(97))
			&& near(at(0, p, 1), camera.clipY(94))
			&& near(at(2, p, 0), camera.clipX(103))
			&& near(at(2, p, 1), camera.clipY(98)),
			'A trimmed frame where it was in its picture, by $by');
		check(near(at(0, uv, 0), 14 / 32) && near(at(0, uv, 1), 0) && near(at(1, uv, 0), 14 / 32) && near(at(1, uv, 1), 6 / 16)
			&& near(at(2, uv, 0), 10 / 32) && near(at(5, uv, 0), 10 / 32) && near(at(5, uv, 1), 0),
			'A rotated frame drawn upright, by $by');
	}
}
