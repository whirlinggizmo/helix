import helix.assets.Assets;
import helix.debug.FpsOverlay;
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
import helix.time.Time;
import helix.host.ScreenShape;

/** The desktop pulls its files from the same site the browser does. In the browser the page fetches each file beside it and caches it; natively,
	files are read from the program's packaged directory unless HELIX_ASSET_HOST names a host (python3 -m http.server in examples/assets, say), which
	is asked first whether it answers: then a cache miss downloads the file into the program's cache. Fetch asset (F) loads the logo again, and says
	whether it came from the cache or was downloaded; Clear cache (C) forgets what was downloaded, so the next fetch downloads it again. Escape quits
	where quitting means anything. HeliX has no UI module yet, so the two buttons are drawn and hit-tested here. */
class App extends helix.App {
	static inline var TEXTURE = "sprites/logo/wg-logo-white-alpha.png";

	var batch:Batch2D;
	var camera = new Camera2D();
	var fps = new FpsOverlay();
	var logo:Null<Texture2D>;
	var source = "";
	var state = "";
	var asking = false;
	var waiting = false;

	override public function init():Void {
		Window.title = "HeliX asset fetch";
		Window.requestSize(800, 520);
		batch = new Batch2D();
		var assets = Assets.instance, url = assets.host;
		if (url == null) {
			source = "the packaged files";
			fetch();
		} else if (url.indexOf("://") < 0) {
			// The browser: the page fetches files beside it.
			source = url + " beside the page";
			fetch();
		} else {
			asking = true;
			state = 'asking $url...';
			assets.pingHost(url, TEXTURE, 2, answered -> {
				asking = false;
				if (answered)
					source = url;
				else {
					assets.setHost(null);
					source = 'the packaged files ($url didn\'t answer)';
				}
				fetch();
			});
		}
	}

	/** Loads the logo again, watching whether it's downloaded or read from the cache. */
	function fetch():Void {
		if (logo != null)
			Textures.release(logo);
		logo = null;
		waiting = true;
		state = 'fetching $TEXTURE...';
		var downloaded = false;
		// Now cached: the texture reads it from there.
		Assets.ensure(TEXTURE, _ -> Textures.load(TEXTURE, true, texture -> show(texture, downloaded), message -> fail(message)), message -> fail(message),
			progress -> if (progress.phase == "downloading") downloaded = true);
	}

	// The logo in, from where it came.
	function show(texture:Texture2D, downloaded:Bool):Void {
		logo = texture;
		waiting = false;
		state = Assets.host == null ? 'read $TEXTURE from the packaged files' : downloaded ? 'downloaded $TEXTURE into the cache' : 'loaded $TEXTURE from the cache';
	}

	// The fetch failed: said on the screen.
	function fail(message:String):Void {
		waiting = false;
		state = message;
	}

	function clearCache():Void
		Assets.clearCache(result -> state = switch result {
			case Written: "cache cleared: the next fetch downloads";
			case Failed(message): "cache not cleared: " + message;
			case Cancelled: state;
		});

	override public function frame(dt:Float):Void {
		var input = Input.instance;
		// The design for the window's shape: the text wrapped to what's visible of it, the buttons under it (laid out before the pointer is
		// tested against them), the logo centered below.
		ScreenShape.update();
		var presentation = Screen.instance;
		presentation.apply(camera);
		var vx = presentation.visibleX,
			vy = presentation.visibleY,
			vw = presentation.visibleWidth;
		var from = "from: " + (asking ? "..." : source);
		var titleY = vy + 40;
		var fromY = titleY + batch.font.measureWrapped("HeliX asset fetch", 24, vw - 24) + 10;
		var stateY = fromY + batch.font.measureWrapped(from, 16, vw - 24) + 10;
		var buttonY = stateY + batch.font.measureWrapped(state, 16, vw - 24) + 20;
		var x = camera.screenToWorldX(input.pointerX),
			y = camera.screenToWorldY(input.pointerY);
		var clicked = input.pointerFramePressed;
		if ((input.isFramePressed(Key.F) || clicked && inside(x, y, vx + 12, buttonY)) && !waiting && !asking)
			fetch();
		if (input.isFramePressed(Key.C) || clicked && inside(x, y, vx + 204, buttonY))
			clearCache();
		if (Host.canQuit() && input.isFramePressed(Key.Escape))
			Host.quit();
		fps.update(dt, Time.frameCpu);
		Graphics.beginFrame(Window.framebufferWidth, Window.framebufferHeight, 0xff1c1e26);
		batch.begin(camera);
		batch.drawTextWrapped("HeliX asset fetch", vx + 12, titleY, 24, vw - 24, 0xfff5f5f5);
		batch.drawTextWrapped(from, vx + 12, fromY, 16, vw - 24, 0xffc8c8c8);
		batch.drawTextWrapped(state, vx + 12, stateY, 16, vw - 24, 0xffffcb00);
		button("Fetch asset", vx + 12, buttonY, inside(x, y, vx + 12, buttonY));
		button("Clear cache", vx + 204, buttonY, inside(x, y, vx + 204, buttonY));
		if (logo != null)
			batch.sprite(logo, vx + vw / 2, buttonY + BUTTON_HEIGHT + 170, 220, 220);
		fps.draw(batch, vx + 12, vy + 8);
		batch.end();
		Graphics.endFrame();
	}

	static inline var BUTTON_WIDTH = 180;
	static inline var BUTTON_HEIGHT = 40;

	static function inside(x:Float, y:Float, left:Float, top:Float):Bool
		return x >= left && x < left + BUTTON_WIDTH && y >= top && y < top + BUTTON_HEIGHT;

	function button(label:String, x:Float, y:Float, hover:Bool):Void {
		batch.roundedRect(x, y, BUTTON_WIDTH, BUTTON_HEIGHT, 6, hover ? 0xff3d4a66 : 0xff2b3448);
		batch.drawText(label, x + BUTTON_WIDTH / 2, y + 11, 17, 0xfff5f5f5, Center);
	}
}
