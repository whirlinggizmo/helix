package helix.platform.adapters.fontrasterizer.stb.internal;

/** Provides font rasterizing over stb_truetype (`fonts.c`), callable from any thread.

	hxcpp builds the C with the program, against `vendor/stb`. */
@:buildXml("<set name='HELIX_PLATFORM' value='${haxelib:helix-platform}' unless='HELIX_PLATFORM'/>
<files id='helix-platform-fontrasterizer-stb' dir='${HELIX_PLATFORM}/src/helix/platform/adapters'>
 <compilerflag value='-I${HELIX_PLATFORM}/vendor/stb'/><compilerflag value='-I${HELIX_PLATFORM}/src/helix/platform/adapters/fontrasterizer/stb/internal'/>
 <compilerflag value='-DNDEBUG' unless='debug'/><compilerflag value='-O2' if='windows' unless='debug'/><compilerflag value='-O3' unless='windows||debug'/>
 <depend name='${HELIX_PLATFORM}/vendor/stb/stb_truetype.h'/><depend name='${HELIX_PLATFORM}/src/helix/platform/adapters/fontrasterizer/stb/internal/fonts.h'/>
 <file name='fontrasterizer/stb/internal/fonts.c'/>
</files>
<files id='haxe'><compilerflag value='-I${HELIX_PLATFORM}/src/helix/platform/adapters/fontrasterizer/stb/internal'/></files>
<target id='haxe'>
 <files id='helix-platform-fontrasterizer-stb'/>
</target>")
@:include("fonts.h")
@:noCompletion
extern class FontBridge {
	@:native("helix_font_open") static function open(data:cpp.RawConstPointer<cpp.Void>, size:Int):cpp.RawPointer<cpp.Void>;
	@:native("helix_font_metrics") static function metrics(font:cpp.RawConstPointer<cpp.Void>, size:cpp.Float32, metrics:cpp.RawPointer<cpp.Float32>):Void;
	@:native("helix_font_glyph") static function glyph(font:cpp.RawConstPointer<cpp.Void>, size:cpp.Float32, codepoint:Int, sdf:Int, box:cpp.RawPointer<Int>,
		advance:cpp.RawPointer<cpp.Float32>):cpp.RawPointer<cpp.UInt8>;
	@:native("helix_font_copy") static function copy(bitmap:cpp.RawConstPointer<cpp.UInt8>, length:Int, dest:cpp.RawPointer<cpp.Void>):Void;
	@:native("helix_font_free_bitmap") static function freeBitmap(bitmap:cpp.RawPointer<cpp.UInt8>, sdf:Int):Void;
	@:native("helix_font_close") static function close(font:cpp.RawPointer<cpp.Void>):Void;
}
