package helix.platform;

/** Represents what the program runs on, as far as the platform reports it.

	It tells a browser from native, and names the operating system and the processor's architecture. It also reports whether there is a
	fine pointer. `ITouch.available` reports touch.

	A game uses it to choose what it shows on each device, such as "tap" or "click" in a prompt, or a landscape lock. */
class Device {
	/** Gets a value indicating whether the program runs in a browser page rather than natively. */
	public final browser:Bool;

	/** Gets the operating system, in lowercase: "windows", "macos", "linux", "android", "ios" or "chromeos".

		It is "" when the platform doesn't report one. */
	public final os:String;

	/** Gets the processor architecture the program runs as, in lowercase: "x86_64", "arm64" or "x86".

		Natively it is the architecture the program was built for. In a page it is the one the browser names, or "" when the browser names
		none. A browser may name none, or the wrong one. Safari on Apple silicon reports Intel. */
	public final architecture:String;

	/** Gets a value indicating whether there is a fine pointer, such as a mouse, a trackpad or a pen.

		It is false on a phone or a tablet alone. */
	public final finePointer:Bool;

	/** Creates a device description. The system adapters call it. */
	@:noCompletion
	public function new(browser:Bool, os:String, architecture:String, finePointer:Bool) {
		this.browser = browser;
		this.os = os;
		this.architecture = architecture;
		this.finePointer = finePointer;
	}
}
