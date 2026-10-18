import helix.behavior.Behavior;
import helix.render3d.Node3D;

/** The race on its node: a countdown, then racing; the laps counted from the checkpoints' reports (Checkpoint tells it an index as the
	car comes within its radius; only the next index counts, so each is passed once a lap, and passing 0 after every other ends a lap),
	the lap's time from the pass's dt, the best lap kept. The checkpoints register their indices as they start, so the race knows how many
	there are without being told. Its state is what the example's autopilot probes. The car (car, the node the Car behavior drives) is
	exposed for the checkpoints. A checkpoint or the car reaches the race from its node reference ("@race" in the file) through the pass
	they share, `pass.on(race, Race)`: no static, no lookup through the node. It runs in Simulate, as the clock the world moves by: its
	countdown frees the car (added after it in the file) the same frame, and the checkpoints report to it in Resolve, after the lap's time
	has taken the frame's dt. */
class Race extends Behavior {
	/** The node the car is on: what the checkpoints measure their distance to. */
	@:prop public var car:Node3D = null;

	/** Seconds from the start until the car may move. */
	@:prop @:range(0, 60) public var countdown = 3.;

	/** "countdown" until the countdown runs out, then "racing". */
	public var state(default, null) = "countdown";

	/** Whether the car may move: the countdown has run out. */
	public var racing(get, never):Bool;

	function get_racing():Bool
		return state == "racing";

	/** Seconds of countdown left; 0 once racing. */
	public var remaining(default, null) = 0.;

	/** The lap being driven, from 1. */
	public var lap(default, null) = 1;

	/** The next checkpoint's index: 1 as a lap starts, 0 once every other has been passed. */
	public var checkpoint(default, null) = 1;

	/** Checkpoints passed in all, every lap counted. */
	public var passed(default, null) = 0;

	/** Seconds since the lap started. */
	public var lapTime(default, null) = 0.;

	/** The best lap's seconds; 0 until a lap is done. */
	public var bestLap(default, null) = 0.;

	/** How many checkpoints there are: one more than the largest index registered. */
	public var checkpointCount(default, null) = 0;

	/** Begins the countdown. */
	override public function start():Void {
		remaining = countdown;
		state = remaining > 0 ? "countdown" : "racing";
	}

	/** The countdown, then the lap's time. */
	override public function update(dt:Float):Void {
		if (state == "countdown") {
			remaining -= dt;
			if (remaining <= 0) {
				remaining = 0;
				state = "racing";
			}
			return;
		}
		lapTime += dt;
	}

	/** A checkpoint of index index exists: counts it in. */
	public function register(index:Int):Void {
		if (index + 1 > checkpointCount)
			checkpointCount = index + 1;
	}

	/** The car is at the checkpoint of index index. True when it was the next one: it counts, and reaching 0 after every other ends the
		lap (the time kept as the best when it is). False, nothing changed, for any other index or before the race runs. */
	public function reach(index:Int):Bool {
		if (!racing || index != checkpoint || checkpointCount == 0)
			return false;
		passed++;
		if (index == 0) {
			if (bestLap == 0 || lapTime < bestLap)
				bestLap = lapTime;
			lapTime = 0;
			lap++;
		}
		checkpoint = (index + 1) % checkpointCount;
		return true;
	}
}
