package helix.geometry;

/** Represents one track of an animation: keys moving one part of one bone's transform. */
class AnimationTrack3D {
	/** Gets the bone it moves, an index into the skeleton's `bones`. */
	public final bone:Int;

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

		@param bone  The bone it moves.
		@param property  The part it moves.
		@param interpolation  How it goes between keys.
		@param times  The keys' times, rising.
		@param values  The keys' values. */
	public function new(bone:Int, property:AnimationProperty3D, interpolation:KeyInterpolation, times:Array<Float>, values:Array<Float>) {
		this.bone = bone;
		this.property = property;
		this.interpolation = interpolation;
		this.times = times;
		this.values = values;
	}
}
