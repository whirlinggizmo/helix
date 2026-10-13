package helix.render2d;
import helix.graphics.IGraphics;
import haxe.io.Bytes;

/** A GPU texture with its size. whiteU/whiteV name an opaque white texel, when it has one, for untextured shapes. */
class Texture2D {
 public var handle(default,null):Int;public var width(default,null):Int;public var height(default,null):Int;
 public var whiteU(default,null)=-1.;public var whiteV(default,null)=-1.;
 function new(handle:Int,width:Int,height:Int){this.handle=handle;this.width=width;this.height=height;}
 public static function fromRgba(gpu:IGraphics,width:Int,height:Int,rgba:Bytes,linear=false,whiteX=-1,whiteY=-1):Texture2D {
  var texture=new Texture2D(gpu.createTexture(width,height,rgba,linear),width,height);
  if(whiteX>=0){texture.whiteU=(whiteX+.5)/width;texture.whiteV=(whiteY+.5)/height;}return texture;
 }
 public function destroy(gpu:IGraphics):Void gpu.destroy("texture",handle);
}
