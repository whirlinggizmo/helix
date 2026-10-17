package helix.render3d;

/** A model: its parts, each a mesh drawn with a material (a glTF node with several primitives is one model of several parts), tinted
	(0xRRGGBBAA, white for none; its alpha below 255 makes it see-through), casting and receiving shadows. A model of a skinned mesh follows
	the joints it's bound to (bindSkeleton). Its mesh and material are its first part's. */
class Model extends Node3D {
	var parts:Array<Part> = [];
	var tint = 0xffffffff;
	var castsShadows = true;
	var receivesShadows = true;
	var skin:Null<Skin>;
	var joints:Null<Array<Node3D>>;

	/** A model of one part, mesh drawn with material (a new white one when null); with no mesh, a model of no parts until setMesh. */
	public function new(?mesh:Mesh, ?material:Material) {
		super();
		if (mesh != null)
			parts.push(new Part(mesh, material));
	}

	/** How many parts it has. */
	public function getPartCount():Int
		return parts.length;

	/** Its part at index, in the file's order; null past the end. */
	public function getPart(index:Int):Null<Part>
		return index >= 0 && index < parts.length ? parts[index] : null;

	/** Adds a part, mesh drawn with material (a new white one when null), after the others. */
	public function addPart(mesh:Mesh, ?material:Material):Void
		parts.push(new Part(mesh, material));

	/** Its first part's mesh, or null with no parts. */
	public function getMesh():Null<Mesh>
		return parts.length > 0 ? parts[0].getMesh() : null;

	/** Gives its first part another mesh, making that part (white) when it has none. */
	public function setMesh(value:Mesh):Void {
		if (parts.length == 0)
			parts.push(new Part(value));
		else
			parts[0].setMesh(value);
	}

	/** Its first part's material, or null with no parts. */
	public function getMaterial():Null<Material>
		return parts.length > 0 ? parts[0].getMaterial() : null;

	/** Gives its first part another material. False, changing nothing, with no parts. */
	public function setMaterial(value:Material):Bool {
		if (parts.length == 0)
			return false;
		parts[0].setMaterial(value);
		return true;
	}

	/** Its tint, 0xRRGGBBAA. */
	public function getTint():Int
		return tint;

	/** Sets its tint, 0xRRGGBBAA: white for none, an alpha below 255 makes it see-through. */
	public function setTint(value:Int):Void
		tint = value;

	/** Whether it casts shadows (from the lights that cast them; see-through models never do). True by default. */
	public function isShadowCasting():Bool
		return castsShadows;

	/** Makes it cast shadows or not. */
	public function setShadowCasting(value:Bool):Void
		castsShadows = value;

	/** Whether shadows fall on it. True by default. */
	public function isShadowReceiving():Bool
		return receivesShadows;

	/** Lets shadows fall on it or not. */
	public function setShadowReceiving(value:Bool):Void
		receivesShadows = value;

	/** Its skin (its mesh's joints by name), or null: a model of a skinned mesh without one draws in its bind pose. */
	public function getSkin():Null<Skin>
		return skin;

	/** How many joints it follows: its skin's, once bound; 0 otherwise. */
	public function getJointCount():Int
		return joints == null ? 0 : joints.length;

	/** The node its joint index follows; null past them or unbound. */
	public function getJoint(index:Int):Null<Node3D>
		return joints == null || index < 0 || index >= joints.length ? null : joints[index];

	/** Binds it, a model of a skinned mesh, to a skeleton: each of skin's joints (its own skin when null) to the node of that name at or under
		skeleton, which must be on the same stage, so its vertices follow them. A piece of gear skinned in a file of its own follows a character
		this way, by joint name. False, changing nothing, for a mesh that isn't skinned, no skin, or a joint name the skeleton lacks. */
	public function bindSkeleton(skeleton:Node3D, ?skin:Skin):Bool {
		var chosen = skin != null ? skin : this.skin, mesh = getMesh();
		if (mesh == null || !mesh.isSkinned() || chosen == null)
			return false;
		var found = [];
		for (j in 0...chosen.getJointCount()) {
			var name = chosen.getJointName(j);
			var node = skeleton.getName() == name ? skeleton : skeleton.find(name);
			if (node == null)
				return false;
			found.push(node);
		}
		this.skin = chosen;
		joints = found;
		return true;
	}
}
