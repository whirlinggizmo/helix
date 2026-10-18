import helix.behavior.Behavior;
import helix.behavior.BehaviorRegistry;
import helix.behavior.BehaviorSchema;
import helix.behavior.Behaviors;
import helix.input.Input;
import helix.render3d.Node3D;
import helix.scene.Scene;
import helix.scene.Scenes;

/** Behaviors (helix.behavior): the schema the build macro generates from @:prop fields (names, types, defaults, a range, a superclass's
	props, @:behavior's name), setting and reading props through the registry's entry (unknown names and wrong types refused, a class
	that can't be made bare not registered); the pass (Behaviors): started on the first update after add, in order; updated only while
	enabled and under enabled nodes; stopped and dropped when done; safe to remove, add and clear from inside; found by class and by
	node; and a Scene's pass ticked by Scenes.update before the scene's update and cleared as the scene exits. */
class BehaviorTests {
	static var checks = 0;
	public static var log:Array<String> = [];

	static function check(value:Bool, message:String):Void {
		if (!value)
			throw message;
		checks++;
	}

	static function took():String {
		var s = log.join(",");
		log = [];
		return s;
	}

	static function propNamed(schema:BehaviorSchema, name:String):Null<BehaviorProp> {
		for (p in schema.props)
			if (p.name == name)
				return p;
		return null;
	}

