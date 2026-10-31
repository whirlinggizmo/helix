package helix.platform.adapters.clipboard.sdl3.internal;

/** Provides SDL3's clipboard calls: its text, and an image as PNG. hxcpp builds the C with the program. */
@:buildXml("<set name='HELIX_PLATFORM' value='${haxelib:helix-platform}' unless='HELIX_PLATFORM'/>
<files id='helix-platform-clipboard-sdl3' dir='${HELIX_PLATFORM}/src/helix/platform/adapters'>
 <compilerflag value='-I${HELIX_PLATFORM}/vendor/sdl3'/><compilerflag value='-I${HELIX_PLATFORM}/src/helix/platform/adapters/clipboard/sdl3/internal'/>
 <compilerflag value='-DNDEBUG' unless='debug'/><compilerflag value='-O2' if='windows' unless='debug'/><compilerflag value='-O3' unless='windows||debug'/>
 <depend name='${HELIX_PLATFORM}/vendor/sdl3/SDL3/SDL.h'/><depend name='${HELIX_PLATFORM}/src/helix/platform/adapters/clipboard/sdl3/internal/clipboard_sdl3.h'/>
 <file name='clipboard/sdl3/internal/clipboard_sdl3.c'/>
</files>
<files id='haxe'><compilerflag value='-I${HELIX_PLATFORM}/src/helix/platform/adapters/clipboard/sdl3/internal'/></files>
<target id='haxe'>
 <files id='helix-platform-clipboard-sdl3'/>
</target>")
@:include("clipboard_sdl3.h")
@:noCompletion
extern class ClipboardBridge {
	@:native("helix_clipboard_text") static function text():cpp.ConstCharStar;
	@:native("helix_clipboard_set_text") static function setText(text:cpp.ConstCharStar):Int;
	@:native("helix_clipboard_image_size") static function imageSize():Int;
	@:native("helix_clipboard_image_copy") static function imageCopy(out:cpp.RawPointer<cpp.Void>):Void;
	@:native("helix_clipboard_set_image") static function setImage(png:cpp.RawConstPointer<cpp.Void>, size:Int):Int;
	@:native("helix_clipboard_dispose") static function dispose():Void;
}
