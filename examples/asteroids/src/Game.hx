class Body {
	public var x:Int;
	public var y:Int;
	public var vx:Int;
	public var vy:Int;
	public var size:Int;
	public var life:Int;
	public var angle:Int;
	public var shape:Array<Int> = [];
	public var lifetime:Int;

	public function new(x:Int, y:Int, vx:Int, vy:Int, size:Int, life:Int = 0, angle:Int = 0) {
		this.x = x;
		this.y = y;
		this.vx = vx;
		this.vy = vy;
		this.size = size;
		this.life = life;
		lifetime = life;
		this.angle = angle;
	}
}

/** Standalone fixed-point implementation, with the reference game's major rules. */
class Game {
	public static inline var W = 960;
	public static inline var H = 720;
	public static inline var Q = 256;

	public var state = "title";
	public var tick = 0;
	public var score = 0;
	public var best = 0;
	public var lives = 3;
	public var wave = 0;
	public var ship = new Body(W * Q >> 1, H * Q >> 1, 0, 0, 12, 0, 192);
	public var rocks:Array<Body> = [];

	// The title screen's drifting rocks: dressing only, from a generator of their own, never part of a game (play starts from a fresh field).
	public var attract:Array<Body> = [];

	var attractRng = 0x2545f491;

	public var bullets:Array<Body> = [];
	public var particles:Array<Body> = [];
	public var hits = 0;
	public var splits = 0;
	public var shots = 0;
	public var deaths = 0;
	public var sounds:Array<Int> = [];
	public var invulnerable = 0;
	public var cooldown = 0;
	public var respawnDelay = 0;
	public var waveDelay = 0;
	public var thrusting = false;

	var rng:Int;
	var seed:Int;
	var startDown = false;
	var turnFraction = 0;

	public function new(seed:Int = 12345) {
		this.seed = seed;
		rng = seed == 0 ? 1 : seed;
		titleField();
	}

	public function random(max:Int):Int {
		rng ^= rng << 13;
		rng ^= rng >>> 17;
		rng ^= rng << 5;
		return (rng & 0x7fffffff) % max;
	}

	public static inline function wrap(value:Int, size:Int):Int {
		var n = value % size;
		return n < 0 ? n + size : n;
	}

	public static function near(a:Body, b:Body, r:Int):Bool {
		var dx = Math.abs(a.x - b.x), dy = Math.abs(a.y - b.y);
		dx = Math.min(dx, W * Q - dx);
		dy = Math.min(dy, H * Q - dy);
		var radius = r * Q * 1.;
		return dx * dx + dy * dy < radius * radius;
	}

	public static function radius(size:Int):Int
		return size == 3 ? 44 : size == 2 ? 24 : 12;

	public static function collisionRadius(size:Int):Int
		return size == 3 ? 40 : size == 2 ? 21 : 11;

	function makeRock(size:Int, x:Int, y:Int, angle:Int = -1):Body {
		if (angle < 0)
			angle = random(256);
		var speed = (size == 3 ? 50 : size == 2 ? 90 : 140) * (70 + random(61)) / 100.,
			velocity = Std.int(speed * Q / 60);
		var rock = new Body(x, y, Std.int(Trig.cos[angle] * velocity / 1024), Std.int(Trig.sin[angle] * velocity / 1024), size, 0, random(256));
		for (i in 0...10)
			rock.shape.push(74 + random(35));
		return rock;
	}

	function titleField():Void {
		rocks = [];
		bullets = [];
		particles = [];
		thrusting = false;
		// The dressing's own generator: the game's isn't touched, so when play starts doesn't matter.
		var gameRng = rng;
		rng = attractRng;
		attract = [for (_ in 0...6) makeRock(3, random(W) * Q, random(H) * Q)];
		attractRng = rng;
		rng = gameRng;
	}

