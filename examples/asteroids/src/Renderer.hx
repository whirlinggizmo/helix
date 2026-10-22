import Game.Body;
import helix.graphics.Color;
import helix.graphics.IGraphics;
import helix.host.Presentation;
import helix.render2d.Batch2D;
import helix.render2d.Camera2D;
import helix.render2d.Align2D;

/** Draws a Game through Batch2D in world units: the Game.W x Game.H field, letterboxed in the framebuffer; then the score, the lives and
	the menu's panel over it in the presentation's units, so they stay readable on a phone. */
class Renderer {
	/** The clear color, 0xAARRGGBB, of the field and the bars around it. */
	public static inline var BACKGROUND = 0xff04060b;

	var gpu:IGraphics;
	var batch:Batch2D;
	var color = 0xffffffff;

	public function new(gpu:IGraphics, batch:Batch2D) {
		this.gpu = gpu;
		this.batch = batch;
	}

	static function rgba(r:Float, g:Float, b:Float, a:Float = 1.):Int
		return Color.fromChannels(Math.round(r * 255), Math.round(g * 255), Math.round(b * 255), Math.round(a * 255));

	function setColor(r:Float, g:Float, b:Float, a:Float = 1.):Void
		color = rgba(r, g, b, a);

	/** The old bitmap alphabet's metrics at scale: 7 * scale tall capitals, 6 * scale apart. */
	function text(value:String, x:Float, y:Float, scale:Float = 3, align:Align2D = Left):Void
		batch.drawText(value, x, y - 3 * scale, 13 * scale, color, align);

	function centered(value:String, x:Float, y:Float, scale:Float = 3):Void
		text(value, x, y, scale, Center);

	function rock(body:Body):Void {
		var x = body.x / 256.,
			y = body.y / 256.,
			radius = Game.radius(body.size) * 1.;
		for (i in 0...10) {
			var a = (body.angle + Std.int(i * 256 / 10)) & 255,
				c = (body.angle + Std.int((i + 1) * 256 / 10)) & 255;
			var ra = radius * (body.shape.length == 10 ? body.shape[i] / 100. : 1.),
				rb = radius * (body.shape.length == 10 ? body.shape[(i + 1) % 10] / 100. : 1.);
			batch.line(x + Trig.cos[a] * ra / 1024, y + Trig.sin[a] * ra / 1024, x + Trig.cos[c] * rb / 1024, y + Trig.sin[c] * rb / 1024, 1.5, color);
		}
	}

	function shipIcon(x:Float, y:Float):Void {
		batch.line(x, y - 12, x + 8, y + 10, 2, color);
		batch.line(x + 8, y + 10, x, y + 5, 2, color);
		batch.line(x, y + 5, x - 8, y + 10, 2, color);
		batch.line(x - 8, y + 10, x, y - 12, 2, color);
	}

	/** The HUD's design is the field's, centered in the presentation's visible area: the menu's panel and buttons keep their places in it. */
	public static function getHudX(presentation:Presentation):Float
		return presentation.visibleX + (presentation.visibleWidth - Game.W) / 2;

	public static function getHudY(presentation:Presentation):Float
		return presentation.visibleY + (presentation.visibleHeight - Game.H) / 2;

	/** Draws game seen through camera, then the score, the lives and the menu's panel through hudCamera (presentation applied to it), and over
		them hud (the menu's buttons), when given. */
	public function render(game:Game, camera:Camera2D, hudCamera:Camera2D, presentation:Presentation, ?hud:helix.render2d.Stage2D):Void {
		gpu.beginFrame(camera.framebufferWidth, camera.framebufferHeight, BACKGROUND);
		batch.begin(camera);
		setColor(.22, .27, .36);
		for (i in 0...100)
			batch.rect((i * 137 + 51) % Game.W, (i * 83 + 19) % Game.H, 1, 1, color);
		setColor(.78, .80, .84);
		for (body in game.rocks.concat(game.attract))
			rock(body);
		for (body in game.bullets)
			batch.rect(body.x / 256. - 2, body.y / 256. - 2, 4, 4, 0xffffffff);
		for (body in game.particles) {
			var fade = body.life / (body.lifetime * 1.);
			batch.rect(body.x / 256. - 1, body.y / 256. - 1, 2 + fade, 2 + fade, rgba(1, .38 + .5 * fade, .12 + .45 * fade, fade));
		}
		if (game.state == "playing" && game.respawnDelay == 0 && (game.invulnerable == 0 || game.tick % 12 < 6)) {
			var ship = game.ship,
				x = ship.x / 256.,
				y = ship.y / 256.,
				c = Trig.cos[ship.angle] / 1024.,
				t = Trig.sin[ship.angle] / 1024.;
			setColor(.5, .83, 1);
			batch.line(x + c * 18, y + t * 18, x - c * 12 - t * 11, y - t * 12 + c * 11, 2, color);
			batch.line(x - c * 12 - t * 11, y - t * 12 + c * 11, x - c * 6, y - t * 6, 2, color);
			batch.line(x - c * 6, y - t * 6, x - c * 12 + t * 11, y - t * 12 - c * 11, 2, color);
			batch.line(x - c * 12 + t * 11, y - t * 12 - c * 11, x + c * 18, y + t * 18, 2, color);
		}
		batch.camera = hudCamera;
		var vx = presentation.visibleX,
			vy = presentation.visibleY,
			vw = presentation.visibleWidth;
		var x = getHudX(presentation), y = getHudY(presentation);
		if (game.state != "title") {
			setColor(.9, .93, .97);
			text(Std.string(game.score), vx + 24, vy + 20, 3);
			setColor(.5, .83, 1);
			for (i in 0...game.lives)
				shipIcon(vx + 32 + i * 26, vy + 72);
			setColor(.7, .75, .8);
			text("WAVE " + game.wave, vx + vw - 150, vy + 24, 2);
		}
		if (game.state != "playing") {
			var over = game.state == "gameover";
			batch.roundedRect(x + 245, y + (over ? 205 : 235), 470, over ? 330 : 240, 8, rgba(.055, .07, .12, .94));
			setColor(.85, .9, .97);
			centered(over ? "GAME OVER" : "ASTEROIDS", x + Game.W / 2, y + (over ? 245 : 275), 6);
			setColor(.65, .72, .8);
			centered(over ? "SCORE " + game.score + "   BEST " + game.best : "TURN: ARROWS   THRUST: UP   FIRE: SPACE", x + Game.W / 2,
				y + (over ? 325 : 345), over ? 2 : 1.5);
			if (!over && game.best > 0) {
				setColor(.65, .72, .8);
				centered("BEST " + game.best, x + Game.W / 2, y + 490, 2);
			}
		}
		if (hud != null)
			hud.draw(batch, hudCamera);
		batch.end();
		gpu.endFrame();
	}
}
