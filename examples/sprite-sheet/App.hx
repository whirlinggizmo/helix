import helix.debug.FpsOverlay;
import helix.graphics.Graphics;
import helix.host.Host;
import helix.host.Screen;
import helix.host.ScreenShape;
import helix.host.Window;
import helix.input.Input;
import helix.input.Key;
import helix.render2d.AnimationDirection;
import helix.render2d.Batch2D;
import helix.render2d.Camera2D;
import helix.render2d.Sprite2D;
import helix.render2d.SpriteAnimator;
import helix.render2d.SpriteSheet;
import helix.render2d.Stage2D;
import helix.time.Time;

/** A sprite sheet (the shared sheets/gizmos.json and .png, TexturePacker's JSON Hash, made by tools/gen_sprite_sheet.py: trimmed frames, five of them
	packed turned a quarter) and its animations, found from the frames' numbered names ("walk_01.png": "walk"):
	- a blob walking in low hops, a Sprite2D a SpriteAnimator shows its frames on, walking to and fro: facing its way by a negative x scale,
	  its feet on the ground by its frames' pivot
	- gears drawn by Batch2D.sheetFrame with no node, one animated, one bigger and turned as a whole
	- the sheet's texture beside them, the blob's frame boxed in it (a turned frame's box is tall where the frame is wide)
	Space pauses, the up and down arrows change the speed, P plays the walk back and forth (an animation added by frame, PingPong). Escape quits
	where quitting means anything. */
class App extends helix.App {
	static inline var SCALE = 4.;

	var stage = new Stage2D();
	var batch:Batch2D;
	var camera = new Camera2D();
	var hud = new Camera2D();
	var fps = new FpsOverlay();
	var sheet:Null<SpriteSheet>;
	var blob = new Sprite2D(null);
	var blobs:Null<SpriteAnimator>;
	var gears:Null<SpriteAnimator>;
	var walk = 0.;
	var heading = 1.;
	var paused = false;
	var pingPong = false;
	var failure:Null<String>;

	override public function init():Void {
		Window.title = "HeliX sprite-sheet";
		Window.requestSize(960, 600);
		batch = new Batch2D();
		blob.setScale(SCALE, SCALE);
		stage.add(blob);
		SpriteSheet.load("sheets/gizmos.json", loaded -> {
			sheet = loaded;
			var frames = loaded.findAnimation("walk").frames;
			loaded.addAnimation("walk-pingpong", frames, AnimationDirection.PingPong);
			blobs = new SpriteAnimator(loaded, blob);
			blobs.play("walk");
			gears = new SpriteAnimator(loaded);
			gears.play("gear");
		}, message -> failure = message);
	}

	override public function update(dt:Float):Void {
		var input = Input.instance;
		if (Host.canQuit() && input.isFramePressed(Key.Escape))
			Host.quit();
		fps.update(dt, Time.frameCpu);
		var width = Window.framebufferWidth, height = Window.framebufferHeight;
		camera.setViewport(width, height);
		camera.pixels(1);
		ScreenShape.update();
		var presentation = Screen.instance;
		presentation.apply(hud);

		var speed = blobs == null ? 1. : blobs.speed;
		if (input.isFramePressed(Key.Space))
			paused = !paused;
		if (input.isFramePressed(Key.Up))
			speed = Math.min(4, speed * 2);
		if (input.isFramePressed(Key.Down))
			speed = Math.max(.125, speed / 2);
		if (input.isFramePressed(Key.P) && blobs != null) {
			pingPong = !pingPong;
			blobs.play(pingPong ? "walk-pingpong" : "walk");
		}
		var step = paused ? 0. : dt;
		if (blobs != null) {
			blobs.speed = speed;
			gears.speed = speed;
			blobs.update(step);
			gears.update(step);
		}
		// To and fro along the ground, turning at the ends: a negative x scale faces it the other way about its pivot.
		var ground = height * .62, left = width * .1, right = width * .55;
		walk += heading * 60 * speed * step;
		if (walk > right - left || walk < 0)
			heading = -heading;
		walk = Math.max(0, Math.min(right - left, walk));
		blob.setPosition(left + walk, ground);
		blob.scaleX = heading * SCALE;

		Graphics.beginFrame(width, height, 0xff1d2230);
		batch.begin(camera);
		batch.rect(0, ground, width, 2, 0xff4a5468);
		stage.draw(batch, camera);
		if (sheet != null) {
			// Gears with no node: one animated, one bigger and turned as a whole.
			batch.sheetFrame(sheet, gears.frame, width * .2, height * .25, SCALE, SCALE);
			batch.sheetFrame(sheet, gears.frame, width * .4, height * .25, SCALE * 1.5, SCALE * 1.5, Time.time * .5);
			// The sheet itself, the blob's frame boxed where it's packed.
			var t = sheet.texture, sx = width * .66, sy = height * .12, s = 2.;
			batch.rect(sx, sy, t.width * s, t.height * s, 0xff2a3142);
			batch.image(t, sx, sy, t.width * s, t.height * s);
			var f = sheet.getFrame(blobs.frame);
			var fw = f.rotated ? f.height : f.width,
				fh = f.rotated ? f.width : f.height;
			batch.frame(sx + f.x * s, sy + f.y * s, fw * s, fh * s, 1, 0xffffd040);
		}
		batch.camera = hud;
		var vx = presentation.visibleX,
			vy = presentation.visibleY,
			vw = presentation.visibleWidth;
		var status = failure != null ? 'failed: $failure' : sheet == null ? "loading" : {
			var f = sheet.getFrame(blobs.frame);
			'walk frame ${blobs.frameIndex + 1} of ${blobs.animation.frames.length}: ${f.name}, ${f.width} x ${f.height} of ${f.sourceWidth} x ${f.sourceHeight}${f.rotated ? ", packed turned" : ""}';
		};
		batch.drawText("HeliX sprite-sheet: TexturePacker's JSON, trimmed and turned frames, animations", vx + 20, vy + 20, 20, 0xffebeef5);
		batch.drawText(status, vx + 20, vy + 46, 15, 0xff8c929e);
		batch.drawText('speed ${speed}x${paused ? " (paused)" : ""}   ${pingPong ? "back and forth" : "forward"}   space pause, up/down speed, P back and forth',
			vx
			+ 20, vy
			+ 66, 15, 0xff8c929e);
		fps.draw(batch, vx + vw - 150, vy + 4);
		batch.end();
		Graphics.endFrame();
	}

	override public function cleanup():Void {
		if (sheet != null)
			sheet.destroy();
		batch.destroy();
	}
}
