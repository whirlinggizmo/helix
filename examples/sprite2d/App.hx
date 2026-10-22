import haxe.io.Bytes;
import helix.assets.Assets;
import helix.debug.Autopilot;
import helix.debug.FpsOverlay;
import helix.debug.TestHarness;
import helix.graphics.Color;
import helix.graphics.Graphics;
import helix.graphics.Screenshots;
import helix.graphics.Shader;
import helix.graphics.Shaders;
import helix.graphics.SpriteEffect;
import helix.host.Host;
import helix.host.Screen;
import helix.host.Window;
import helix.input.IInput;
import helix.input.Input;
import helix.input.Key;
import helix.render2d.Camera2D;
import helix.render2d.Drawing2D;
import helix.render2d.Sprite2D;
import helix.render2d.Stage;
import helix.render2d.Texture2D;
import helix.render2d.Textures2D;
import helix.shaders.PaletteSwap;
import helix.shaders.SpriteDissolve;
import helix.shaders.SpriteFlash;
import helix.shaders.SpriteOutline;
import helix.time.Time;
import helix.host.ScreenShape;

/** Sprites on the stage, in the design for the window's shape and spread over what's visible of it:
	- "sheet": the 256x256 logo as a 2x2 sprite sheet, its region stepping through the quarters like animation frames
	- "spin": turns about its center (the default pivot)
	- "swing": turns about its top-left corner (pivot 0, 0)
	- "flip": mirrored by a negative x scale
	- "tint": a white copy of the logo cycling through colors (a tint multiplies the texels, so it can't show on the black logo)
	- "palette": a little creature made here as indexed pixels (its red channel a color's index), drawn in a palette's colors
	- the logo once more in the corner, drawn by a Drawing2D (Flash's graphics) with the text, no sprite
	Sprite effects (helix.shaders, packed into the program): 1 outlines the sheet and the spin with one SpriteOutline they share (one draw,
	read only inside each sprite's region: the sheet's neighboring quarters never show), 2 dissolves the tint (SpriteDissolve), F flashes the
	flip (SpriteFlash), 3 turns the creature's PaletteSwap off and on, R steps its palette's row. 4 turns the swing's wave off and on: the
	example's own sprite shader, shaders/wave.glsl (packed into an .hxshader asset and loaded at run time, new SpriteEffect(shader)), its parameters set by
	name.
	Hovering enlarges the sprite under the pointer, the topmost (the last drawn) first: the pointer taken into each sprite's own units
	(Sprite2D.toLocalX), then inside its gear's disc, or the sheet's or creature's rectangle. Escape quits where quitting means anything.
	Options: autopilot (a script under assets/: the time is then held, the stage's with it (Stage.heldTime), the window the autopilot's
	page's size, so its samples of the frame compare across targets) and autoclose (1: quit once the script is done); the probes are ready (the logos and the wave in), outline,
	dissolving, palette, row and waving. */
class App extends helix.App {
	static inline var LOGO = "sprites/logo/wg-logo-bw-alpha.png";
	static inline var WHITE_LOGO = "sprites/logo/wg-logo-white-alpha.png";
	static var NAMES = ["sheet", "spin", "swing", "flip", "tint", "palette"];
	// The creature's pixels, a character an index into its palette's columns: . none, o its outline, b its body, e its eyes.
	static var CREATURE = [
		"....oooooooo....", "..oobbbbbbbboo..", ".obbbbbbbbbbbbo.", ".obbbbbbbbbbbbo.", "obbbeeebbeeebbbo", "obbbeooebeooebbo", "obbbeooebeooebbo",
		"obbbeeebbeeebbbo", "obbbbbbbbbbbbbbo", "obbbbbbbbbbbbbbo", "obbboooooooobbbo", ".obbbbbbbbbbbbo.", ".obbbbbbbbbbbbo.", "..oobbbbbbbboo..",
		"..o.oo....oo.o..", ".oo..........oo."
	];
	// Its palette: a row a variant, a column an index (none, outline, body, eyes); 0xAARRGGBB.
	static var PALETTE = [
		[0x00000000, 0xff1a2a1a, 0xff58c858, 0xfff5f5f5],
		[0x00000000, 0xff2a1414, 0xffe05050, 0xffffe040],
		[0x00000000, 0xff141a30, 0xff5078f0, 0xfff5f5f5]
	];
	// The time the autopilot holds the sprites at, and its window's size (the autopilot's browser page's), so its samples compare across targets.
	static inline var HELD_TIME = 2.;
	static inline var PILOT_WIDTH = 800;
	static inline var PILOT_HEIGHT = 600;