	public function reset():Void {
		rng = seed == 0 ? 1 : seed;
		score = 0;
		lives = 3;
		wave = 0;
		rocks = [];
		attract = [];
		bullets = [];
		particles = [];
		hits = 0;
		splits = 0;
		shots = 0;
		deaths = 0;
		tick = 0;
		cooldown = 0;
		respawnDelay = 0;
		waveDelay = 0;
		state = "playing";
		respawn();
		nextWave();
		sounds.push(0);
	}

	public function respawn():Void {
		ship.x = W * Q >> 1;
		ship.y = H * Q >> 1;
		ship.vx = 0;
		ship.vy = 0;
		ship.angle = 192;
		turnFraction = 0;
		invulnerable = 120;
	}

	public function nextWave():Void {
		wave++;
		waveDelay = 0;
		for (_ in 0...3 + wave) {
			var side = random(4),
				x = side == 0 ? 0 : side == 1 ? W * Q : random(W) * Q,
				y = side == 2 ? 0 : side == 3 ? H * Q : random(H) * Q;
			rocks.push(makeRock(3, wrap(x, W * Q), wrap(y, H * Q)));
		}
	}

	public function addScore(points:Int):Void {
		var before = Std.int(score / 10000);
		score += points;
		if (Std.int(score / 10000) > before) {
			lives++;
			sounds.push(5);
		}
	}

	public function burst(x:Int, y:Int, n:Int, flame:Bool = false):Void {
		for (_ in 0...n) {
			var angle = flame ? wrap(ship.angle + 128 + random(25) - 12, 256) : random(256),
				velocity = flame ? 500 + random(250) : 200 + random(550);
			var particle = new Body(x, y, Std.int(Trig.cos[angle] * velocity / 1024), Std.int(Trig.sin[angle] * velocity / 1024), flame ? 0 : 1,
				flame ? 7 + random(12) : 24 + random(37));
			particles.push(particle);
		}
	}

	static function move(body:Body):Void {
		body.x = wrap(body.x + body.vx, W * Q);
		body.y = wrap(body.y + body.vy, H * Q);
	}

	function splitRock(index:Int):Void {
		var rock = rocks[index];
		rocks.splice(index, 1);
		hits++;
		addScore(rock.size == 3 ? 20 : rock.size == 2 ? 50 : 100);
		burst(rock.x, rock.y, rock.size == 3 ? 40 : rock.size == 2 ? 24 : 14);
		sounds.push(rock.size == 3 ? 2 : rock.size == 2 ? 3 : 4);
		if (rock.size > 1) {
			splits++;
			var angle = random(256);
			rocks.push(makeRock(rock.size - 1, rock.x, rock.y, angle));
			rocks.push(makeRock(rock.size - 1, rock.x, rock.y, wrap(angle + 77 + random(103), 256)));
		}
	}

