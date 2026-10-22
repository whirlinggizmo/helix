package helix.render3d;

import helix.graphics.Color;
import helix.graphics.IGraphics;
import haxe.io.Bytes;

/** Immediate 3D drawing in world units through a Camera3D, inside a frame (IGraphics.beginFrame to endFrame), depth-tested against what the frame
	has drawn in 3D so far. A batch is two uploads and at most two draws: its triangles, then its lines. Colors are 0xAARRGGBB. Solid shapes are
	shaded on the CPU by one fixed light from above (setLight), with no lighting in the shader. */
class Batch3D {
	var gpu:IGraphics;
	var capacity:Int;
	var triangles:Bytes;
	var lines:Bytes;
	var triangleBuffer:Int;
	var lineBuffer:Int;
	var pipelines:helix.graphics.Pipelines;
	var uniforms = Bytes.alloc(64);
	var camera:Camera3D;
	var triangleVertices = 0;
	var lineVertices = 0;
	var draws = 0;

	/** A batch of up to maxVertices triangle vertices and maxVertices line vertices a frame, with its own buffers on gpu; destroy frees them.  Without gpu, the program's (Graphics.instance). */
	public function new(?gpu:IGraphics, maxVertices = 65536) {
		if (gpu == null)
			gpu = helix.graphics.Graphics.instance;
		this.gpu = gpu;
		capacity = maxVertices;
		triangles = Bytes.alloc(capacity * Color3DProgram.stride);
		lines = Bytes.alloc(capacity * Color3DProgram.stride);
		triangleBuffer = gpu.createBuffer(capacity * Color3DProgram.stride);
		lineBuffer = gpu.createBuffer(capacity * Color3DProgram.stride);
		pipelines = helix.graphics.Pipelines.of(gpu);
		setLight(.3, .9, .3, .35);
	}

	/** Vertices of the frame drawn last, triangles' and lines'. */
	public var vertexCount(get, never):Int;

	function get_vertexCount():Int
		return triangleVertices + lineVertices;

	/** Draws of the frame drawn last: up to two. */
	public var drawCallCount(get, never):Int;

	function get_drawCallCount():Int
		return draws;

	/** The direction toward the light, x (normalized). */
	public var lightX(default, null):Float = .3;

	/** The direction toward the light, y (normalized). */
	public var lightY(default, null):Float = .9;

	/** The direction toward the light, z (normalized). */
	public var lightZ(default, null):Float = .3;

	/** The brightness of a face turned away from the light, 0 to 1. */
	public var ambient(default, null):Float = .35;

	/** The light solid shapes are shaded by: from the direction x, y, z (toward the light, normalized here), with ambient the brightness of a face
		turned away (0 to 1). False, changing nothing, for a zero direction or an ambient outside 0 to 1. */
	public function setLight(x:Float, y:Float, z:Float, ambient:Float):Bool {
		var length = Math.sqrt(x * x + y * y + z * z);
		if (length == 0 || !(ambient >= 0 && ambient <= 1))
			return false;
		lightX = x / length;
		lightY = y / length;
		lightZ = z / length;
		this.ambient = ambient;
		return true;
	}

	/** Starts collecting a batch seen through camera; later calls only fill it until end. */
	public function begin(camera:Camera3D):Void {
		this.camera = camera;
		triangleVertices = 0;
		lineVertices = 0;
		draws = 0;
	}

	/** Draws the batch in the open frame, in the camera's viewport: its triangles, then its lines. Once a frame. */
	public function end():Void {
		gpu.applyViewport(camera.viewportX, camera.framebufferHeight - camera.viewportY - camera.viewportHeight, camera.viewportWidth, camera.viewportHeight);
		camera.viewProjection.writeTo(uniforms);
		gpu.updateBuffer(triangleBuffer, triangles, triangleVertices * Color3DProgram.stride);
		gpu.updateBuffer(lineBuffer, lines, lineVertices * Color3DProgram.stride);
		if (triangleVertices > 0) {
			gpu.draw(pipelines.color3D(), [triangleBuffer], 0, 0, triangleVertices, 0, 1, [], [], [uniforms]);
			draws++;
		}
		if (lineVertices > 0) {
			gpu.draw(pipelines.lines3D(), [lineBuffer], 0, 0, lineVertices, 0, 1, [], [], [uniforms]);
			draws++;
		}
	}

