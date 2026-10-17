package helix.render3d;

/** What a character wears, by slot ("head", "body", "hand" ... the game names them): a part file for each, from a Wardrobe shared by every
	character. A part's skinned models are bound to the character's skeleton by joint name (Node.bindSkeleton), so gear from files of its own
	follows the character's animation; its rigid models (a sword, a gun, a hat) hang from the character's joint named as the one the file
	hangs them from, keeping their offset from it, or from a joint the choice names (a socket). A part's file may carry a whole copy of the
	skeleton (an exporter's armature): only its models are taken. Choices may come
	before the skeleton does, and in any order while files load: each slot wears its latest choice once both its file and the skeleton are in,
	and a choice overtaken while its file loads is dropped. */
class Outfit {
	var wardrobe:Wardrobe;
	var skeleton:Null<Node>;
	var chosen:Map<String, Choice> = [];
	var worn:Map<String, Worn> = [];
	var errors:Map<String, String> = [];

	/** An outfit drawing its parts from wardrobe, for a skeleton given later (setSkeleton). */
	public function new(wardrobe:Wardrobe)
		this.wardrobe = wardrobe;

	/** The skeleton parts are worn on (a character's root, its joints at or under it), or null before it's given. */
	public function getSkeleton():Null<Node>
		return skeleton;

	/** Wears every slot's choice on skeleton, taking them off the one before (null takes everything off). */
	public function setSkeleton(value:Null<Node>):Void {
		for (slot in [for (s in worn.keys()) s])
			takeOff(slot);
		skeleton = value;
		// Each choice tried afresh on it: what one skeleton refused another may take (a file that failed fails again, remembered).
		errors.clear();
		for (slot in [for (s in chosen.keys()) s])
			apply(slot);
	}

	/** Chooses path's part for slot (null leaves the slot empty): worn on the skeleton by joint name, its rigid models at their joints, or, with
		joint, at that one (a socket). It's worn once its file has loaded (at once when it has, and the skeleton is given); a later choice for the slot overtakes it.
		A part that can't be worn (its file fails, its skeleton lacks a joint it names) leaves the slot empty, with getError saying why. */
	public function choose(slot:String, path:Null<String>, ?joint:String):Void {
		errors.remove(slot);
		if (path == null) {
			chosen.remove(slot);
			takeOff(slot);
			return;
		}
		var choice = new Choice(path, joint);
		chosen[slot] = choice;
		apply(slot);
	}

	/** The path chosen for slot, or null for none. */
	public function getChoice(slot:String):Null<String> {
		var choice = chosen[slot];
		return choice == null ? null : choice.path;
	}

	/** The path slot wears now (its choice once it's on), or null for none. */
	public function getWorn(slot:String):Null<String> {
		var w = worn[slot];
		return w == null ? null : w.path;
	}

	/** The nodes slot's part added to the character, empty for none. */
	public function getNodes(slot:String):Array<Node> {
		var w = worn[slot];
		return w == null ? [] : w.nodes.copy();
	}

	/** The slots chosen, in no order. */
	public function getSlots():Array<String>
		return [for (s in chosen.keys()) s];

	/** Why slot's choice couldn't be worn, or null. */
	public function getError(slot:String):Null<String>
		return errors[slot];

	/** Whether a choice is waiting for its file (or for the skeleton). */
	public function isPending():Bool {
		for (slot => choice in chosen)
			if (getWorn(slot) != choice.path && !errors.exists(slot))
				return true;
		return false;
	}

