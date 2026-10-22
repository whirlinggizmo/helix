package helix.behavior;

/** The program's behaviors: one pass (BehaviorPass) the runner updates after the app's update and before the frame is drawn, with the game's
	clock, so a behavior attached to a node on the stage runs with nothing more (docs/DISPLAY_MODEL.md); what a scene file attaches goes
	here unless it's given another pass. Installed by its first use. The program's one, a static class: each member forwards to instance,
	written by helix.macro.Facade from BehaviorPass's public members with their doc comments. */
@:build(helix.macro.Facade.build(helix.behavior.BehaviorPass, ["update"], helix.behavior.BehaviorPass.install))
class Behaviors {
	/** The pass forwarded to: installed by its first use (an optional part, helix.host.Part) until the program's end, null before and after. Kept across a hot reload (@:hot): set once by the runner, nothing would set it again. */
	@:hot public static var instance(default, null):BehaviorPass;

	/** The program's pass itself, installed if it wasn't: what SceneFile.instantiate attaches to unless given another. */
	public static var pass(get, never):BehaviorPass;

	static function get_pass():BehaviorPass
		return service();

	/** The first behavior of class cls (or a subclass) in the pass, started ones first (by phase, then in the order added), or null. */
	public static function find<T:Behavior>(cls:Class<T>):Null<T>
		return service().find(cls);

	/** Every behavior of class cls (or a subclass) in the pass, started ones first (by phase, then in the order added). */
	public static function findAll<T:Behavior>(cls:Class<T>):Array<T>
		return service().findAll(cls);

	/** The first behavior of class cls (or a subclass) on node, started ones first (by phase, then in the order added), or null: how a
		behavior given a node reference reaches the behavior on it. */
	public static function on<T:Behavior>(node:helix.render3d.Node3D, cls:Class<T>):Null<T>
		return service().on(node, cls);

	/** Every behavior of class or interface cls on node or on a node under it, started ones first (by phase, then in the order added),
		then the pending: how a resolver gathers what has a say on an entity (BehaviorPass.allUnder). */
	public static function allUnder<T>(node:helix.render3d.Node3D, cls:Class<T>):Array<T>
		return service().allUnder(node, cls);
}
