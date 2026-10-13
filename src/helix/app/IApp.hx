package helix.app;

/** What a host drives. Hosts call through the object each time, so after a hot reload its new methods are what run. */
interface IApp {
	/** Once, before the first frame, with the host's services ready. */
	public function init():Void;

	/** Once a display refresh; dt is the measured seconds since the last frame, held between 1e-6 and 0.1, and 1/60 on the first: for animation. A fixed-rate simulation takes IHost.getFrameElapsed instead (helix.host.FrameClock). */
	public function frame(dt:Float):Void;

	/** Once, when the window closes (on the web, at the page's pagehide). */
	public function cleanup():Void;
}
