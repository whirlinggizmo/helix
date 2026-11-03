package helix.formats.gltf;

/** Represents one channel of a glTF animation: which node's property it moves, by which sampler. */
class GltfChannel {
	/** Gets the index of the node it moves into `GltfFile.nodes`, or -1 when the file names none. */
	public final nodeIndex:Int;

	/** Gets the property: "translation", "rotation" (a quaternion, x, y, z, w), "scale" or "weights" (morph targets). */
	public final path:String;

	/** Gets the index of its sampler in its animation's `samplers`. */
	public final samplerIndex:Int;

	@:allow(helix.formats.gltf)
	function new(nodeIndex:Int, path:String, samplerIndex:Int) {
		this.nodeIndex = nodeIndex;
		this.path = path;
		this.samplerIndex = samplerIndex;
	}
}
