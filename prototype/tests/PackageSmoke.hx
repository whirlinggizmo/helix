import hybrid.IHost;
import hybrid.IInput;
import hybrid.IGraphics;
import hybrid.IAudio;
import hybrid.IAssets;
import hybrid.IDiagnostics;
import hybrid.InputState;
import hybrid.Key;
import hybrid.Autopilot;
/** This consumer compiles with framework + tests only; no game/adapters/generated shader. */
class PackageSmoke {
 static function main():Void {
  var input:IInput=new InputState();var source:InputState=cast input;source.keyEvent(Key.Enter,true);
  if(!input.pressed(Key.Enter))throw "Independent input consumer failed";
  var pilot=new Autopilot('{"version":1,"seed":1,"commands":[{"op":"assert","probe":"ready","equals":true}]}');pilot.advance(_->true);
  if(!pilot.done)throw "Independent autopilot consumer failed";
  var host:Null<IHost>=null,graphics:Null<IGraphics>=null,audio:Null<IAudio>=null,assets:Null<IAssets>=null,diagnostics:Null<IDiagnostics>=null;
  trace("Standalone framework consumer passed");
 }
}
