package helix.adapters.host.sokol.internal;

/** Built with the app by hxcpp: The sokol_app window and loop, and sokol_app_utils' window and display calls: X11 and GLX on Linux, Win32 and WGL on Windows, Cocoa on macOS (compiled as Objective-C there through host_macos.m, as hxcpp picks a file's language by its extension). */
@:buildXml('<files id="helix-host-sokol" dir="${HELIX_ROOT}/src/helix/adapters">
 <compilerflag value="-I${HELIX_ROOT}/vendor"/><compilerflag value="-I${HELIX_ROOT}/vendor/sokol_utils"/><compilerflag value="-I${HELIX_ROOT}/src/helix/adapters/internal"/><compilerflag value="-I${HELIX_ROOT}/src/helix/adapters/host/sokol/internal"/><compilerflag value="-I${HELIX_ROOT}/src/helix/adapters/inputsource/sokol/internal"/>
 <compilerflag value="-DNDEBUG"/><compilerflag value="-O2" if="windows"/><compilerflag value="-O3" unless="windows"/><compilerflag value="-D_POSIX_C_SOURCE=200809L" if="linux"/>
 <!-- hxcpp rebuilds an object when its source changes; these make a changed header rebuild it too. -->
 <depend name="${HELIX_ROOT}/vendor/sokol_app.h"/><depend name="${HELIX_ROOT}/vendor/sokol_log.h"/><depend name="${HELIX_ROOT}/vendor/sokol_utils/sokol_app_utils.h"/><depend name="${HELIX_ROOT}/src/helix/adapters/internal/surface.h"/><depend name="${HELIX_ROOT}/src/helix/adapters/host/sokol/internal/host.h"/><depend name="${HELIX_ROOT}/src/helix/adapters/host/sokol/internal/host.c"/><depend name="${HELIX_ROOT}/src/helix/adapters/inputsource/sokol/internal/input.h"/>
 <file name="host/sokol/internal/host.c" unless="macos"/><file name="host/sokol/internal/host_macos.m" if="macos"/>
</files>
<files id="haxe"><compilerflag value="-I${HELIX_ROOT}/vendor"/><compilerflag value="-I${HELIX_ROOT}/vendor/sokol_utils"/><compilerflag value="-I${HELIX_ROOT}/src/helix/adapters/internal"/><compilerflag value="-I${HELIX_ROOT}/src/helix/adapters/host/sokol/internal"/></files>
<target id="haxe">
 <files id="helix-host-sokol"/>
 <section if="linux"><lib name="-lX11"/><lib name="-lXrandr"/><lib name="-lXi"/><lib name="-lXcursor"/><lib name="-lGL"/><lib name="-ldl"/><lib name="-lpthread"/></section>
 <section if="windows"><lib name="opengl32.lib"/><lib name="gdi32.lib"/><lib name="user32.lib"/><lib name="kernel32.lib"/><lib name="shell32.lib"/></section>
 <section if="macos"><vflag name="-framework" value="Cocoa"/><vflag name="-framework" value="QuartzCore"/><vflag name="-framework" value="OpenGL"/></section>
</target>')
@:include("host.h")
extern class HostBridge {
	@:native("helix_run") static function run(init:cpp.Callable<Void->Void>, frame:cpp.Callable<Void->Void>, cleanup:cpp.Callable<Void->Void>,
		sampleCount:Int):Void;
	@:native("helix_quit") static function quit():Void;
	@:native("helix_width") static function width():Int;
	@:native("helix_height") static function height():Int;
	@:native("helix_pixel_ratio") static function pixelRatio():cpp.Float32;
	@:native("helix_window_set_title") static function setTitle(title:cpp.ConstCharStar):Void;
	@:native("helix_window_width") static function windowWidth():Int;
	@:native("helix_window_height") static function windowHeight():Int;
	@:native("helix_window_set_size") static function setSize(width:Int, height:Int):Void;
	@:native("helix_window_can_move") static function canMove():Int;
	@:native("helix_window_x") static function windowX():Int;
	@:native("helix_window_y") static function windowY():Int;
	@:native("helix_window_set_position") static function setPosition(x:Int, y:Int):Void;
	@:native("helix_window_focused") static function focused():Int;
	@:native("helix_window_fullscreen") static function fullscreen():Int;
	@:native("helix_window_set_fullscreen") static function requestFullscreen(on:Int):Void;
	@:native("helix_window_visible") static function visible():Int;
	@:native("helix_window_set_visible") static function setVisible(on:Int):Void;
	@:native("helix_display_count") static function displayCount():Int;
	@:native("helix_display_current") static function displayCurrent():Int;
	@:native("helix_display_set") static function setDisplay(index:Int):Void;
	@:native("helix_display_x") static function displayX(index:Int):Int;
	@:native("helix_display_y") static function displayY(index:Int):Int;
	@:native("helix_display_width") static function displayWidth(index:Int):Int;
	@:native("helix_display_height") static function displayHeight(index:Int):Int;
	@:native("helix_display_name") static function displayName(index:Int):cpp.ConstCharStar;
}
