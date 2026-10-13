package helix.render2d;

enum abstract Align2D(Int) {var Left;var Center;var Right;}

/** Text in world units. size is the glyph height; x is the left edge, center or right edge by align; y is the top. */
class Text2D {
 public static function width(font:Font2D,text:String,size:Float):Float {var unit=size/font.glyphHeight;return text.length==0?0:((text.length-1)*font.advance+font.glyphWidth)*unit;}
 public static function draw(batch:Batch2D,text:String,x:Float,y:Float,size:Float,color:Int,align:Align2D=Left):Void {
  var font=batch.font,unit=size/font.glyphHeight,w=width(font,text,size);
  if(align==Center)x-=w/2;else if(align==Right)x-=w;
  batch.useTexture(font.texture);
  for(i in 0...text.length){var uv=font.glyph(text.charCodeAt(i));if(uv!=null)batch.quad(x+i*font.advance*unit,y,font.glyphWidth*unit,size,uv[0],uv[1],uv[2],uv[3],color);}
 }
}
