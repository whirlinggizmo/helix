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

	/** Gets null: no test reads the device. */
	public var device(get, never):Device;

	function get_device():Device
		return null;

	public function getOption(name:String):Null<String>
		return options.get(name);

	public function getTime():Float
		return now;

	public function getProgramDirectory():String
		return "program";

	public function getDataDirectory():String
		return 'Company/Game/data';

	public function getCacheDirectory():String
		return 'Company/Game/cache';
}
