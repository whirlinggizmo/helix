package helix.audio;

/** Progressively decoded resource. Stored and remote sources are independent policy. */
class AudioStream extends AudioResource {
	/** Owns backend stream id; releaseSource ends the stored copy's lease after the stream is destroyed. AudioResources.loadStream creates it. */
	public function new(id:Int, backend:IAudio, releaseSource:Void->Void) {
		super(id, backend, () -> {
			backend.destroyStream(id);
			releaseSource();
		});
	}
}
