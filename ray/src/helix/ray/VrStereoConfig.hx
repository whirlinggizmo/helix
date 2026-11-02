package helix.ray;

/** Represents raylib's `VrStereoConfig`: what `BeginVrStereoMode` draws each eye with, and what a distortion shader reads, as
	`LoadVrStereoConfig` computes them from a display's parameters. */
@:structInit
class VrStereoConfig {
	/** Gets or sets each eye's projection: the first drawn in the left half. */
	public var projection:Array<Matrix>;

	/** Gets or sets each eye's view offset, applied after the view. */
	public var viewOffset:Array<Matrix>;

	/** Gets or sets the left lens's center, x and y, 0 to 1 across what is drawn into. */
	public var leftLensCenter:Array<Float>;

	/** Gets or sets the right lens's center. */
	public var rightLensCenter:Array<Float>;

	/** Gets or sets the left screen half's center. */
	public var leftScreenCenter:Array<Float>;

	/** Gets or sets the right screen half's center. */
	public var rightScreenCenter:Array<Float>;

	/** Gets or sets the distortion's scale, x and y. */
	public var scale:Array<Float>;

	/** Gets or sets the distortion's scale in, x and y. */
	public var scaleIn:Array<Float>;

	/** Creates a VrStereoConfig, each omitted field zero.

		@param projection  Optional. Each eye's projection.
		@param viewOffset  Optional. Each eye's view offset.
		@param leftLensCenter  Optional. The left lens's center.
		@param rightLensCenter  Optional. The right lens's center.
		@param leftScreenCenter  Optional. The left screen half's center.
		@param rightScreenCenter  Optional. The right screen half's center.
		@param scale  Optional. The distortion's scale.
		@param scaleIn  Optional. The distortion's scale in. */
	public function new(?projection:Array<Matrix>, ?viewOffset:Array<Matrix>, ?leftLensCenter:Array<Float>, ?rightLensCenter:Array<Float>,
			?leftScreenCenter:Array<Float>, ?rightScreenCenter:Array<Float>, ?scale:Array<Float>, ?scaleIn:Array<Float>) {
		this.projection = projection == null ? [new Matrix(), new Matrix()] : projection;
		this.viewOffset = viewOffset == null ? [new Matrix(), new Matrix()] : viewOffset;
		this.leftLensCenter = leftLensCenter == null ? [0, 0] : leftLensCenter;
		this.rightLensCenter = rightLensCenter == null ? [0, 0] : rightLensCenter;
		this.leftScreenCenter = leftScreenCenter == null ? [0, 0] : leftScreenCenter;
		this.rightScreenCenter = rightScreenCenter == null ? [0, 0] : rightScreenCenter;
		this.scale = scale == null ? [0, 0] : scale;
		this.scaleIn = scaleIn == null ? [0, 0] : scaleIn;
	}
}
