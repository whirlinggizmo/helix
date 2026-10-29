package helix.platform;

/** Represents what the program runs on, as far as the platform says: a browser or native, the operating system, a touch screen, a fine
	pointer.

	A game uses it for what it shows by device: touch controls on a phone, "tap" or "click" in a prompt, a landscape lock. A browser can be
	wrong about a laptop with a touch screen (it has both), so touch controls also appear on the first touch, not by device alone. */
class Device {
	/** Gets a value indicating whether the program runs in a browser page rather than natively. */
	public final browser:Bool;

	/** Gets the operating system, lowercase: "windows", "macos", "linux", "android", "ios", "chromeos"; "" when the platform doesn't say. */
	public final os:String;

	/** Gets a value indicating whether there is a touch screen; natively always false. */
	public final touchScreen:Bool;

	/** Gets a value indicating whether there is a fine pointer: a mouse, a trackpad or a pen. False on a phone or a tablet alone. */
	public final finePointer:Bool;

	/** Gets a value indicating whether it is a phone or a tablet: a touch screen and no fine pointer. */
	public var mobile(get, never):Bool;

	function get_mobile():Bool
		return touchScreen && !finePointer;

	/** Creates a device description; the system adapters make it. */
	@:noCompletion
	public function new(browser:Bool, os:String, touchScreen:Bool, finePointer:Bool) {
		this.browser = browser;
		this.os = os;
		this.touchScreen = touchScreen;
		this.finePointer = finePointer;
	}
}
