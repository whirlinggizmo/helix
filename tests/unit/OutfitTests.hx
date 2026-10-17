import haxe.io.Bytes;
import helix.assets.IAssets;
import helix.render3d.Gltf;
import helix.render3d.Material;
import helix.render3d.Mesh;
import helix.render3d.ModelFile;
import helix.render3d.Models;
import helix.render3d.Node;

/** Characters dressed by slot (the examples' Outfit, examples/shared/src) from part files shared through Models, over the framework's queries
	(Node.collectModels, bindSkeleton and findAttachment), with Quaternius's modular women (the dressing-room and animation examples'): parts
	bound to the skeleton by joint name, held parts at a socket, choices before the skeleton and overtaken while loading, failures, and one load
	shared by many characters. */
class OutfitTests {
	static var checks = 0;
	// The loads the test's assets hold until released, by path, and how many each was asked for.
	static var held:Map<String, helix.assets.IAssets.AssetResult->Void> = [];
	static var asked:Map<String, Int> = [];

	static function check(value:Bool, message:String):Void {
		if (!value)
			throw message;
		checks++;
	}

	static function bytes(name:String):Bytes
		return sys.io.File.getBytes('examples/assets/models/modular-women/$name.glb');

	static function file(name:String):ModelFile
		return @:privateAccess new ModelFile(Gltf.read(bytes(name)));

	// Models over assets that answer only when the test releases a path (the part files carry no images, so no textures are needed).
	static function models():Models
		return new Models(new Held(), null);

	static function release(path:String, result:helix.assets.IAssets.AssetResult):Void {
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
		var shared = models();
		for (name in ["Casual_Head", "Witch_Head", "Adventurer_Body", "Sword"])
			shared.put(name, file(name));
		var animations = file("Animations");
		var character = animations.instantiate("character");
		var outfit = new Outfit(shared);

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
		shared.put("Casual_Legs", file("Casual_Legs"));
		outfit.choose("legs", "Casual_Legs");
		check(outfit.getWorn("legs") == "Casual_Legs", "A later choice already loaded is worn at once");
		release("Slow_Legs", Loaded(bytes("Adventurer_Legs")));
		check(outfit.getWorn("legs") == "Casual_Legs" && !outfit.isPending(), "and the overtaken one, landing after, is dropped");
		check(shared.isLoaded("Slow_Legs"), "though the models keep its file");

		// A file that fails.
		outfit.choose("feet", "Missing_Feet");
		release("Missing_Feet", Failed("not found"));
		check(outfit.getWorn("feet") == null && outfit.getError("feet") != null && !outfit.isPending(), "A part whose file fails empties its slot");

		// Many characters, one load.
		var others = [for (i in 0...3) new Outfit(shared)];
		var skeletons = [for (i in 0...3) animations.instantiate('other$i')];
		for (i in 0...3) {
			others[i].setSkeleton(skeletons[i]);
			others[i].choose("feet", "Shared_Feet");
		}
		check(asked["Shared_Feet"] == 1, "Characters asking for one part share its load");
		release("Shared_Feet", Loaded(bytes("Casual_Feet")));
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
		var every = models(), model = new Outfit(every), refused = [];
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

		// A file whose models sit under no joint: the piece is the whole file, hung at a socket.
		var loose = Node.group(),
			gem = Node.model(Mesh.plane(.1, .1), new Material());
		gem.setName("gem");
		var holder = Node.group();
		holder.setName("holder");
		holder.add(gem);
		loose.add(holder);
		var at = loose.findAttachment(gem, character);
		check(at != null && at.piece == holder && at.joint == null, "A model under no joint of the skeleton's is a piece at the file's top, with no joint");
		check(loose.findAttachment(character, character) == null, "A node not under the file has no attachment");

		// Shutting the models down cancels what's still loading.
		var cancelled = false;
		shared.load("Never", result -> cancelled = result.match(Cancelled));
		shared.shutdown();
		check(cancelled && !shared.isLoaded("Casual_Head"), "Shutting down cancels loads and forgets files");
		Sys.println(haxe.Json.stringify({passed: true, checks: checks}));
	}
}

/** Assets whose loads wait until the test releases them, counting how often each path is asked for. */
private class Held implements IAssets {
	public function new() {}

	public function load(path:String, complete:helix.assets.IAssets.AssetResult->Void):Void {
		@:privateAccess OutfitTests.asked[path] = (OutfitTests.asked.exists(path) ? OutfitTests.asked[path] : 0) + 1;
		@:privateAccess OutfitTests.held[path] = complete;
	}

	public function ensure(path:String, complete:helix.assets.IAssets.AssetResult->Void, ?progress:helix.assets.IAssets.AssetProgress->Void,
			?options:helix.assets.IAssets.EnsureOptions):helix.assets.IRequest {
		load(path, complete);
		return new helix.assets.Request(() -> {
			@:privateAccess OutfitTests.held.remove(path);
			complete(Cancelled);
		});
	}

	public function getHost():Null<String>
		return null;

	public function setHost(host:Null<String>):Bool
		return false;

	public function pingHost(host:String, probePath:String, timeoutSeconds:Float, complete:Bool->Void):helix.assets.IRequest
		return new helix.assets.Request(() -> {});

	public function clearCache(complete:helix.assets.Storage.StorageWriteResult->Void):helix.assets.IRequest
		return new helix.assets.Request(() -> {});

	public function getManifest():Null<String>
		return null;

	public function setManifest(path:Null<String>):Bool
		return true;

	public function getCacheMode():helix.assets.IAssets.AssetCacheMode
		return Revalidate;

	public function setCacheMode(mode:helix.assets.IAssets.AssetCacheMode):Void {}

	public function streamSource(path:String, complete:helix.assets.IAssets.AssetSourceResult->Void):helix.assets.IRequest
		return new helix.assets.Request(() -> {});

	public function subscribe(path:String, target:helix.assets.IReloadable):Void {}

	public function unsubscribe(path:String, target:helix.assets.IReloadable):Void {}

	public function isBusy():Bool
		return false;
}
