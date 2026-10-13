import Game.Body;
import helix.input.InputState;
import helix.input.Key;
import helix.input.PadButton;
import helix.input.PadAxis;
import helix.debug.Autopilot;

class SimulationTests {
	static var checks = 0;

	static function check(value:Bool, message:String):Void {
		if (!value)
			throw message;
		checks++;
	}

	static function rejects(action:Void->Void, message:String):Void {
		var rejected = false;
		try {
			action();
		} catch (error:Dynamic) {
			rejected = true;
		}
		check(rejected, message);
	}

	static function main():Void {
		var g = new Game(), c = new Controls();
		check(g.state == "title" && g.rocks.length == 6, "Drifting title field");
		c.start = true;
		g.step(c);
		check(g.state == "playing" && g.lives == 3 && g.wave == 1 && g.rocks.length == 4, "Start reference wave count");
		c.start = false;
		c.thrust = true;
		for (_ in 0...20)
			g.step(c);
		check(g.ship.y < Game.H * 128, "Thrust accelerates ship");
		c.thrust = false;
		g.ship.x = Game.W * 256 - 1;
		g.ship.vx = 500;
		g.step(c);
		check(g.ship.x < 1000, "Ship wraps");
		check(Game.near(new Body(2 * 256, 0, 0, 0, 1), new Body((Game.W - 1) * 256, 0, 0, 0, 1), 5), "Toroidal seam collision");
		g.rocks = [new Body(100 * 256, 100 * 256, 0, 0, 3)];
		g.bullets = [new Body(100 * 256, 100 * 256, 0, 0, 2, 10)];
		g.step(c);
		check(g.hits == 1 && g.splits == 1 && g.score == 20 && g.rocks.length == 2 && g.bullets.length == 0, "Bullet splits large rock");
		g.rocks = [new Body(g.ship.x, g.ship.y, 0, 0, 3)];
		g.invulnerable = 0;
		g.lives = 1;
		g.ship.vx = g.ship.vy = 0;
		g.step(c);
		check(g.state == "gameover" && g.lives == 0 && g.deaths == 1 && g.best == g.score, "Last collision records best");
		var best = g.best;
		c.title = true;
		g.step(c);
		check(g.state == "title" && g.rocks.length == 6, "Return to title");
		c.title = false;
		c.start = true;
		g.step(c);
		check(g.state == "playing" && g.lives == 3 && g.score == 0 && g.best == best, "Restart retains best");
		var a = new Game(73), b = new Game(73);
		for (i in 0...2400) {
			c.replay(i);
			a.step(c);
			b.step(c);
		}
		check(haxe.Json.stringify(a.snapshot()) == haxe.Json.stringify(b.snapshot()), "Seeded replay repeats exactly");
		g = new Game();
		c = new Controls();
		c.start = true;
		g.step(c);
		c.start = false;
		c.fire = true;
		g.rocks = [new Body(200 * 256, 200 * 256, 0, 0, 3)];
		for (_ in 0...30)
			g.step(c);
		check(g.shots == 3, "Fire cooldown bounds rate");
		for (_ in 0...20)
			g.step(c);
		check(g.bullets.length <= 6, "Bullet cap");
		g.bullets = [new Body(50 * 256, 50 * 256, 0, 0, 2, 1)];
		c.fire = false;
		g.step(c);
		check(g.bullets.length == 0, "Bullet expiry");
		g.rocks = [];
		var wave = g.wave;
		for (_ in 0...89)
			g.step(c);
		check(g.wave == wave && g.waveDelay == 89, "Wave delay preserved");
		g.step(c);
		check(g.wave == wave + 1, "Wave advances after 90 ticks");
		g.score = 9980;
		g.lives = 2;
		g.addScore(20);
		check(g.lives == 3 && g.sounds.indexOf(5) >= 0, "Extra life every 10000 points");
		g.rocks = [new Body(g.ship.x, g.ship.y, 0, 0, 3)];
		g.ship.vx = g.ship.vy = 0;
		g.invulnerable = 0;
		g.step(c);
		check(g.respawnDelay == 120 && g.lives == 2, "Two-second respawn delay");
		for (_ in 0...120)
			g.step(c);
		check(g.respawnDelay == 0 && g.invulnerable > 0, "Respawn grants invulnerability");
		var state = new InputState();
		state.keyEvent(Key.Enter, true);
		state.keyEvent(Key.Enter, false);
		check(!state.isDown(Key.Enter) && state.isPressed(Key.Enter) && state.isReleased(Key.Enter), "Short tap retains both edges");
		c.read(state);
		check(c.start, "Controls see short tap");
		state.consume();
		check(!state.isPressed(Key.Enter) && !state.isReleased(Key.Enter), "Consume once");
		state.keyEvent(Key.Space, true);
		state.consume();
		state.keyEvent(Key.Space, true);
		check(state.isDown(Key.Space) && !state.isPressed(Key.Space), "Key repeat is not a new edge");
		state.clear();
		check(!state.isDown(Key.Space) && state.isReleased(Key.Space), "Focus clear releases held key");
		state.padEvent(PadButton.East, true);
		state.axisEvent(PadAxis.LeftX, -.8);
		state.axisEvent(PadAxis.RightTrigger, .7);
		c.read(state);
		check(c.fire && c.left && c.thrust, "Standard controller actions");
		state.clear();
		check(state.getPadAxis(PadAxis.LeftX) == 0 && !state.isPadDown(PadButton.East), "Controller disconnect clears state");
		g = new Game();
		c = new Controls();
		state = new InputState();
		var menu = new Menu();
		state.pointerEvent(500, 416 * 700 / 720., true);
		c.read(state);
		var camera = new helix.render2d.Camera2D();
		Field.view(camera, 1000, 700);
		menu.update(g, c, state, camera);
		g.step(c);
		check(g.state == "playing", "Letterboxed pointer menu activation");
		for (name in ["smoke", "playthrough"]) {
			var pilot = new Autopilot(sys.io.File.getContent("examples/asteroids/autopilot/" + name + ".json"));
			g = new Game(pilot.getSeed());
			menu = new Menu();
			Field.view(camera, 800, 600);
			c = new Controls();
			for (_ in 0...15000) {
				var source = pilot.advance(g.probe);
				if (pilot.isDone())
					break;
				c.read(source);
				menu.update(g, c, source, camera);
				g.step(c);
				source.consume();
			}
			check(pilot.isDone(), "Autopilot " + name + " completes");
			if (name == "playthrough")
				check(g.state == "playing" && g.lives == 3 && g.score == 0, "Autopilot covers gameover/title/restart");
		}
		rejects(() -> new Autopilot('{"version":1,"seed":1,"commands":[{"op":"hold","keys":[],"ticks":-1}]}'), "Invalid script duration rejected");
		var timeout = new Autopilot('{"version":1,"seed":1,"commands":[{"op":"wait","probe":"state","equals":"never","timeout":1}]}');
		timeout.advance(g.probe);
		rejects(() -> timeout.advance(g.probe), "Unmet wait fails with bounded timeout");
		trace(haxe.Json.stringify({checks: checks, passed: true, replay: a.snapshot()}));
	}
}
