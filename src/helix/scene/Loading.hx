package helix.scene;

import helix.host.Services;
import helix.render2d.Batch2D;
import helix.render2d.Camera2D;
import helix.render2d.Text2D;
import helix.ui.Theme;

/** The built-in loading scene: the theme's panel color, "Loading", a bar of the loader's progress and the count, and what failed in the
	disabled text color. Its theme is its own (setTheme), the default unless given. */
class Loading extends LoadingScene {
	var theme = new Theme();
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
		var progress = loader == null ? 1 : loader.getProgress();
		var barWidth = Math.min(360, vw - 80),
			x = vx + (vw - barWidth) / 2,
			y = vy + vh / 2;
		Text2D.draw(batch, "Loading", vx + vw / 2, y - 40, theme.getTextSize() * 1.2, theme.getTextColor(), Center, theme.getFont());
		batch.rect(x, y, barWidth, 10, theme.getFaceColor());
		batch.rect(x, y, barWidth * progress, 10, theme.getAccentColor());
		var count = loader == null ? "" : '${loader.getDoneCount()} of ${loader.getCount()}';
		Text2D.draw(batch, count, vx + vw / 2, y + 24, theme.getTextSize() * .8, theme.getDisabledTextColor(), Center, theme.getFont());
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
