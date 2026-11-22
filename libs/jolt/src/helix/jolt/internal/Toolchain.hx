package helix.jolt.internal;

/** Chooses hxcpp's settings for a program on helix-jolt, from its extraParams.hxml. Jolt is C++17, and hxcpp's own -std=c++11
	follows a library's flags, so hxcpp's C++11 is turned off (HXCPP_NO_CPP11) and the compiler's default, C++17, holds. On macOS,
	hxcpp's toolchain then links libstdc++, which macOS no longer has; HXCPP_GCC keeps it on libc++, its one effect on a macOS build. */
@:noCompletion
class Toolchain {
	public static function select():Void {
		#if macro
		if (Sys.systemName() == "Mac" && !haxe.macro.Context.defined("iphoneos") && !haxe.macro.Context.defined("iphonesim"))
			haxe.macro.Compiler.define("HXCPP_GCC");
		#end
	}
}