	// The stage's units, fitted as the stage's camera is: what the pointer is taken into.
	var camera = new Camera2D();
	var drawing = new Drawing2D();
	var fps = new FpsOverlay();
	var sprites:Array<Sprite2D> = [];
	var logo:Null<Texture2D>;
	var whiteLogo = false;
	var tints:Array<Int> = [];
	var sheetFrame = 0;
	var hovered = -1;
	var outline:SpriteOutline;
	var dissolve:SpriteDissolve;
	var flash:SpriteFlash;
	var swap:PaletteSwap;
	var shaders:Shaders;
	var wave:Null<SpriteEffect>;
	var waving = true;
	var outlined = true;
	var dissolving = true;
	var swapped = true;
	var creature:Texture2D;
	var palette:Texture2D;
	var pilot:Null<Autopilot>;
	var published = false;

	override public function init():Void {
		Window.title = "HeliX sprite2d";
		var script = Host.getOption("autopilot", "");
		if (script != "") {
			Window.requestSize(PILOT_WIDTH, PILOT_HEIGHT);
			// The stage drawn at the held time too: its effects' clock.
			Stage.heldTime = HELD_TIME;
			Assets.load(script, bytes -> startPilot(bytes), message -> throw 'Autopilot load failed: ' + message);
		} else
			Window.requestSize(900, 520);
		var gpu = Graphics.instance;
		Stage.color = 0xff1c1e26;
		// Colors are values, so cycle a list of them.
		for (i in 0...24) {
			var a = i / 24 * Math.PI * 2;
			inline function channel(phase:Float):Int
				return Std.int(127 + 127 * Math.sin(a + phase));
			tints.push(Color.fromChannels(channel(0), channel(2.1), channel(4.2)));
		}
		for (i in 0...NAMES.length) {
			var sprite = new Sprite2D(null);
			sprite.name = NAMES[i];
			sprite.setSize(128, 128);
			sprites.push(sprite);
			Stage.addChild(sprite);
		}
		// Placed each frame, in what's visible.
		sprites[2].setPivot(0, 0);
		sprites[2].setSize(96, 96);
		sprites[4].setSize(96, 96);
		// The creature and its palette, made here: its red channel an index (alpha 0 where there's nothing), the palette a row a variant.
		var pixels = Bytes.alloc(16 * 16 * 4);
		for (y in 0...16)
			for (x in 0...16) {
				var index = ".obe".indexOf(CREATURE[y].charAt(x));
				pixels.set((y * 16 + x) * 4, index);
				pixels.set((y * 16 + x) * 4 + 3, index == 0 ? 0 : 255);
			}
		creature = Texture2D.fromRgba(gpu, 16, 16, pixels);
		var colors = Bytes.alloc(PALETTE.length * 4 * 4);
		for (row in 0...PALETTE.length)
			for (column in 0...4)
				for (channel in 0...4)
					colors.set((row * 4 + column) * 4 + channel, (Color.toRgba(PALETTE[row][column]) >>> (24 - channel * 8)) & 255);
		palette = Texture2D.fromRgba(gpu, 4, PALETTE.length, colors);
		sprites[5].texture = creature;
		sprites[5].setSize(112, 112);
		// The effects: the sheet and the spin share an outline (one draw); each other one has its own.
		outline = new SpriteOutline(0xffffb020, 8);
		dissolve = new SpriteDissolve();
		flash = new SpriteFlash();
		swap = new PaletteSwap(palette);
		sprites[0].effect = outline;
		sprites[1].effect = outline;
		sprites[4].effect = dissolve;
		sprites[3].effect = flash;
		sprites[5].effect = swap;
		Textures2D.load(LOGO, true, texture -> useLogo(texture));
		Textures2D.load(WHITE_LOGO, true, texture -> useWhiteLogo(texture));
		shaders = new Shaders(Assets.instance, gpu);
		shaders.load("shaders/wave.hxshader", shader -> useWave(shader));
		Stage.addChild(drawing);
		Stage.addChild(fps);
	}

