package hybrid;
/** Physical keys, independent of DOM/Sokol numeric codes. */
enum abstract Key(Int) to Int {
 var Enter=0;var Escape=1;var Tab=2;var Space=3;var Left=4;var Right=5;var Up=6;var Down=7;
 var A=8;var D=9;var W=10;var S=11;
 public static final all:Array<Key>=[Enter,Escape,Tab,Space,Left,Right,Up,Down,A,D,W,S];
 public static function named(name:String):Key return switch(name.toUpperCase()){
  case "ENTER":Enter;case "ESCAPE":Escape;case "TAB":Tab;case "SPACE":Space;
  case "LEFT":Left;case "RIGHT":Right;case "UP":Up;case "DOWN":Down;
  case "A":A;case "D":D;case "W":W;case "S":S;default:throw 'Unknown key '+name;
 };
}
