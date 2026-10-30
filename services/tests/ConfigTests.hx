import helix.services.config.Config;

/** Checks Config over a fake system: options given or not, text as given, true and false in their spellings, whole numbers and numbers
	strictly, each falling back on what it can't read. */
class ConfigTests {
	static var checks = 0;

	static function check(value:Bool, message:String):Void {
		if (!value)
			throw message;
		checks++;
	}

	static function main():Void {
		var system = new FakeSystem();
		var config = new Config(system);
		check(!config.hasOption("speed") && config.getString("speed", "x") == "x", "not given: the fallback");
		system.options.set("empty", "");
		check(config.hasOption("empty") && config.getString("empty", "x") == "", "given empty: has it, as given");

		for (word in ["1", "true", "YES", " On "]) {
			system.options.set("b", word);
			check(config.getBool("b", false), 'true: "$word"');
		}
		for (word in ["0", "False", "no", "OFF"]) {
			system.options.set("b", word);
			check(!config.getBool("b", true), 'false: "$word"');
		}
		system.options.set("b", "maybe");
		check(config.getBool("b", true) && !config.getBool("b", false), "neither: the fallback");

		for (pair in [
			{text: "42", value: 42},
			{text: "-7", value: -7},
			{text: "+3", value: 3},
			{text: "010", value: 10},
			{text: " 5 ", value: 5}
		]) {
			system.options.set("i", pair.text);
			check(config.getInt("i", 0) == pair.value, 'whole: "${pair.text}"');
		}
		for (word in ["4.5", "12abc", "", "0x10", "99999999999"]) {
			system.options.set("i", word);
			check(config.getInt("i", -1) == -1, 'not whole: "$word"');
		}

		for (pair in [
			{text: "2", value: 2.},
			{text: "0.5", value: .5},
			{text: ".25", value: .25},
			{text: "-1e3", value: -1000.},
			{text: "3.", value: 3.}
		]) {
			system.options.set("f", pair.text);
			check(config.getFloat("f", 0) == pair.value, 'number: "${pair.text}"');
		}
		for (word in ["abc", "1.5x", "", "Infinity", "NaN", "1e999"]) {
			system.options.set("f", word);
			check(config.getFloat("f", -1) == -1, 'not a finite number: "$word"');
		}
		var report = haxe.Json.stringify({passed: true, checks: checks});
		#if js
		js.Syntax.code("console.log({0})", report);
		#else
		Sys.println(report);
		#end
	}
}
