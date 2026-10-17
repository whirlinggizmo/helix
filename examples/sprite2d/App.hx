import helix.app.BaseApp;
import helix.debug.FpsOverlay;
import helix.graphics.Graphics;
import helix.host.Host;
import helix.host.Screen;
import helix.host.Window;
import helix.input.Input;
import helix.input.Key;
import helix.render2d.Batch2D;
import helix.render2d.Camera2D;
import helix.render2d.Sprite2D;
import helix.render2d.Stage2D;
import helix.render2d.Texture2D;
import helix.render2d.Textures;
import helix.time.Time;

/** Sprites on a Stage2D, in the design for the window's shape and spread over what's visible of it:
	- "sheet": the 256x256 logo as a 2x2 sprite sheet, its region stepping through the quarters like animation frames
	- "spin": turns about its center (the default pivot)
	- "swing": turns about its top-left corner (pivot 0, 0)
	- "flip": mirrored by a negative x scale
	- "tint": a white copy of the logo cycling through colors (a tint multiplies the texels, so it can't show on the black logo)
	- a one-off Batch2D.sprite in the corner, no node
	Hovering enlarges the sprite under the pointer, the topmost (the last drawn) first: the pointer taken into each sprite's own units
	(Sprite2D.toLocalX), then inside its gear's disc, or the sheet's quarter inside its rectangle. Escape quits where quitting means anything. */
class App extends BaseApp {
	static inline var LOGO = "sprites/logo/wg-logo-bw-alpha.png";
	static inline var WHITE_LOGO = "sprites/logo/wg-logo-white-alpha.png";
	static var NAMES = ["sheet", "spin", "swing", "flip", "tint"];

	var stage = new Stage2D();
	var batch:Batch2D;
	var camera = new Camera2D();
	var fps = new FpsOverlay();
	var sprites:Array<Sprite2D> = [];
	var logo:Null<Texture2D>;
	var palette:Array<Int> = [];
	var sheetFrame = 0;
	var hovered = -1;

	override public function init():Void {
		Window.title = "HeliX sprite2d";
		Window.requestSize(900, 520);
		batch = new Batch2D(Graphics.instance);
		// Colors are values, so cycle a palette.
		for (i in 0...24) {
			var a = i / 24 * Math.PI * 2;
			inline function channel(phase:Float):Int
				return Std.int(127 + 127 * Math.sin(a + phase));
			palette.push(channel(0) << 24 | channel(2.1) << 16 | channel(4.2) << 8 | 255);
		}
		for (i in 0...NAMES.length) {
			var sprite = new Sprite2D(null);
			sprite.name = NAMES[i];
			sprite.setSize(128, 128);
			sprites.push(sprite);
			stage.add(sprite);
		}
		// Placed each frame, in what's visible.
		sprites[2].setPivot(0, 0);
		sprites[2].setSize(96, 96);
		sprites[4].setSize(96, 96);
		Textures.load(LOGO, true, texture -> useLogo(texture));
		Textures.load(WHITE_LOGO, true, texture -> sprites[4].texture = texture);
	}

	// The logo's sheet in: the first four sprites draw it.
	function useLogo(texture:Texture2D):Void {
		logo = texture;
		for (i in 0...4)
			sprites[i].texture = texture;
	}

	// Whether world point x, y is on sprite i, as the last draw placed it: in its gear's disc, or the sheet's quarter in its rectangle.
	function isOver(i:Int, x:Float, y:Float):Bool {
		var sprite = sprites[i], w = sprite.width, h = sprite.height;
		if (w <= 0 || h <= 0)
			return false;
		// From its pivot to its center, in its own units.
		var lx = sprite.toLocalX(x, y) - (.5 - sprite.pivotX) * w,
			ly = sprite.toLocalY(x, y) - (.5 - sprite.pivotY) * h;
		if (i == 0)
			return Math.abs(lx) <= w / 2 && Math.abs(ly) <= h / 2;
		return lx * lx + ly * ly <= w * w / 4;
	}

	override public function frame(dt:Float):Void {
		var input = Input.instance;
		if (Host.canQuit() && input.isFramePressed(Key.Escape))
			Host.quit();
		// The game's clock: paused, the motion stops.
		var time = Time.clock.time;
		fps.update(dt, Time.frameCpu);
		var width = Window.framebufferWidth, height = Window.framebufferHeight;
		// The design for the window's shape: the sprites spread over what's visible of it under the text, three columns across, two upright.
		var shape = ScreenShape.update();
		var presentation = Screen.instance;
		presentation.apply(camera);
		var vx = presentation.visibleX,
			vy = presentation.visibleY,
			vw = presentation.visibleWidth,
			vh = presentation.visibleHeight;
		var top = vy + (shape == "portrait" ? 140 : 90), tall = vy + vh - top;
		inline function place(i:Int, across:Float, down:Float)
			sprites[i].setPosition(vx + vw * across, top + tall * down);
		if (shape == "portrait") {
			place(0, .28, .15);
			place(4, .72, .15);
			place(1, .28, .5);
			place(2, .62, .4);
			place(3, .5, .82);
		} else {
			place(0, .16, .25);
			place(1, .16, .72);
			place(4, .5, .25);
			place(2, .74, .12);
			place(3, .82, .72);
		}

		// The sheet: one quarter of the 256x256 texture an animation frame.
		sheetFrame = Std.int(time * 2) % 4;
		sprites[0].setRegion((sheetFrame % 2) * 128, Std.int(sheetFrame / 2) * 128, 128, 128);
		sprites[1].rotation = time;
		sprites[2].rotation = Math.sin(time * 1.5) * .8;
		sprites[4].tint = palette[Std.int(time * 6) % palette.length];

		// Hover: the topmost sprite under the pointer, the last drawn first.
		var x = camera.screenToWorldX(input.pointerX),
			y = camera.screenToWorldY(input.pointerY);
		hovered = -1;
		if (input.pointerX >= 0) {
			var i = sprites.length;
			while (i-- > 0 && hovered < 0)
				if (isOver(i, x, y))
					hovered = i;
		}
		for (i in 0...sprites.length) {
			var grow = i == hovered ? 1.15 : 1;
			// "flip" keeps its mirror.
			sprites[i].setScale(i == 3 ? -grow : grow, grow);
		}

		Graphics.beginFrame(width, height, 0x1c1e26ff);
		batch.begin(camera);
		stage.draw(batch, camera);
		if (logo != null)
			batch.sprite(logo, vx + vw - 42, vy + 42, 64, 64);
		// Wrapped short of the corner sprite.
		var line = vy + 36;
		line += batch.drawTextWrapped("HeliX sprite2d: source region, pivot, rotation, flip, tint, hover", vx + 12, line, 16, vw - 96, 0xf5f5f5ff) + 4;
		batch.drawTextWrapped('pointer (${Std.int(x)}, ${Std.int(y)})  hover: ${hovered < 0 ? "nothing" : NAMES[hovered]}  sheet frame $sheetFrame', vx + 12,
			line, 16, vw - 96, 0xc8c8c8ff);
		fps.draw(batch, vx + 12, vy + 10);
		batch.end();
		Graphics.endFrame();
	}

	override public function cleanup():Void
		batch.destroy();
}
