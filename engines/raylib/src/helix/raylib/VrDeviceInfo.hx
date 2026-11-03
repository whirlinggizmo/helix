package helix.raylib;

/** Represents raylib's `VrDeviceInfo`: a head-mounted display's parameters, which `LoadVrStereoConfig` makes a stereo config of. */
@:structInit
class VrDeviceInfo {
	/** Gets or sets the horizontal resolution, in pixels. */
	public var hResolution:Int;

	/** Gets or sets the vertical resolution, in pixels. */
	public var vResolution:Int;

	/** Gets or sets the screen's horizontal size, in meters. */
	public var hScreenSize:Float;

	/** Gets or sets the screen's vertical size, in meters. */
	public var vScreenSize:Float;

	/** Gets or sets the distance from the eyes to the screen, in meters. */
	public var eyeToScreenDistance:Float;

	/** Gets or sets the distance between the lenses' centers, in meters. */
	public var lensSeparationDistance:Float;

	/** Gets or sets the distance between the pupils, in meters. */
	public var interpupillaryDistance:Float;

	/** Gets or sets the lenses' four distortion constants. */
	public var lensDistortionValues:Array<Float>;

	/** Gets or sets the four chromatic aberration correction parameters. */
	public var chromaAbCorrection:Array<Float>;

	/** Creates a VrDeviceInfo.

		@param hResolution  The horizontal resolution, in pixels.
		@param vResolution  The vertical resolution, in pixels.
		@param hScreenSize  The screen's horizontal size, in meters.
		@param vScreenSize  The screen's vertical size, in meters.
		@param eyeToScreenDistance  The distance from the eyes to the screen, in meters.
		@param lensSeparationDistance  The distance between the lenses' centers, in meters.
		@param interpupillaryDistance  The distance between the pupils, in meters.
		@param lensDistortionValues  Optional. The four distortion constants; zeros when omitted.
		@param chromaAbCorrection  Optional. The four chromatic aberration parameters; zeros when omitted. */
	public function new(hResolution:Int = 0, vResolution:Int = 0, hScreenSize:Float = 0, vScreenSize:Float = 0, eyeToScreenDistance:Float = 0,
			lensSeparationDistance:Float = 0, interpupillaryDistance:Float = 0, ?lensDistortionValues:Array<Float>, ?chromaAbCorrection:Array<Float>) {
		this.hResolution = hResolution;
		this.vResolution = vResolution;
		this.hScreenSize = hScreenSize;
		this.vScreenSize = vScreenSize;
		this.eyeToScreenDistance = eyeToScreenDistance;
		this.lensSeparationDistance = lensSeparationDistance;
		this.interpupillaryDistance = interpupillaryDistance;
		this.lensDistortionValues = lensDistortionValues == null ? [0, 0, 0, 0] : lensDistortionValues;
		this.chromaAbCorrection = chromaAbCorrection == null ? [0, 0, 0, 0] : chromaAbCorrection;
	}
}
