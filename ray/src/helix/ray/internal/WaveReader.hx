package helix.ray.internal;

/** Reads a sound file's bytes into a wave for `LoadWaveAsync` and `LoadWaveFromMemoryAsync`: one for each kind of file, chosen as the
	program builds where its name is known (`WaveMacro`), so a program carries only the readers it names. Its answer comes at a later
	frame: `done` with the wave, or `failed` with raylib's message. */
@:noCompletion
typedef WaveReader = (fileType:String, data:haxe.io.Bytes, done:helix.ray.Wave->Void, failed:String->Void) -> Void;
