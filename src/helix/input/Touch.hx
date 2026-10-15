package helix.input;

/** A finger, in framebuffer pixels like the pointer. Its id stays the same while it is down. */
typedef Touch = {final id:Int; final x:Float; final y:Float; final down:Bool; final pressed:Bool; final released:Bool;}
