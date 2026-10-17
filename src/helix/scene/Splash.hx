package helix.scene;

import helix.host.Services;
import helix.render2d.Batch2D;
import helix.render2d.Camera2D;
import helix.render2d.Text2D;
import helix.render2d.Texture2D;
import helix.scene.Transition.Fade;
import helix.ui.Theme;

/** The built-in splash: a logo (or none) centered on the theme's panel color for at least its seconds, then the next scene, once the user
	has pressed a key, a button or a finger (IInput.isActivated: a browser lets audio start and fullscreen be asked for only after that; the
	same rule everywhere), or after setMaxWait's seconds without one: "press any key" shows until then, or, where a press came already,
	nothing. A pad's press doesn't count (a browser can't unlock with one), so the line stays for a tap. Pushed with a Fade, it fades in from
	the color. Extend it for another look; setTheme for its colors and font, setPrompt for the line. */
class Splash extends Scene {
	var logo:Null<Texture2D>;
	var seconds:Float;
	var next:Scene;
	var transition:Null<Transition>;
	var theme = new Theme();
	var prompt = "press any key";
	var shown = 0.;
	var maxWait = 0.;
	var batch:Null<Batch2D>;
	var camera = new Camera2D();
	var left = false;

	/** A splash of logo (null: the theme's colors alone), shown at least seconds, then next, by transition (a half-second fade unless given). */
	public function new(logo:Null<Texture2D>, seconds:Float, next:Scene, ?transition:Transition) {
		super();
		this.logo = logo;
		this.seconds = seconds;
		this.next = next;
		this.transition = transition == null ? new Fade() : transition;
	}

	/** Its theme. */
	public function getTheme():Theme
		return theme;

	/** The theme it draws with. */
	public function setTheme(value:Theme):Void
		theme = value;

	/** What it asks for the press with. */
	public function getPrompt():String
		return prompt;

	/** The line shown until a press comes ("press any key" to start). */
	public function setPrompt(value:String):Void
		prompt = value;

	/** Seconds shown so far. */
	public function getShown():Float
		return shown;

	/** The most seconds it waits for a press before going on without one; 0 for as long as it takes. */
	public function getMaxWait():Float
		return maxWait;

	/** Goes on after seconds even without a press (a game that needs no audio unlock, or one that unlocks later), 0 to wait for one. False,
		changing nothing, for under 0. */
	public function setMaxWait(seconds:Float):Bool {
		if (!(seconds >= 0))
			return false;
		maxWait = seconds;
		return true;
	}

	override public function exit():Void {
		if (batch != null)
			batch.destroy();
		batch = null;
	}

	override public function update(dt:Float):Void {
		shown += Math.max(0, dt);
		var pressed = scenes.getInput().isActivated() || (maxWait > 0 && shown >= maxWait);
		if (!left && (scenes.isQuick() || (shown >= seconds && pressed && !scenes.isTransitioning()))) {
			left = true;
			scenes.replace(next, transition);
		}
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
		if (logo != null) {
			var side = Math.min(vw, vh) * .4;
			batch.sprite(logo, vx + (vw - side) / 2, vy + (vh - side) / 2 - 20, side, side);
		}
		if (!scenes.getInput().isActivated())
			Text2D.draw(batch, prompt, vx + vw / 2, vy + vh * .8, theme.getTextSize(), theme.getDisabledTextColor(), Center, theme.getFont());
		batch.end();
	}
}
