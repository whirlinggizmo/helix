import helix.assets.IRequest;
import helix.assets.Request;
import helix.render3d.Gltf;
import helix.render3d.ModelFile;
import helix.render3d.Models.ModelLoadResult;
import helix.render3d.Node;
import helix.render3d.Outfit;
import helix.render3d.Wardrobe;

/** Characters dressed by slot (Outfit) from shared part files (Wardrobe), with Quaternius's modular women (the dressing-room and animation
	examples'): parts bound to the skeleton by joint name, held parts at a socket, choices before the skeleton and overtaken while loading,
	failures, and one load shared by many characters. */
class OutfitTests {
	static var checks = 0;
	// The loads the test's loader holds until released, by path, and how many it was asked for.
	static var held:Map<String, ModelLoadResult->Void> = [];
	static var asked:Map<String, Int> = [];

	static function check(value:Bool, message:String):Void {
		if (!value)
			throw message;
		checks++;
	}

	static function file(name:String):ModelFile
		return @:privateAccess new ModelFile(Gltf.read(sys.io.File.getBytes('examples/assets/models/modular-women/$name.glb')));

	// A loader that answers only when the test releases a path.
	static function load(path:String, complete:ModelLoadResult->Void):IRequest {
		asked[path] = (asked.exists(path) ? asked[path] : 0) + 1;
		held[path] = complete;
		return new Request(() -> {
			held.remove(path);
			complete(Cancelled);
		});
	}

	static function release(path:String, result:ModelLoadResult):Void {
		var complete = held[path];
		held.remove(path);
		complete(result);
	}

	// Whether node is character or under it.
	static function under(node:Null<Node>, character:Node):Bool {
		while (node != null) {
			if (node == character)
				return true;
			node = node.getParent();
		}
		return false;
	}