	static function main():Void {
		// The schema the macro generated.
		var schema = Probe.schema();
		check(schema.name == "Probe" && schema.props.length == 8, "A probe's schema has its name and every prop");
		check([for (p in schema.props) p.name].join(",") == "count,speed,on,label,points,tint,target,bias", "in the order declared");
		var count = propNamed(schema, "count"),
			speed = propNamed(schema, "speed"),
			on = propNamed(schema, "on"),
			label = propNamed(schema, "label"),
			points = propNamed(schema, "points"),
			tint = propNamed(schema, "tint"),
			target = propNamed(schema, "target"),
			bias = propNamed(schema, "bias");
		check(count.type == IntProp && count.value == 3 && count.min == null && count.max == null, "An Int inferred from its initializer, no range");
		check(speed.type == FloatProp && speed.value == 2.5 && speed.min == 0 && speed.max == 10, "A Float with its @:range");
		check(on.type == BoolProp && on.value == true, "A Bool");
		check(label.type == StringProp && label.value == "x", "A String");
		check(points.type == FloatsProp && (points.value : Array<Float>).join(",") == "1,2", "A declared Array<Float> with its list");
		check(tint.type == ColorProp && tint.value == 0xff0000ff, "An Int marked a color");
		check(target.type == NodeProp && target.value == null, "A Node3D reference, null to start");
		check(bias.type == FloatProp && bias.value == -.5 && bias.min == -1 && bias.max == 1, "A negative default and range");

		// The registry: by the class's name, or @:behavior's; the abstract and the parameterized not registered.
		var entry = BehaviorRegistry.find("Probe");
		check(entry != null && entry.name == "Probe" && entry.schema.props.length == 8, "The probe is registered under its class's name");
		check(BehaviorRegistry.find("Renamed") != null && BehaviorRegistry.find("Named") == null, "@:behavior gives the registered name");
		check(BehaviorRegistry.find("Base") == null && BehaviorRegistry.find("Parameterized") == null,
			"An abstract class and one whose constructor takes arguments aren't registered");
		check(BehaviorRegistry.find("Nothing") == null, "An unknown name finds nothing");
		var names = BehaviorRegistry.names;
		check(names.indexOf("Probe") >= 0 && names.indexOf("Derived") >= 0 && names.indexOf("Renamed") >= 0, "names lists the registered");
		check(BehaviorRegistry.schemas.length == names.length && BehaviorRegistry.schemas[names.indexOf("Probe")].name == "Probe",
			"schemas, in the same order");
		var made = entry.make();
		check(Std.isOfType(made, Probe) && (cast made : Probe).count == 3, "make gives a fresh one at its defaults");
		// Set and get through the entry.
		var node = new Node3D();
		check(entry.setProp(made, "count", 7) && entry.getProp(made, "count") == 7, "An Int set and read");
		check(entry.setProp(made, "speed", 4) && entry.getProp(made, "speed") == 4, "A Float takes an Int");
		check(entry.setProp(made, "on", false) && entry.getProp(made, "on") == false, "A Bool");
		check(entry.setProp(made, "label", "y") && entry.getProp(made, "label") == "y", "A String");
		var list:Dynamic = [3, 4.5];
		check(entry.setProp(made, "points", list)
			&& (entry.getProp(made, "points") : Array<Float>).join(",") == "3,4.5", "A list of numbers");
		check(entry.setProp(made, "tint", 0x00ff00ff) && entry.getProp(made, "tint") == 0x00ff00ff, "A color");
		check(entry.setProp(made, "target", node) && entry.getProp(made, "target") == node, "A node reference");
		check(entry.setProp(made, "target", null) && entry.getProp(made, "target") == null, "which can be null");
		var probe:Probe = cast made;
		check(probe.count == 7 && probe.speed == 4 && !probe.on && probe.label == "y" && probe.points.length == 2 && probe.tint == 0x00ff00ff,
			"The fields hold what was set");
		check(!entry.setProp(made, "nothing", 1) && entry.getProp(made, "nothing") == null, "An unknown prop is refused, read as null");
		check(!entry.setProp(made, "count", 1.5) && !entry.setProp(made, "count", "1") && probe.count == 7, "A wrong type for an Int is refused");
		check(!entry.setProp(made, "speed", "fast")
			&& !entry.setProp(made, "on", 1)
			&& !entry.setProp(made, "label", 2), "and for a Float, a Bool, a String");
		var mixed:Dynamic = [1, "two"];
		check(!entry.setProp(made, "points", mixed)
			&& !entry.setProp(made, "points", 3)
			&& probe.points.length == 2, "A list with a string in it, or no list");
		check(!entry.setProp(made, "target", "car")
			&& !entry.setProp(made, "tint", "#ff0000"), "A reference that isn't a node, a color that isn't an Int");
		check(!entry.setProp(new Named(), "count", 1), "A behavior of another class is refused");
		// A subclass's schema has its superclass's props, set through its own entry.
		var derived = BehaviorRegistry.find("Derived");
		check([for (p in derived.schema.props) p.name].join(",") == "shared,own", "A derived class's props follow its base's");
		var d = derived.make();
		check(derived.setProp(d, "shared", 9) && derived.getProp(d, "shared") == 9 && (cast d : Derived).shared == 9, "and a base's prop is set through it");
		check(Derived.schema().props[0].value == 1 && Base.schema().name == "Base", "An abstract base has a schema of its own");

		// The pass.
		var pass = new Behaviors();
		var root = new Node3D(), group = new Node3D(), leaf = new Node3D();
		root.addChild(group);
		group.addChild(leaf);
		var a = new Logged("a"), b = new Logged("b"), c = new Logged("c");
		check(pass.add(a, root) && pass.add(b, leaf) && a.node == root && b.node == leaf, "add sets the node");
		check(!pass.add(a, group) && !pass.add(c, null) && pass.count == 2, "Refused: already in a pass, or no node");
		check(took() == "" && pass.find(Logged) == a && pass.of(leaf)[0] == b, "Nothing starts until an update; found meanwhile");
		pass.update(.1);
		check(took() == "a.start,b.start,a.update,b.update", "The first update starts them in order, then updates");
		b.enabled = false;
		pass.update(.1);
		check(took() == "a.update", "A disabled one is skipped");
		b.enabled = true;
		group.enabled = false;
		pass.update(.1);
		check(took() == "a.update", "and one under a disabled node, however far above");
		group.enabled = true;
		leaf.enabled = false;
		pass.update(.1);
		check(took() == "a.update", "or whose own node is disabled");
		leaf.enabled = true;
		// Done: stopped at the end of that update and dropped.
		a.endAt = 1;
		pass.update(.1);
		check(took() == "a.update,b.update,a.stop"
			&& pass.count == 1
			&& a.node == null, "Done: stopped after the update, dropped, its node let go");
		a.endAt = 0;
		check(pass.add(a, root) && pass.count == 2, "and can be added again");
		// Added inside an update: starts on the next. Removed inside an update: safe.
		var later = new Logged("later");
		b.onUpdate = () -> pass.add(later, leaf);
		pass.update(.1);
		check(took() == "a.start,b.update,a.update" && pass.count == 3, "One added during an update waits for the next");
		b.onUpdate = () -> pass.remove(a);
		pass.update(.1);
		check(took() == "later.start,b.update,a.stop,later.update"
			&& pass.count == 2, "One removed during an update stops at once and isn't updated");
		b.onUpdate = null;
		check(!pass.remove(a) && a.node == null, "remove refuses one not in the pass");
		// Found by class and by node.
		var other = new Other();
		pass.add(other, leaf);
		check(pass.find(Other) == other && pass.findAll(Logged).length == 2 && pass.findAll(Behavior).length == 3 && pass.find(Probe) == null,
			"find and findAll by class, a base class finding all");
		check(pass.of(leaf).length == 3 && pass.of(root).length == 0, "of by node");
		check(pass.on(leaf, Other) == other && pass.on(root, Other) == null && other.pass == pass, "on by node and class; a behavior knows its pass");
		// clear stops the started, not the pending.
		pass.clear();
		check(took() == "b.stop,later.stop" && pass.count == 0 && other.node == null, "clear stops each started one and drops the rest");
		// A clear from inside an update, and one done before it started.
		var d1 = new Logged("d1"), d2 = new Logged("d2");
		pass.add(d1, root);
		pass.add(d2, root);
		d1.onUpdate = () -> pass.clear();
		pass.update(.1);
		check(took() == "d1.start,d2.start,d1.update,d1.stop,d2.stop"
			&& pass.count == 0, "A clear inside an update stops everything, once");
		d1.onUpdate = null;

		// A scene's pass: ticked by the stack before the scene's update, cleared as the scene exits.
		@:privateAccess Input.bind(new helix.input.InputState());
		var scenes = new Scenes();
		scenes.pauseOnBlur = false;
		var scene = new LoggedScene();
		var s1 = new Logged("s1");
		scenes.push(scene);
		check(scene.behaviors.add(s1, root) && took() == "scene.enter", "A scene has a pass of its own");
		scenes.update(.1);
		check(took() == "s1.start,s1.update,scene.update", "The stack runs the scene's behaviors before its update");
		var under = new LoggedScene();
		scenes.push(under);
		took();
		scenes.update(.1);
		check(took() == "scene.update", "Under another scene, neither runs");
		scenes.pop();
		took();
		scenes.update(.1);
		check(took() == "s1.update,scene.update", "On top again, both do");
		scenes.pop();
		check(took() == "s1.stop,scene.exit" && scene.behaviors.count == 0, "Popped: its behaviors stop, then it exits");
		Sys.println(haxe.Json.stringify({passed: true, checks: checks}));
	}
}

