package helix.formats.gltf;

/** Represents one channel of a glTF animation: which node's property it moves, by which sampler. */
class GltfChannel {
	/** Gets the node it moves, an index into `GltfFile.nodes`, or -1 when the file names none. */
	public final node:Int;

	/** Gets the property: "translation", "rotation" (a quaternion, x, y, z, w), "scale" or "weights" (morph targets). */
	public final path:String;

	/** Gets its sampler, an index into its animation's `samplers`. */
	public final sampler:Int;

	@:allow(helix.formats.gltf)
	function new(node:Int, path:String, sampler:Int) {
		this.node = node;
		this.path = path;
		this.sampler = sampler;
	}
}
