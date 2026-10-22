package helix.render2d;

/** Plays a SpriteSheet's animations: which frame shows, each for its own duration, in its animation's direction, looping or once. Call update
	once a frame; frame is the sheet's frame to draw (Batch2D.sheetFrame), and a sprite given to it shows that frame itself. entered says
	which of the animation's frames the last update reached, a footstep's sound on the frame its foot lands. */
class SpriteAnimator {
	var playing:Null<SpriteAnimation>;
	var playingName:Null<String>;
	// The animation's frames (their places in it) in the order shown: one turn of a ping-pong, both ways (back to its first when played once).
	var order:Array<Int> = [];
	var step = 0;
	var elapsed = 0.;
	var looping = true;
	var done = false;
	var reloads = 0;
	// By place in the animation: whether the last update (or play) reached it.
	var reached:Array<Bool> = [];

	/** Plays sheet's animations, showing each frame on sprite as it changes when one is given. */
	public function new(sheet:SpriteSheet, ?sprite:Sprite2D) {
		this.sheet = sheet;
		this.sprite = sprite;
		reloads = sheet.reloadCount;
	}

	/** The sheet it plays. */
	public var sheet(default, null):SpriteSheet;

	/** The sprite showing its frame, or null. */
	public var sprite:Null<Sprite2D>;

	/** How fast time runs: 1 as the sheet's durations say, 2 twice as fast, 0 held. Below 0, or not finite, is taken as 0. */
	public var speed(default, set):Float = 1.;

	function set_speed(value:Float):Float
		return speed = value > 0 && Math.isFinite(value) ? value : 0.;

	/** The animation playing (or finished and holding its last frame), or null. */
	public var animation(get, never):Null<SpriteAnimation>;

	function get_animation():Null<SpriteAnimation>
		return playing;

	/** The sheet's frame showing, by index (SpriteSheet.getFrame), or -1 with no animation. */
	public var frame(get, never):Int;

	function get_frame():Int
		return playing == null ? -1 : playing.frames[order[step]];

	/** The frame showing by its place in the animation (0 its first), or -1 with no animation. */
	public var frameIndex(get, never):Int;

	function get_frameIndex():Int
		return playing == null ? -1 : order[step];

	/** Whether an animation played once has reached its end (it holds its last frame); false while one loops, or with none. */
	public var finished(get, never):Bool;

	function get_finished():Bool
		return done;

	/** Plays the sheet's animation named name from its start, looping or once; playing the one already playing (not finished) goes on where it
		is, looping as now asked. False, changing nothing, for a name the sheet hasn't. */
	public function play(name:String, loop = true):Bool {
		var next = sheet.findAnimation(name);
		if (next == null)
			return false;
		looping = loop;
		if (next == playing && !done)
			return true;
		start(next);
		return true;
	}

	/** Stops: no animation, no frame (a sprite keeps the frame it shows). */
	public function stop():Void {
		playing = null;
		playingName = null;
		done = false;
		reached.resize(0);
	}

	/** Whether the last update (or the play that started it) reached the animation's frame at index (its place in the animation, 0 its first),
		though a long update may have passed it already. */
	public function entered(index:Int):Bool
		return index >= 0 && index < reached.length && reached[index];

	/** Advances time by seconds (times speed): the frames whose durations it passes go by, an animation played once stops on its last. */
	public function update(seconds:Float):Void {
		if (playing != null && sheet.reloadCount != reloads)
			refind();
		for (i in 0...reached.length)
			reached[i] = false;
		if (playing == null || done)
			return;
		elapsed += Math.isFinite(seconds) && seconds > 0 ? seconds * speed : 0;
		var before = step;
		while (elapsed >= duration(step)) {
			elapsed -= duration(step);
			if (step + 1 < order.length)
				step++;
			else if (looping)
				step = 0;
			else {
				done = true;
				elapsed = 0;
				break;
			}
			reached[order[step]] = true;
		}
		if (step != before)
			show();
	}

	function start(next:SpriteAnimation):Void {
		playing = next;
		playingName = next.name;
		var n = next.frames.length;
		order = switch next.direction {
			case Forward: [for (i in 0...n) i];
			case Reverse: [for (i in 0...n) n - 1 - i];
			case PingPong: [for (i in 0...n) i].concat([for (i in 1...n - 1) n - 1 - i]);
			case PingPongReverse: [for (i in 0...n) n - 1 - i].concat([for (i in 1...n - 1) i]);
		};
		// Played once, a ping-pong ends where it began.
		if (!looping && n > 1 && (next.direction == PingPong || next.direction == PingPongReverse))
			order.push(order[0]);
		step = 0;
		elapsed = 0;
		done = false;
		reached = [for (_ in 0...n) false];
		reached[order[0]] = true;
		show();
	}

	// How long the frame at step shows; at least a millisecond, so frames of no duration can't hold an update.
	function duration(at:Int):Float {
		var seconds = sheet.getFrame(playing.frames[order[at]]).duration;
		return seconds > .001 ? seconds : .001;
	}

	// The sheet read its file again: the animation found again by name (stopped if it's gone), from its start if its frames changed.
	function refind():Void {
		reloads = sheet.reloadCount;
		var next = sheet.findAnimation(playingName);
		if (next == null) {
			stop();
			return;
		}
		var at = step, time = elapsed, wasDone = done;
		start(next);
		if (at < order.length) {
			step = at;
			elapsed = time;
			done = wasDone;
			show();
		}
	}

	function show():Void
		if (sprite != null)
			sprite.setFrame(sheet, frame);
}
