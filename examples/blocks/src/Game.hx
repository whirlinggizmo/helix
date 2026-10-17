import helix.math.Random;

/** One tick's requests, from keyboard, touch or a script. */
class Actions {
	public var start = false;
	public var pause = false;
	public var left = 0;
	public var right = 0;
	public var softDrop = false;
	public var dropRows = 0;
	public var rotateClockwise = false;
	public var rotateCounter = false;
	public var hardDrop = false;
	public var hold = false;

	public function new() {}

	public function clear():Void {
		start = pause = softDrop = rotateClockwise = rotateCounter = hardDrop = hold = false;
		left = right = dropRows = 0;
	}
}

/** Fixed-step falling-blocks rules: a 10x20 field with two hidden rows above it, seven-piece bags, hold, lock delay and line clears. */
class Game {
	public static inline var W = 10;
	public static inline var H = 22;
	public static inline var HIDDEN = 2;
	public static inline var LOCK_TICKS = 30;
	public static inline var LOCK_RESETS = 15;
	public static inline var CLEAR_TICKS = 20;
	public static inline var SPAWN_TICKS = 6;
	// Rows per tick, in 1/65536ths, for levels 1-20: the common guideline curve.
	static final gravity = [
		1092, 1377, 1768, 2311, 3075, 4169, 5759, 8107, 11634, 17026, 25416, 38709, 60169, 95483, 154742, 256187, 433425, 749597, 1325716, 1441792
	];

	/** title, playing, paused or over. */
	public var state = "title";

	public var tick = 0;
	public var board:Array<Int> = [for (_ in 0...W * H) 0];
	public var piece = -1;
	public var rotation = 0;
	public var px = 0;
	public var py = 0;
	public var held = -1;
	public var holdUsed = false;
	public var queue:Array<Int> = [];
	public var score = 0;
	public var best = 0;
	public var lines = 0;
	public var level = 1;
	public var combo = -1;
	public var backToBack = false;
	public var pieces = 0;
	public var clearing:Array<Int> = [];
	public var clearTimer = 0;
	public var spawnTimer = 0;
	public var lockTimer = 0;
	public var lockResets = 0;
	public var fall = 0;
	public var lowest = 0;

	/** Sound events this tick: move, rotate, lock, drop, clear, four, level, over, hold, start. */
	public var events:Array<String> = [];

	var rng:Random;
	var seed:Int;

	public function new(seed = 12345) {
		this.seed = seed;
		rng = new Random(seed);
	}

	function refill():Void {
		while (queue.length < 7) {
			queue = queue.concat(rng.shuffle([0, 1, 2, 3, 4, 5, 6]));
		}
	}

	public function cell(x:Int, y:Int):Int
		return board[y * W + x];

	public function fits(kind:Int, turn:Int, x:Int, y:Int):Bool {
		var c = Pieces.cells[kind][turn];
		for (i in 0...4) {
			var cx = x + c[i * 2], cy = y + c[i * 2 + 1];
			if (cx < 0 || cx >= W || cy < 0 || cy >= H || board[cy * W + cx] != 0)
				return false;
		}
		return true;
	}

	public function ghostY():Int {
		var y = py;
		while (fits(piece, rotation, px, y + 1))
			y++;
		return y;
	}

	public function reset():Void {
		rng.setSeed(seed);
		board = [for (_ in 0...W * H) 0];
		queue = [];
		held = -1;
		holdUsed = false;
		score = 0;
		lines = 0;
		level = 1;
		combo = -1;
		backToBack = false;
		pieces = 0;
		clearing = [];
		tick = 0;
		state = "playing";
		refill();
		events.push("start");
		spawn(next());
	}

	function next():Int {
		var kind = queue.shift();
		refill();
		return kind;
	}

	function spawn(kind:Int):Void {
		piece = kind;
		rotation = 0;
		px = 3;
		py = 0;
		lockTimer = 0;
		lockResets = 0;
		fall = 0;
		if (!fits(piece, rotation, px, py)) {
			gameOver();
			return;
		}
		if (fits(piece, rotation, px, py + 1))
			py++;
		lowest = py;
	}

	function gameOver():Void {
		state = "over";
		piece = -1;
		if (score > best)
			best = score;
		events.push("over");
	}

	function onGround():Bool
		return !fits(piece, rotation, px, py + 1);

	/** A successful move or turn on the ground restarts the lock delay, a limited number of times. */
	function moved():Void {
		if (onGround() && lockResets < LOCK_RESETS) {
			lockTimer = 0;
			lockResets++;
		}
	}

	function shift(dx:Int):Bool {
		if (!fits(piece, rotation, px + dx, py))
			return false;
		px += dx;
		moved();
		events.push("move");
		return true;
	}

