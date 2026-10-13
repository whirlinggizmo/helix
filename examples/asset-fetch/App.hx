import helix.app.BaseApp;
import helix.debug.FpsOverlay;
import helix.host.IHost;
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

	var host:IHost;
	var batch:Batch2D;
	var camera = new Camera2D();
	var fps = new FpsOverlay();
	var logo:Null<Texture2D>;
	var source = "";
	var state = "";
	var asking = false;
	var waiting = false;

	public function new(host:IHost) {
		super();
		this.host = host;
	}

	override public function init():Void {
		host.window.setTitle("HeliX asset fetch");
		host.window.setSize(800, 520);
		batch = new Batch2D(host.graphics);
		var assets = host.assets, url = assets.getHost();
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
			host.textures.release(logo);
		logo = null;
		waiting = true;
		state = 'fetching $TEXTURE...';
		var downloaded = false;
		host.assets.ensure(TEXTURE, result -> switch result {
			case Loaded(_):
				// Now cached: the texture reads it from there.
				host.textures.load(TEXTURE, true, loaded -> switch loaded {
					case Ready(texture):
						logo = texture;
						waiting = false;
						state = host.assets.getHost() == null ? 'read $TEXTURE from the packaged files' : downloaded ? 'downloaded $TEXTURE into the cache' : 'loaded $TEXTURE from the cache';
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
		host.assets.clearCache(result -> state = switch result {
			case Written: "cache cleared: the next fetch downloads";
			case Failed(message): "cache not cleared: " + message;
			case Cancelled: state;
		});

	override public function frame(dt:Float):Void {
		var input = host.input;
		camera.setViewport(host.getFramebufferWidth(), host.getFramebufferHeight());
		camera.pixels(host.getPixelRatio());
		var x = camera.screenToWorldX(input.getPointerX()),
			y = camera.screenToWorldY(input.getPointerY());
		var clicked = input.isPointerFramePressed();
		if ((input.isFramePressed(Key.F) || clicked && inside(x, y, 12, 150)) && !waiting && !asking)
			fetch();
		if (input.isFramePressed(Key.C) || clicked && inside(x, y, 204, 150))
			clearCache();
		if (host.canQuit() && input.isFramePressed(Key.Escape))
			host.quit();
		fps.update(dt, host.diagnostics.getFrameCpu());
		batch.begin(camera, 0x1c1e26ff);
		Text2D.draw(batch, "HeliX asset fetch", 12, 40, 24, 0xf5f5f5ff);
		Text2D.draw(batch, "from: " + (asking ? "..." : source), 12, 80, 16, 0xc8c8c8ff);
		Text2D.draw(batch, state, 12, 110, 16, 0xffcb00ff);
		button("Fetch asset", 12, 150, inside(x, y, 12, 150));
		button("Clear cache", 204, 150, inside(x, y, 204, 150));
		if (logo != null)
			batch.sprite(logo, 400, 360, 220, 220);
		fps.draw(batch, 12, 8);
		batch.end();
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
