package helix.render2d;

/** A 2D view: the world point at the viewport's center and how many pixels a world unit covers. Y grows downward. */
class Camera2D {
 public var x=0.;public var y=0.;public var zoom=1.;
 public var viewportWidth(default,null)=1;public var viewportHeight(default,null)=1;
 public function new(){}
 public function viewport(width:Int,height:Int):Void {viewportWidth=width<1?1:width;viewportHeight=height<1?1:height;}
 /** Show a world rectangle whole and centered; the longer screen side shows extra world. */
 public function fit(left:Float,top:Float,width:Float,height:Float):Void {zoom=Math.min(viewportWidth/width,viewportHeight/height);x=left+width/2;y=top+height/2;}
 /** World units are logical pixels from the viewport's top-left: scale is the pixel ratio (framebuffer pixels per logical pixel). */
 public function pixels(scale:Float):Void {zoom=scale;x=viewportWidth/2/scale;y=viewportHeight/2/scale;}
 public function screenToWorldX(px:Float):Float return x+(px-viewportWidth/2)/zoom;
 public function screenToWorldY(py:Float):Float return y+(py-viewportHeight/2)/zoom;
 public function worldToScreenX(wx:Float):Float return (wx-x)*zoom+viewportWidth/2;
 public function worldToScreenY(wy:Float):Float return (wy-y)*zoom+viewportHeight/2;
 public inline function clipX(wx:Float):Float return (wx-x)*zoom*2/viewportWidth;
 public inline function clipY(wy:Float):Float return -(wy-y)*zoom*2/viewportHeight;
}
