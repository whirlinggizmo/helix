package hybrid;

import haxe.io.Bytes;

/** Thin resource/submission contract. No scene policy belongs in an adapter. */
interface IGraphics {
 public function createTexture(width:Int,height:Int,rgba:Bytes):Int;
 public function createBuffer(capacityBytes:Int):Int;
 public function createPipeline(alpha:Bool):Int;
 public function updateBuffer(handle:Int,data:Bytes,usedBytes:Int):Void;
 public function beginFrame(width:Int,height:Int,x:Int,y:Int,w:Int,h:Int):Void;
 public function draw(pipeline:Int,buffer:Int,texture:Int,vertices:Int):Void;
 public function endFrame():Void;
 public function destroy(kind:String,handle:Int):Void;
 public function shutdown():Void;
}
