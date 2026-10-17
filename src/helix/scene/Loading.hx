package helix.scene;

import helix.graphics.Graphics;
import helix.host.Screen;
import helix.host.Window;
import helix.render2d.Batch2D;
import helix.render2d.Camera2D;
import helix.render2d.Texture2D;
import helix.ui.Theme;

/** The built-in loading scene: the theme's panel color or a picture (setImage: a level's art, covering the screen or centered), a caption
	("Loading the caves", text; "Loading" unless given) over a bar of the loader's progress and the count, a tip along the bottom
	(tip), and what failed in the disabled text color. With holdForPress it stays once loaded, saying so, until a press (the "loaded,
	go" screen of a movie-like opening); else the scene runs as soon as its loads are in. The game drives it: one for the program
	(Scenes.loadingScene) set before each level, or one a level brings (Scene.loadingScene). Its theme is its own (theme). */
class Loading extends LoadingScene {
	var cover = true;
	var hold = false;
	var went = false;
	var batch:Null<Batch2D>;
	var camera = new Camera2D();

	/** The built-in loading scene with the default theme. */
	public function new()
		super();

	/** The theme it draws with. */
	public var theme:Theme = new Theme();

	/** Its picture, or null. */
	public var image(default, null):Null<Texture2D>;

	/** A picture behind the rest: covering the screen (cropped to its shape) when cover, else centered whole; null for the panel color alone. */
	public function setImage(value:Null<Texture2D>, cover = true):Void {
		image = value;
		this.cover = cover;
	}

	/** The caption over the bar: what's loading ("Loading the caves"). */
	public var text:String = "Loading";

	/** A line along the bottom (a hint, a credit), wrapped; "" for none. */
	public var tip:String = "";

	/** Whether it stays once the loads are done, showing the prompt, until a key, a button or a finger is pressed. */
	public var holdForPress(get, set):Bool;

	function get_holdForPress():Bool
		return hold;

	function set_holdForPress(value:Bool):Bool {
		hold = value;
		return value;
	}

	/** The line shown once loaded, while holding for a press. */
	public var prompt:String = "press any key";

	override public function enter():Void
		went = false;

	override function get_holding():Bool
		return hold && !went && !(scenes != null && scenes.quick);

	override public function update(dt:Float):Void
		if (hold && shownLoader != null && shownLoader.done && scenes.input.anyFramePressed)
			went = true;

	override public function exit():Void {
		if (batch != null)
			batch.destroy();
		batch = null;
	}

	override public function draw():Void {
		var width = Window.framebufferWidth, height = Window.framebufferHeight;
		if (batch == null)
			batch = new Batch2D();
		Screen.apply(camera);
		var p = Screen.instance;
		var vx = p.visibleX,
			vy = p.visibleY,
			vw = p.visibleWidth,
			vh = p.visibleHeight;
		Graphics.beginFrame(width, height, theme.panelColor);
		batch.begin(camera);
		if (image != null) {
			// Covering: scaled to fill the visible area, its middle kept; else whole, centered, as large as fits.
			var iw = image.width, ih = image.height;
			var scale = cover ? Math.max(vw / iw, vh / ih) : Math.min(vw / iw, vh / ih);
			var w = iw * scale, h = ih * scale;
			batch.sprite(image, vx + (vw - w) / 2, vy + (vh - h) / 2, w, h);
		}
		var progress = shownLoader == null ? 1 : shownLoader.progress;
		var barWidth = Math.min(360, vw - 80),
			x = vx + (vw - barWidth) / 2,
			y = vy + vh / 2;
		batch.drawText(shownLoader != null && shownLoader.done && hold ? "Loaded" : text, vx + vw / 2, y - 40, theme.textSize * 1.2, theme.textColor, Center,
			theme.font);
		batch.rect(x, y, barWidth, 10, theme.faceColor);
		batch.rect(x, y, barWidth * progress, 10, theme.accentColor);
		var count = shownLoader == null ? "" : shownLoader.done && hold ? prompt : '${shownLoader.doneCount} of ${shownLoader.count}';
		batch.drawText(count, vx + vw / 2, y + 24, theme.textSize * .8, theme.disabledTextColor, Center, theme.font);
		if (tip != "")
			batch.drawTextWrapped(tip, vx + vw / 2, vy + vh - 60, theme.textSize * .8, vw - 80, theme.disabledTextColor, Center, 1.25, theme.font);
		if (shownLoader != null) {
			var line = y + 56;
			for (failure in shownLoader.failures) {
				line += batch.drawTextWrapped(failure, vx + vw / 2, line, theme.textSize * .8, vw - 80, theme.disabledTextColor, Center, 1.25, theme.font);
			}
		}
		batch.end();
	}
}
