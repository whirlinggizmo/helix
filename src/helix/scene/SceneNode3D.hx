package helix.scene;

/** A node as a .scene3d file has it, not a live one: its kind (or the prefab it instantiates), name, a Model's glTF or generated mesh, its
	transform and flags (each null when unsaid), its kind's properties by name, an inline material, overrides by path for the nodes its file or prefab makes, its children,
	the behaviors to attach and the game's own props. Each absent part means the default: a null transform is identity, a null flag true, a
	property its class's. An override is a SceneNode3D too, with no name, kind or scene: only what it changes, plus children and behaviors to
	add. Phase 3 of the file's plan makes live nodes from these and captures them back. */
class SceneNode3D {
	/** Its name, unique among its siblings (paths depend on it); null for an override. */
	public var name:Null<String>;

	/** The class it is (Node3D for a group, else a kind's name from SceneSchema); null for a prefab node or an override. */
	public var kind:Null<String>;

	/** The .scene3d file instantiated here as a prefab; null for a node of a kind or an override. */
	public var scene:Null<String>;

	/** A Model's glTF, instantiated under it; null for none. A Model has a file or a mesh, never both. */
	public var file:Null<String>;

	/** A Model's generated mesh, made by one of Mesh's generators as its first part; null for none. */
	public var mesh:Null<SceneMesh>;

	/** Its position, x, y, z in its parent's units; null for the origin. */
	public var position:Null<Array<Float>>;

	/** Its rotation, Euler x, y, z in radians as Node3D.setRotation takes them; null for none. */
	public var rotation:Null<Array<Float>>;

	/** Its scale, x, y, z; null for 1, 1, 1. */
	public var scale:Null<Array<Float>>;

	/** Whether it takes part at all (Node.enabled), as the file says it; null for unsaid: a node's default, true, when instantiated, and
		unchanged for an override, which may say true to bring a prefab's disabled node back. */
	public var enabled:Null<Bool>;

	/** Whether its own output is drawn (Node.visible), as the file says it; null for unsaid: true for a node, unchanged for an override. */
	public var visible:Null<Bool>;

	/** Whether a pick can hit it (Node.pickable), as the file says it; null for unsaid: true for a node, unchanged for an override. */
	public var pickable:Null<Bool>;

	/** Its kind's properties by name (intensity, fovY, tint), from its kind's table in SceneSchema; one absent is the class's default.
		An override's name any kind's property. */
	public var properties:Map<String, SceneValue> = new Map();

	/** A Model's inline material, replacing the mesh's or the file's root material; null for none. */
	public var material:Null<SceneMaterial>;

	/** By path from this node ("road/line"), what changes on the nodes its file or prefab makes: each an override node. */
	public var overrides:Map<String, SceneNode3D> = new Map();

	/** The nodes under it, in drawing order; under an override, the nodes added. */
	public var children:Array<SceneNode3D> = [];

	/** The behaviors attached to it when the scene is instantiated. */
	public var behaviors:Array<SceneBehavior> = [];

	/** The game's own values by name, kept by the instance for this node, never on the live node. */
	public var props:Map<String, SceneValue> = new Map();

	/** A node of kind (null for a prefab node or an override), named name (null for an override), everything else at its default. */
	public function new(?kind:String, ?name:String) {
		this.kind = kind;
		this.name = name;
	}

	/** Whether it is an override: no name, no kind and no prefab, only what changes on a node another file made. */
	public var isOverride(get, never):Bool;

	function get_isOverride():Bool
		return name == null && kind == null && scene == null;
}