	static inline function put(data:Bytes, index:Int, x:Float, y:Float, z:Float, color:Int, shade:Float):Void {
		var p = index * Color3DProgram.stride + Color3DProgram.positionOffset,
			c = index * Color3DProgram.stride + Color3DProgram.colorOffset;
		data.setFloat(p, x);
		data.setFloat(p + 4, y);
		data.setFloat(p + 8, z);
		data.setFloat(c, (Color.getRed(color) / 255) * shade);
		data.setFloat(c + 4, (Color.getGreen(color) / 255) * shade);
		data.setFloat(c + 8, (Color.getBlue(color) / 255) * shade);
		data.setFloat(c + 12, Color.getAlpha(color) / 255);
	}

	/** The brightness of a surface facing nx, ny, nz (normalized). */
	inline function shade(nx:Float, ny:Float, nz:Float):Float {
		var lit = nx * lightX + ny * lightY + nz * lightZ;
		return ambient + (1 - ambient) * (lit > 0 ? lit : 0);
	}

	inline function vertex(x:Float, y:Float, z:Float, color:Int, brightness:Float):Void {
		if (triangleVertices >= capacity)
			throw "Batch3D capacity exceeded";
		put(triangles, triangleVertices++, x, y, z, color, brightness);
	}

	/** A segment between two world points. */
	public function line(x0:Float, y0:Float, z0:Float, x1:Float, y1:Float, z1:Float, color:Int):Void {
		if (lineVertices + 2 > capacity)
			throw "Batch3D capacity exceeded";
		put(lines, lineVertices++, x0, y0, z0, color, 1);
		put(lines, lineVertices++, x1, y1, z1, color, 1);
	}

	/** A filled triangle through three world points, unshaded. */
	public function triangle(x0:Float, y0:Float, z0:Float, x1:Float, y1:Float, z1:Float, x2:Float, y2:Float, z2:Float, color:Int):Void {
		vertex(x0, y0, z0, color, 1);
		vertex(x1, y1, z1, color, 1);
		vertex(x2, y2, z2, color, 1);
	}

	// One face of a box: its four corners in order, and the normal the light shades it by.
	function face(ax:Float, ay:Float, az:Float, bx:Float, by:Float, bz:Float, cx:Float, cy:Float, cz:Float, dx:Float, dy:Float, dz:Float, nx:Float, ny:Float,
			nz:Float, color:Int):Void {
		var s = shade(nx, ny, nz);
		vertex(ax, ay, az, color, s);
		vertex(bx, by, bz, color, s);
		vertex(cx, cy, cz, color, s);
		vertex(ax, ay, az, color, s);
		vertex(cx, cy, cz, color, s);
		vertex(dx, dy, dz, color, s);
	}

	/** A solid box centered on x, y, z, width along x, height along y, depth along z, each face shaded by the light. */
	public function cube(x:Float, y:Float, z:Float, width:Float, height:Float, depth:Float, color:Int):Void {
		var x0 = x - width / 2,
			x1 = x + width / 2,
			y0 = y - height / 2,
			y1 = y + height / 2,
			z0 = z - depth / 2,
			z1 = z + depth / 2;
		face(x0, y0, z1, x1, y0, z1, x1, y1, z1, x0, y1, z1, 0, 0, 1, color);
		face(x1, y0, z0, x0, y0, z0, x0, y1, z0, x1, y1, z0, 0, 0, -1, color);
		face(x1, y0, z1, x1, y0, z0, x1, y1, z0, x1, y1, z1, 1, 0, 0, color);
		face(x0, y0, z0, x0, y0, z1, x0, y1, z1, x0, y1, z0, -1, 0, 0, color);
		face(x0, y1, z1, x1, y1, z1, x1, y1, z0, x0, y1, z0, 0, 1, 0, color);
		face(x0, y0, z0, x1, y0, z0, x1, y0, z1, x0, y0, z1, 0, -1, 0, color);
	}

