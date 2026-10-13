package helix.assets;

import haxe.io.Bytes;
/** Told when a subscribed asset's file changed and was loaded again (IAssets.subscribe). Called through the object, so after a hot reload its new code runs. */
interface IReloadable {
 function reloaded(path:String,bytes:Bytes):Void;
}
