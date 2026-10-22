package helix.adapter.audio.sdl3.internal;

/** Built with the app by hxcpp: an SDL3 audio stream into the default playback device feeding the shared mixer (shared/mixer.c); linked with the SDL3 the host links (HELIX_SDL3_LIBRARY). */
@:buildXml('<set name="HELIX_ROOT" value="${haxelib:helix}" unless="HELIX_ROOT"/>
<files id="helix-audio-sdl3" dir="${HELIX_ROOT}/src/helix/adapter">
 <compilerflag value="-I${HELIX_ROOT}/vendor/sdl3"/><compilerflag value="-I${HELIX_ROOT}/src/helix/adapter/shared"/>
 <compilerflag value="-DNDEBUG" unless="debug"/><compilerflag value="-O2" if="windows" unless="debug"/><compilerflag value="-O3" unless="windows||debug"/><compilerflag value="-D_POSIX_C_SOURCE=200809L" if="linux"/>
 <!-- hxcpp rebuilds an object when its source changes; these make a changed header rebuild it too. -->
 <depend name="${HELIX_ROOT}/vendor/sdl3/SDL3/SDL.h"/><depend name="${HELIX_ROOT}/src/helix/adapter/shared/lock.h"/><depend name="${HELIX_ROOT}/src/helix/adapter/shared/audio.h"/><depend name="${HELIX_ROOT}/src/helix/adapter/shared/mixer.h"/>
 <file name="shared/mixer.c"/>
 <file name="audio/sdl3/internal/output_sdl3.c"/>
</files>
<files id="haxe"><compilerflag value="-I${HELIX_ROOT}/vendor/sdl3"/><compilerflag value="-I${HELIX_ROOT}/src/helix/adapter/shared"/></files>
<target id="haxe">
 <files id="helix-audio-sdl3"/>
 <lib name="${HELIX_SDL3_LIBRARY}"/>
</target>')
@:include("audio.h")
extern class AudioBridge {
	@:native("helix_audio_setup") static function setup():Void;
	@:native("helix_audio_shutdown") static function shutdown():Void;
}
