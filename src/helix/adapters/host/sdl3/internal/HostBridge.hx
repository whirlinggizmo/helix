package helix.adapters.host.sdl3.internal;

/** Built with the app by hxcpp: the SDL3 window, its GL 4.1 context (or none, for SDL_GPU) and the frame loop, linked with HELIX_SDL3_LIBRARY (tools/sdl3.py:
	the system's SDL3 of 3.4.18 or newer, or the pinned one built or fetched into build/deps), compiled against vendor/sdl3's headers. On Linux,
	Xlib too, to ask whether X is XWayland; on Windows, DWM's, to wait on the compositor. */
@:buildXml('<files id="helix-host-sdl3" dir="${HELIX_ROOT}/src/helix/adapters">
 <compilerflag value="-I${HELIX_ROOT}/vendor/sdl3"/><compilerflag value="-I${HELIX_ROOT}/src/helix/adapters/shared"/><compilerflag value="-I${HELIX_ROOT}/src/helix/adapters/host/sdl3/internal"/>
 <compilerflag value="-DNDEBUG" unless="debug"/><compilerflag value="-O2" if="windows" unless="debug"/><compilerflag value="-O3" unless="windows||debug"/><compilerflag value="-D_POSIX_C_SOURCE=200809L" if="linux"/>
 <!-- hxcpp rebuilds an object when its source changes; these make a changed header rebuild it too. -->
 <depend name="${HELIX_ROOT}/vendor/sdl3/SDL3/SDL.h"/><depend name="${HELIX_ROOT}/src/helix/adapters/shared/surface.h"/><depend name="${HELIX_ROOT}/src/helix/adapters/shared/window.h"/><depend name="${HELIX_ROOT}/src/helix/adapters/host/sdl3/internal/host.h"/>
 <file name="host/sdl3/internal/host.c"/>
</files>
<files id="haxe"><compilerflag value="-I${HELIX_ROOT}/src/helix/adapters/shared"/><compilerflag value="-I${HELIX_ROOT}/src/helix/adapters/host/sdl3/internal"/></files>
<target id="haxe">
 <files id="helix-host-sdl3"/>
 <lib name="${HELIX_SDL3_LIBRARY}"/>
 <section if="windows"><lib name="dwmapi.lib"/></section>
 <section if="linux"><lib name="-lX11"/><lib name="-lm"/><lib name="-ldl"/><lib name="-lpthread"/></section>
 <flag value="-Wl,-rpath,@executable_path" if="macos"/>
</target>')
@:include("host.h")
extern class HostBridge {
	@:native("helix_sdl3_run") static function run(init:cpp.Callable<Void->Void>, frame:cpp.Callable<Void->Void>, cleanup:cpp.Callable<Void->Void>,
		sampleCount:Int, withGl:Int):Void;
	@:native("helix_sdl3_quit") static function quit():Void;
}
