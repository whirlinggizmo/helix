package helix.platform.adapters.system.dom;

import helix.platform.Device;
import helix.platform.ISystem;
import js.Browser;

/** Provides `ISystem` in a browser page: the device as the browser describes it, and options from the URL's query.

	The system comes from the user agent, a touch screen from its touch points, a fine pointer from the any-pointer media query. */
class DomSystemAdapter implements ISystem {
	var params = new js.html.URLSearchParams(Browser.window.location.search);

	/** Creates the system's facts. */
	public function new() {}

	public var device(get, never):Device;

	function get_device():Device {
		var touches:Int = js.Syntax.code("navigator.maxTouchPoints || 0");
		var fine:Bool = js.Syntax.code("window.matchMedia ? window.matchMedia('(any-pointer: fine)').matches : true");
		var agent = Browser.navigator.userAgent;
		return new Device(true, systemOf(agent, touches), architectureOf(agent), touches > 0, fine);
	}

	// The architecture a browser's user agent names ("" for none): ARM's names, then x86-64's, then 32-bit x86's.
	static function architectureOf(agent:String):String {
		if (~/aarch64|arm64|ARM64/.match(agent))
			return "arm64";
		if (~/x86_64|x64|Win64|WOW64|amd64|Intel Mac/.match(agent))
			return "x86_64";
		if (~/i[3-6]86|x86/.match(agent))
			return "x86";
		return "";
	}

	// The operating system a browser's user agent names, as Device names it ("" for none it knows); an iPad saying it's a Mac is told by
	// its touch points.
	static function systemOf(agent:String, touchPoints:Int):String {
		if (agent.indexOf("Android") >= 0)
			return "android";
		if (~/iPhone|iPad|iPod/.match(agent) || agent.indexOf("Macintosh") >= 0 && touchPoints > 1)
			return "ios";
		if (agent.indexOf("CrOS") >= 0)
			return "chromeos";
		if (agent.indexOf("Windows") >= 0)
			return "windows";
		if (agent.indexOf("Mac OS X") >= 0)
			return "macos";
		if (agent.indexOf("Linux") >= 0)
			return "linux";
		return "";
	}

	public function getOption(name:String):Null<String>
		return params.get(name);

	public function getTime():Float
		return js.Browser.window.performance.now() / 1000;

	public function getProgramDirectory():String
		return "./";

	public function getDataDirectory(company:String, product:String):String
		return '$company/$product/data';

	public function getCacheDirectory(company:String, product:String):String
		return '$company/$product/cache';
}
