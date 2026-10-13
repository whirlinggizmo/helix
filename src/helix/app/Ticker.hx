package helix.app;
import helix.input.IInput;

/** A fixed-rate simulation inside the frame callback. Each tick sees the input's tick edges, consumed after it, so a press is seen by exactly one tick.
    fraction is how far the frame is between the last tick and the next, for drawing between them. */
class Ticker {
 public var rate(default,null):Float;
 public var delta(default,null):Float;
 /** Scales simulated time: 0 pauses the ticks while frames go on. */
 public var timeScale=1.;
 public var fraction(default,null)=0.;
 /** Ticks run in one frame at most; a longer stall loses the rest rather than spiralling. */
 public var maxSteps=8;
 var input:IInput;var accumulator=0.;
 public function new(input:IInput,rate=60.){this.input=input;setRate(rate);}
 public function setRate(value:Float):Void {rate=value;delta=1/value;}
 /** Runs tick for each step due after dt seconds; returns how many ran. */
 public function advance(dt:Float,tick:Void->Void):Int {
  accumulator+=Math.max(0,Math.min(dt,.25))*timeScale;var steps=0;
  while(accumulator>=delta&&steps<maxSteps){tick();input.consume();accumulator-=delta;steps++;}
  if(accumulator>=delta)accumulator%=delta;
  fraction=accumulator/delta;return steps;
 }
}
