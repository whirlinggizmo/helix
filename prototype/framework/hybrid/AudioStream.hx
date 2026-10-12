package hybrid;
/** Progressively decoded resource. Stored and remote sources are independent policy. */
class AudioStream extends AudioResource {
 public function new(id:Int,backend:IAudio,releaseSource:Void->Void){super(id,backend,()->{backend.destroyStream(id);releaseSource();});}
}