	public function step(input:Controls):Void {
		sounds.resize(0);
		thrusting = false;
		if (input.title && state == "gameover") {
			state = "title";
			titleField();
		}
		if (input.start && !startDown && state != "playing")
			reset();
		startDown = input.start;
		if (state != "playing") {
			for (rock in rocks.concat(attract)) {
				move(rock);
				rock.angle = wrap(rock.angle + 1, 256);
			}
			return;
		}
		tick++;
		if (cooldown > 0)
			cooldown--;
		if (respawnDelay > 0) {
			respawnDelay--;
			if (respawnDelay == 0)
				respawn();
		}
		if (respawnDelay == 0) {
			if (invulnerable > 0)
				invulnerable--;
			var turn = (input.right ? 1 : 0) - (input.left ? 1 : 0);
			turnFraction += turn * 730;
			var delta = Std.int(turnFraction / 256);
			turnFraction -= delta * 256;
			ship.angle = wrap(ship.angle + delta, 256);
			thrusting = input.thrust;
			if (thrusting) {
				ship.vx += Std.int(Trig.cos[ship.angle] * 30 / 1024);
				ship.vy += Std.int(Trig.sin[ship.angle] * 30 / 1024);
				burst(ship.x - Std.int(Trig.cos[ship.angle] * 12 * Q / 1024), ship.y - Std.int(Trig.sin[ship.angle] * 12 * Q / 1024), tick % 6 == 0 ? 2 : 1,
					true);
			}
			ship.vx = Std.int(ship.vx * 254.5 / 256);
			ship.vy = Std.int(ship.vy * 254.5 / 256);
			var speed = Math.sqrt(ship.vx * ship.vx + ship.vy * ship.vy),
				limit = 420 * Q / 60.;
			if (speed > limit) {
				ship.vx = Std.int(ship.vx * limit / speed);
				ship.vy = Std.int(ship.vy * limit / speed);
			}
			move(ship);
			if (input.fire && cooldown == 0 && bullets.length < 6) {
				var dx = Trig.cos[ship.angle], dy = Trig.sin[ship.angle];
				bullets.push(new Body(wrap(ship.x + Std.int(dx * 18 * Q / 1024), W * Q), wrap(ship.y + Std.int(dy * 18 * Q / 1024), H * Q),
					ship.vx + Std.int(dx * 2390 / 1024), ship.vy + Std.int(dy * 2390 / 1024), 2, 60));
				cooldown = 10;
				shots++;
				sounds.push(1);
			}
		}
		for (rock in rocks) {
			move(rock);
			rock.angle = wrap(rock.angle + 1, 256);
		}
		var i = bullets.length - 1;
		while (i >= 0) {
			var bullet = bullets[i];
			move(bullet);
			bullet.life--;
			var hit = -1;
			for (j in 0...rocks.length)
				if (near(bullet, rocks[j], collisionRadius(rocks[j].size) + 3)) {
					hit = j;
					break;
				}
			if (hit >= 0) {
				splitRock(hit);
				bullets.splice(i, 1);
			} else if (bullet.life <= 0)
				bullets.splice(i, 1);
			i--;
		}
		if (respawnDelay == 0 && invulnerable == 0)
			for (j in 0...rocks.length)
				if (near(ship, rocks[j], collisionRadius(rocks[j].size) + 12)) {
					burst(ship.x, ship.y, 40);
					sounds.push(2);
					deaths++;
					lives--;
					splitRock(j);
					thrusting = false;
					if (lives <= 0) {
						state = "gameover";
						best = Std.int(Math.max(best, score));
						sounds.push(6);
					} else
						respawnDelay = 120;
					break;
				}
		i = particles.length - 1;
		while (i >= 0) {
			var p = particles[i];
			move(p);
			p.life--;
			if (p.life <= 0)
				particles.splice(i, 1);
			i--;
		}
		if (rocks.length == 0 && state == "playing") {
			waveDelay++;
			if (waveDelay >= 90)
				nextWave();
		} else
			waveDelay = 0;
	}

	public function probe(name:String):Dynamic
		return switch (name) {
			case "state": state;
			case "score": score;
			case "best": best;
			case "lives": lives;
			case "wave": wave;
			case "shots": shots;
			case "deaths": deaths;
			case "hits": hits;
			default: throw 'Unknown probe ' + name;
		};

	public function snapshot():Dynamic
		return {
			state: state,
			tick: tick,
			score: score,
			best: best,
			lives: lives,
			wave: wave,
			rng: rng,
			invulnerable: invulnerable,
			cooldown: cooldown,
			respawnDelay: respawnDelay,
			waveDelay: waveDelay,
			turnFraction: turnFraction,
			thrusting: thrusting,
			hits: hits,
			splits: splits,
			shots: shots,
			deaths: deaths,
			ship: [ship.x, ship.y, ship.vx, ship.vy, ship.angle],
			rocks: [for (r in rocks) [r.x, r.y, r.vx, r.vy, r.size, r.angle].concat(r.shape)],
			bullets: [for (b in bullets) [b.x, b.y, b.vx, b.vy, b.life]],
			particles: [for (p in particles) [p.x, p.y, p.vx, p.vy, p.size, p.life, p.lifetime]]
		};
}
