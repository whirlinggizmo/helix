package helix.formats.obj;

/** Represents a part of an OBJ model, as `ObjFile.computeParts` gathers them: the faces of one object, group and material, split into
	triangles. */
class ObjPart {
	/** Gets the object's name, as `ObjGroup.objectName`; "" when parts aren't by group. */
	public final objectName:String;

	/** Gets the group's name, as `ObjGroup.groupName`; "" when parts aren't by group. */
	public final groupName:String;

	/** Gets the material, by its index in `ObjFile.materialNames` (and in what `ObjFile.computeMaterials` returns), or -1 for faces
		before any `usemtl`. */
	public final materialIndex:Int;

	/** Gets the material's name, as the file's `usemtl` gives it, or "" for faces before any `usemtl`. */
	public final materialName:String;

	/** Gets the triangles, three corners each, by their index in the corner arrays (`ObjFile.cornerPositionIndices` and the others). */
	public final cornerIndices:haxe.ds.ReadOnlyArray<Int>;

	/** Gets how many triangles it has: a third of `cornerIndices`' length. */
	public final triangleCount:Int;

	@:allow(helix.formats.obj)
	function new(objectName:String, groupName:String, materialIndex:Int, materialName:String, cornerIndices:haxe.ds.ReadOnlyArray<Int>, triangleCount:Int) {
		this.objectName = objectName;
		this.groupName = groupName;
		this.materialIndex = materialIndex;
		this.materialName = materialName;
		this.cornerIndices = cornerIndices;
		this.triangleCount = triangleCount;
	}
}
