import helix.app.BaseApp;
import helix.graphics.Graphics;
import helix.host.Host;
import helix.host.Screen;
import helix.host.Window;
import helix.input.Input;
import helix.input.Key;
import helix.render2d.Batch2D;
import helix.render2d.Camera2D;
import helix.render2d.Texture2D;
import helix.render2d.Textures;

/** Fingers, the two-finger gesture, and the pointer: every finger gets a numbered ring (its id) while it's down, and a fading one where it lifted;
	two fingers pan, pinch and twist the logo about the point between them, so it stays under the fingers; one finger is also the pointer: drag the
	coin. A second finger lets the drag go, so a pinch never drops the coin somewhere. Without a touch screen: drag with the mouse, and the wheel
	zooms the logo about the mouse. Escape quits where quitting means anything. */
class App extends BaseApp {
	static inline var RING = 38.;
	static inline var COIN = 96.;
	static inline var FINGERS = 8;

	var batch:Batch2D;
	var camera = new Camera2D();
	var logo:Null<Texture2D>;
	var tiles:Null<Texture2D>;

	/** The window's shape the logo and the coin were placed for: they go back to the middle when it changes. */
	var shaped = "";

	var logoX = 0.;
	var logoY = 0.;
	var logoScale = 1.;
	var logoRotation = 0.;
	var coinX = 0.;
	var coinY = 0.;
	var coinHeld = false;

	/** Where each finger id last lifted, x and y, and how much of its ring is left to fade (1 down to 0). */
	var lifted = [for (_ in 0...FINGERS) [0., 0., 0.]];

	override public function init():Void {
		Window.title = "HeliX touch";
		Window.requestSize(900, 700);
		batch = new Batch2D(Graphics.instance);
		Textures.load("sprites/logo/wg-logo-white-alpha.png", true, texture -> logo = texture);
		// Pixel art: nearest, no smoothing.
		Textures.load("textures/tiles.png", false, texture -> tiles = texture);
	}

	/** Scales and turns the logo about x, y, so the point under the fingers stays put. */
	function transformLogo(x:Float, y:Float, scale:Float, rotation:Float):Void {
		var c = Math.cos(rotation), s = Math.sin(rotation);
		var ox = (logoX - x) * scale, oy = (logoY - y) * scale;
		logoX = x + ox * c - oy * s;
		logoY = y + ox * s + oy * c;
		logoScale = Math.min(Math.max(logoScale * scale, .2), 8);
		logoRotation += rotation;
	}

	override public function frame(dt:Float):Void {
		var input = Input.instance;
		// The design for the window's shape; the logo and the coin start in the middle of what's visible of it, and go back there when
		// the shape changes (a phone turned), as they might be past the new edges.
		var shape = ScreenShape.update();
		var presentation = Screen.instance;
		presentation.apply(camera);
		var vx = presentation.visibleX,
			vy = presentation.visibleY,
			vw = presentation.visibleWidth,
			vh = presentation.visibleHeight;
		if (shape != shaped) {
			shaped = shape;
			logoX = coinX = vx + vw / 2;
			logoY = vy + vh * .45;
			coinY = vy + vh * .8;
		}
		if (Host.canQuit() && input.isFramePressed(Key.Escape))
			Host.quit();
		// Two fingers move the logo; the wheel zooms it about the mouse.
		if (input.touchGesture) {
			logoX += input.getTouchGesturePanX() / presentation.scaleX;
			logoY += input.getTouchGesturePanY() / presentation.scaleY;
			transformLogo(camera.screenToWorldX(input.touchGestureCenterX), camera.screenToWorldY(input.touchGestureCenterY), input.getTouchGestureScale(),
				input.getTouchGestureRotation());
		}
		var mouseX = camera.screenToWorldX(input.pointerX),
			mouseY = camera.screenToWorldY(input.pointerY);
		if (input.wheelY != 0)
			transformLogo(mouseX, mouseY, Math.pow(1.1, input.wheelY), 0);
		// The pointer (the mouse, or one finger) drags the coin: picked where it was before this frame moved it.
		if (input.pointerFramePressed)
			coinHeld = Math.abs(mouseX - coinX) < COIN / 2 && Math.abs(mouseY - coinY) < COIN / 2;
		else if (!input.pointerDown)
			coinHeld = false;
		if (coinHeld) {
			coinX = mouseX;
			coinY = mouseY;
		}
		// Where fingers lifted: a ring that fades.
		for (ring in lifted)
			ring[2] = Math.max(ring[2] - .033, 0);
		for (touch in input.touches)
			if (touch.released && touch.id >= 0) {
				var ring = lifted[touch.id % FINGERS];
				ring[0] = camera.screenToWorldX(touch.x);
				ring[1] = camera.screenToWorldY(touch.y);
				ring[2] = 1;
			}

		Graphics.beginFrame(Window.framebufferWidth, Window.framebufferHeight, 0x161921ff);
		batch.begin(camera);
		if (logo != null)
			batch.sprite(logo, logoX, logoY, 240 * logoScale, 240 * logoScale, logoRotation);
		if (tiles != null) {
			var w = tiles.width, h = tiles.height;
			// The coin: 16x16 texels at 42, 22 in the tile sheet.
			batch.sprite(tiles, coinX, coinY, COIN, COIN, 0, coinHeld ? 0xffe696ff : 0xffffffff, 42 / w, 22 / h, 58 / w, 38 / h);
		}
		for (i in 0...FINGERS) {
			var ring = lifted[i];
			if (ring[2] > 0)
				batch.circleLines(ring[0], ring[1], RING * (2 - ring[2]), 1, color(i, Std.int(200 * ring[2])));
		}
		for (touch in input.touches) {
			if (!touch.down)
				continue;
			var x = camera.screenToWorldX(touch.x),
				y = camera.screenToWorldY(touch.y),
				id = touch.id % FINGERS;
			batch.circle(x, y, RING, color(id, 90));
			batch.circleLines(x, y, RING, 1, color(id, 255));
			batch.drawText(Std.string(touch.id), x - 6, y - RING - 26, 22, color(id, 255));
		}
		if (input.touchGesture)
			batch.circle(camera.screenToWorldX(input.touchGestureCenterX), camera.screenToWorldY(input.touchGestureCenterY), 6, 0xffffffff);
		var fingers = 0;
		for (touch in input.touches)
			if (touch.down)
				fingers++;
		var y = vy + 16;
		y += batch.drawTextWrapped('fingers: $fingers   pointer: ' + (input.pointerDown ? "down" : "up"), vx + 16, y, 18, vw - 32, 0xffffffff) + 1.5;
		y += batch.drawTextWrapped('logo: scale ${Math.round(logoScale * 100) / 100}, turn ${Math.round(logoRotation * 180 / Math.PI)} deg', vx + 16, y, 18,
			vw - 32, 0xffffffff)
			+ 1.5;
		batch.drawTextWrapped("two fingers: pan, pinch, twist the logo; one finger drags the coin", vx + 16, y, 16, vw - 32, 0x969eafff);
		batch.end();
		Graphics.endFrame();
	}

	/** A finger's color, by its id, with alpha. */
	static function color(id:Int, alpha:Int):Int
		return ((90 + 20 * id) << 24) | ((200 - 15 * id) << 16) | ((120 + 17 * id) << 8) | alpha;
}
