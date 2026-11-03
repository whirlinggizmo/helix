package helix.platform.adapters.shared.sdl3mixer;

@:buildXml("<set name='HELIX_PLATFORM' value='${haxelib:helix-platform}' unless='HELIX_PLATFORM'/>
<files id='helix-platform-sdl3mixer' dir='${HELIX_PLATFORM}/vendor/sdl3_mixer/src'>
 <compilerflag value='-I${HELIX_PLATFORM}/vendor/sdl3'/><compilerflag value='-I${HELIX_PLATFORM}/vendor/sdl3_mixer/include'/><compilerflag value='-I${HELIX_PLATFORM}/vendor/sdl3_mixer/src'/>
 <compilerflag value='-DDECODER_WAV'/><compilerflag value='-DDECODER_OGGVORBIS_STB'/><compilerflag value='-DDECODER_MP3_DRMP3'/><compilerflag value='-DDECODER_FLAC_DRFLAC'/>
 <compilerflag value='-DNDEBUG' unless='debug'/><compilerflag value='-O2' if='windows' unless='debug'/><compilerflag value='-O3' unless='windows||debug'/><compilerflag value='-D_POSIX_C_SOURCE=200809L' if='linux'/>
 <depend name='${HELIX_PLATFORM}/vendor/sdl3/SDL3/SDL.h'/><depend name='${HELIX_PLATFORM}/vendor/sdl3_mixer/include/SDL3_mixer/SDL_mixer.h'/><depend name='${HELIX_PLATFORM}/vendor/sdl3_mixer/src/SDL_mixer_internal.h'/>
 <file name='SDL_mixer.c'/>
 <file name='SDL_mixer_metadata_tags.c'/>
 <file name='SDL_mixer_spatialization.c'/>
 <file name='decoder_raw.c'/>
 <file name='decoder_sinewave.c'/>
 <file name='decoder_wav.c'/>
 <file name='decoder_stb_vorbis.c'/>
 <file name='decoder_drmp3.c'/>
 <file name='decoder_drflac.c'/>
</files>
<files id='haxe'><compilerflag value='-I${HELIX_PLATFORM}/vendor/sdl3'/><compilerflag value='-I${HELIX_PLATFORM}/vendor/sdl3_mixer/include'/></files>
<target id='haxe'>
 <files id='helix-platform-sdl3mixer'/>
 <lib name='${HELIX_SDL3_LIBRARY}'/>
 <section if='linux'><lib name='-lm'/><lib name='-ldl'/><lib name='-lpthread'/></section>
</target>")
/** Provides SDL3_mixer, which the SDL3_mixer adapters share: built from `vendor/sdl3_mixer` with the program, with its built-in decoders only
	(WAV, stb_vorbis, dr_mp3, dr_flac), and linked with the SDL3 library HELIX_SDL3_LIBRARY names.

	hxcpp builds what a program's code names, so each adapter calls `version` once to bring the library into its build. */
@:include("SDL3_mixer/SDL_mixer.h")
@:noCompletion
extern class Sdl3MixerBridge {
	@:native("MIX_Version") static function version():Int;
}
