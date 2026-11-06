package render;

import lime.graphics.Image;
import lime.graphics.WebGLRenderContext;
import lime.graphics.opengl.GLBuffer;
import lime.graphics.opengl.GLProgram;
import lime.graphics.opengl.GLTexture;
import lime.math.Matrix4;
import lime.utils.Float32Array;

/** Lime's BunnyMark renderer (lime-samples 7.0.0), with a tint a bunny: six vertices a bunny of a position, a texture coordinate and a
	color, 8 floats each, written into one Float32Array each frame and uploaded with bufferData, drawn with one drawArrays. */
class GLRenderer {
	static inline final FLOATS = 6 * 8;

	var buffer:GLBuffer;
	var bufferData:Float32Array;
	var gl:WebGLRenderContext;
	var image:Image;
	var numBunnies:Int;
	var program:GLProgram;
	var texture:GLTexture;
	var vertexAttribute:Int;
	var textureAttribute:Int;
	var colorAttribute:Int;

	public function new(gl:WebGLRenderContext, image:Image, width:Int, height:Int) {
		this.gl = gl;
		this.image = image;
		numBunnies = 0;
		createShader();
		createBuffer();
		createMatrix(width, height);
		createTexture();
		gl.clearColor(245 / 255, 245 / 255, 245 / 255, 1);
		gl.blendFunc(gl.SRC_ALPHA, gl.ONE_MINUS_SRC_ALPHA);
		gl.enable(gl.BLEND);
	}

	function createBuffer():Void {
		vertexAttribute = gl.getAttribLocation(program, "aVertexPosition");
		textureAttribute = gl.getAttribLocation(program, "aTexCoord");
		colorAttribute = gl.getAttribLocation(program, "aColor");
		buffer = gl.createBuffer();
		gl.bindBuffer(gl.ARRAY_BUFFER, buffer);
		bufferData = new Float32Array(0);
		var stride = 8 * Float32Array.BYTES_PER_ELEMENT;
		gl.enableVertexAttribArray(vertexAttribute);
		gl.vertexAttribPointer(vertexAttribute, 2, gl.FLOAT, false, stride, 0);
		gl.enableVertexAttribArray(textureAttribute);
		gl.vertexAttribPointer(textureAttribute, 2, gl.FLOAT, false, stride, 2 * Float32Array.BYTES_PER_ELEMENT);
		gl.enableVertexAttribArray(colorAttribute);
		gl.vertexAttribPointer(colorAttribute, 4, gl.FLOAT, false, stride, 4 * Float32Array.BYTES_PER_ELEMENT);
	}

	function createMatrix(width:Int, height:Int):Void {
		var matrixUniform = gl.getUniformLocation(program, "uMatrix");
		var matrix = new Matrix4();
		matrix.createOrtho(0, width, height, 0, -1000, 1000);
		gl.uniformMatrix4fv(matrixUniform, false, matrix);
	}

	function createShader():Void {
		var vertexSource = "
			attribute vec2 aVertexPosition;
			attribute vec2 aTexCoord;
			attribute vec4 aColor;
			uniform mat4 uMatrix;
			varying vec2 vTexCoord;
			varying vec4 vColor;
			void main (void) {
				vTexCoord = aTexCoord;
				vColor = aColor;
				gl_Position = uMatrix * vec4 (aVertexPosition, 0.0, 1.0);
			}
		";
		var fragmentSource = "precision mediump float;
			varying vec2 vTexCoord;
			varying vec4 vColor;
			uniform sampler2D uImage0;
			void main (void) {
				gl_FragColor = texture2D (uImage0, vTexCoord) * vColor;
			}
		";
		program = GLProgram.fromSources(gl, vertexSource, fragmentSource);
		gl.useProgram(program);
	}

	function createTexture():Void {
		var imageUniform = gl.getUniformLocation(program, "uImage0");
		gl.uniform1i(imageUniform, 0);
		texture = gl.createTexture();
		gl.bindTexture(gl.TEXTURE_2D, texture);
		gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_S, gl.CLAMP_TO_EDGE);
		gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_T, gl.CLAMP_TO_EDGE);
		gl.texImage2D(gl.TEXTURE_2D, 0, gl.RGBA, gl.RGBA, gl.UNSIGNED_BYTE, image.src);
		gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_MAG_FILTER, gl.NEAREST);
		gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_MIN_FILTER, gl.NEAREST);
	}

	/** Writes every bunny's six vertices, the array grown when there are more bunnies than before. */
	public function updateBuffer(bunnies:Array<Bunny>):Void {
		if (bunnies.length > numBunnies) {
			bufferData = new Float32Array(bunnies.length * FLOATS);
			numBunnies = bunnies.length;
		}
		var w = image.width, h = image.height;
		var d = bufferData;
		for (i in 0...numBunnies) {
			var at = i * FLOATS;
			var b = bunnies[i];
			var x = Std.int(b.x), y = Std.int(b.y);
			var x2 = x + w, y2 = y + h;
			// Two triangles: (x, y) (x2, y) (x, y2), then (x, y2) (x2, y) (x2, y2).
			put(d, at, x, y, 0, 0, b);
			put(d, at + 8, x2, y, 1, 0, b);
			put(d, at + 16, x, y2, 0, 1, b);
			put(d, at + 24, x, y2, 0, 1, b);
			put(d, at + 32, x2, y, 1, 0, b);
			put(d, at + 40, x2, y2, 1, 1, b);
		}
	}

	inline function put(d:Float32Array, at:Int, x:Float, y:Float, u:Float, v:Float, b:Bunny):Void {
		d[at] = x;
		d[at + 1] = y;
		d[at + 2] = u;
		d[at + 3] = v;
		d[at + 4] = b.r;
		d[at + 5] = b.g;
		d[at + 6] = b.b;
		d[at + 7] = 1;
	}

	/** Clears and draws every bunny. */
	public function render():Void {
		gl.clear(gl.COLOR_BUFFER_BIT);
		gl.bufferData(gl.ARRAY_BUFFER, bufferData, gl.DYNAMIC_DRAW);
		gl.drawArrays(gl.TRIANGLES, 0, numBunnies * 6);
	}
}
