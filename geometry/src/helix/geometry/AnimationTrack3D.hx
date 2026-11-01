package helix.geometry;

/** Represents one track of an animation: keys moving one part of one bone's transform. */
class AnimationTrack3D {
	/** Gets the index of the bone it moves in the skeleton's `bones`. */
	public final boneIndex:Int;

	/** Gets the part it moves. */
	public final property:AnimationProperty3D;

	/** Gets how it goes between keys. */
	public final interpolation:KeyInterpolation;

	/** Gets the keys' times, in seconds, rising. */
	public final times:Array<Float>;

	/** Gets the keys' values: three numbers a key for a translation or scale, four (x, y, z, w) for a rotation; for `CubicSpline`, each
		key's in-tangent, value and out-tangent, one after another. */
	public final values:Array<Float>;

	/** Creates a track.

		@param boneIndex  The index of the bone it moves.
		@param property  The part it moves.
		@param interpolation  How it goes between keys.
		@param times  The keys' times, rising.
		@param values  The keys' values. */
	public function new(boneIndex:Int, property:AnimationProperty3D, interpolation:KeyInterpolation, times:Array<Float>, values:Array<Float>) {
		this.boneIndex = boneIndex;
		this.property = property;
		this.interpolation = interpolation;
		this.times = times;
		this.values = values;
	}
}