	// Wears slot's choice when its file and the skeleton are in; asks the wardrobe for the file otherwise.
	function apply(slot:String):Void {
		var choice = chosen[slot];
		if (choice == null || skeleton == null)
			return;
		var w = worn[slot];
		if (w != null && w.path == choice.path && w.joint == choice.joint)
			return;
		var file = wardrobe.find(choice.path);
		if (file == null) {
			wardrobe.get(choice.path, result -> if (chosen[slot] == choice) switch result {
				case Ready(_): apply(slot);
				case Failed(message): fail(slot, message);
				case Cancelled:
			});
			return;
		}
		takeOff(slot);
		var copy = file.instantiate(slot), models = [], rigid = [];
		collect(copy, models, rigid);
		if (models.length == 0 && rigid.length == 0) {
			fail(slot, '${choice.path}: no model to wear');
			return;
		}
		for (model in models)
			if (!model.bindSkeleton(skeleton)) {
				fail(slot, '${choice.path}: ${model.getName()} names a joint the skeleton hasn\'t');
				return;
			}
		// The rigid models in pieces: each the node just under the nearest of its ancestors the skeleton has a joint of that name for (an
		// importer may split one mesh into several models under it), hung from that joint, or from the socket chosen.
		var pieces:Array<Node> = [], sockets = [];
		for (model in rigid) {
			var piece = model, above = model.getParent();
			while (above != null && above != copy && joint(above.getName()) == null) {
				piece = above;
				above = above.getParent();
			}
			if (pieces.indexOf(piece) >= 0)
				continue;
			var name = choice.joint != null ? choice.joint : above != null && above != copy ? above.getName() : null;
			var socket = name == null ? null : joint(name);
			if (socket == null) {
				fail(slot, '${choice.path}: the skeleton has no joint ${name == null ? "to hang " + piece.getName() + " from" : name}');
				return;
			}
			pieces.push(piece);
			sockets.push(socket);
		}
		var nodes = [];
		for (model in models) {
			model.getParent().remove(model);
			skeleton.add(model);
			nodes.push(model);
		}
		for (i in 0...pieces.length) {
			if (pieces[i].getParent() != null)
				pieces[i].getParent().remove(pieces[i]);
			sockets[i].add(pieces[i]);
			nodes.push(pieces[i]);
		}
		worn[slot] = new Worn(choice.path, choice.joint, nodes);
	}

	// The skeleton's joint (or root) named name, or null.
	function joint(name:String):Null<Node>
		return name == "" ? null : skeleton.getName() == name ? skeleton : skeleton.find(name);

	function fail(slot:String, message:String):Void {
		takeOff(slot);
		errors[slot] = message;
	}

	function takeOff(slot:String):Void {
		var w = worn[slot];
		if (w == null)
			return;
		for (node in w.nodes)
			if (node.getParent() != null)
				node.getParent().remove(node);
		worn.remove(slot);
	}

	// The models under node: skinned ones into models, rigid ones into rigid (a rigid one's own children go with it).
	static function collect(node:Node, models:Array<Node>, rigid:Array<Node>):Void {
		if (node.getKind() == Model && node.getMesh() != null) {
			if (node.getMesh().isSkinned())
				models.push(node);
			else {
				rigid.push(node);
				return;
			}
		}
		for (i in 0...node.getChildCount())
			collect(node.getChild(i), models, rigid);
	}
}

/** A slot's choice: its part's path, and the socket its rigid models hang from (null: the joints their file hangs them from). */
private class Choice {
	/** The part file's path. */
	public final path:String;

	/** The socket chosen, or null. */
	public final joint:Null<String>;

	/** A choice of path, held at joint. */
	public function new(path:String, joint:Null<String>) {
		this.path = path;
		this.joint = joint;
	}
}

/** What a slot wears: its path and socket, and the nodes it added to the character. */
private class Worn {
	/** The part file's path. */
	public final path:String;

	/** The socket chosen, or null. */
	public final joint:Null<String>;

	/** The nodes added to the character: skinned models under the skeleton, rigid pieces under their joints. */
	public final nodes:Array<Node>;

	/** What path, held at joint, added: nodes. */
	public function new(path:String, joint:Null<String>, nodes:Array<Node>) {
		this.path = path;
		this.joint = joint;
		this.nodes = nodes;
	}
}