	function rotate(clockwise:Bool):Void {
		var to = (rotation + (clockwise ? 1 : 3)) % 4, kicks = Pieces.kicks(piece, rotation, clockwise), i = 0;
		while (i < kicks.length) {
			if (fits(piece, to, px + kicks[i], py + kicks[i + 1])) {
				px += kicks[i];
				py += kicks[i + 1];
				rotation = to;
				moved();
				events.push("rotate");
				return;
			}
			i += 2;
		}
	}

	function drop(rows:Int, points:Int):Int {
		var n = 0;
		while (n < rows && fits(piece, rotation, px, py + 1)) {
			py++;
			n++;
		}
		score += n * points;
		if (py > lowest) {
			lowest = py;
			lockResets = 0;
		}
		return n;
	}

	function lock():Void {
		var c = Pieces.cells[piece][rotation], above = true;
		for (i in 0...4) {
			var x = px + c[i * 2], y = py + c[i * 2 + 1];
			board[y * W + x] = piece + 1;
			if (y >= HIDDEN)
				above = false;
		}
		pieces++;
		piece = -1;
		holdUsed = false;
		events.push("lock");
		if (above) {
			gameOver();
			return;
		}
		clearing = [for (y in 0...H) if (isFull(y)) y];
		if (clearing.length > 0) {
			clearTimer = CLEAR_TICKS;
			award(clearing.length);
		} else {
			combo = -1;
			spawnTimer = SPAWN_TICKS;
		}
	}

	function isFull(y:Int):Bool {
		for (x in 0...W)
			if (board[y * W + x] == 0)
				return false;
		return true;
	}

	function award(count:Int):Void {
		var points = [0, 100, 300, 500, 800][count] * level;
		if (count == 4) {
			if (backToBack)
				points = Std.int(points * 1.5);
			backToBack = true;
		} else
			backToBack = false;
		combo++;
		if (combo > 0)
			points += 50 * combo * level;
		score += points;
		var before = level;
		lines += count;
		level = Std.int(Math.min(20, 1 + lines / 10));
		events.push(count == 4 ? "four" : "clear");
		if (level > before)
			events.push("level");
	}

	function collapse():Void {
		for (y in clearing) {
			var row = y;
			while (row > 0) {
				for (x in 0...W)
					board[row * W + x] = board[(row - 1) * W + x];
				row--;
			}
			for (x in 0...W)
				board[x] = 0;
		}
		clearing = [];
		spawn(next());
	}

	public function step(a:Actions):Void {
		events.resize(0);
		if (state == "title" || state == "over") {
			if (a.start)
				reset();
			return;
		}
		if (a.pause) {
			state = state == "paused" ? "playing" : "paused";
			return;
		}
		if (state == "paused") {
			if (a.start)
				state = "playing";
			return;
		}
		tick++;
		if (clearing.length > 0) {
			clearTimer--;
			if (clearTimer <= 0)
				collapse();
			return;
		}
		if (piece < 0) {
			spawnTimer--;
			if (spawnTimer <= 0)
				spawn(next());
			return;
		}
		if (a.hold && !holdUsed) {
			var kind = piece;
			holdUsed = true;
			events.push("hold");
			if (held < 0) {
				held = kind;
				spawn(next());
			} else {
				var swap = held;
				held = kind;
				spawn(swap);
			}
			return;
		}
		if (a.rotateClockwise)
			rotate(true);
		if (a.rotateCounter)
			rotate(false);
		for (_ in 0...a.left)
			if (!shift(-1))
				break;
		for (_ in 0...a.right)
			if (!shift(1))
				break;
		if (a.hardDrop) {
			drop(H, 2);
			events.push("drop");
			lock();
			return;
		}
		if (a.dropRows > 0)
			drop(a.dropRows, 1);
		var g = gravity[level - 1];
		if (a.softDrop)
			g = Std.int(Math.max(g * 20, 32768));
		fall += g;
		var rows = fall >> 16;
		fall &= 0xffff;
		if (rows > 0) {
			var n = drop(rows, a.softDrop ? 1 : 0);
			if (n < rows)
				fall = 0;
		}
		if (onGround()) {
			lockTimer++;
			if (lockTimer >= LOCK_TICKS)
				lock();
		} else
			lockTimer = 0;
	}

	public function probe(name:String):Dynamic
		return switch (name) {
			case "state": state;
			case "score": score;
			case "lines": lines;
			case "level": level;
			case "pieces": pieces;
			case "held": held;
			case "piece": piece;
			case "x": px;
			case "rotation": rotation;
			default: throw 'Unknown probe ' + name;
		};

	public function snapshot():Dynamic
		return {
			state: state,
			tick: tick,
			score: score,
			best: best,
			lines: lines,
			level: level,
			pieces: pieces,
			piece: piece,
			rotation: rotation,
			x: px,
			y: py,
			held: held,
			queue: queue.slice(0, 3),
			board: board.join("")
		};
}
