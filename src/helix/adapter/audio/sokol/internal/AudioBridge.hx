package helix.adapter.audio.sokol.internal;

/** Built with the app by hxcpp: sokol_audio (ALSA on Linux, WASAPI on Windows, AudioToolbox on macOS) feeding the shared mixer (shared/mixer.c). */
@:buildXml('<set name="HELIX_ROOT" value="${haxelib:helix}" unless="HELIX_ROOT"/>
<files id="helix-audio-sokol" dir="${HELIX_ROOT}/src/helix/adapter">
 <compilerflag value="-I${HELIX_ROOT}/vendor"/><compilerflag value="-I${HELIX_ROOT}/src/helix/adapter/shared"/>
 <compilerflag value="-DNDEBUG" unless="debug"/><compilerflag value="-O2" if="windows" unless="debug"/><compilerflag value="-O3" unless="windows||debug"/><compilerflag value="-D_POSIX_C_SOURCE=200809L" if="linux"/>
 <!-- hxcpp rebuilds an object when its source changes; these make a changed header rebuild it too. -->
 <depend name="${HELIX_ROOT}/vendor/sokol_audio.h"/><depend name="${HELIX_ROOT}/vendor/sokol_log.h"/><depend name="${HELIX_ROOT}/src/helix/adapter/shared/lock.h"/><depend name="${HELIX_ROOT}/src/helix/adapter/shared/audio.h"/><depend name="${HELIX_ROOT}/src/helix/adapter/shared/mixer.h"/>
 <file name="shared/mixer.c"/>
 <file name="audio/sokol/internal/output_sokol.c"/>
</files>
<files id="haxe"><compilerflag value="-I${HELIX_ROOT}/vendor"/><compilerflag value="-I${HELIX_ROOT}/src/helix/adapter/shared"/></files>
<target id="haxe">
 <files id="helix-audio-sokol"/>
 <section if="linux"><lib name="-lasound"/><lib name="-lpthread"/></section>
 <section if="windows"><lib name="ole32.lib"/></section>
 <section if="macos"><vflag name="-framework" value="AudioToolbox"/></section>
</target>')
@:include("audio.h")
extern class AudioBridge {
	@:native("helix_audio_setup") static function setup():Void;
	@:native("helix_audio_shutdown") static function shutdown():Void;
}
