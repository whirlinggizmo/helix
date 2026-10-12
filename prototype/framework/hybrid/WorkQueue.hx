package hybrid;
/** Cooperative host work. Individual operations can exceed the nominal budget. */
class WorkQueue {
 var pending:Array<Void->Void>=[];
 public var budgetMs=2.;
 public function new(){}
 public function add(work:Void->Void):Void pending.push(work);
 public function poll():Void {
  var start=haxe.Timer.stamp(),count=pending.length;
  for(_ in 0...count){pending.shift()();if((haxe.Timer.stamp()-start)*1000>=budgetMs)break;}
 }
}
