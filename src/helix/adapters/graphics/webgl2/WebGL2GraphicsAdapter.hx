package helix.adapters.graphics.webgl2;

import helix.graphics.IGraphics;
import haxe.io.Bytes;
import js.html.CanvasElement;
import js.html.webgl.WebGL2RenderingContext;

/** Raw browser API calls only; geometry and batching stay in shared Renderer. */
class WebGL2GraphicsAdapter implements IGraphics {
 public var gl(default,null):WebGL2RenderingContext;
 var next=1;var buffers:Map<Int,Dynamic>=[];var textures:Map<Int,Dynamic>=[];var pipelines:Map<Int,Dynamic>=[];
 var clearColor=0;var customClear=false;
 public function setClearColor(color:Int):Void {clearColor=color;customClear=true;}
 var active=false;var cacheState:Bool;var shareShader:Bool;var shared:Dynamic;
 var currentProgram:Dynamic;var currentBuffer=0;var currentTexture=0;var currentAlpha:Null<Bool>;
 public function new(canvas:CanvasElement,preserve:Bool,cacheState:Bool=false,shareShader:Bool=false){
  this.cacheState=cacheState;this.shareShader=shareShader;
  gl=cast canvas.getContext("webgl2",{alpha:false,antialias:false,depth:false,stencil:false,preserveDrawingBuffer:preserve});
  if(gl==null)throw "WebGL2 is required";
  #if hotreload live.push(this); #end
 }
 public function createTexture(width:Int,height:Int,rgba:Bytes,linear:Bool=false):Int {
  if(width<=0||height<=0||rgba.length!=width*height*4)throw "Invalid texture";
  currentTexture=0;var tex=gl.createTexture();gl.bindTexture(WebGL2RenderingContext.TEXTURE_2D,tex);gl.pixelStorei(WebGL2RenderingContext.UNPACK_ALIGNMENT,1);
  gl.texImage2D(WebGL2RenderingContext.TEXTURE_2D,0,WebGL2RenderingContext.RGBA,width,height,0,WebGL2RenderingContext.RGBA,WebGL2RenderingContext.UNSIGNED_BYTE,new js.lib.Uint8Array(rgba.getData()));
  gl.texParameteri(WebGL2RenderingContext.TEXTURE_2D,WebGL2RenderingContext.TEXTURE_MIN_FILTER,linear?WebGL2RenderingContext.LINEAR:WebGL2RenderingContext.NEAREST);gl.texParameteri(WebGL2RenderingContext.TEXTURE_2D,WebGL2RenderingContext.TEXTURE_MAG_FILTER,linear?WebGL2RenderingContext.LINEAR:WebGL2RenderingContext.NEAREST);
  gl.texParameteri(WebGL2RenderingContext.TEXTURE_2D,WebGL2RenderingContext.TEXTURE_WRAP_S,WebGL2RenderingContext.CLAMP_TO_EDGE);gl.texParameteri(WebGL2RenderingContext.TEXTURE_2D,WebGL2RenderingContext.TEXTURE_WRAP_T,WebGL2RenderingContext.CLAMP_TO_EDGE);
  var id=next++;textures[id]=tex;return id;
 }
 public function createBuffer(capacityBytes:Int):Int {
  if(capacityBytes<=0||capacityBytes%GeneratedLayout.stride!=0)throw "Invalid buffer capacity";
  var buffer=gl.createBuffer();gl.bindBuffer(WebGL2RenderingContext.ARRAY_BUFFER,buffer);gl.bufferData(WebGL2RenderingContext.ARRAY_BUFFER,capacityBytes,WebGL2RenderingContext.DYNAMIC_DRAW);
  var id=next++;buffers[id]={buffer:buffer,capacity:capacityBytes,used:0};return id;
 }
 function shader(type:Int,source:String):Dynamic {var s=gl.createShader(type);gl.shaderSource(s,source);gl.compileShader(s);if(!gl.getShaderParameter(s,WebGL2RenderingContext.COMPILE_STATUS))throw gl.getShaderInfoLog(s);return s;}
 function program():Dynamic {
  var v=shader(WebGL2RenderingContext.VERTEX_SHADER,GeneratedShader.vertex()),f=shader(WebGL2RenderingContext.FRAGMENT_SHADER,GeneratedShader.fragment()),p=gl.createProgram();
  gl.attachShader(p,v);gl.attachShader(p,f);
  gl.bindAttribLocation(p,GeneratedLayout.positionSlot,GeneratedLayout.positionName);gl.bindAttribLocation(p,GeneratedLayout.uvSlot,GeneratedLayout.uvName);gl.bindAttribLocation(p,GeneratedLayout.colorSlot,GeneratedLayout.colorName);
  gl.linkProgram(p);gl.deleteShader(v);gl.deleteShader(f);
  if(!gl.getProgramParameter(p,WebGL2RenderingContext.LINK_STATUS))throw gl.getProgramInfoLog(p);
  var uniform=gl.getUniformLocation(p,GeneratedLayout.uniform);if(uniform==null)throw "Missing generated texture uniform";
  return {program:p,uniform:uniform,references:0,vertex:GeneratedShader.vertex(),fragment:GeneratedShader.fragment()};
 }
 public function createPipeline(alpha:Bool):Int {
  var shader=shareShader&&shared!=null?shared:program();if(shareShader)shared=shader;shader.references++;
  var id=next++;pipelines[id]={shader:shader,alpha:alpha};return id;
 }
 public function updateBuffer(handle:Int,data:Bytes,usedBytes:Int):Void {
  var b=buffers[handle];if(b==null||usedBytes<0||usedBytes%GeneratedLayout.stride!=0||usedBytes>b.capacity||usedBytes>data.length)throw "Invalid upload";
  gl.bindBuffer(WebGL2RenderingContext.ARRAY_BUFFER,b.buffer);gl.bufferSubData(WebGL2RenderingContext.ARRAY_BUFFER,0,new js.lib.Uint8Array(data.getData(),0,usedBytes));b.used=usedBytes;
 }
 public function beginFrame(width:Int,height:Int,x:Int,y:Int,w:Int,h:Int):Void {
  if(active||width<=0||height<=0||w<=0||h<=0)throw "Invalid pass";
  active=true;currentProgram=null;currentBuffer=0;currentTexture=0;currentAlpha=null;gl.disable(WebGL2RenderingContext.SCISSOR_TEST);gl.disable(WebGL2RenderingContext.DEPTH_TEST);gl.disable(WebGL2RenderingContext.CULL_FACE);
  if(customClear)gl.clearColor((clearColor>>>24)/255,((clearColor>>>16)&255)/255,((clearColor>>>8)&255)/255,(clearColor&255)/255);else gl.clearColor(.015,.025,.045,1);gl.clear(WebGL2RenderingContext.COLOR_BUFFER_BIT);gl.viewport(x,y,w,h);
 }
 public function draw(pipeline:Int,buffer:Int,texture:Int,vertices:Int,firstVertex:Int):Void {
  var p=pipelines[pipeline],b=buffers[buffer],t=textures[texture];
  if(!active||p==null||b==null||t==null||vertices<=0||vertices%3!=0||firstVertex<0||firstVertex%3!=0||firstVertex>b.used/GeneratedLayout.stride-vertices)throw "Invalid draw";
  // Match the reference's consecutive-state reuse. Validation still runs for every draw.
  if(!cacheState||currentProgram!=p.shader.program){gl.useProgram(p.shader.program);gl.uniform1i(p.shader.uniform,GeneratedLayout.textureUnit);currentProgram=p.shader.program;}
  if(!cacheState||currentBuffer!=buffer){
   gl.bindBuffer(WebGL2RenderingContext.ARRAY_BUFFER,b.buffer);
   gl.enableVertexAttribArray(GeneratedLayout.positionSlot);gl.vertexAttribPointer(GeneratedLayout.positionSlot,GeneratedLayout.positionComponents,WebGL2RenderingContext.FLOAT,false,GeneratedLayout.stride,GeneratedLayout.positionOffset);
   gl.enableVertexAttribArray(GeneratedLayout.uvSlot);gl.vertexAttribPointer(GeneratedLayout.uvSlot,GeneratedLayout.uvComponents,WebGL2RenderingContext.FLOAT,false,GeneratedLayout.stride,GeneratedLayout.uvOffset);
   gl.enableVertexAttribArray(GeneratedLayout.colorSlot);gl.vertexAttribPointer(GeneratedLayout.colorSlot,GeneratedLayout.colorComponents,WebGL2RenderingContext.FLOAT,false,GeneratedLayout.stride,GeneratedLayout.colorOffset);
   currentBuffer=buffer;
  }
  if(!cacheState||currentTexture!=texture){gl.activeTexture(WebGL2RenderingContext.TEXTURE0+GeneratedLayout.textureUnit);gl.bindTexture(WebGL2RenderingContext.TEXTURE_2D,t);currentTexture=texture;}
  if(!cacheState||currentAlpha!=p.alpha){
   if(p.alpha){gl.enable(WebGL2RenderingContext.BLEND);gl.blendFuncSeparate(WebGL2RenderingContext.SRC_ALPHA,WebGL2RenderingContext.ONE_MINUS_SRC_ALPHA,WebGL2RenderingContext.ONE,WebGL2RenderingContext.ONE_MINUS_SRC_ALPHA);}else gl.disable(WebGL2RenderingContext.BLEND);
   currentAlpha=p.alpha;
  }
  gl.drawArrays(WebGL2RenderingContext.TRIANGLES,firstVertex,vertices);
 }
 public function endFrame():Void {if(!active)throw "No pass";active=false;}
 public function destroy(kind:String,handle:Int):Void {
  switch(kind){
   case "buffer":var b=buffers[handle];if(b==null)throw "Invalid buffer";gl.deleteBuffer(b.buffer);buffers.remove(handle);currentBuffer=0;
   case "texture":var t=textures[handle];if(t==null)throw "Invalid texture";gl.deleteTexture(t);textures.remove(handle);currentTexture=0;
   case "pipeline":var p=pipelines[handle];if(p==null)throw "Invalid pipeline";p.shader.references--;if(p.shader.references==0){gl.deleteProgram(p.shader.program);if(shared==p.shader)shared=null;}pipelines.remove(handle);currentProgram=null;currentAlpha=null;
   default:throw "Invalid resource kind";
  }
 }
 public function shutdown():Void {#if hotreload live.remove(this); #end}
 #if hotreload
 // Development only (hotreload-hx): a reload brings new generated shader source; programs are rebuilt in place so pipeline handles stay valid.
 static var live:Array<WebGL2GraphicsAdapter>=[];
 @:afterHotReload static function reloadShaders():Void for(adapter in live)adapter.rebuildPrograms();
 function rebuildPrograms():Void {
  var seen=[];for(p in pipelines){var s:Dynamic=p.shader;if(seen.indexOf(s)>=0||s.vertex==GeneratedShader.vertex()&&s.fragment==GeneratedShader.fragment())continue;seen.push(s);
   var fresh=program();gl.deleteProgram(s.program);s.program=fresh.program;s.uniform=fresh.uniform;s.vertex=fresh.vertex;s.fragment=fresh.fragment;}
  currentProgram=null;
 }
 #end
}
