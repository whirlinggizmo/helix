package helix.behavior;

import helix.render3d.Node3D;

/** What a game's logic on a node extends: a behavior drives the node a Behaviors pass gave it (node), from start to stop, its update
	run each frame by the pass while it and its node are enabled, until it sets done. It is never on the node: nodes draw, behaviors act,
	the pass runs them, and the game's state stays the truth (docs/DECISIONS.md, 61 and 130). Nothing else is on it: no signals, no
	children, no lookups through the node; a behavior reaches the game as any code does, through statics, the scene, what it was given.

	Its props, the fields a scene file or an inspector sets, are `@:prop public var` fields with an initializer (`@:prop public var
	radius = 4.;`), of Int, Float, Bool, String, Array<Float>, a color (an Int marked `@:prop("color")`) or Node3D (a reference); an
	optional `@:range(min, max)` on the field gives an inspector its range. The build macro helix.macro.Behaviors runs on each subclass:
	it generates `schema()` and the typed setters the registry uses, and registers the class in BehaviorRegistry by its name, or the string
	in `@:behavior("Name")` on the class, as the program starts (so a class the game's code never names, one only a file names, must be in
	the build: a class path's `--macro include("pack")`, or an import). A class marked `@:abstract`, or whose constructor takes arguments,
	is built but not registered: it is a base for others.

	Across a hot reload, as docs/DECISIONS.md 130 says of closures: in the browser a reload re-points its methods as any class's, so an
	instance in a pass runs the new update from the next frame, keeping its fields; natively an old instance runs its old module until the
	pass is remade (a scene re-entered). */
@:autoBuild(helix.macro.Behaviors.build())
class Behavior {
	/** The pass it's in, from add until it's dropped, null outside: how a behavior reaches another through a node it was given
		(`pass.on(node, Race)`), with no lookup through the node itself. Add refuses one already in a pass, anywhere. */
	@:allow(helix.behavior.Behaviors)
	public var pass(default, null):Null<Behaviors>;

	/** One in no pass yet. */
	public function new() {}

	/** The node it drives: set by the pass it's added to, before start, and null until then and once it's dropped. */
	@:allow(helix.behavior.Behaviors)
	public var node(default, null):Null<Node3D>;

	/** Whether its update runs: off, the pass skips it (start and stop still come). On to start. */
	public var enabled:Bool = true;

	/** Set true to end it: at the end of that update the pass calls stop and drops it. False to start. */
	public var done:Bool = false;

	/** Once, on the pass's first update after it's added, its node set: what it needs from the node and the game. */
	public function start():Void {}

	/** A frame, dt seconds since the last, while it and its node (with every node above it) are enabled. */
	public function update(dt:Float):Void {}

	/** Once, when it ends (done), is removed or the pass is cleared, after start: undo what start did. Not called for one never
		started. */
	public function stop():Void {}
}
