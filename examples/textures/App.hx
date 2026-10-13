import helix.app.BaseApp;
import helix.debug.FpsOverlay;
import helix.graphics.Sampling;
import helix.host.IHost;
import helix.input.Key;
import helix.render2d.Batch2D;
import helix.render2d.Camera2D;
import helix.render2d.Text2D;
import helix.render2d.Texture2D;

/** One loaded texture or file, and how its load went. */
private class Slot {
	public var path:String;
	public var texture:Null<Texture2D>;
	public var chosen = "";
	public var status = "loading...";
	public var asked:Float;
	public var took = 0.;

	public function new(path:String, asked:Float) {
		this.path = path;
		this.asked = asked;
	}
}

/** Textures from image files, each drawn large twice, smooth (linear) then sharp (nearest): one texture whose sampling changes between the
	draws, with its size, GPU memory and how long it took from asking to having it. The tile sheet draws as its cells, cut from their gutters.
	Below, the logo and the flame again as "name.ktx": compressed for this GPU (name.bc7.ktx on desktops, name.astc.ktx on phones,
	name.etc2.ktx on older phones), else name.png, as the tile sheet, which has no compressed files, shows. Escape quits where quitting means anything. */
class App extends BaseApp {
	static var PATHS = ["sprites/logo/wg-logo-bw-alpha.png", "textures/flame.png", "textures/tiles.png"];
	static var KTX_PATHS = ["sprites/logo/wg-logo-bw-alpha.ktx", "textures/flame.ktx", "textures/tiles.ktx"];
	static inline var TILES = 2;

	// The tile sheet's cells in its texels, x, y, width, height: each has a 2 texel gutter repeating its edge, so filtering and mipmaps never
	// reach a neighbour; the gutters aren't drawn. Grass, sand, water, stone; tree, flag, coin, rock.
	static var CELLS = [
		 [2, 2, 16, 16],  [22, 2, 16, 16],  [42, 2, 16, 16], [62, 2, 16, 16],
		[2, 22, 16, 32], [22, 22, 16, 32], [42, 22, 16, 16], [62, 22, 16, 16]
	];

	var host:IHost;
	var batch:Batch2D;
	var camera = new Camera2D();
	var fps = new FpsOverlay();
	var slots:Array<Slot> = [];
	var compressed:Array<Slot> = [];

	public function new(host:IHost) {
		super();
		this.host = host;
	}

	override public function init():Void {
		host.window.setTitle("HeliX textures");
		host.window.setSize(1010, 610);
		batch = new Batch2D(host.graphics);
		for (path in PATHS)
			slots.push(load(path));
		for (path in KTX_PATHS)
			compressed.push(load(path));
	}

	function load(path:String):Slot {
		var slot = new Slot(path, host.getTime());
		host.textures.load(path, true, result -> switch result {
			case Ready(texture):
				slot.texture = texture;
				slot.took = host.getTime() - slot.asked;
				slot.chosen = host.textures.getPath(texture);
			case Failed(message):
				slot.status = "failed";
				trace(message);
			case Cancelled:
		});
		return slot;
	}

	static function fileName(path:String):String
		return path.substr(path.lastIndexOf("/") + 1);

	// Under a texture: its file's name (and the file chosen for a .ktx, under it), then its size, the GPU memory it takes, and how long it took.
	function caption(slot:Slot, x:Float, y:Float):Void {
		var name = fileName(slot.path), chosen = fileName(slot.chosen);
		Text2D.draw(batch, name, x, y, 16, 0xc8c8c8ff);
		if (slot.chosen != "" && chosen != name) {
			y += 22;
			Text2D.draw(batch, 'loaded $chosen', x, y, 14, 0x66bfffff);
		}
		var t = slot.texture;
		var line = t == null ? slot.status : '${t.getWidth()} x ${t.getHeight()}, GPU ${Math.round(t.getByteSize() / 1024)} KB, ready in ${Math.round(slot.took * 1000)} ms';
		Text2D.draw(batch, line, x, y + 22, 14, 0xc8c8c8ff);
	}

	// One texture width wide at x, y: the tile sheet as its cells set edge to edge, anything else whole.
	function drawOne(index:Int, texture:Texture2D, x:Float, y:Float, width:Float):Void {
		if (index != TILES) {
			batch.image(texture, x, y, width, width);
			return;
		}
		// The cells span 64 by 48 texels.
		var scale = width / 64;
		for (c in 0...CELLS.length) {
			var cell = CELLS[c], column = c % 4, top = c < 4 ? 0 : 16;
			batch.image(texture, x + column * 16 * scale, y + top * scale, cell[2] * scale, cell[3] * scale, 0xffffffff, cell[0], cell[1], cell[2], cell[3]);
		}
	}

	override public function frame(dt:Float):Void {
		if (host.canQuit() && host.input.isFramePressed(Key.Escape))
			host.quit();
		fps.update(dt, host.diagnostics.getFrameCpu());
		var width = host.getFramebufferWidth(),
			height = host.getFramebufferHeight();
		camera.setViewport(width, height);
		camera.pixels(host.getPixelRatio());

		host.graphics.beginFrame(width, height, 0x262a36ff);
		batch.begin(camera);
		Text2D.draw(batch, "HeliX textures: smooth (linear) and sharp (nearest) sampling", 12, 30, 22, 0xf5f5f5ff);
		for (i in 0...slots.length) {
			var x = 20 + i * 330, y = 80, texture = slots[i].texture;
			if (texture != null) {
				// Sampling is the texture's, read as each draw takes it: one texture, drawn smooth, then sharp.
				texture.setSampling(Sampling.LINEAR);
				drawOne(i, texture, x, y, 150);
				texture.setSampling(Sampling.NEAREST);
				drawOne(i, texture, x + 160, y, 150);
			}
			caption(slots[i], x, y + 166);
		}
		Text2D.draw(batch, "compressed: as name.ktx, this GPU's variant or else the PNG", 12, 310, 22, 0xf5f5f5ff);
		for (i in 0...compressed.length) {
			var x = 20 + i * 330, y = 360, texture = compressed[i].texture;
			if (texture != null)
				drawOne(i, texture, x, y, 150);
			caption(compressed[i], x, y + 166);
		}
		fps.draw(batch, 12, 6);
		batch.end();
		host.graphics.endFrame();
	}

	override public function cleanup():Void {
		for (slot in slots.concat(compressed))
			if (slot.texture != null)
				host.textures.release(slot.texture);
		batch.destroy();
	}
}
