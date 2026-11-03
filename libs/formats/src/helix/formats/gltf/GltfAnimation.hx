package helix.formats.gltf;

/** Represents a glTF animation: channels, each moving one property of one node by a sampler's keys. */
class GltfAnimation {
	/** Gets its name: empty when the file gives none. */
	public final name:String;

	/** Gets its channels. */
	public final channels:Array<GltfChannel>;

	/** Gets its samplers, which the channels name by index. */
	public final samplers:Array<GltfSampler>;

	@:allow(helix.formats.gltf)
	function new(name:String, channels:Array<GltfChannel>, samplers:Array<GltfSampler>) {
		this.name = name;
		this.channels = channels;
		this.samplers = samplers;
	}
}
