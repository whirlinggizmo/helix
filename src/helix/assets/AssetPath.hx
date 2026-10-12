package helix.assets;

class AssetPath {
 public static function valid(path:String):Bool {
  if(path==null||path.length==0||path.length>256)return false;
  for(i in 0...path.length){var c=path.charCodeAt(i);if(!(c>=65&&c<=90||c>=97&&c<=122||c>=48&&c<=57||c==95||c==46||c==45||c==47))return false;}
  for(part in path.split("/"))if(part==""||part=="."||part=="..")return false;return true;
 }
}
