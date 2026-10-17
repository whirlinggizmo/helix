import helix.app.BaseApp;
import helix.debug.FpsOverlay;
import helix.host.Services;
import helix.input.Key;
import helix.render2d.Batch2D;
import helix.render2d.Camera2D;
import helix.render2d.Text2D;
import helix.render2d.Texture2D;

/** The desktop pulls its files from the same site the browser does. In the browser the page fetches each file beside it and caches it; natively,
	files are read from the program's packaged folder unless HELIX_ASSET_HOST names a host (python3 -m http.server in examples/assets, say), which
	is asked first whether it answers: then a cache miss downloads the file into the program's cache. Fetch asset (F) loads the logo again, and says
	whether it came from the cache or was downloaded; Clear cache (C) forgets what was downloaded, so the next fetch downloads it again. Escape quits
	where quitting means anything. HeliX has no UI module yet, so the two buttons are drawn and hit-tested here. */
class App extends BaseApp {
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
		Services.window.setTitle("HeliX asset fetch");
		Services.window.requestSize(800, 520);
		batch = new Batch2D(Services.graphics);
		var assets = Services.assets, url = assets.getHost();
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
			Services.textures.release(logo);
		logo = null;
		waiting = true;
		state = 'fetching $TEXTURE...';
		var downloaded = false;
		Services.assets.ensure(TEXTURE, result -> switch result {
			case Loaded(_):
				// Now cached: the texture reads it from there.
				Services.textures.load(TEXTURE, true, loaded -> switch loaded {
					case Ready(texture):
						logo = texture;
						waiting = false;
						state = Services.assets.getHost() == null ? 'read $TEXTURE from the packaged files' : downloaded ? 'downloaded $TEXTURE into the cache' : 'loaded $TEXTURE from the cache';
					case Failed(message):
						waiting = false;
						state = message;
					case Cancelled:
				});
			case Failed(message):
				waiting = false;
				state = message;
			case Cancelled:
		}, progress -> if (progress.phase == "downloading") downloaded = true);
	}

	function clearCache():Void
		Services.assets.clearCache(result -> state = switch result {
			case Written: "cache cleared: the next fetch downloads";
			case Failed(message): "cache not cleared: " + message;
			case Cancelled: state;
		});

	override public function frame(dt:Float):Void {
		var input = Services.input;
		// The design for the window's shape: the text wrapped to what's visible of it, the buttons under it (laid out before the pointer is
		// tested against them), the logo centered below.
		ScreenShape.update();
		var presentation = Services.presentation;
		presentation.apply(camera);
		var vx = presentation.getVisibleX(),
			vy = presentation.getVisibleY(),
			vw = presentation.getVisibleWidth();
		var from = "from: " + (asking ? "..." : source);
		var titleY = vy + 40;
		var fromY = titleY + Text2D.measureWrapped(batch.getFont(), "HeliX asset fetch", 24, vw - 24) + 10;
		var stateY = fromY + Text2D.measureWrapped(batch.getFont(), from, 16, vw - 24) + 10;
		var buttonY = stateY + Text2D.measureWrapped(batch.getFont(), state, 16, vw - 24) + 20;
		var x = camera.screenToWorldX(input.getPointerX()),
			y = camera.screenToWorldY(input.getPointerY());
		var clicked = input.isPointerFramePressed();
		if ((input.isFramePressed(Key.F) || clicked && inside(x, y, vx + 12, buttonY)) && !waiting && !asking)
			fetch();
		if (input.isFramePressed(Key.C) || clicked && inside(x, y, vx + 204, buttonY))
			clearCache();
		if (Services.canQuit() && input.isFramePressed(Key.Escape))
			Services.quit();
		fps.update(dt, Services.getFrameCpu());
		Services.graphics.beginFrame(Services.window.getFramebufferWidth(), Services.window.getFramebufferHeight(), 0x1c1e26ff);
		batch.begin(camera);
		Text2D.drawWrapped(batch, "HeliX asset fetch", vx + 12, titleY, 24, vw - 24, 0xf5f5f5ff);
		Text2D.drawWrapped(batch, from, vx + 12, fromY, 16, vw - 24, 0xc8c8c8ff);
		Text2D.drawWrapped(batch, state, vx + 12, stateY, 16, vw - 24, 0xffcb00ff);
		button("Fetch asset", vx + 12, buttonY, inside(x, y, vx + 12, buttonY));
		button("Clear cache", vx + 204, buttonY, inside(x, y, vx + 204, buttonY));
		if (logo != null)
			batch.sprite(logo, vx + vw / 2, buttonY + BUTTON_HEIGHT + 170, 220, 220);
		fps.draw(batch, vx + 12, vy + 8);
		batch.end();
		Services.graphics.endFrame();
	}

	static inline var BUTTON_WIDTH = 180;
	static inline var BUTTON_HEIGHT = 40;

	static function inside(x:Float, y:Float, left:Float, top:Float):Bool
		return x >= left && x < left + BUTTON_WIDTH && y >= top && y < top + BUTTON_HEIGHT;

	function button(label:String, x:Float, y:Float, hover:Bool):Void {
		batch.roundedRect(x, y, BUTTON_WIDTH, BUTTON_HEIGHT, 6, hover ? 0x3d4a66ff : 0x2b3448ff);
		Text2D.draw(batch, label, x + BUTTON_WIDTH / 2, y + 11, 17, 0xf5f5f5ff, Center);
	}
}
