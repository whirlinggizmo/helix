package helix.scene;

/** A behavior as a .scene file attaches it to a node: the behavior class's name and its props by name, as data. The file says which
	behaviors a node gets; at run time they live in the behaviors pass, never on the node. */
class SceneBehavior {
	/** The behavior class's name, as the registry knows it. */
	public var kind:String;

	/** Its props by name: numbers, text, flags, lists, colors and references to nodes of the file. */
	public var props:Map<String, SceneValue> = new Map();

	/** A behavior of class kind with no props set. */
	public function new(kind:String) {
		this.kind = kind;
	}
}
