package helix.scene;

import helix.host.Services;
import helix.render2d.Batch2D;
import helix.render2d.Camera2D;
import helix.render2d.Text2D;
import helix.render2d.Texture2D;
import helix.ui.Theme;

/** The built-in loading scene: the theme's panel color or a picture (setImage: a level's art, covering the screen or centered), a caption
	("Loading the caves", setText; "Loading" unless given) over a bar of the loader's progress and the count, a tip along the bottom
	(setTip), and what failed in the disabled text color. With setHoldForPress it stays once loaded, saying so, until a press (the "loaded,
	go" screen of a movie-like opening); else the scene runs as soon as its loads are in. The game drives it: one for the program
	(Scenes.getLoadingScene) set before each level, or one a level brings (Scene.getLoadingScene). Its theme is its own (setTheme). */
class Loading extends LoadingScene {
	var theme = new Theme();
	var image:Null<Texture2D>;
	var cover = true;
	var text = "Loading";
	var tip = "";
	var hold = false;
	var prompt = "press any key";
	var went = false;
	var batch:Null<Batch2D>;
	var camera = new Camera2D();

	/** The built-in loading scene with the default theme. */
	public function new()
		super();

	/** Its theme. */
	public function getTheme():Theme
		return theme;

	/** The theme it draws with. */
	public function setTheme(value:Theme):Void
		theme = value;

	/** Its picture, or null. */
	public function getImage():Null<Texture2D>
		return image;

	/** A picture behind the rest: covering the screen (cropped to its shape) when cover, else centered whole; null for the panel color alone. */
	public function setImage(value:Null<Texture2D>, cover = true):Void {
		image = value;
		this.cover = cover;
	}

	/** The caption over the bar. */
	public function getText():String
		return text;

	/** The caption over the bar: what's loading ("Loading the caves"). */
	public function setText(value:String):Void
		text = value;

	/** The tip along the bottom, "" for none. */
	public function getTip():String
		return tip;

	/** A line along the bottom (a hint, a credit), wrapped; "" for none. */
	public function setTip(value:String):Void
		tip = value;

	/** Whether it stays once loaded, until a press. */
	public function isHoldForPress():Bool
		return hold;

	/** Stays once the loads are done, showing the prompt, until a key, a button or a finger is pressed. */
	public function setHoldForPress(value:Bool):Void
		hold = value;

	/** The line shown once loaded, while holding for a press. */
	public function getPrompt():String
		return prompt;

	/** Sets the line shown while holding. */
	public function setPrompt(value:String):Void
		prompt = value;

	override public function enter():Void
		went = false;

	override public function isHolding():Bool
		return hold && !went && !(scenes != null && scenes.isQuick());

	override public function update(dt:Float):Void
		if (hold && loader != null && loader.isDone() && scenes.getInput().isAnyFramePressed())
			went = true;

	override public function exit():Void {
		if (batch != null)
			batch.destroy();
		batch = null;
	}

	override public function draw():Void {
		var width = Services.window.getFramebufferWidth(),
			height = Services.window.getFramebufferHeight();
		if (batch == null)
			batch = new Batch2D(Services.graphics);
		Services.presentation.apply(camera);
		var p = Services.presentation;
		var vx = p.getVisibleX(),
			vy = p.getVisibleY(),
			vw = p.getVisibleWidth(),
			vh = p.getVisibleHeight();
		Services.graphics.beginFrame(width, height, theme.getPanelColor());
		batch.begin(camera);
		if (image != null) {
			// Covering: scaled to fill the visible area, its middle kept; else whole, centered, as large as fits.
			var iw = image.getWidth(), ih = image.getHeight();
			var scale = cover ? Math.max(vw / iw, vh / ih) : Math.min(vw / iw, vh / ih);
			var w = iw * scale, h = ih * scale;
			batch.sprite(image, vx + (vw - w) / 2, vy + (vh - h) / 2, w, h);
		}
		var progress = loader == null ? 1 : loader.getProgress();
		var barWidth = Math.min(360, vw - 80),
			x = vx + (vw - barWidth) / 2,
			y = vy + vh / 2;
		Text2D.draw(batch, loader != null && loader.isDone() && hold ? "Loaded" : text, vx + vw / 2, y - 40, theme.getTextSize() * 1.2, theme.getTextColor(),
			Center, theme.getFont());
		batch.rect(x, y, barWidth, 10, theme.getFaceColor());
		batch.rect(x, y, barWidth * progress, 10, theme.getAccentColor());
		var count = loader == null ? "" : loader.isDone() && hold ? prompt : '${loader.getDoneCount()} of ${loader.getCount()}';
		Text2D.draw(batch, count, vx + vw / 2, y + 24, theme.getTextSize() * .8, theme.getDisabledTextColor(), Center, theme.getFont());
		if (tip != "")
			Text2D.drawWrapped(batch, tip, vx + vw / 2, vy + vh - 60, theme.getTextSize() * .8, vw - 80, theme.getDisabledTextColor(), Center, 1.25,
				theme.getFont());
		if (loader != null) {
			var line = y + 56;
			for (failure in loader.getFailures()) {
				line += Text2D.drawWrapped(batch, failure, vx + vw / 2, line, theme.getTextSize() * .8, vw - 80, theme.getDisabledTextColor(), Center, 1.25,
					theme.getFont());
			}
		}
		batch.end();
	}
}
