import hybrid.IGraphics;
import haxe.io.Bytes;
import js.html.CanvasElement;
import js.html.webgl.WebGL2RenderingContext;

/** Raw browser API calls only; geometry and batching stay in shared Renderer. */
class GraphicsBackend implements IGraphics {
 public var gl(default,null):WebGL2RenderingContext;
 var next=1;var buffers:Map<Int,Dynamic>=[];var textures:Map<Int,Dynamic>=[];var pipelines:Map<Int,Dynamic>=[];
 var active=false;
 public function new(canvas:CanvasElement,preserve:Bool){
  gl=cast canvas.getContext("webgl2",{alpha:false,antialias:false,depth:false,stencil:false,preserveDrawingBuffer:preserve});
  if(gl==null)throw "WebGL2 is required";
 }
 public function createTexture(width:Int,height:Int,rgba:Bytes):Int {
  if(width<=0||height<=0||rgba.length!=width*height*4)throw "Invalid texture";
  var tex=gl.createTexture();gl.bindTexture(WebGL2RenderingContext.TEXTURE_2D,tex);gl.pixelStorei(WebGL2RenderingContext.UNPACK_ALIGNMENT,1);
  gl.texImage2D(WebGL2RenderingContext.TEXTURE_2D,0,WebGL2RenderingContext.RGBA,width,height,0,WebGL2RenderingContext.RGBA,WebGL2RenderingContext.UNSIGNED_BYTE,new js.lib.Uint8Array(rgba.getData()));
  gl.texParameteri(WebGL2RenderingContext.TEXTURE_2D,WebGL2RenderingContext.TEXTURE_MIN_FILTER,WebGL2RenderingContext.NEAREST);gl.texParameteri(WebGL2RenderingContext.TEXTURE_2D,WebGL2RenderingContext.TEXTURE_MAG_FILTER,WebGL2RenderingContext.NEAREST);
  gl.texParameteri(WebGL2RenderingContext.TEXTURE_2D,WebGL2RenderingContext.TEXTURE_WRAP_S,WebGL2RenderingContext.CLAMP_TO_EDGE);gl.texParameteri(WebGL2RenderingContext.TEXTURE_2D,WebGL2RenderingContext.TEXTURE_WRAP_T,WebGL2RenderingContext.CLAMP_TO_EDGE);
  var id=next++;textures[id]=tex;return id;
 }
 public function createBuffer(capacityBytes:Int):Int {
  if(capacityBytes<=0||capacityBytes%GeneratedLayout.stride!=0)throw "Invalid buffer capacity";
  var buffer=gl.createBuffer();gl.bindBuffer(WebGL2RenderingContext.ARRAY_BUFFER,buffer);gl.bufferData(WebGL2RenderingContext.ARRAY_BUFFER,capacityBytes,WebGL2RenderingContext.DYNAMIC_DRAW);
  var id=next++;buffers[id]={buffer:buffer,capacity:capacityBytes,used:0};return id;
 }
 function shader(type:Int,source:String):Dynamic {var s=gl.createShader(type);gl.shaderSource(s,source);gl.compileShader(s);if(!gl.getShaderParameter(s,WebGL2RenderingContext.COMPILE_STATUS))throw gl.getShaderInfoLog(s);return s;}
 public function createPipeline(alpha:Bool):Int {
  var v=shader(WebGL2RenderingContext.VERTEX_SHADER,GeneratedShader.vertex),f=shader(WebGL2RenderingContext.FRAGMENT_SHADER,GeneratedShader.fragment),p=gl.createProgram();
  gl.attachShader(p,v);gl.attachShader(p,f);
  gl.bindAttribLocation(p,GeneratedLayout.positionSlot,GeneratedLayout.positionName);gl.bindAttribLocation(p,GeneratedLayout.uvSlot,GeneratedLayout.uvName);gl.bindAttribLocation(p,GeneratedLayout.colorSlot,GeneratedLayout.colorName);
  gl.linkProgram(p);gl.deleteShader(v);gl.deleteShader(f);
  if(!gl.getProgramParameter(p,WebGL2RenderingContext.LINK_STATUS))throw gl.getProgramInfoLog(p);
  var uniform=gl.getUniformLocation(p,GeneratedLayout.uniform);if(uniform==null)throw "Missing generated texture uniform";
  var id=next++;pipelines[id]={program:p,alpha:alpha,uniform:uniform};return id;
 }
 public function updateBuffer(handle:Int,data:Bytes,usedBytes:Int):Void {
  var b=buffers[handle];if(b==null||usedBytes<0||usedBytes%GeneratedLayout.stride!=0||usedBytes>b.capacity||usedBytes>data.length)throw "Invalid upload";
  gl.bindBuffer(WebGL2RenderingContext.ARRAY_BUFFER,b.buffer);gl.bufferSubData(WebGL2RenderingContext.ARRAY_BUFFER,0,new js.lib.Uint8Array(data.getData(),0,usedBytes));b.used=usedBytes;
 }
 public function beginFrame(width:Int,height:Int,x:Int,y:Int,w:Int,h:Int):Void {
  if(active||width<=0||height<=0||w<=0||h<=0)throw "Invalid pass";
  active=true;gl.disable(WebGL2RenderingContext.SCISSOR_TEST);gl.disable(WebGL2RenderingContext.DEPTH_TEST);gl.disable(WebGL2RenderingContext.CULL_FACE);
  gl.clearColor(.015,.025,.045,1);gl.clear(WebGL2RenderingContext.COLOR_BUFFER_BIT);gl.viewport(x,y,w,h);
 }
 public function draw(pipeline:Int,buffer:Int,texture:Int,vertices:Int):Void {
  var p=pipelines[pipeline],b=buffers[buffer],t=textures[texture];
  if(!active||p==null||b==null||t==null||vertices<=0||vertices%3!=0||vertices*GeneratedLayout.stride>b.used)throw "Invalid draw";
  gl.useProgram(p.program);gl.bindBuffer(WebGL2RenderingContext.ARRAY_BUFFER,b.buffer);
  gl.enableVertexAttribArray(GeneratedLayout.positionSlot);gl.vertexAttribPointer(GeneratedLayout.positionSlot,GeneratedLayout.positionComponents,WebGL2RenderingContext.FLOAT,false,GeneratedLayout.stride,GeneratedLayout.positionOffset);
  gl.enableVertexAttribArray(GeneratedLayout.uvSlot);gl.vertexAttribPointer(GeneratedLayout.uvSlot,GeneratedLayout.uvComponents,WebGL2RenderingContext.FLOAT,false,GeneratedLayout.stride,GeneratedLayout.uvOffset);
  gl.enableVertexAttribArray(GeneratedLayout.colorSlot);gl.vertexAttribPointer(GeneratedLayout.colorSlot,GeneratedLayout.colorComponents,WebGL2RenderingContext.FLOAT,false,GeneratedLayout.stride,GeneratedLayout.colorOffset);
  gl.activeTexture(WebGL2RenderingContext.TEXTURE0+GeneratedLayout.textureUnit);gl.bindTexture(WebGL2RenderingContext.TEXTURE_2D,t);gl.uniform1i(p.uniform,GeneratedLayout.textureUnit);
  if(p.alpha){gl.enable(WebGL2RenderingContext.BLEND);gl.blendFuncSeparate(WebGL2RenderingContext.SRC_ALPHA,WebGL2RenderingContext.ONE_MINUS_SRC_ALPHA,WebGL2RenderingContext.ONE,WebGL2RenderingContext.ONE_MINUS_SRC_ALPHA);}else gl.disable(WebGL2RenderingContext.BLEND);
  gl.drawArrays(WebGL2RenderingContext.TRIANGLES,0,vertices);
 }
 public function endFrame():Void {if(!active)throw "No pass";active=false;}
 public function destroy(kind:String,handle:Int):Void {
  switch(kind){
   case "buffer":var b=buffers[handle];if(b==null)throw "Invalid buffer";gl.deleteBuffer(b.buffer);buffers.remove(handle);
   case "texture":var t=textures[handle];if(t==null)throw "Invalid texture";gl.deleteTexture(t);textures.remove(handle);
   case "pipeline":var p=pipelines[handle];if(p==null)throw "Invalid pipeline";gl.deleteProgram(p.program);pipelines.remove(handle);
   default:throw "Invalid resource kind";
  }
 }
 public function shutdown():Void {}
}
