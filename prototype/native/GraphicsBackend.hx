import hybrid.IGraphics;
import haxe.io.Bytes;
class GraphicsBackend implements IGraphics {
 public function new(){Native.setup();}
 static function pointer(data:Bytes):cpp.RawPointer<cpp.UInt8> return cpp.Pointer.arrayElem(data.getData(),0).raw;
 static function valid(handle:Int):Int {if(handle==0)throw "Native resource creation failed";return handle;}
 public function createTexture(width:Int,height:Int,rgba:Bytes):Int return valid(Native.texture(width,height,pointer(rgba),rgba.length));
 public function createBuffer(capacityBytes:Int):Int return valid(Native.buffer(capacityBytes));
 public function createPipeline(alpha:Bool):Int return valid(Native.pipeline(alpha?1:0));
 public function updateBuffer(handle:Int,data:Bytes,usedBytes:Int):Void {if(usedBytes>data.length||usedBytes<0||Native.update(handle,pointer(data),usedBytes)!=1)throw "Invalid native upload";}
 public function beginFrame(width:Int,height:Int,x:Int,y:Int,w:Int,h:Int):Void {if(Native.begin(width,height,x,y,w,h)!=1)throw "Invalid native pass";}
 public function draw(pipeline:Int,buffer:Int,texture:Int,vertices:Int):Void {if(Native.draw(pipeline,buffer,texture,vertices)!=1)throw "Invalid native draw";}
 public function endFrame():Void Native.end();
 public function destroy(kind:String,handle:Int):Void {var n=switch(kind){case "buffer":0;case "texture":1;case "pipeline":2;default:-1;};if(Native.destroy(n,handle)!=1)throw "Invalid native resource";}
 public function shutdown():Void Native.shutdown();
}
