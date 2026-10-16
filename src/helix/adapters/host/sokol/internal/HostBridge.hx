package helix.adapters.host.sokol.internal;

/** Built with the app by hxcpp: The sokol_app window and loop, and sokol_app_utils' window and display calls: X11 and GLX on Linux, Win32 and WGL on Windows, Cocoa on macOS (compiled as Objective-C there through host_macos.m, as hxcpp picks a file's language by its extension). */
@:buildXml('<files id="helix-host-sokol" dir="${HELIX_ROOT}/src/helix/adapters">
 <compilerflag value="-I${HELIX_ROOT}/vendor"/><compilerflag value="-I${HELIX_ROOT}/vendor/sokol_utils"/><compilerflag value="-I${HELIX_ROOT}/src/helix/adapters/shared"/><compilerflag value="-I${HELIX_ROOT}/src/helix/adapters/host/sokol/internal"/>
 <compilerflag value="-DNDEBUG"/><compilerflag value="-O2" if="windows"/><compilerflag value="-O3" unless="windows"/><compilerflag value="-D_POSIX_C_SOURCE=200809L" if="linux"/>
 <!-- hxcpp rebuilds an object when its source changes; these make a changed header rebuild it too. -->
 <depend name="${HELIX_ROOT}/vendor/sokol_app.h"/><depend name="${HELIX_ROOT}/vendor/sokol_log.h"/><depend name="${HELIX_ROOT}/vendor/sokol_utils/sokol_app_utils.h"/><depend name="${HELIX_ROOT}/src/helix/adapters/shared/surface.h"/><depend name="${HELIX_ROOT}/src/helix/adapters/shared/window.h"/><depend name="${HELIX_ROOT}/src/helix/adapters/host/sokol/internal/host.h"/><depend name="${HELIX_ROOT}/src/helix/adapters/host/sokol/internal/host.c"/><depend name="${HELIX_ROOT}/src/helix/adapters/shared/input.h"/>
 <file name="host/sokol/internal/host.c" unless="macos"/><file name="host/sokol/internal/host_macos.m" if="macos"/>
</files>
<files id="haxe"><compilerflag value="-I${HELIX_ROOT}/vendor"/><compilerflag value="-I${HELIX_ROOT}/vendor/sokol_utils"/><compilerflag value="-I${HELIX_ROOT}/src/helix/adapters/shared"/><compilerflag value="-I${HELIX_ROOT}/src/helix/adapters/host/sokol/internal"/></files>
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
}
