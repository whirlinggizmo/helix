import helix.render2d.Camera2D;

/** The playing field on screen: Game.W x Game.H world units, letterboxed in the framebuffer. */
class Field {
	/** Sets camera to a width x height framebuffer, its viewport the largest area of the field's shape, centered, showing the whole field. */
	public static function view(camera:Camera2D, width:Int, height:Int):Void {
		camera.setViewport(width, height);
		var scale = Math.min(width / (Game.W * 1.), height / (Game.H * 1.)),
			w = Std.int(Game.W * scale),
			h = Std.int(Game.H * scale);
		camera.setViewportArea(Std.int((width - w) / 2), Std.int((height - h) / 2), w, h);
		camera.fit(0, 0, Game.W, Game.H);
	}
}
