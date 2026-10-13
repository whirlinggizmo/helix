import helix.host.IHost;
import helix.input.IInput;
import helix.graphics.IGraphics;
import helix.audio.IAudio;
import helix.assets.IAssets;
import helix.debug.IDiagnostics;
import helix.input.InputState;
import helix.input.Key;
import helix.debug.Autopilot;
/** This consumer compiles with framework + tests only; no game/adapters/generated shader. */
class PackageSmoke {
 static function main():Void {
  var input:IInput=new InputState();var source:InputState=cast input;source.keyEvent(Key.Enter,true);
  if(!input.isPressed(Key.Enter))throw "Independent input consumer failed";
  var pilot=new Autopilot('{"version":1,"seed":1,"commands":[{"op":"assert","probe":"ready","equals":true}]}');pilot.advance(_->true);
  if(!pilot.isDone())throw "Independent autopilot consumer failed";
  var host:Null<IHost>=null,graphics:Null<IGraphics>=null,audio:Null<IAudio>=null,assets:Null<IAssets>=null,diagnostics:Null<IDiagnostics>=null;
  trace("Standalone framework consumer passed");
 }
}
