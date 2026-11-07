package helix.raylib;

/** Represents a model's materials, raylib's `model.materials`: read and written by index (`model.materials[0] = material`), iterated, and
	with a `length`.

	The model holds a count on each material here. Writing one retains the new material and releases the one it replaces. `UnloadModel`
	releases them all.

	An array assigned to `Model.materials` is copied, so changing the array afterwards changes nothing here. */
@:forward(length, iterator, keyValueIterator, indexOf, contains, copy)
abstract ModelMaterials(Array<Material>) {
	inline function new(materials:Array<Material>)
		this = materials;

	@:from static inline function fromArray(materials:Array<Material>):ModelMaterials
		return new ModelMaterials(materials);

	@:arrayAccess inline function get(index:Int):Material
		return this[index];

	@:arrayAccess function set(index:Int, material:Material):Material {
		helix.raylib.internal.Models.retainMaterial(material);
		var old = index < this.length ? this[index] : null;
		this[index] = material;
		helix.raylib.internal.Models.releaseMaterial(old);
		return material;
	}
}
