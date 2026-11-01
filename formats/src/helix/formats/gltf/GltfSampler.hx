package helix.formats.gltf;

/** Represents a glTF animation sampler: keys at times, and how to go between them. */
class GltfSampler {
	/** Gets the keys' times, in seconds, rising. */
	public final input:Array<Float>;

	/** Gets the keys' values, as floats, one value's components after another (for "CUBICSPLINE", each key's in-tangent, value and
		out-tangent); normalized integers scaled as `GltfPrimitive`'s are. */
	public final output:Array<Float>;

	/** Gets how to go between keys: "LINEAR", "STEP" or "CUBICSPLINE". */
	public final interpolation:String;

	@:allow(helix.formats.gltf)
	function new(input:Array<Float>, output:Array<Float>, interpolation:String) {
		this.input = input;
		this.output = output;
		this.interpolation = interpolation;
	}
}
