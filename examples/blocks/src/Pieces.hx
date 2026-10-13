/** The seven pieces in their spawn orientation, and the standard rotation system's wall kicks. Y grows downward. */
class Pieces {
 public static inline var I=0;public static inline var O=1;public static inline var T=2;public static inline var S=3;public static inline var Z=4;public static inline var J=5;public static inline var L=6;
 public static final names=["I","O","T","S","Z","J","L"];
 /** Bounding box size, then x,y pairs. */
 static final spawn:Array<Array<Int>>=[[4,0,1,1,1,2,1,3,1],[4,1,0,2,0,1,1,2,1],[3,1,0,0,1,1,1,2,1],[3,1,0,2,0,0,1,1,1],[3,0,0,1,0,1,1,2,1],[3,0,0,0,1,1,1,2,1],[3,2,0,0,1,1,1,2,1]];
 /** Cells of a piece in a rotation (0 spawn, 1 right, 2 reversed, 3 left), as x,y pairs within its box. */
 public static final cells:Array<Array<Array<Int>>>=[for(kind in 0...7)[for(rotation in 0...4)turn(kind,rotation)]];
 static function turn(kind:Int,rotation:Int):Array<Int> {
  var shape=spawn[kind],size=shape[0],result=shape.slice(1);
  if(kind!=O)for(_ in 0...rotation)for(i in 0...4){var x=result[i*2],y=result[i*2+1];result[i*2]=size-1-y;result[i*2+1]=x;}
  return result;
 }
 // Offsets tried in order for a turn from each rotation, clockwise then counterclockwise, as x,y pairs with y up as published.
 static final kicksClockwise=[[0,0,-1,0,-1,1,0,-2,-1,-2],[0,0,1,0,1,-1,0,2,1,2],[0,0,1,0,1,1,0,-2,1,-2],[0,0,-1,0,-1,-1,0,2,-1,2]];
 static final kicksCounter=[[0,0,1,0,1,1,0,-2,1,-2],[0,0,1,0,1,-1,0,2,1,2],[0,0,-1,0,-1,1,0,-2,-1,-2],[0,0,-1,0,-1,-1,0,2,-1,2]];
 static final kicksClockwiseI=[[0,0,-2,0,1,0,-2,-1,1,2],[0,0,-1,0,2,0,-1,2,2,-1],[0,0,2,0,-1,0,2,1,-1,-2],[0,0,1,0,-2,0,1,-2,-2,1]];
 static final kicksCounterI=[[0,0,-1,0,2,0,-1,2,2,-1],[0,0,2,0,-1,0,2,1,-1,-2],[0,0,1,0,-2,0,1,-2,-2,1],[0,0,-2,0,1,0,-2,-1,1,2]];
 public static function kicks(kind:Int,from:Int,clockwise:Bool):Array<Int> {
  if(kind==O)return [0,0];var table=kind==I?(clockwise?kicksClockwiseI:kicksCounterI):(clockwise?kicksClockwise:kicksCounter);
  var row=table[from];return [for(i in 0...row.length)i%2==1?-row[i]:row[i]];
 }
}
