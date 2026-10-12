package helix.audio;

/** Fully decoded, reusable audio resource. */
class AudioClip extends AudioResource {
 public function new(id:Int,backend:IAudio){super(id,backend,()->backend.destroyClip(id));}
}
