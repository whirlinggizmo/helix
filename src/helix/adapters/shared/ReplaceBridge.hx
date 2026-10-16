package helix.adapters.shared;

#if cpp
@:buildXml('<files id="helix-shared-replace" dir="${HELIX_ROOT}/src/helix/adapters">
 <compilerflag value="-I${HELIX_ROOT}/src/helix/adapters/shared"/>
 <compilerflag value="-DNDEBUG"/><compilerflag value="-O2" if="windows"/><compilerflag value="-O3" unless="windows"/>
 <depend name="${HELIX_ROOT}/src/helix/adapters/shared/replace.h"/>
 <file name="shared/replace.c"/>
</files>
<files id="haxe"><compilerflag value="-I${HELIX_ROOT}/src/helix/adapters/shared"/></files>
<target id="haxe">
 <files id="helix-shared-replace"/>
</target>')
/** Built with the app by hxcpp, once for every adapter that writes files: replacing a file in one step (replace.c), which Windows' rename
	can't. */
@:include("replace.h")
extern class ReplaceBridge {
	@:native("helix_replace_file") static function replace(from:cpp.ConstCharStar, to:cpp.ConstCharStar):Int;
}
#else

/** Elsewhere (the interpreter's tests): the target's rename, which replaces an existing file on the systems the tests run on but Windows'. */
class ReplaceBridge {
	/** 1 when from replaced to, else 0, as replace.c's. */
	public static function replace(from:String, to:String):Int {
		if (Sys.systemName() == "Windows" && sys.FileSystem.exists(to))
			sys.FileSystem.deleteFile(to);
		sys.FileSystem.rename(from, to);
		return 1;
	}
}
#end
