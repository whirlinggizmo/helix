import helix.platform.Device;
import helix.platform.ISystem;

/** Stands in for the platform's system in the services' tests: options from a map, and a clock the test moves by hand. */
class FakeSystem implements ISystem {
	/** Gets the options it answers with, by name. */
	public final options = new Map<String, String>();

	/** Gets or sets the seconds `getTime` returns. */
	public var now = 0.;

	/** Creates one with no options at time 0. */
	public function new() {}

	/** Gets or sets what `device` returns: null until a test sets it. */
	public var described:Null<Device> = null;

	/** Gets "Company". */
	public var company(default, null):String = "Company";

	/** Gets "Game". */
	public var product(default, null):String = "Game";

	public var device(get, never):Device;

	function get_device():Device
		return described;

	public function getOption(name:String):Null<String>
		return options.get(name);

	public function getTime():Float
		return now;

	public function getMemoryBytes():Float
		return 0;

	public function getProgramDirectory():String
		return "program";

	public function getDataDirectory():String
		return '$company/$product/data';

	public function getCacheDirectory():String
		return '$company/$product/cache';

	/** Gets the URLs `openUrl` was asked to open, in order. */
	public final opened:Array<String> = [];

	/** Records the URL as opened. */
	public function openUrl(url:String):Bool {
		opened.push(url);
		return true;
	}
}
