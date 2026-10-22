import helix.debug.FpsOverlay;
import helix.graphics.Graphics;
import helix.host.Host;
import helix.host.Screen;
import helix.host.Window;
import helix.input.Input;
import helix.input.Key;
import helix.render2d.Batch2D;
import helix.render2d.Camera2D;
import helix.render2d.Font2D;
import helix.render2d.Fonts;
import helix.time.Time;
import helix.host.ScreenShape;

/** TrueType fonts loaded from files and baked into distance fields in Haxe (Fonts): a measured, centered title in Komika, JetBrains Mono at
	several sizes, kerning (Komika's pairs closing "AV", "AT" and "LT"), and the built-in font drawing until they are ready. D switches the last
	line's font between the built-in one and Komika; Escape quits where quitting means anything. */
class App extends helix.App {
	static inline var MONO = "fonts/JetBrainsMono/JetBrainsMono-Regular.ttf";
	static inline var KOMIKA = "fonts/Komika/KOMIKAH_.ttf";

	var batch:Batch2D;
	var camera = new Camera2D();
	var fps = new FpsOverlay();
	var mono:Null<Font2D>;
	var komika:Null<Font2D>;
	var failed = false;
	var useKomika = false;

	override public function init():Void {
		Window.title = "HeliX font";
		Window.requestSize(900, 500);
		batch = new Batch2D();
		Fonts.load(MONO, font -> mono = font, message -> fail(message));
		Fonts.load(KOMIKA, font -> komika = font, message -> fail(message));
	}

	// A font failed to load: said on the screen, and why in the log.
	function fail(message:String):Void {
		failed = true;
		trace(message);
	}

	override public function update(dt:Float):Void {
		var input = Input.instance;
		if (Host.canQuit() && input.isFramePressed(Key.Escape))
			Host.quit();
		if (input.isFramePressed(Key.D) && komika != null)
			useKomika = !useKomika;
		fps.update(dt, Time.frameCpu);
		// The specimen in the design for the window's shape, its lines wrapped to what's visible of it; upright, the kerned line goes under the
		// title instead of beside the specimen.
		var shape = ScreenShape.update();
		var presentation = Screen.instance;
		presentation.apply(camera);
		var vx = presentation.visibleX,
			vy = presentation.visibleY,
			vw = presentation.visibleWidth;
		var x = vx + 40, wrap = vw - 80, y = vy + (shape == "portrait" ? 220 : 200);

		Graphics.beginFrame(Window.framebufferWidth, Window.framebufferHeight, 0xfff8f8fa);
		batch.begin(camera);
		// A centered title, measured.
		if (komika != null)
			batch.drawTextWrapped("HeliX + TrueType", vx + vw / 2, vy + 90, 56, vw - 48, 0xff0052ac, Center, komika);
		// A few sizes.
		if (mono != null) {
			y += batch.drawTextWrapped("The quick brown fox jumps over the lazy dog.", x, y, 28, wrap, 0xff000000, Left, mono) + 15;
			y += batch.drawTextWrapped("scalable, anti-aliased TrueType glyphs", x, y, 20, wrap, 0xff505050, Left, mono) + 15;
			y += batch.drawTextWrapped("0123456789  !@#$%^&*()  +-*/=", x, y, 24, wrap, 0xffbe2137, Left, mono) + 40;
		} else
			y += batch.drawTextWrapped(failed ? "a font failed to load" : "loading fonts...", x, y, 20, wrap, 0xff828282) + 135;
		if (komika != null)
			batch.drawText("AVATAR, TALL: kerned", shape == "portrait" ? x : vx + 520, vy + 160, 28, 0xff00752c, Left, komika);
		batch.drawTextWrapped(useKomika ? "[D] font: Komika   {a|b} ~ \\ ^_`" : "[D] font: built in   {a|b} ~ \\ ^_`", x, y, 16, wrap, 0xff00752c, Left,
			useKomika ? komika : null);
		fps.draw(batch, vx + 12, vy + 12);
		batch.end();
		Graphics.endFrame();
	}

	override public function cleanup():Void {
		for (font in [mono, komika])
			if (font != null)
				Fonts.release(font);
		batch.destroy();
	}
}
