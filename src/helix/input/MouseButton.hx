package helix.input;

enum abstract MouseButton(Int) to Int {
 var Left=0;var Right=1;var Middle=2;
 public static final all:Array<MouseButton>=[Left,Right,Middle];
}
