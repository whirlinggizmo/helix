package helix.ray;

/** Represents a model's materials, raylib's `model.materials`: read and written by index (`model.materials[0] = material`), iterated,
	and with a `length`.

	The model holds a count on each material here (docs/DECISIONS.md 25): writing one retains the new material and releases the one it
	replaces, and `UnloadModel` releases them all. An array assigned to `Model.materials` is copied, so changing it afterwards changes
	nothing here. */
@:forward(length, iterator, keyValueIterator, indexOf, contains, copy)
abstract ModelMaterials(Array<Material>) {
	inline function new(materials:Array<Material>)
		this = materials;

	@:from static inline function fromArray(materials:Array<Material>):ModelMaterials
		return new ModelMaterials(materials);

	@:arrayAccess inline function get(index:Int):Material
		return this[index];

	@:arrayAccess function set(index:Int, material:Material):Material {
		helix.ray.internal.Models.retainMaterial(material);
		var old = index < this.length ? this[index] : null;
		this[index] = material;
		helix.ray.internal.Models.releaseMaterial(old);
		return material;
	}
}
