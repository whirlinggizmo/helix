package helix.input;

/** A finger, in framebuffer pixels like the pointer. Its id stays the same while it is down. */
typedef Touch = {var id:Int; var x:Float; var y:Float; var down:Bool; var pressed:Bool; var released:Bool;}
