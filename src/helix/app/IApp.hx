package helix.app;

/** What a host drives. Hosts call through the object each time, so after a hot reload its new methods are what run. */
interface IApp {
	/** Once, before the first frame, with the host's services ready. */
	public function init():Void;

	/** Once a display refresh; dt is the seconds since the last frame (natively sokol's smoothed frame duration, in a browser the raw interval). */
	public function frame(dt:Float):Void;

	/** Once, when the window closes (on the web, at the page's pagehide). */
	public function cleanup():Void;
}
