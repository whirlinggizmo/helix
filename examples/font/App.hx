import helix.app.BaseApp;
import helix.debug.FpsOverlay;
import helix.host.IHost;
import helix.input.Key;
import helix.render2d.Batch2D;
import helix.render2d.Camera2D;
import helix.render2d.Font2D;
import helix.render2d.Fonts;
import helix.render2d.Text2D;

/** TrueType fonts loaded from files and baked into distance fields in Haxe (Fonts): a measured, centered title in Komika, JetBrains Mono at
	several sizes, kerning (Komika's pairs closing "AV", "AT" and "LT"), and the built-in font drawing until they are ready. D switches the last
	line's font between the built-in one and Komika; Escape quits where quitting means anything. */
class App extends BaseApp {
	static inline var MONO = "fonts/JetBrainsMono/JetBrainsMono-Regular.ttf";
	static inline var KOMIKA = "fonts/Komika/KOMIKAH_.ttf";

	var host:IHost;
	var batch:Batch2D;
	var camera = new Camera2D();
	var fps = new FpsOverlay();
	var fonts:Fonts;
	var mono:Null<Font2D>;
	var komika:Null<Font2D>;
	var failed = false;
	var useKomika = false;

	public function new(host:IHost) {
		super();
		this.host = host;
	}

	override public function init():Void {
		host.window.setTitle("HeliX font");
		host.window.setSize(900, 500);
		batch = new Batch2D(host.graphics);
		fonts = new Fonts(host.assets, host.graphics);
		fonts.load(MONO, result -> switch result {
			case Ready(font):
				mono = font;
			case Failed(message):
				failed = true;
				trace(message);
			case Cancelled:
		});
		fonts.load(KOMIKA, result -> switch result {
			case Ready(font):
				komika = font;
			case Failed(message):
				failed = true;
				trace(message);
			case Cancelled:
		});
	}

	override public function frame(dt:Float):Void {
		var input = host.input;
		if (host.canQuit() && input.isFramePressed(Key.Escape))
			host.quit();
		if (input.isFramePressed(Key.D) && komika != null)
			useKomika = !useKomika;
		fps.update(dt, host.diagnostics.getFrameCpu());
		var width = host.getFramebufferWidth(),
			height = host.getFramebufferHeight(),
			ratio = host.getPixelRatio();
		camera.setViewport(width, height);
		camera.pixels(ratio);

		host.graphics.beginFrame(width, height, 0xf8f8faff);
		batch.begin(camera);
		// A centered title, measured.
		if (komika != null)
			Text2D.draw(batch, "HeliX + TrueType", width / ratio / 2, 90, 56, 0x0052acff, Center, komika);
		// A few sizes.
		if (mono != null) {
			Text2D.draw(batch, "The quick brown fox jumps over the lazy dog.", 40, 200, 28, 0x000000ff, Left, mono);
			Text2D.draw(batch, "scalable, anti-aliased TrueType glyphs", 40, 250, 20, 0x505050ff, Left, mono);
			Text2D.draw(batch, "0123456789  !@#$%^&*()  +-*/=", 40, 290, 24, 0xbe2137ff, Left, mono);
		} else
			Text2D.draw(batch, failed ? "a font failed to load" : "loading fonts...", 40, 200, 20, 0x828282ff);
		if (komika != null)
			Text2D.draw(batch, "AVATAR, TALL: kerned", 520, 160, 28, 0x00752cff, Left, komika);
		Text2D.draw(batch, useKomika ? "[D] font: Komika   {a|b} ~ \\ ^_`" : "[D] font: built in   {a|b} ~ \\ ^_`", 40, 360, 16, 0x00752cff, Left,
			useKomika ? komika : null);
		fps.draw(batch, 12, 12);
		batch.end();
		host.graphics.endFrame();
	}

	override public function cleanup():Void {
		for (font in [mono, komika])
			if (font != null)
				fonts.release(font);
		batch.destroy();
	}
}
