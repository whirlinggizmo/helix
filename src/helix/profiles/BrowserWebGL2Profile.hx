package helix.profiles;
import helix.adapters.host.dom.DomHostAdapter;
import helix.adapters.graphics.webgl2.WebGL2GraphicsAdapter;
import helix.adapters.input.dom.DomInputAdapter;
import helix.adapters.audio.webaudio.WebAudioAdapter;
import helix.adapters.fetch.fetchapi.FetchApiAdapter;
import helix.adapters.storage.indexeddb.IndexedDbStorageAdapter;
/** This sample profile chooses providers. Reusable host code owns their lifecycle. */
class BrowserWebGL2Profile extends DomHostAdapter {
 public function new(cacheName:String="helix-cache-v1",assetBase:String="assets/") {
  super((canvas,preserve)->{
   var graphics=new WebGL2GraphicsAdapter(canvas,preserve),input=new DomInputAdapter(canvas),audio=new WebAudioAdapter();
   return {graphics:graphics,input:input,audio:audio,fetch:new FetchApiAdapter(),storage:new IndexedDbStorageAdapter(cacheName),packaged:new IndexedDbStorageAdapter(cacheName+"-packaged"),base:assetBase,
    pollInput:input.poll,focusInput:active->{input.active=active;if(!active)input.clear();},unlockAudio:audio.unlock,suspendAudio:audio.suspend,shutdownInput:()->{},
    info:()->{var gl=graphics.gl,ext=gl.getExtension("WEBGL_debug_renderer_info"),value=audio.info();value.backend="raw-webgl2";value.renderer=gl.getParameter(ext==null?js.html.webgl.WebGL2RenderingContext.RENDERER:untyped ext.UNMASKED_RENDERER_WEBGL);return value;}};
  });
 }
}
