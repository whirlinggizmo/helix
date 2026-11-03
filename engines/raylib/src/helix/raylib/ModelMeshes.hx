package helix.raylib;

/** Represents a model's meshes, raylib's `model.meshes`: read and written by index (`model.meshes[0] = mesh`), iterated, and with a
	`length`.

	The model holds a count on each mesh here (docs/DECISIONS.md 25): writing one retains the new mesh and releases the one it replaces,
	and `UnloadModel` releases them all. An array assigned to `Model.meshes` is copied, so changing it afterwards changes nothing here. */
@:forward(length, iterator, keyValueIterator, indexOf, contains, copy)
abstract ModelMeshes(Array<Mesh>) {
	inline function new(meshes:Array<Mesh>)
		this = meshes;

	@:from static inline function fromArray(meshes:Array<Mesh>):ModelMeshes
		return new ModelMeshes(meshes);

	@:arrayAccess inline function get(index:Int):Mesh
		return this[index];

	@:arrayAccess function set(index:Int, mesh:Mesh):Mesh {
		helix.raylib.internal.Models.retainMesh(mesh);
		var old = index < this.length ? this[index] : null;
		this[index] = mesh;
		helix.raylib.internal.Models.releaseMesh(old);
		return mesh;
	}
}
