import helix.behavior.Behavior;
import helix.behavior.Behaviors;
import helix.behavior.Phase;
import helix.render3d.Node3D;

/** The behaviors pass's phases and its subtree query, probed with a small combat: `@:phase` read into the schema and the generated phase
	getter (a subclass keeping its base's, Simulate when none says); one update running every Input behavior, then Simulate, Resolve and
	Late, whatever order they were added in; an Attacker (Simulate) queueing hits on a Combat resolver (Resolve), which applies every
	IDamageModifier under the target (a FireWard on a child node halving fire, not a physical hit; a ward on a sibling's node not counted)
	then the target's Health; and `allUnder` with a class and with an interface, started ones first by phase then pending. Built on JS
	and hxcpp too, to prove the interface checks and the generated getter there. */
class CombatProbeTests {
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

	static function main():Void {
		// The phase, from @:phase, the base's, or Simulate.
		check(Health.schema().phase == Simulate && Combat.schema().phase == Resolve && Intent.schema().phase == Input,
			"The schema carries @:phase, Simulate without it");
		check(Follower.schema().phase == Late && SteadyFollower.schema().phase == Late, "A subclass without @:phase keeps its base's");
		var steady:Behavior = new SteadyFollower();
		check(new Health().phase == Simulate && new Combat().phase == Resolve && steady.phase == Late && new Intent().phase == Input,
			"and the instance's phase is the class's, read through Behavior");

		// The world: a knight with a shield (a child node) and a squire beside him, each warded against fire.
		var pass = new Behaviors();
		var root = new Node3D(),
			knight = new Node3D(),
			shield = new Node3D(),
			squire = new Node3D(),
			camera = new Node3D();
		root.addChild(knight);
		knight.addChild(shield);
		root.addChild(squire);
		root.addChild(camera);
		// Added in the reverse of the phases' order: the pass orders them.
		var follower = new Follower(),
			combat = new Combat(),
			attacker = new Attacker(),
			intent = new Intent();
		var health = new Health(),
			ward = new FireWard(),
			squireWard = new FireWard();
		pass.add(follower, camera);
		pass.add(combat, root);
		pass.add(attacker, root);
		pass.add(intent, root);
		pass.add(health, knight);
		pass.add(ward, shield);
		pass.add(squireWard, squire);
		attacker.target = knight;
		pass.update(.1);
		check(took() == "intent,attacker,combat,follower", "One update runs Input, then Simulate, Resolve and Late");
		check(health.hp == 100 - 5 - 10, "The fire hit halved by the shield's ward, the physical one whole, the squire's ward not counted");
		check(combat.applied.join(",") == "fire:5,physical:10", "The resolver applied the queue in order");
		pass.update(.1);
		check(took() == "intent,attacker,combat,follower" && health.hp == 70, "and again the next frame");
		// The started ones by phase, then in the order added.
		var order = [
			for (b in pass.findAll(Behavior))
				Type.getClassName(Type.getClass(b)).split(".").pop()
		];
		check(order.join(",") == "Intent,Attacker,Health,FireWard,FireWard,Combat,Follower", "findAll: by phase, then the order added");
		check(pass.find(Behavior) == intent
			&& pass.of(root).join(",") == [intent, attacker, combat].join(","), "find and of the same way");

		// allUnder, with an interface and with a class.
		var modifiers = pass.allUnder(knight, IDamageModifier);
		check(modifiers.length == 1 && modifiers[0] == ward, "allUnder an interface: the shield's ward, not the squire's");
		check(pass.allUnder(root, FireWard).length == 2 && pass.allUnder(squire, FireWard)[0] == squireWard, "allUnder a class");
		check(pass.allUnder(shield, Health).length == 0
			&& pass.allUnder(knight, Health)[0] == health, "a node itself counts, not its parent");
		check(pass.allUnder(root, Behavior).length == 7, "everything under the root");
		var late = new FireWard();
		pass.add(late, knight);
		var both = pass.allUnder(knight, IDamageModifier);
		check(both.length == 2 && both[0] == ward && both[1] == late, "a pending one after the started");
		pass.remove(ward);
		pass.remove(late);
		check(pass.allUnder(knight, IDamageModifier).length == 0 && pass.count == 6, "and gone once removed");
		pass.update(.1);
		took();
		check(health.hp == 70 - 10 - 10, "Without the ward, the fire hit lands whole");
		// Removed in its phase by an earlier phase: not updated; clear stops by phase.
		intent.onUpdate = () -> pass.remove(follower);
		pass.update(.1);
		check(took() == "intent,attacker,combat" && pass.count == 5, "One removed by an earlier phase doesn't run");
		intent.onUpdate = null;
		pass.clear();
		check(pass.count == 0 && combat.node == null, "clear empties every phase");
		var out = haxe.Json.stringify({passed: true, checks: checks});
		#if sys
		Sys.println(out);
		#else
		trace(out);
		#end
	}
}

/** What can change a hit before it lands: gear, a buff, a ward. */
private interface IDamageModifier {
	/** The amount a hit of kind does after this one's say. */
	function modifyDamage(kind:String, amount:Float):Float;
}

/** An entity's hit points. */
private class Health extends Behavior {
	/** What it has left. */
	@:prop public var hp = 100.;
}

/** Gear on a child node: halves fire. */
private class FireWard extends Behavior implements IDamageModifier {
	/** Fire at half. */
	public function modifyDamage(kind:String, amount:Float):Float
		return kind == "fire" ? amount / 2 : amount;
}

/** The player's intent, read first. */
@:phase(Input)
private class Intent extends Behavior {
	/** Run inside each update. */
	public var onUpdate:Null<Void->Void>;

	override public function update(dt:Float):Void {
		CombatProbeTests.log.push("intent");
		if (onUpdate != null)
			onUpdate();
	}
}

/** Swings at target each frame: a fire hit and a physical one, queued on the Combat. */
private class Attacker extends Behavior {
	/** The node it hits. */
	@:prop public var target:Node3D = null;

	override public function update(dt:Float):Void {
		CombatProbeTests.log.push("attacker");
		var combat = pass.find(Combat);
		if (combat == null || target == null)
			return;
		combat.queue(target, "fire", 10);
		combat.queue(target, "physical", 10);
	}
}

/** The resolver: applies the hits queued this frame, each through the modifiers under its target, then the target's health. */
@:phase(Resolve)
private class Combat extends Behavior {
	var hits:Array<{target:Node3D, kind:String, amount:Float}> = [];

	/** What it applied last, "kind:amount". */
	public var applied(default, null):Array<String> = [];

	/** A hit of kind and amount on target, applied in Resolve. */
	public function queue(target:Node3D, kind:String, amount:Float):Void
		hits.push({target: target, kind: kind, amount: amount});

	override public function update(dt:Float):Void {
		CombatProbeTests.log.push("combat");
		applied = [];
		for (hit in hits) {
			var amount = hit.amount;
			for (modifier in pass.allUnder(hit.target, IDamageModifier))
				amount = modifier.modifyDamage(hit.kind, amount);
			var health = pass.on(hit.target, Health);
			if (health != null)
				health.hp -= amount;
			applied.push('${hit.kind}:$amount');
		}
		hits = [];
	}
}

/** Follows the settled world, last. */
@:phase(Late)
private class Follower extends Behavior {
	override public function update(dt:Float):Void
		CombatProbeTests.log.push("follower");
}

/** Says no phase: keeps its base's. */
private class SteadyFollower extends Follower {}
