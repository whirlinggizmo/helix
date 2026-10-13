package helix.input;

/** Physical keys, independent of DOM/Sokol numeric codes. */
enum abstract Key(Int) to Int {
 var Enter=0;var Escape=1;var Tab=2;var Space=3;var Left=4;var Right=5;var Up=6;var Down=7;
 var A=8;var D=9;var W=10;var S=11;var Z=12;var X=13;var C=14;var P=15;var Shift=16;
 public static final all:Array<Key>=[Enter,Escape,Tab,Space,Left,Right,Up,Down,A,D,W,S,Z,X,C,P,Shift];
 public static function named(name:String):Key return switch(name.toUpperCase()){
  case "ENTER":Enter;case "ESCAPE":Escape;case "TAB":Tab;case "SPACE":Space;
  case "LEFT":Left;case "RIGHT":Right;case "UP":Up;case "DOWN":Down;
  case "A":A;case "D":D;case "W":W;case "S":S;case "Z":Z;case "X":X;case "C":C;case "P":P;case "SHIFT":Shift;default:throw 'Unknown key '+name;
 };
}
