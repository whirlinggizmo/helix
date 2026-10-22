package helix.decal;

import helix.graphics.Color;
import helix.scene.Flow;

/** What Decals2D and Decals3D share: their marks in the order put down, each one's tint as placed and its age, and how each fades: by how
	soon the pool comes round to it (fadeCount) and, given a life, by its age on the game's clock (lifeSeconds, then fadeSeconds), taken up
	once faded out. It runs itself while a mark is ageing (Flow), on the game's clock, so a paused game's marks stay as they are. */
@:noCompletion
class DecalPool<T> {
	/** A pool of capacity (at least 1) marks, tinting one by tint and taking one up (off its node, kept for reuse) by takeUp. */
	public function new(capacity:Int, tint:(T, Int) -> Void, takeUp:T->Void) {
		this.capacity = capacity > 1 ? capacity : 1;
		fadeCount = Std.int(this.capacity / 4);
		this.tint = tint;
		this.takeUp = takeUp;
	}

	/** How many it holds before the oldest is put down again. */
	public var capacity(default, null):Int;

	/** The marks down, oldest first. */
	public var marks(default, null):Array<T> = [];

	/** The marks taken up, to put down again. */
	public var spare(default, null):Array<T> = [];

	/** As Decals2D's and Decals3D's. */
	public var fadeCount(default, set):Int;

	function set_fadeCount(value:Int):Int {
		fadeCount = value > 0 ? (value < capacity ? value : capacity) : 0;
		return fadeCount;
	}

	/** As Decals2D's and Decals3D's. */
	public var lifeSeconds(default, set):Float = 0;

	function set_lifeSeconds(value:Float):Float {
		lifeSeconds = value > 0 ? value : 0;
		follow();
		return lifeSeconds;
	}

	/** As Decals2D's and Decals3D's. */
	public var fadeSeconds(default, set):Float = .5;

	function set_fadeSeconds(value:Float):Float {
		fadeSeconds = value > 0 ? value : 0;
		return fadeSeconds;
	}

	var tint:(T, Int) -> Void;
	var takeUp:T->Void;
	var tints:Array<Int> = [];
	var ages:Array<Float> = [];
	var following = false;

	/** The mark to put down next: a spare one, else the oldest taken up (null while there's room for a new one). */
	public function next():Null<T> {
		if (spare.length > 0)
			return spare.pop();
		if (marks.length < capacity)
			return null;
		tints.shift();
		ages.shift();
		return marks.shift();
	}

	/** Puts mark down as the newest, placed tinted placedTint (0xAARRGGBB), and fades the line. */
	public function add(mark:T, placedTint:Int):Void {
		marks.push(mark);
		tints.push(placedTint);
		ages.push(0);
		fade();
		follow();
	}

	/** Takes every mark up. */
	public function clear():Void {
		for (mark in marks) {
			takeUp(mark);
			spare.push(mark);
		}
		marks = [];
		tints = [];
		ages = [];
	}

	/** Ages every mark by seconds on the game's clock, taking up those faded out, and fades the line: what its step does each frame. */
	public function age(seconds:Float):Void {
		if (!(seconds > 0) || lifeSeconds <= 0)
			return;
		for (i in 0...ages.length)
			ages[i] += seconds;
		// The oldest go first: they're the first to have lived out their life.
		while (ages.length > 0 && ages[0] >= lifeSeconds + fadeSeconds) {
			var mark = marks.shift();
			tints.shift();
			ages.shift();
			takeUp(mark);
			spare.push(mark);
		}
		fade();
	}

	// Each mark's tint: faded by how soon the pool comes round to it and by its age past its life, the rest as placed.
	function fade():Void {
		var free = capacity - marks.length;
		for (i in 0...marks.length) {
			var soon = free + i,
				amount = soon < fadeCount ? (soon + 1) / (fadeCount + 1) : 1.;
			if (lifeSeconds > 0 && ages[i] > lifeSeconds)
				amount *= fadeSeconds > 0 ? 1 - (ages[i] - lifeSeconds) / fadeSeconds : 0;
			var placed = tints[i];
			tint(marks[i], amount >= 1 ? placed : Color.withAlpha(placed, Math.round(Color.getAlpha(placed) * (amount > 0 ? amount : 0))));
		}
	}

	// Ages the marks each frame while any has a life to live out, on the game's clock (the frames' outside a running program: a test).
	function follow():Void {
		if (following || lifeSeconds <= 0 || marks.length == 0)
			return;
		following = true;
		Flow.run(dt -> {
			var clock = helix.time.Time.clock;
			age(clock != null ? clock.delta : dt);
			following = lifeSeconds > 0 && marks.length > 0;
			return following;
		});
	}
}