	// The example's own shader in: the swing waves, its parameters set by name.
	function useWave(shader:Shader):Void {
		wave = new SpriteEffect(shader);
		wave.parameters.setFloat("amplitude", 32);
		wave.parameters.setFloat("waves", 1);
		wave.parameters.setFloat("speed", .8);
		sprites[2].effect = waving ? wave : null;
	}

	// The autopilot's script in: the input it plays from now on.
	function startPilot(bytes:Bytes):Void
		pilot = new Autopilot(bytes.toString(), name -> Screenshots.take(name), null, (points, done, failed) -> Screenshots.sample(points, done, failed));

	function probe(name:String):Dynamic
		return switch name {
			case "ready": logo != null && whiteLogo && wave != null;
			case "outline": outlined;
			case "dissolving": dissolving;
			case "palette": swapped;
			case "row": swap.row;
			case "waving": waving;
			default: throw 'Unknown probe ' + name;
		}

	// The logo's sheet in: the first four sprites draw it.
	function useLogo(texture:Texture2D):Void {
		logo = texture;
		for (i in 0...4)
			sprites[i].texture = texture;
	}

	function useWhiteLogo(texture:Texture2D):Void {
		whiteLogo = true;
		sprites[4].texture = texture;
	}

	// Whether world point x, y is on sprite i, as the last draw placed it: in its gear's disc, or the sheet's quarter or the creature in its
	// rectangle.
	function isOver(i:Int, x:Float, y:Float):Bool {
		var sprite = sprites[i], w = sprite.width, h = sprite.height;
		if (w <= 0 || h <= 0)
			return false;
		// From its pivot to its center, in its own units.
		var lx = sprite.toLocalX(x, y) - (.5 - sprite.pivotX) * w,
			ly = sprite.toLocalY(x, y) - (.5 - sprite.pivotY) * h;
		if (i == 0 || i == 5)
			return Math.abs(lx) <= w / 2 && Math.abs(ly) <= h / 2;
		return lx * lx + ly * ly <= w * w / 4;
	}

