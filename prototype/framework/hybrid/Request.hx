package hybrid;
class Request implements IRequest {
 public var settled(default,null)=false;
 var cancelled:Void->Void;
 public function new(cancelled:Void->Void){this.cancelled=cancelled;}
 public function finish():Bool {if(settled)return false;settled=true;return true;}
 public function cancel():Void {if(finish())cancelled();}
}
