package helix.scene;

import helix.graphics.Graphics;
import helix.host.Screen;
import helix.host.Window;
import helix.render2d.Batch2D;
import helix.render2d.Camera2D;
import helix.render2d.Texture2D;
import helix.scene.Transition.Fade;
import helix.ui.Theme;

/** The built-in splash: a logo (or none) centered on the theme's panel color for at least its seconds, then the next scene, once the user
	has pressed a key, a button or a finger (IInput.activated: a browser lets audio start and fullscreen be asked for only after that; the
	same rule everywhere), or after maxWait's seconds without one: "press any key" shows until then, or, where a press came already,
	nothing. A pad's press doesn't count (a browser can't unlock with one), so the line stays for a tap. Pushed with a Fade, it fades in from
	the color. Extend it for another look; theme for its colors and font, prompt for the line. */
class Splash extends Scene {
	var logo:Null<Texture2D>;
	var seconds:Float;
	var next:Scene;
	var transition:Null<Transition>;
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

	/** The theme it draws with. */
	public var theme:Theme = new Theme();

	/** The line that asks for the press, shown until one comes ("press any key" to start). */
	public var prompt:String = "press any key";

	/** Seconds shown so far. */
	public var shown(default, null):Float = 0.;

	/** The most seconds it waits for a press before going on without one (a game that needs no audio unlock, or one that unlocks later);
		0, the default, waits for one as long as it takes. 0 or more (under 0, or NaN, is 0). */
	public var maxWait(default, set):Float = 0.;

	function set_maxWait(seconds:Float):Float {
		seconds = seconds >= 0 ? seconds : 0;
		maxWait = seconds;
		return seconds;
	}

	override public function exit():Void {
		if (batch != null)
			batch.destroy();
		batch = null;
	}

	override public function update(dt:Float):Void {
		shown += Math.max(0, dt);
		var pressed = scenes.input.activated || (maxWait > 0 && shown >= maxWait);
		if (!left && (scenes.quick || (shown >= seconds && pressed && !scenes.transitioning))) {
			left = true;
			scenes.replace(next, transition);
		}
	}

	override public function draw():Void {
		var width = Window.framebufferWidth, height = Window.framebufferHeight;
		if (batch == null)
			batch = new Batch2D(Graphics.instance);
		Screen.apply(camera);
		var p = Screen.instance;
		var vx = p.visibleX,
			vy = p.visibleY,
			vw = p.visibleWidth,
			vh = p.visibleHeight;
		Graphics.beginFrame(width, height, theme.panelColor);
		batch.begin(camera);
		if (logo != null) {
			var side = Math.min(vw, vh) * .4;
			batch.sprite(logo, vx + (vw - side) / 2, vy + (vh - side) / 2 - 20, side, side);
		}
		if (!scenes.input.activated)
			batch.drawText(prompt, vx + vw / 2, vy + vh * .8, theme.textSize, theme.disabledTextColor, Center, theme.font);
		batch.end();
	}
}
