#if macro
import haxe.macro.Context;
import haxe.macro.Expr;
import haxe.macro.Type;
#end

/** Writes, as the program builds, a call to every function of `helix.raylib.Raylib`, `Raymath`, `Rlgl`, `Raygui` and `helix.raylib.extras` a program can call, read from
	the compiler's types of them, so the size ladder's last rung links all of helix-raylib. Each argument is `Everything.value` and each result
	goes to `Everything.result`, both of no type, so nothing a call is given or returns is known as the program builds and nothing is
	folded away. The functions that refuse to compile (a section's `@:unsupported` or `@:unimplemented`) are left out; the macro functions
	that choose a reader by a constant file name (DECISIONS 29) are called by hand in `Main`, once for each reader, and named in
	`BY_HAND`, so a macro function added to helix-raylib and not called fails the build here. A build step (`BUILD_STEPS`) is left out.
	It runs as a `--macro`, not in a program. */
class Everything {
	/** What every generated call is given: unknown as the program builds. */
	public static var value:Dynamic = null;

	/** Where every generated call's result goes, so none is dropped as unused. */
	public static var result:Dynamic = null;

	#if macro
	/** The facades whose functions are called. */
	static final FACADES = [
		"helix.raylib.Raylib",
		"helix.raylib.Raymath",
		"helix.raylib.Rlgl",
		"helix.raylib.Raygui",
		"helix.raylib.Rlights",
		"helix.raylib.extras.Models",
		"helix.raylib.extras.Lighting",
		"helix.raylib.extras.VirtualGamepad",
		"helix.raylib.extras.Device"
	];

	/** raylib's modules in helix-raylib, whose functions carry the refusals' metadata. */
	static final SECTIONS = [
		"RAudio",
		"RAudioAsync",
		"RCore",
		"RDevice",
		"RFilesAsync",
		"RGui",
		"RGuiAsync",
		"RGuiControls",
		"RLighting",
		"RLights",
		"RMath",
		"RModels",
		"RModelsAsync",
		"RModelsPosed",
		"RModelsMerged",
		"RRlgl",
		"RShapes",
		"RText",
		"RTextAsync",
		"RTextures",
		"RTexturesAsync",
		"RVirtualGamepad",
		"RWindowAsync"
	];

	/** The section metadata that makes a function refuse to compile. */
	static final REFUSALS = [":unsupported", ":unimplemented"];

	/** The macro functions a build runs as a `--macro`, which a program doesn't call. */
	static final BUILD_STEPS = ["CompileShaderFile"];

	/** The macro functions Main calls by hand, with a constant name of each extension their readers are chosen by. */
	static final BY_HAND = [
		"LoadModelAsync",
		"LoadImageAsync",
		"LoadImageFromMemoryAsync",
		"LoadTextureAsync",
		"LoadFontAsync",
		"LoadImageAnimAsync",
		"LoadImageAnimFromMemoryAsync",
		"LoadWaveAsync",
		"LoadWaveFromMemoryAsync",
		"LoadAutomationEventList"
	];
	#end

	/** Returns a call to every function the facades have that a program can call and Main doesn't call by hand. With `-D
		everything-count`, prints how many it calls and how many refuse.

		@return  The calls, a block. */
	public static macro function calls():Expr {
		var refused = new Map<String, Bool>();
		for (section in SECTIONS)
			switch Context.getType('helix.raylib.modules.$section') {
				case TInst(_.get() => c, _):
					for (f in c.statics.get())
						if (Lambda.exists(REFUSALS, m -> f.meta.has(m)))
							refused[f.name] = true;
				case _:
			}
		var calls:Array<Expr> = [], counts:Array<String> = [], refusedCount = 0, byHand = 0;
		for (facade in FACADES) {
			var called = 0;
			switch Context.getType(facade) {
				case TInst(_.get() => c, _):
					for (f in c.statics.get()) {
						if (!f.isPublic)
							continue;
						switch f.kind {
							case FMethod(MethMacro):
								if (refused.exists(f.name)) refusedCount++; else if (BY_HAND.contains(f.name)) byHand++; else
									if (!BUILD_STEPS.contains(f.name))
										Context.error('Everything: $facade.${f.name} is a macro function Main doesn\'t call by hand', Context.currentPos());
							case FMethod(_):
								calls.push(call(facade, f));
								called++;
							case _:
						}
					}
				case _:
					Context.error('Everything: $facade is not a class', Context.currentPos());
			}
			counts.push('$facade $called');
		}
		if (Context.defined("everything-count"))
			Sys.println('Everything: ${counts.join(", ")} called; $byHand macro functions by hand in Main; $refusedCount refuse to compile');
		return macro $b{calls};
	}

	#if macro
	// A call to a facade's function with every argument Everything.value (a rest argument given none), its result kept.
	static function call(facade:String, f:ClassField):Expr {
		var path = facade.split(".").concat([f.name]);
		return switch Context.follow(f.type) {
			case TFun(args, ret):
				var values = [
					for (a in args)
						if (!isRest(a.t)) macro Everything.value
				];
				var e = macro $p{path}($a{values});
				isVoid(ret) ? e : macro Everything.result = $e;
			case _:
				Context.error('Everything: $facade.${f.name} is not a function', Context.currentPos());
		}
	}

	static function isRest(t:Type):Bool {
		return switch t {
			case TAbstract(_.get() => a, _): a.pack.join(".") == "haxe" && a.name == "Rest";
			case TType(_, _) | TLazy(_): isRest(Context.follow(t, true));
			case _: false;
		}
	}

	static function isVoid(t:Type):Bool {
		return switch Context.follow(t) {
			case TAbstract(_.get() => a, _): a.pack.length == 0 && a.name == "Void";
			case _: false;
		}
	}
	#end
}
