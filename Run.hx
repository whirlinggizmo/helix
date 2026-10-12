/** Optional Haxe front door; deliberately kept out of framework/game classpaths. */
class Run {
 static function main():Void {
  var python=Sys.getEnv("HYBRID_PYTHON");if(python==null)python=Sys.systemName()=="Windows"?"python":"python3";
  var runner=haxe.io.Path.join([Sys.getCwd(),"hybrid.py"]);
  if(!sys.FileSystem.exists(runner))throw "Run with --cwd pointing at experiments/05-hybrid-asteroids";
  Sys.exit(Sys.command(python,[runner].concat(Sys.args())));
 }
}
