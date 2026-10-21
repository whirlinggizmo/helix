package helix.tools.shared;

import haxe.ds.Vector;
import haxe.io.Bytes;

/** SHA-256, laid out for Haxe's interpreter: about twice haxe.crypto.Sha256's speed there (some 3 MB a second), so the tools hash what they
	download once, when it arrives, and a manifest's directories only where a write changed them. */
class Sha256 {
	static final K = Vector.fromArrayCopy([
		0x428a2f98, 0x71374491, 0xb5c0fbcf, 0xe9b5dba5, 0x3956c25b, 0x59f111f1, 0x923f82a4, 0xab1c5ed5, 0xd807aa98, 0x12835b01, 0x243185be, 0x550c7dc3,
		0x72be5d74, 0x80deb1fe, 0x9bdc06a7, 0xc19bf174, 0xe49b69c1, 0xefbe4786, 0x0fc19dc6, 0x240ca1cc, 0x2de92c6f, 0x4a7484aa, 0x5cb0a9dc, 0x76f988da,
		0x983e5152, 0xa831c66d, 0xb00327c8, 0xbf597fc7, 0xc6e00bf3, 0xd5a79147, 0x06ca6351, 0x14292967, 0x27b70a85, 0x2e1b2138, 0x4d2c6dfc, 0x53380d13,
		0x650a7354, 0x766a0abb, 0x81c2c92e, 0x92722c85, 0xa2bfe8a1, 0xa81a664b, 0xc24b8b70, 0xc76c51a3, 0xd192e819, 0xd6990624, 0xf40e3585, 0x106aa070,
		0x19a4c116, 0x1e376c08, 0x2748774c, 0x34b0bcb5, 0x391c0cb3, 0x4ed8aa4a, 0x5b9cca4f, 0x682e6ff3, 0x748f82ee, 0x78a5636f, 0x84c87814, 0x8cc70208,
		0x90befffa, 0xa4506ceb, 0xbef9a3f7, 0xc67178f2
	]);

	/** data's SHA-256 as 64 lowercase hex digits. */
	public static function hex(data:Bytes):String {
		var length = data.length;
		var total = ((length + 9 + 63) >> 6) << 6;
		var buffer = Bytes.alloc(total);
		buffer.blit(0, data, 0, length);
		buffer.set(length, 0x80);
		putInt(buffer, total - 8, Std.int(length / 536870912.0));
		putInt(buffer, total - 4, length << 3);
		var h0 = 0x6a09e667, h1 = 0xbb67ae85, h2 = 0x3c6ef372, h3 = 0xa54ff53a;
		var h4 = 0x510e527f, h5 = 0x9b05688c, h6 = 0x1f83d9ab, h7 = 0x5be0cd19;
		var w = new Vector<Int>(64);
		var offset = 0;
		while (offset < total) {
			for (i in 0...16) {
				var p = offset + i * 4;
				w[i] = (buffer.get(p) << 24) | (buffer.get(p + 1) << 16) | (buffer.get(p + 2) << 8) | buffer.get(p + 3);
			}
			for (i in 16...64) {
				var x = w[i - 15], y = w[i - 2];
				var s0 = ((x >>> 7) | (x << 25)) ^ ((x >>> 18) | (x << 14)) ^ (x >>> 3);
				var s1 = ((y >>> 17) | (y << 15)) ^ ((y >>> 19) | (y << 13)) ^ (y >>> 10);
				w[i] = (w[i - 16] + s0 + w[i - 7] + s1) | 0;
			}
			var a = h0, b = h1, c = h2, d = h3, e = h4, f = h5, g = h6, h = h7;
			for (i in 0...64) {
				var sum1 = ((e >>> 6) | (e << 26)) ^ ((e >>> 11) | (e << 21)) ^ ((e >>> 25) | (e << 7));
				var t1 = (h + sum1 + ((e & f) ^ (~e & g)) + K[i] + w[i]) | 0;
				var sum0 = ((a >>> 2) | (a << 30)) ^ ((a >>> 13) | (a << 19)) ^ ((a >>> 22) | (a << 10));
				var t2 = (sum0 + ((a & b) ^ (a & c) ^ (b & c))) | 0;
				h = g;
				g = f;
				f = e;
				e = (d + t1) | 0;
				d = c;
				c = b;
				b = a;
				a = (t1 + t2) | 0;
			}
			h0 = (h0 + a) | 0;
			h1 = (h1 + b) | 0;
			h2 = (h2 + c) | 0;
			h3 = (h3 + d) | 0;
			h4 = (h4 + e) | 0;
			h5 = (h5 + f) | 0;
			h6 = (h6 + g) | 0;
			h7 = (h7 + h) | 0;
			offset += 64;
		}
		var out = Bytes.alloc(32);
		for (i => v in [h0, h1, h2, h3, h4, h5, h6, h7])
			putInt(out, i * 4, v);
		return out.toHex();
	}

	static function putInt(bytes:Bytes, at:Int, value:Int):Void {
		bytes.set(at, (value >>> 24) & 255);
		bytes.set(at + 1, (value >>> 16) & 255);
		bytes.set(at + 2, (value >>> 8) & 255);
		bytes.set(at + 3, value & 255);
	}
}
