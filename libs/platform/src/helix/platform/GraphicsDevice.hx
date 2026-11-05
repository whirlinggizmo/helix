package helix.platform;

/** Represents the GPU and driver a graphics adapter draws with, as the graphics API reports them. A value the API doesn't report is "". */
typedef GraphicsDevice = {
	/** The graphics API: "WebGL 2", "OpenGL", "Vulkan", "Metal" or "Direct3D 12". */
	final api:String;

	/** The GPU's maker, or the driver's. */
	final vendor:String;

	/** The GPU, or the software renderer drawing in its place. */
	final renderer:String;

	/** The API's or the driver's version. */
	final version:String;

	/** The shading language the adapter compiles programs for, and its version. */
	final shadingLanguage:String;
}
