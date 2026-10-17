package helix.render3d;

/** A model: its parts, each a mesh drawn with a material (a glTF node with several primitives is one model of several parts), tinted
	(0xRRGGBBAA, white for none; its alpha below 255 makes it see-through), casting and receiving shadows. A model of a skinned mesh follows
	the joints it's bound to (bindSkeleton). Its mesh and material are its first part's. */
class Model extends Node3D {
	var parts:Array<Part> = [];
	var castsShadows = true;
	var receivesShadows = true;
	var joints:Null<Array<Node3D>>;

	/** A model of one part, mesh drawn with material (a new white one when null); with no mesh, a model of no parts until mesh. */
	public function new(?mesh:Mesh, ?material:Material) {
		super();
		if (mesh != null)
			parts.push(new Part(mesh, material));
	}

	/** How many parts it has. */
	public var partCount(get, never):Int;

	function get_partCount():Int
		return parts.length;

	/** Its part at index, in the file's order; null past the end. */
	public function getPart(index:Int):Null<Part>
		return index >= 0 && index < parts.length ? parts[index] : null;

	/** Adds a part, mesh drawn with material (a new white one when null), after the others. */
	public function addPart(mesh:Mesh, ?material:Material):Void
		parts.push(new Part(mesh, material));

	/** Its first part's mesh, or null with no parts. Assigned to a model with no parts, it makes that part (white). */
	public var mesh(get, set):Null<Mesh>;

	function get_mesh():Null<Mesh>
		return parts.length > 0 ? parts[0].mesh : null;

	function set_mesh(value:Null<Mesh>):Null<Mesh> {
		if (parts.length == 0)
			parts.push(new Part(value));
		else
			parts[0].mesh = value;
		return value;
	}

	/** Its first part's material, or null with no parts. Assigned to a model with no parts, it makes that part (with no mesh). */
	public var material(get, set):Null<Material>;

	function get_material():Null<Material>
		return parts.length > 0 ? parts[0].material : null;

	function set_material(value:Null<Material>):Null<Material> {
		if (parts.length == 0)
			parts.push(new Part(null, value));
		else
			parts[0].material = value;
		return value;
	}

	/** Its tint, 0xRRGGBBAA. */
	public var tint:Int = 0xffffffff;

	/** Whether it casts shadows (from the lights that cast them; see-through models never do). True by default. */
	public var shadowCasting(get, set):Bool;

	function get_shadowCasting():Bool
		return castsShadows;

	function set_shadowCasting(value:Bool):Bool {
		castsShadows = value;
		return value;
	}

	/** Whether shadows fall on it. True by default. */
	public var shadowReceiving(get, set):Bool;

	function get_shadowReceiving():Bool
		return receivesShadows;

	function set_shadowReceiving(value:Bool):Bool {
		receivesShadows = value;
		return value;
	}

	/** Its skin (its mesh's joints by name), or null: a model of a skinned mesh without one draws in its bind pose. */
	public var skin(default, null):Null<Skin>;

	/** How many joints it follows: its skin's, once bound; 0 otherwise. */
	public var jointCount(get, never):Int;

	function get_jointCount():Int
		return joints == null ? 0 : joints.length;

	/** The node its joint index follows; null past them or unbound. */
	public function getJoint(index:Int):Null<Node3D>
		return joints == null || index < 0 || index >= joints.length ? null : joints[index];

	/** Binds it, a model of a skinned mesh, to a skeleton: each of skin's joints (its own skin when null) to the node of that name at or under
		skeleton, which must be on the same stage, so its vertices follow them. A piece of gear skinned in a file of its own follows a character
		this way, by joint name. False, changing nothing, for a mesh that isn't skinned, no skin, or a joint name the skeleton lacks. */
	public function bindSkeleton(skeleton:Node3D, ?skin:Skin):Bool {
		var chosen = skin != null ? skin : this.skin, mesh = this.mesh;
		if (mesh == null || !mesh.skinned || chosen == null)
			return false;
		var found = [];
		for (j in 0...chosen.jointCount) {
			var name = chosen.getJointName(j);
			var node = skeleton.name == name ? skeleton : skeleton.find(name);
			if (node == null)
				return false;
			found.push(node);
		}
		this.skin = chosen;
		joints = found;
		return true;
	}
}
