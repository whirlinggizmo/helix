package helix.behavior;

import helix.render3d.Node3D;

/** The pass that runs behaviors, beside a game's timers and tweens: add puts a behavior on a node, update each frame starts the ones
	added since the last update (in order, so a scene file can attach many and they start together), updates each enabled one whose node
	is enabled (with every node above it: a disabled group stops what's under it), then stops and drops the ones done. One pass per
	Scene (Scene.behaviors, which the Scenes stack updates before the scene's own update and clears as it exits); an app without a stack
	makes one and updates it, as it does a Tweens. Adding, removing and clearing inside a behavior's start, update or stop are safe: the
	pass walks copies, and a change takes effect from the next step. */
class Behaviors {
	// The started ones, in the order added, and the ones added since the last update, not yet started.
	var active:Array<Behavior> = [];
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
		if (active.remove(behavior))
			end(behavior);
		else {
			pending.remove(behavior);
			drop(behavior);
		}
		return true;
	}

	/** How many it holds: started, or waiting for the next update to start. */
	public var count(get, never):Int;

	function get_count():Int
		return active.length + pending.length;

	/** The first behavior of class cls (or a subclass) in it, started ones first, or null. */
	public function find<T:Behavior>(cls:Class<T>):Null<T> {
		for (b in active)
			if (Std.isOfType(b, cls))
				return cast b;
		for (b in pending)
			if (Std.isOfType(b, cls))
				return cast b;
		return null;
	}

	/** Every behavior of class cls (or a subclass) in it, started ones first. */
	public function findAll<T:Behavior>(cls:Class<T>):Array<T> {
		var found:Array<T> = [];
		for (b in active)
			if (Std.isOfType(b, cls))
				found.push(cast b);
		for (b in pending)
			if (Std.isOfType(b, cls))
				found.push(cast b);
		return found;
	}

	/** The behaviors on node, started ones first. */
	public function of(node:Node3D):Array<Behavior> {
		var found = [];
		for (b in active)
			if (b.node == node)
				found.push(b);
		for (b in pending)
			if (b.node == node)
				found.push(b);
		return found;
	}

	/** Takes every behavior out, stopping each started one. */
	public function clear():Void {
		var ending = active, waiting = pending;
		active = [];
		pending = [];
		for (b in ending)
			end(b);
		for (b in waiting)
			drop(b);
	}

	/** A frame: starts the ones added since the last update, updates the enabled ones under enabled nodes by dt seconds (a clock's delta),
		then stops and drops the ones done. Once a frame. */
	public function update(dt:Float):Void {
		var starting = pending;
		pending = [];
		for (b in starting) {
			// Removed before it started, from an earlier start.
			if (b.pass != this)
				continue;
			active.push(b);
			b.start();
		}
		for (b in active.copy()) {
			if (b.pass != this || b.done)
				continue;
			if (b.enabled && isEnabled(b.node))
				b.update(dt);
		}
		var kept = [];
		for (b in active.copy()) {
			if (b.pass != this)
				continue;
			if (b.done)
				end(b);
			else
				kept.push(b);
		}
		// Those a stop removed are out already; a clear emptied the list, and what was added since is pending.
		active = kept.filter(b -> b.pass == this);
	}

	// Whether node and every node above it are enabled: a node doesn't know its ancestors' flags, so they're walked.
	static function isEnabled(node:Null<Node3D>):Bool {
		var at = node;
		while (at != null) {
			if (!at.enabled)
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
