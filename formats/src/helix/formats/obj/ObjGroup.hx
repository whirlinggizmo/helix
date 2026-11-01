package helix.formats.obj;

/** Represents a run of an OBJ model's faces that are in one object and one group: the faces after an `o` or `g` line, up to the next
	such line. */
class ObjGroup {
	/** Gets the object the faces are in: the name the last `o` line gives, the whole rest of its line, or "" before the first. */
	public final objectName:String;

	/** Gets the group the faces are in: the name the last `g` line in this object gives, the whole rest of its line (a line naming
		several groups keeps them as written), or "" when the object has none yet: an `o` line starts its object with no group. */
	public final groupName:String;

	/** Gets the index of its first face in the face arrays (`ObjFile.faceVertexCounts` and the others). */
	public final firstFaceIndex:Int;

	/** Gets how many faces it has; at least 1. */
	public final faceCount:Int;

	@:allow(helix.formats.obj)
	function new(objectName:String, groupName:String, firstFaceIndex:Int, faceCount:Int) {
		this.objectName = objectName;
		this.groupName = groupName;
		this.firstFaceIndex = firstFaceIndex;
		this.faceCount = faceCount;
	}
}