	override public function update(dt:Float):Void {
		// The window's input, or the autopilot's: a tick a frame, none while a sample waits for its frame.
		var input:Null<IInput> = Input.instance;
		if (pilot != null) {
			input = pilot.done ? null : pilot.advance(name -> probe(name));
			if (pilot.awaitingFrame)
				input = null;
		}
		if (input != null) {
			if (Host.canQuit() && input.isFramePressed(Key.Escape))
				Host.quit();
			if (input.isFramePressed(Key.Digit1)) {
				outlined = !outlined;
				sprites[0].effect = sprites[1].effect = outlined ? outline : null;
			}
			if (input.isFramePressed(Key.Digit2)) {
				dissolving = !dissolving;
				sprites[4].effect = dissolving ? dissolve : null;
			}
			if (input.isFramePressed(Key.Digit3)) {
				swapped = !swapped;
				sprites[5].effect = swapped ? swap : null;
			}
			if (input.isFramePressed(Key.Digit4)) {
				waving = !waving;
				sprites[2].effect = waving ? wave : null;
			}
			if (input.isFramePressed(Key.R))
				swap.row = (swap.row + 1) % PALETTE.length;
			if (input.isFramePressed(Key.F))
				flash.trigger(0xffff3020, .4);
		}
		// The game's clock: paused, the motion stops; held under the autopilot.
		var time = pilot != null ? HELD_TIME : Time.clock.time;
		// Half gone at the autopilot's held time, coming and going.
		dissolve.amount = .5 + .45 * Math.sin((time - HELD_TIME) * .9);
		fps.update(dt, Time.frameCpu);
		// The design for the window's shape: the sprites spread over what's visible of it under the text, three columns across, two upright.
		var shape = ScreenShape.update();
		var presentation = Screen.instance;
		presentation.apply(camera);
		var vx = presentation.visibleX,
			vy = presentation.visibleY,
			vw = presentation.visibleWidth,
			vh = presentation.visibleHeight;
		var top = vy + (shape == "portrait" ? 160 : 110), tall = vy + vh - top;
		inline function place(i:Int, across:Float, down:Float)
			sprites[i].setPosition(vx + vw * across, top + tall * down);
		if (shape == "portrait") {
			place(0, .28, .15);
			place(4, .72, .15);
			place(1, .28, .5);
			place(2, .62, .4);
			place(3, .3, .82);
			place(5, .72, .82);
		} else {
			place(0, .16, .25);
			place(1, .16, .72);
			place(4, .5, .25);
			place(5, .5, .72);
			place(2, .74, .12);
			place(3, .82, .72);
		}

		// The sheet: one quarter of the 256x256 texture an animation frame.
		sheetFrame = Std.int(time * 2) % 4;
		sprites[0].setRegion((sheetFrame % 2) * 128, Std.int(sheetFrame / 2) * 128, 128, 128);
		sprites[1].rotation = time;
		sprites[2].rotation = Math.sin(time * 1.5) * .8;
		sprites[4].tint = tints[Std.int(time * 6) % tints.length];

		// Hover: the topmost sprite under the pointer, the last drawn first, as the last frame placed them.
		var pointer = Input.instance;
		var x = camera.screenToWorldX(pointer.pointerX),
			y = camera.screenToWorldY(pointer.pointerY);
		hovered = -1;
		if (pilot == null && pointer.pointerX >= 0) {
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

		drawing.clear();
		if (logo != null)
			drawing.image(logo, vx + vw - 74, vy + 10, 64, 64);
		// Wrapped short of the corner sprite.
		var on = (value:Bool) -> value ? "on" : "off";
		var line = vy + 36,
			title = "HeliX sprite2d: source region, pivot, rotation, flip, tint, hover; sprite effects",
			keys = '[1] outline ${on(outlined)}  [2] dissolve ${on(dissolving)}  [3] palette swap ${on(swapped)}  [R] palette row ${swap.row}  [4] wave ${on(waving)}  [F] flash';
		line += drawing.drawTextWrapped(title, vx + 12, line, 16, vw - 96, 0xfff5f5f5) + 4;
		line += drawing.drawTextWrapped(keys, vx + 12, line, 16, vw - 96, 0xffc8c8c8) + 4;
		drawing.drawTextWrapped('pointer (${Std.int(x)}, ${Std.int(y)})  hover: ${hovered < 0 ? "nothing" : NAMES[hovered]}  sheet frame $sheetFrame',
			vx + 12, line, 16, vw - 96, 0xffc8c8c8);
		fps.setPosition(vx + 12, vy + 10);
		if (pilot != null && pilot.done && !published) {
			published = true;
			TestHarness.publish({
				game: {
					outline: outlined,
					dissolving: dissolving,
					palette: swapped,
					row: swap.row,
					waving: waving
				},
				autopilot: pilot.snapshot
			});
			if (Host.getOption("autoclose", "0") == "1")
				Host.quit();
		}
	}

	override public function cleanup():Void {
		creature.destroy(Graphics.instance);
		palette.destroy(Graphics.instance);
		if (wave != null)
			shaders.release(wave.shader);
	}
}