	static function main():Void {
		var wardrobe = new Wardrobe(load);
		for (name in ["Casual_Head", "Witch_Head", "Adventurer_Body", "Sword"])
			wardrobe.put(name, file(name));
		var animations = file("Animations");
		var character = animations.instantiate("character");
		var outfit = new Outfit(wardrobe);

		// Chosen before the skeleton: waits, then is worn on it.
		outfit.choose("head", "Casual_Head");
		check(outfit.isPending() && outfit.getWorn("head") == null, "A choice before the skeleton waits");
		outfit.setSkeleton(character);
		var head = outfit.getNodes("head");
		check(outfit.getWorn("head") == "Casual_Head" && head.length > 0 && !outfit.isPending(), "and is worn once it's given");
		check(head[0].getParent() == character && under(head[0].getJoint(0), character), "Its models are bound to the character's joints");

		// Swapped: the old part comes off.
		outfit.choose("head", "Witch_Head");
		check(outfit.getWorn("head") == "Witch_Head" && head[0].getParent() == null, "A new choice takes the old part off");
		outfit.choose("body", "Adventurer_Body");
		check(outfit.getWorn("body") == "Adventurer_Body" && outfit.getWorn("head") == "Witch_Head", "Slots are worn apart");

		// Held at a socket.
		outfit.choose("hand", "Sword", "Middle1.R");
		var sword = outfit.getNodes("hand");
		check(sword.length == 1 && sword[0].getParent() == character.find("Middle1.R"), "A held part hangs from its joint");
		var offset = sword[0].getMatrix().join(",");
		outfit.choose("hand", "Sword");
		var hung = outfit.getNodes("hand");
		check(hung.length == 1 && hung[0].getParent() == character.find("Middle1.R") && hung[0].getMatrix().join(",") == offset,
			"Without a socket, a rigid part hangs from the joint its file hangs it from, at the file's offset");
		check(hung[0].find("Root") == null && hung[0].find("Middle1.R") == null, "and the file's own copy of the skeleton doesn't come with it");
		outfit.choose("hand", "Sword", "Nope");
		check(outfit.getWorn("hand") == null && outfit.getError("hand") != null && sword[0].getParent() == null,
			"A socket the skeleton lacks empties the slot, saying why");
		outfit.choose("hand", null);
		check(outfit.getChoice("hand") == null && outfit.getError("hand") == null, "A slot can be emptied");

		// A choice overtaken while its file loads is dropped.
		outfit.choose("legs", "Slow_Legs");
		check(outfit.isPending() && held.exists("Slow_Legs"), "A part not yet loaded is asked for");
		var legs = file("Casual_Legs");
		wardrobe.put("Casual_Legs", legs);
		outfit.choose("legs", "Casual_Legs");
		check(outfit.getWorn("legs") == "Casual_Legs", "A later choice already loaded is worn at once");
		release("Slow_Legs", Ready(file("Adventurer_Legs")));
		check(outfit.getWorn("legs") == "Casual_Legs" && !outfit.isPending(), "and the overtaken one, landing after, is dropped");
		check(wardrobe.isLoaded("Slow_Legs"), "though the wardrobe keeps its file");

		// A file that fails.
		outfit.choose("feet", "Missing_Feet");
		release("Missing_Feet", Failed("not found"));
		check(outfit.getWorn("feet") == null && outfit.getError("feet") != null && !outfit.isPending(), "A part whose file fails empties its slot");

		// Many characters, one load.
		var others = [for (i in 0...3) new Outfit(wardrobe)];
		var skeletons = [for (i in 0...3) animations.instantiate('other$i')];
		for (i in 0...3) {
			others[i].setSkeleton(skeletons[i]);
			others[i].choose("feet", "Shared_Feet");
		}
		check(asked["Shared_Feet"] == 1, "Characters asking for one part share its load");
		release("Shared_Feet", Ready(file("Casual_Feet")));
		var feet = [for (o in others) o.getNodes("feet")[0]];
		check(feet[0] != feet[1] && feet[1] != feet[2] && feet[0].getMesh() == feet[1].getMesh(), "and each wears its own nodes over the same meshes");
		check(under(feet[2].getJoint(0), skeletons[2]) && !under(feet[2].getJoint(0), skeletons[0]), "each bound to its own skeleton");

		// Another skeleton: choices move to it; one lacking the joints refuses them.
		var moved = animations.instantiate("moved");
		outfit.setSkeleton(moved);
		check(outfit.getNodes("head")[0].getParent() == moved
			&& outfit.getWorn("body") == "Adventurer_Body"
			&& !under(outfit.getNodes("body")[0], character),
			"Choices move to a new skeleton, off the old one");
		outfit.setSkeleton(Node.group());
		check(outfit.getWorn("head") == null && outfit.getError("head") != null, "A skeleton without the joints refuses a part");
		outfit.setSkeleton(null);
		check(outfit.getNodes("body").length == 0 && outfit.getChoice("head") == "Witch_Head" && outfit.isPending(),
			"Without a skeleton nothing is worn, and the choices are kept");

		// Every part of the pack is worn on the animations' skeleton, each slot's part from each outfit.
		var every = new Wardrobe(load), model = new Outfit(every), refused = [];
		model.setSkeleton(animations.instantiate("model"));
		for (look in [
			"Adventurer",
			"Casual",
			"Formal",
			"Medieval",
			"Punk",
			"SciFi",
			"Soldier",
			"Suit",
			"Witch",
			"Worker"
		])
			for (slot in ["Head", "Body", "Legs", "Feet"]) {
				var name = '${look}_$slot';
				every.put(name, file(name));
				model.choose(slot, name);
				if (model.getWorn(slot) != name)
					refused.push('$name: ${model.getError(slot)}');
			}
		check(refused.length == 0, 'Every part of the ten outfits is worn: $refused');

		// Closing cancels what's still loading.
		var cancelled = false;
		wardrobe.get("Never", result -> cancelled = result.match(Cancelled));
		wardrobe.close();
		check(cancelled && !wardrobe.isLoaded("Casual_Head"), "Closing cancels loads and forgets files");
		Sys.println(haxe.Json.stringify({passed: true, checks: checks}));
	}
}