	/** A box's twelve edges, centered on x, y, z, as cube's. */
	public function cubeWires(x:Float, y:Float, z:Float, width:Float, height:Float, depth:Float, color:Int):Void {
		var x0 = x - width / 2,
			x1 = x + width / 2,
			y0 = y - height / 2,
			y1 = y + height / 2,
			z0 = z - depth / 2,
			z1 = z + depth / 2;
		for (yy in [y0, y1]) {
			line(x0, yy, z0, x1, yy, z0, color);
			line(x1, yy, z0, x1, yy, z1, color);
			line(x1, yy, z1, x0, yy, z1, color);
			line(x0, yy, z1, x0, yy, z0, color);
		}
		line(x0, y0, z0, x0, y1, z0, color);
		line(x1, y0, z0, x1, y1, z0, color);
		line(x1, y0, z1, x1, y1, z1, color);
		line(x0, y0, z1, x0, y1, z1, color);
	}

	/** A solid sphere centered on x, y, z, of rings bands from pole to pole and slices around, each vertex shaded by its normal. */
	public function sphere(x:Float, y:Float, z:Float, radius:Float, color:Int, rings = 16, slices = 24):Void {
		for (ring in 0...rings) {
			var a0 = Math.PI * ring / rings, a1 = Math.PI * (ring + 1) / rings;
			var y0 = Math.cos(a0),
				r0 = Math.sin(a0),
				y1 = Math.cos(a1),
				r1 = Math.sin(a1);
			for (slice in 0...slices) {
				var b0 = Math.PI * 2 * slice / slices,
					b1 = Math.PI * 2 * (slice + 1) / slices;
				var c0 = Math.cos(b0),
					s0 = Math.sin(b0),
					c1 = Math.cos(b1),
					s1 = Math.sin(b1);
				// The quad's corners as unit normals: ring a0 then a1, slice b0 then b1.
				var ax = r0 * c0, az = r0 * s0, bx = r0 * c1, bz = r0 * s1, cx = r1 * c1, cz = r1 * s1, dx = r1 * c0, dz = r1 * s0;
				if (ring > 0) {
					vertex(x + ax * radius, y + y0 * radius, z + az * radius, color, shade(ax, y0, az));
					vertex(x + cx * radius, y + y1 * radius, z + cz * radius, color, shade(cx, y1, cz));
					vertex(x + bx * radius, y + y0 * radius, z + bz * radius, color, shade(bx, y0, bz));
				}
				if (ring < rings - 1) {
					vertex(x + ax * radius, y + y0 * radius, z + az * radius, color, shade(ax, y0, az));
					vertex(x + dx * radius, y + y1 * radius, z + dz * radius, color, shade(dx, y1, dz));
					vertex(x + cx * radius, y + y1 * radius, z + cz * radius, color, shade(cx, y1, cz));
				}
			}
		}
	}

	/** A square grid on the y = 0 plane centered on the origin: slices cells a side, each spacing world units. */
	public function grid(slices:Int, spacing:Float, color:Int):Void {
		var half = slices * spacing / 2;
		for (i in 0...slices + 1) {
			var at = -half + i * spacing;
			line(at, 0, -half, at, 0, half, color);
			line(-half, 0, at, half, 0, at, color);
		}
	}

	/** Frees the buffers made by new; the batch is unusable after. */
	public function destroy():Void {
		gpu.destroyBuffer(triangleBuffer);
		gpu.destroyBuffer(lineBuffer);
	}
}
