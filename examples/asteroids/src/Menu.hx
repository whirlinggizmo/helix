import helix.input.IInput;
/** Small shared game menu. Hit testing and focus are not adapter responsibilities. */
class Menu {
 public var selected(default,null)=0;public var hovered(default,null)=-1;var previous="";
 public function new(){}
 public function update(game:Game,controls:Controls,input:IInput,width:Int,height:Int):Void {
  if(previous!=game.state){selected=0;previous=game.state;}hovered=-1;
  if(game.state=="playing")return;
  var count=game.state=="gameover"?2:1;
  if(controls.next)selected=(selected+1)%count;
  var scale=Math.min(width/(Game.W*1.),height/(Game.H*1.)),x=(input.getPointerX()-(width-Game.W*scale)/2)/scale,y=(input.getPointerY()-(height-Game.H*scale)/2)/scale;
  for(i in 0...count)if(x>=330&&x<630&&y>=390+i*64&&y<442+i*64){hovered=i;if(input.isPointerPressed()){selected=i;controls.start=true;}}
  if(controls.start&&game.state=="gameover"&&selected==1){controls.start=false;controls.title=true;}
 }
}
