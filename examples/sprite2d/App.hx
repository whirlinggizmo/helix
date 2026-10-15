import helix.app.BaseApp;
import helix.debug.FpsOverlay;
import helix.host.Services;
import helix.input.Key;
import helix.render2d.Batch2D;
import helix.render2d.Camera2D;
import helix.render2d.Node2D;
import helix.render2d.Stage2D;
import helix.render2d.Text2D;
import helix.render2d.Texture2D;

/** Sprites on a Stage2D, in logical pixels:
	- "sheet": the 256x256 logo as a 2x2 sprite sheet, its region stepping through the quarters like animation frames
	- "spin": turns about its center (the default pivot)
	- "swing": turns about its top-left corner (pivot 0, 0)
	- "flip": mirrored by a negative x scale
	- "tint": a white copy of the logo cycling through colors (a tint multiplies the texels, so it can't show on the black logo)
	- a one-off Batch2D.sprite in the corner, no node
	Hovering enlarges the sprite under the pointer, the topmost (the last drawn) first: the pointer taken into each sprite's own units
	(Node2D.toLocalX), then inside its gear's disc, or the sheet's quarter inside its rectangle. Escape quits where quitting means anything. */
class App extends BaseApp {
	static inline var LOGO = "sprites/logo/wg-logo-bw-alpha.png";
	static inline var WHITE_LOGO = "sprites/logo/wg-logo-white-alpha.png";
	static var NAMES = ["sheet", "spin", "swing", "flip", "tint"];

	var services:Services;
	var stage = new Stage2D();
	var batch:Batch2D;
	var camera = new Camera2D();
	var fps = new FpsOverlay();
	var sprites:Array<Node2D> = [];
	var logo:Null<Texture2D>;
	var palette:Array<Int> = [];
	var time = 0.;
	var sheetFrame = 0;
	var hovered = -1;

	public function new(services:Services) {
		super();
		this.services = services;
	}

	override public function init():Void {
		services.window.setTitle("HeliX sprite2d");
		services.window.requestSize(900, 520);
		batch = new Batch2D(services.graphics);
		// Colors are values, so cycle a palette.
		for (i in 0...24) {
			var a = i / 24 * Math.PI * 2;
			inline function channel(phase:Float):Int
				return Std.int(127 + 127 * Math.sin(a + phase));
			palette.push(channel(0) << 24 | channel(2.1) << 16 | channel(4.2) << 8 | 255);
		}
		for (i in 0...NAMES.length) {
			var sprite = Node2D.sprite(null);
			sprite.setName(NAMES[i]);
			sprite.setSize(128, 128);
			sprites.push(sprite);
			stage.add(sprite);
		}
		sprites[0].setPosition(140, 170);
		sprites[1].setPosition(140, 380);
		sprites[2].setPivot(0, 0);
		sprites[2].setPosition(700, 110);
		sprites[2].setSize(96, 96);
		sprites[3].setPosition(760, 400);
		sprites[4].setPosition(450, 110);
		sprites[4].setSize(96, 96);
		services.textures.load(LOGO, true, result -> switch result {
			case Ready(texture):
				logo = texture;
				for (i in 0...4)
					sprites[i].setTexture(texture);
			case Failed(message):
				trace(message);
			case Cancelled:
		});
		services.textures.load(WHITE_LOGO, true, result -> switch result {
			case Ready(texture):
				sprites[4].setTexture(texture);
			case Failed(message):
				trace(message);
			case Cancelled:
		});
	}

	// Whether world point x, y is on sprite i, as the last draw placed it: in its gear's disc, or the sheet's quarter in its rectangle.
	function isOver(i:Int, x:Float, y:Float):Bool {
		var sprite = sprites[i], w = sprite.getWidth(), h = sprite.getHeight();
		if (w <= 0 || h <= 0)
			return false;
		// From its pivot to its center, in its own units.
		var lx = sprite.toLocalX(x, y) - (.5 - sprite.getPivotX()) * w,
			ly = sprite.toLocalY(x, y) - (.5 - sprite.getPivotY()) * h;
		if (i == 0)
			return Math.abs(lx) <= w / 2 && Math.abs(ly) <= h / 2;
		return lx * lx + ly * ly <= w * w / 4;
	}

	override public function frame(dt:Float):Void {
		var input = services.input;
		if (services.canQuit() && input.isFramePressed(Key.Escape))
			services.quit();
		time += dt;
		fps.update(dt, services.getFrameCpu());
		var width = services.window.getFramebufferWidth(),
			height = services.window.getFramebufferHeight();
		camera.setViewport(width, height);
		camera.pixels(services.window.getPixelRatio());

		// The sheet: one quarter of the 256x256 texture an animation frame.
		sheetFrame = Std.int(time * 2) % 4;
		sprites[0].setSource((sheetFrame % 2) * 128, Std.int(sheetFrame / 2) * 128, 128, 128);
		sprites[1].setRotation(time);
		sprites[2].setRotation(Math.sin(time * 1.5) * .8);
		sprites[4].setColor(palette[Std.int(time * 6) % palette.length]);

		// Hover: the topmost sprite under the pointer, the last drawn first.
		var x = camera.screenToWorldX(input.getPointerX()),
			y = camera.screenToWorldY(input.getPointerY());
		hovered = -1;
		if (input.getPointerX() >= 0) {
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

		services.graphics.beginFrame(width, height, 0x1c1e26ff);
		batch.begin(camera);
		stage.draw(batch, camera);
		if (logo != null)
			batch.sprite(logo, width / services.window.getPixelRatio() - 42, 42, 64, 64);
		Text2D.draw(batch, "HeliX sprite2d: source region, pivot, rotation, flip, tint, hover", 12, 36, 16, 0xf5f5f5ff);
		Text2D.draw(batch, 'pointer (${Std.int(x)}, ${Std.int(y)})  hover: ${hovered < 0 ? "nothing" : NAMES[hovered]}  sheet frame $sheetFrame', 12, 60, 16,
			0xc8c8c8ff);
		fps.draw(batch, 12, 10);
		batch.end();
		services.graphics.endFrame();
	}

	override public function cleanup():Void
		batch.destroy();
}