/** A behavior with a prop of every type. */
private class Probe extends Behavior {
	@:prop public var count = 3;
	@:prop @:range(0, 10) public var speed = 2.5;
	@:prop public var on = true;
	@:prop public var label = "x";
	@:prop public var points:Array<Float> = [1, 2];
	@:prop("color") public var tint = 0xff0000ff;
	@:prop public var target:Node3D = null;
	@:range(-1, 1) @:prop public var bias:Float = -.5;
}

/** Registered under another name. */
@:behavior("Renamed")
private class Named extends Behavior {
	@:prop public var count = 0;
}

/** A base other behaviors extend: not registered itself. */
@:abstract
private class Base extends Behavior {
	@:prop public var shared = 1;
}

/** Its base's prop and one of its own. */
private class Derived extends Base {
	@:prop public var own = "d";
}

/** Made with an argument: not registered. */
private class Parameterized extends Behavior {
	public function new(x:Int) {
		super();
	}
}

/** Logs its hooks; ends itself after endAt updates; runs onUpdate inside its update. */
private class Logged extends Behavior {
	var label:String;
	var updates = 0;

	/** Ends after this many updates; 0 for never. */
	public var endAt = 0;

	/** Run inside each update. */
	public var onUpdate:Null<Void->Void>;

	public function new(label:String) {
		super();
		this.label = label;
	}

	override public function start():Void
		BehaviorTests.log.push('$label.start');

	override public function update(dt:Float):Void {
		BehaviorTests.log.push('$label.update');
		updates++;
		if (onUpdate != null)
			onUpdate();
		if (endAt > 0 && updates >= endAt)
			done = true;
	}

	override public function stop():Void
		BehaviorTests.log.push('$label.stop');
}

/** Another class, to find apart. */
private class Other extends Behavior {}

/** A scene logging its hooks. */
private class LoggedScene extends Scene {
	override public function enter():Void
		BehaviorTests.log.push("scene.enter");

	override public function exit():Void
		BehaviorTests.log.push("scene.exit");

	override public function update(dt:Float):Void
		BehaviorTests.log.push("scene.update");
}
