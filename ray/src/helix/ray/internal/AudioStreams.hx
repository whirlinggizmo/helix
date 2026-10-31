package helix.ray.internal;

import helix.platform.IPollable;

/** Holds the audio streams that have a callback (`SetAudioStreamCallback`), and tops each up once a frame, in helix-ray's poll: raylib
	calls a stream's callback on its audio thread as the mixer needs frames, which a page can't run Haxe on, so here the callback is
	called on the main thread until the stream holds two buffers ahead of what is heard. */
@:noCompletion
class AudioStreams implements IPollable {
	/** The streams with a callback, in the order they were given one. */
	public final streams:Array<helix.ray.AudioStream> = [];

	/** Creates it, holding none. */
	public function new() {}

	/** Tops up every stream that is playing and not paused. */
	public function poll():Void {
		for (stream in streams.copy())
			helix.ray.raylib.RAudio.topUp(stream);
	}
}
