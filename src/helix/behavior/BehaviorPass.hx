package helix.behavior;

import helix.render3d.Node3D;

/** A pass that runs behaviors: add puts a behavior on a node, update each frame starts the ones added since the last update (in order, so
	a scene file can attach many and they start together), then updates each enabled one whose node runs (enabled and not paused, with
	every node above it: a disabled or paused group stops what's under it, Node.paused) phase by phase, Input, Simulate, Resolve, Late
	(Phase, the class's `@:phase`), each phase's in the order added, then stops and drops the ones done. The program's one is Behaviors,
	run by the runner after the app's update and before the frame is drawn (docs/DISPLAY_MODEL.md); a test makes its own and updates it.
	Adding, removing and clearing inside a behavior's start, update or stop are safe: the pass walks copies, and a change takes effect
	from the next step.

	Behaviors don't signal each other. One that decides across entities is a resolver (a Combat in Resolve, found with find): the others
	report to it or queue on it, and it gathers what has a say on an entity with allUnder (gear on the entity's child nodes implementing
	an interface, an IDamageModifier) and applies them in an order of its own, so the order lives in one place a test can read. */
@:build(helix.macro.Facade.record())
class BehaviorPass {
	// The program's pass, made at its first use and updated by the runner each frame with the game's clock (an optional part).
	@:allow(helix.behavior.Behaviors)
	static function install():BehaviorPass {
		return helix.host.Host.installPart(runner -> {
			var pass = new BehaviorPass();
			runner.install({
				update: dt -> pass.update(dt),
				shutdown: () -> {
					pass.clear();
					Behaviors.bind(null);
				}
			});
			pass;
		});
	}

	// The started ones, a list per phase in Phase's order, each in the order added; and the ones added since the last update, not yet
	// started.
	var active:Array<Array<Behavior>> = lists();
	var pending:Array<Behavior> = [];

	/** No behaviors yet. */
	public function new() {}

	/** Puts behavior on node: it starts on the next update. False, changing nothing, for one already in a pass (this or another) or a
		null node. */
	public function add(behavior:Behavior, node:Node3D):Bool {
		if (behavior.pass != null || node == null)
			return false;
		behavior.pass = this;
		behavior.node = node;
		behavior.done = false;
		pending.push(behavior);
		return true;
	}

	/** Takes behavior out: stopped first if it had started. False when it isn't in this pass. */
	public function remove(behavior:Behavior):Bool {
		if (behavior.pass != this)
			return false;
		var started = false;
		for (list in active)
			if (list.remove(behavior))
				started = true;
		if (started)
			end(behavior);
		else {
			pending.remove(behavior);
			drop(behavior);
		}
		return true;
	}

	/** How many it holds: started, or waiting for the next update to start. */
	public var count(get, never):Int;

	function get_count():Int {
		var n = pending.length;
		for (list in active)
			n += list.length;
		return n;
	}

	/** The first behavior of class cls (or a subclass) in it, started ones first (by phase, then in the order added), or null. */
	public function find<T:Behavior>(cls:Class<T>):Null<T> {
		for (b in all())
			if (Std.isOfType(b, cls))
				return cast b;
		return null;
	}

	/** Every behavior of class cls (or a subclass) in it, started ones first (by phase, then in the order added). */
	public function findAll<T:Behavior>(cls:Class<T>):Array<T> {
		return [for (b in all()) if (Std.isOfType(b, cls)) cast b];
	}

	/** The first behavior of class cls (or a subclass) on node, started ones first (by phase, then in the order added), or null: how a
		behavior given a node reference reaches the behavior on it. */
	public function on<T:Behavior>(node:Node3D, cls:Class<T>):Null<T> {
		for (b in all())
			if (b.node == node && Std.isOfType(b, cls))
				return cast b;
		return null;
	}

	/** The behaviors on node, started ones first (by phase, then in the order added). */
	public function of(node:Node3D):Array<Behavior> {
		return [for (b in all()) if (b.node == node) b];
	}

	/** Every behavior of class or interface cls on node or on a node under it, started ones first (by phase, then in the order added),
		then the pending: how a resolver gathers what has a say on an entity, the gear on its child nodes implementing an interface
		(`allUnder(target, IDamageModifier)`). Each behavior's node is walked up to node; the tree isn't walked down. */
	public function allUnder<T>(node:Node3D, cls:Class<T>):Array<T> {
		var found:Array<T> = [];
		if (node == null)
			return found;
		for (b in all())
			if (Std.isOfType(b, cls) && isUnder(b.node, node))
				found.push(cast b);
		return found;
	}

	/** Takes every behavior out, stopping each started one (by phase, then in the order added). */
	public function clear():Void {
		var ending = active, waiting = pending;
		active = lists();
		pending = [];
		for (list in ending)
			for (b in list)
				end(b);
		for (b in waiting)
			drop(b);
	}

	/** A frame: starts the ones added since the last update, updates the enabled ones under enabled nodes by dt seconds (a clock's delta),
		every Input one, then every Simulate, Resolve and Late one, each phase's in the order added; then stops and drops the ones done.
		Once a frame. */
	public function update(dt:Float):Void {
		var starting = pending;
		pending = [];
		for (b in starting) {
			// Removed before it started, from an earlier start.
			if (b.pass != this)
				continue;
			active[(b.phase : Int)].push(b);
			b.start();
		}
		for (phase in 0...PHASES)
			for (b in active[phase].copy()) {
				if (b.pass != this || b.done)
					continue;
				if (b.enabled && runs(b.node))
					b.update(dt);
			}
		for (phase in 0...PHASES) {
			var kept = [];
			for (b in active[phase].copy()) {
				if (b.pass != this)
					continue;
				if (b.done)
					end(b);
				else
					kept.push(b);
			}
			// Those a stop removed are out already; a clear emptied the lists, and what was added since is pending.
			active[phase] = kept.filter(b -> b.pass == this);
		}
	}

	// How many phases there are: one list each.
	static inline var PHASES = (Phase.Late : Int) + 1;

	static function lists():Array<Array<Behavior>>
		return [for (_ in 0...PHASES) []];

	// The started ones by phase, then the pending, as one list.
	function all():Array<Behavior> {
		var found = [];
		for (list in active)
			for (b in list)
				found.push(b);
		for (b in pending)
			found.push(b);
		return found;
	}

	// Whether at is node or under it.
	static function isUnder(at:Null<Node3D>, node:Node3D):Bool {
		while (at != null) {
			if (at == node)
				return true;
			at = at.parent;
		}
		return false;
	}

	// Whether node and every node above it run: enabled and not paused. A node doesn't know its ancestors' flags, so they're walked.
	static function runs(node:Null<Node3D>):Bool {
		var at = node;
		while (at != null) {
			if (!at.enabled || at.paused)
				return false;
			at = at.parent;
		}
		return true;
	}

	// Ends a started one: out of the pass, then stop with its node still set.
	function end(behavior:Behavior):Void {
		behavior.pass = null;
		behavior.stop();
		behavior.node = null;
	}

	// Drops one never started: no stop.
	function drop(behavior:Behavior):Void {
		behavior.pass = null;
		behavior.node = null;
	}
}
