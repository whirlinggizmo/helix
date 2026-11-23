package helix.jolt.internal;

/** Chooses hxcpp's settings for a program on helix-jolt, from its extraParams.hxml. Jolt is C++17, and hxcpp's own -std=c++11
	follows a library's flags, so hxcpp's C++11 is turned off (HXCPP_NO_CPP11) and the compiler's default, C++17, holds. On macOS,
	hxcpp's toolchain then links libstdc++, which macOS no longer has, and targets macOS 10.6, which has no thread-local storage for
	hxcpp's own threads. HXCPP_GCC keeps it on libc++, its one effect on a macOS build, and MACOSX_DEPLOYMENT_TARGET, unless the
	program's environment sets it, is 10.15, the oldest macOS Jolt supports. hxcpp's toolchain reads the variable from the environment
	it inherits from the compiler. */
@:noCompletion
class Toolchain {
	public static function select():Void {
		#if macro
		if (Sys.systemName() == "Mac" && !haxe.macro.Context.defined("iphoneos") && !haxe.macro.Context.defined("iphonesim")) {
			haxe.macro.Compiler.define("HXCPP_GCC");
			if (Sys.getEnv("MACOSX_DEPLOYMENT_TARGET") == null)
				Sys.putEnv("MACOSX_DEPLOYMENT_TARGET", "10.15");
		}
		#end
	}
}
