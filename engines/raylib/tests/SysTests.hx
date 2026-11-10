/** Checks `Sys.args` as helix-raylib gives it in a page: the URL's query as a command line, each `name=value` as `--name=value` and a bare
	`name` as `--name`, in order and decoded, and none without a query. Natively `Sys` is Haxe's own, and the test only reads it. */
class SysTests {
	static var checks = 0;

	static function check(value:Bool, message:String):Void {
		if (!value)
			throw message;
		checks++;
	}

	static function main():Void {
		#if js
		js.Syntax.code("globalThis.location = {search: ''}");
		check(Sys.args().length == 0, 'no query, no options: ${Sys.args()}');
		js.Syntax.code("globalThis.location = {search: '?enemies=200&warp&&name=a%20b+c'}");
		var args = Sys.args();
		check(args.join("|") == "--enemies=200|--warp|--name=a b c", 'the query as a command line: $args');
		#else
		check(Sys.args() != null, "Haxe's own Sys.args");
		#end
		var report = haxe.Json.stringify({passed: true, checks: checks});
		#if js
		js.Syntax.code("console.log({0})", report);
		#else
		Sys.println(report);
		#end
	}
}
