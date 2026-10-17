package helix.scene;

/** What every node shares, in a 3D tree (Node3D) or a 2D one: a name, the flags (enabled, visible, pickable), a parent and children, and
	find. It has no transform: Node3D adds its own, and takes children of its own kind only (its add and remove). Never made bare and never
	subclassed by a game: the framework's kinds are its classes, and game state lives elsewhere, the node its view (docs/DECISIONS.md, 61 and
	130). */
class Node {
	var name = "";
	var parent:Null<Node>;
	var children:Array<Node> = [];
	var enabled = true;
	var visible = true;
	var pickable = true;

	function new() {}

	/** Its name: a model file's node name, or what the game gave it; "" for none. */
	public function getName():String
		return name;

	/** Names it. */
	public function setName(value:String):Void
		name = value;

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

	/** Whether it takes part at all: off, it and everything under it are skipped by drawing, picking and updates (an emitter under it isn't
		moved on), as if it weren't in the tree. The only flag that reaches its children; theirs are kept, so enabling it brings each back as
		set. On to start. */
	public function isEnabled():Bool
		return enabled;

	/** Turns it, and everything under it, on or off (isEnabled). */
	public function setEnabled(value:Bool):Void
		enabled = value;

	/** Whether its own output is drawn: off, a model, sprite, text or emitter isn't drawn and a light doesn't shine or cast; it stays placed,
		and its children are as they are. On to start. */
	public function isVisible():Bool
		return visible;

	/** Shows or hides its own output (isVisible). */
	public function setVisible(value:Bool):Void
		visible = value;

	/** Whether a pick can hit its own output: off, the ray passes through it, though its children can still be hit. Drawing doesn't matter
		to it: hidden and pickable is a hit area. On to start, but for text. */
	public function isPickable():Bool
		return pickable;

	/** Lets picks hit its own output, or not (isPickable). */
	public function setPickable(value:Bool):Void
		pickable = value;

	/** Its parent, or null. */
	public function getParent():Null<Node>
		return parent;

	/** How many children it has. */
	public function getChildCount():Int
		return children.length;

	/** Its child at index, in drawing order; null past the end. */
	public function getChild(index:Int):Null<Node>
		return index >= 0 && index < children.length ? children[index] : null;

	// Makes child its last child, taking it from any parent it had; false for itself or one of its own ancestors. The subclasses' add, typed.
	function attach(child:Node):Bool {
		var at:Null<Node> = this;
		while (at != null) {
			if (at == child)
				return false;
			at = at.parent;
		}
		if (child.parent != null)
			child.parent.children.remove(child);
		child.parent = this;
		children.push(child);
		return true;
	}

	// Takes child from its children; false when it isn't one. The subclasses' remove, typed.
	function detach(child:Node):Bool {
		if (child.parent != this)
			return false;
		children.remove(child);
		child.parent = null;
		return true;
	}
}
