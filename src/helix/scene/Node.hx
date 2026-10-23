package helix.scene;

/** What every node shares, in a 3D tree (Node3D) or a 2D one: a name, the flags (visible, paused, pickable), a parent and children, and
	find. It has no transform: Node3D and Node2D add their own, each taking children of its own kind only (its addChild and removeChild). Never made bare and never
	subclassed by a game: the framework's kinds are its classes, and game state lives elsewhere, the node its view (docs/DECISIONS.md, 61 and
	130). */
class Node {
	// Its parent: read and set through each tree's own typed parent (Node3D's, Node2D's).
	var parentNode:Null<Node>;
	var children:Array<Node> = [];

	function new() {}

	/** Its name: a model file's node name, or what the game gave it; "" for none. */
	public var name:String = "";

	/** The first node named name below it (depth first, in drawing order), or null: for picking out a part of a loaded model (its wheels, a
		lamp), once, and keeping the node. Never a path. */
	public function find(name:String):Null<Node> {
		for (child in children) {
			if (child.name == name)
				return child;
			var found = child.find(name);
			if (found != null)
				return found;
		}
		return null;
	}

	/** Whether it and everything under it are shown: off, none of it is drawn or picked (a light doesn't shine or cast), though it all still
		runs (behaviors, emitters) and stays placed. A child's own visible is kept, so showing it again brings each back as set. On to start. */
	public var visible:Bool = true;

	/** Whether it and everything under it are frozen: on, still drawn and picked, but their behaviors don't update and what moves by itself
		(emitters, decals fading, animated tiles) holds still (a level frozen under a pause menu, docs/DISPLAY_MODEL.md). Off to start. */
	public var paused:Bool = false;

	/** Whether it and everything under it can be picked: off, a pick passes through them all to what's behind. What a node is hit by is what
		it draws, or its hitArea when it has one. On to start, but for text. */
	public var pickable:Bool = true;

	/** How many children it has. */
	public var childCount(get, never):Int;

	function get_childCount():Int
		return children.length;

	/** Its child at index, in drawing order; null past the end. */
	public function getChild(index:Int):Null<Node>
		return index >= 0 && index < children.length ? children[index] : null;

	// Whether child can be made its child: false for itself or one of its own ancestors.
	function canLink(child:Node):Bool {
		var at:Null<Node> = this;
		while (at != null) {
			if (at == child)
				return false;
			at = at.parentNode;
		}
		return true;
	}

	// Makes child its last child, taking it from any parent it had; false for itself or one of its own ancestors. The subclasses' addChild, typed.
	function link(child:Node):Bool {
		if (!canLink(child))
			return false;
		if (child.parentNode != null)
			child.parentNode.children.remove(child);
		child.parentNode = this;
		children.push(child);
		return true;
	}

	// Takes child from its children; false when it isn't one. The subclasses' removeChild, typed.
	function unlink(child:Node):Bool {
		if (child.parentNode != this)
			return false;
		children.remove(child);
		child.parentNode = null;
		return true;
	}
}
