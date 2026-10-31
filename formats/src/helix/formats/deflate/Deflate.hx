package helix.formats.deflate;

import haxe.ds.Vector;
import haxe.io.Bytes;

/** Provides DEFLATE compression (RFC 1951) as raylib 5.5's `CompressData` compresses, byte for byte.

	It is sdefl 1.0 (`sdefl.h`, raylib 5.5's copy), ported: a hash chain matcher, its lazy match from level 5, and a dynamic Huffman
	block for each 256 KiB of input, stored as raw blocks when that is smaller. The stream is raw DEFLATE, with no zlib header or
	checksum; `haxe.zip.InflateImpl` reads it back with its header off. Empty input compresses to no bytes, as sdefl's does.

	```haxe
	var compressed = Deflate.compress(bytes, 8);
	``` */
class Deflate {
	/** Compresses bytes into a raw DEFLATE stream.

		Level 8 is raylib's `CompressData`'s; sdefl's own default is 5. Each level searches longer for matches: 0 and 1 skip ahead over
		a long match, 5 and up look one byte on for a longer one.

		@param data  The bytes to compress.
		@param level  The compression level, from 0 (fastest) to 8 (smallest).
		@return  The DEFLATE stream.
		@throws String  The level is outside 0 to 8. */
	public static function compress(data:Bytes, level:Int):Bytes {
		if (level < 0 || level > 8)
			throw 'Deflate level $level is outside 0 to 8';
		return new SmallDeflate(data, level).run();
	}
}

/* Ported from sdefl.h (Small Deflate), raylib 5.5's copy, by Micha Mettke, under either license below.

	ALTERNATIVE A - MIT License
	Copyright (c) 2020-2023 Micha Mettke
	Permission is hereby granted, free of charge, to any person obtaining a copy of
	this software and associated documentation files (the "Software"), to deal in
	the Software without restriction, including without limitation the rights to
	use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies
	of the Software, and to permit persons to whom the Software is furnished to do
	so, subject to the following conditions:
	The above copyright notice and this permission notice shall be included in all
	copies or substantial portions of the Software.
	THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
	IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
	FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
	AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
	LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
	OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
	SOFTWARE.

	ALTERNATIVE B - Public Domain (www.unlicense.org)
	This is free and unencumbered software released into the public domain.
	Anyone is free to copy, modify, publish, use, compile, sell, or distribute this
	software, either in source code form or as a compiled binary, for any purpose,
	commercial or non-commercial, and by any means. */
/** Provides `Deflate.compress`'s work: sdefl's state, for one stream. */
private class SmallDeflate {
	static inline final MAX_OFF = 1 << 15;
	static inline final WIN_SIZ = MAX_OFF;
	static inline final WIN_MSK = WIN_SIZ - 1;
	static inline final HASH_BITS = 15;
	static inline final HASH_SIZ = 1 << HASH_BITS;
	static inline final MIN_MATCH = 4;
	static inline final BLK_MAX = 256 * 1024;
	static inline final SYM_MAX = 288;
	static inline final OFF_MAX = 32;
	static inline final PRE_MAX = 19;
	static inline final NIL = -1;
	static inline final MAX_MATCH = 258;
	static inline final SYM_BITS = 10;
	static inline final SYM_MSK = (1 << SYM_BITS) - 1;
	static inline final RAW_BLK_SIZE = 65535;
	static inline final LIT_LEN_CODES = 14;
	static inline final OFF_CODES = 15;
	static inline final PRE_CODES = 7;
	static inline final EOB = 256;

	static final PREF = [8, 10, 14, 24, 30, 48, 65, 96, 130];
	static final DXMAX = [0, 6, 12, 24, 48, 96, 192, 384, 768, 1536, 3072, 6144, 12288, 24576];
	static final LSLOT = [
		0, 0, 0, 0, 1, 2, 3, 4, 5, 6, 7, 8, 8, 9, 9, 10, 10, 11, 11, 12, 12, 12, 12, 13, 13, 13, 13, 14, 14, 14, 14, 15, 15, 15, 15, 16, 16, 16, 16, 16, 16,
		16, 16, 17, 17, 17, 17, 17, 17, 17, 17, 18, 18, 18, 18, 18, 18, 18, 18, 19, 19, 19, 19, 19, 19, 19, 19, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20,
		20, 20, 20, 20, 20, 21, 21, 21, 21, 21, 21, 21, 21, 21, 21, 21, 21, 21, 21, 21, 21, 22, 22, 22, 22, 22, 22, 22, 22, 22, 22, 22, 22, 22, 22, 22, 22,
		23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 24, 24, 24, 24, 24, 24, 24, 24, 24, 24, 24, 24, 24, 24, 24, 24, 24, 24, 24, 24, 24,
		24, 24, 24, 24, 24, 24, 24, 24, 24, 24, 24, 25, 25, 25, 25, 25, 25, 25, 25, 25, 25, 25, 25, 25, 25, 25, 25, 25, 25, 25, 25, 25, 25, 25, 25, 25, 25,
		25, 25, 25, 25, 25, 25, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26,
		26, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 28
	];
	static final X_PRE_BITS = [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 2, 3, 7];
	static final X_LEN_BITS = [
		0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 1, 1, 2, 2, 2, 2, 3, 3, 3, 3, 4, 4, 4, 4, 5, 5, 5, 5, 0
	];
	static final X_OFF_BITS = [
		0, 0, 0, 0, 1, 1, 2, 2, 3, 3, 4, 4, 5, 5, 6, 6, 7, 7, 8, 8, 9, 9, 10, 10, 11, 11, 12, 12, 13, 13
	];
	static final LXN = [
		0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 1, 1, 2, 2, 2, 2, 3, 3, 3, 3, 4, 4, 4, 4, 5, 5, 5, 5, 0
	];
	static final LMIN = [
		3, 4, 5, 6, 7, 8, 9, 10, 11, 13, 15, 17, 19, 23, 27, 31, 35, 43, 51, 59, 67, 83, 99, 115, 131, 163, 195, 227, 258
	];
	static final DMIN = [
		1, 2, 3, 4, 5, 7, 9, 13, 17, 25, 33, 49, 65, 97, 129, 193, 257, 385, 513, 769, 1025, 1537, 2049, 3073, 4097, 6145, 8193, 12289, 16385, 24577
	];
	static final PERM = [16, 17, 18, 0, 8, 7, 9, 6, 10, 5, 11, 4, 12, 3, 13, 2, 14, 1, 15];

	final input:Bytes;
	final inLen:Int;
	final lvl:Int;
	final out:Bytes;
	var q = 0;
	var bits = 0;
	var bitcnt = 0;
	final tbl = new Vector<Int>(HASH_SIZ, NIL);
	final prv = new Vector<Int>(WIN_SIZ, 0);
	// sdefl holds (BLK_MAX + 2) / 3 sequences and asserts it never needs more; a block can hold at most one per byte.
	final seqOff = new Vector<Int>(BLK_MAX + 1, 0);
	final seqLen = new Vector<Int>(BLK_MAX + 1, 0);
	var seqCnt = 0;
	final freqLit = new Vector<Int>(SYM_MAX, 0);
	final freqOff = new Vector<Int>(OFF_MAX, 0);
	final wordLit = new Vector<Int>(SYM_MAX, 0);
	final wordOff = new Vector<Int>(OFF_MAX, 0);
	final lenLit = new Vector<Int>(SYM_MAX, 0);
	final lenOff = new Vector<Int>(OFF_MAX, 0);
	// The last match found, sdefl_fnd's struct sdefl_match.
	var matchOff = 0;
	var matchLen = 0;
	// The last match's codes, sdefl_match_codes's struct.
	var codeLs = 0;
	var codeLc = 0;
	var codeDc = 0;
	var codeDx = 0;
	// The last precode's counts, struct sdefl_symcnt.
	var symItems = 0;
	var symLit = 0;
	var symOff = 0;

	/** Makes the state for compressing input at level lvl. */
	public function new(input:Bytes, lvl:Int) {
		this.input = input;
		this.inLen = input.length;
		this.lvl = lvl;
		// sdefl_bound.
		var maxBlocks = 1 + divRoundUp(inLen, RAW_BLK_SIZE);
		out = Bytes.alloc(5 * maxBlocks + inLen + 1 + 4 + 8);
	}

	/** Returns the input's DEFLATE stream, as `sdeflate` writes it. */
	public function run():Bytes {
		compr();
		return out.sub(0, q);
	}

	static inline function divRoundUp(n:Int, d:Int):Int
		return Std.int((n + (d - 1)) / d);

	static function ilog2(n:Int):Int {
		if (n == 0)
			return 0;
		var r = 0;
		while ((n >>>= 1) != 0)
			r++;
		return r;
	}

	static inline function npow2(n:Int):Int
		return 1 << (ilog2(n - 1) + 1);

	inline function uload32(p:Int):Int
		return input.get(p) | (input.get(p + 1) << 8) | (input.get(p + 2) << 16) | (input.get(p + 3) << 24);

	inline function hash32(p:Int):Int {
		var n:haxe.Int32 = uload32(p);
		var h:Int = n * 0x9E377989;
		return h >>> (32 - HASH_BITS);
	}

	function put(code:Int, count:Int):Void {
		bits |= code << bitcnt;
		bitcnt += count;
		while (bitcnt >= 8) {
			out.set(q++, bits & 0xFF);
			bits >>>= 8;
			bitcnt -= 8;
		}
	}

	inline function put16(x:Int):Void {
		out.set(q++, x & 0xFF);
		out.set(q++, (x >> 8) & 0xFF);
	}

	// sdefl_heap_sub, on a's elements from base, indexed from 1. The values (a symbol and its count) stay under 2^31, so signed
	// comparisons order them as sdefl's unsigned ones do.
	static function heapSub(a:Vector<Int>, base:Int, len:Int, sub:Int):Void {
		var c, p = sub;
		var v = a[base + sub];
		while ((c = p << 1) <= len) {
			if (c < len && a[base + c + 1] > a[base + c])
				c++;
			if (v >= a[base + c])
				break;
			a[base + p] = a[base + c];
			p = c;
		}
		a[base + p] = v;
	}

	static function heapSort(a:Vector<Int>, start:Int, n:Int):Void {
		var base = start - 1;
		var sub = n >> 1;
		while (sub >= 1) {
			heapSub(a, base, n, sub);
			sub--;
		}
		while (n >= 2) {
			var tmp = a[base + n];
			a[base + n] = a[base + 1];
			n--;
			a[base + 1] = tmp;
			heapSub(a, base, n, 1);
		}
	}

	static function sortSym(symCnt:Int, freqs:Vector<Int>, lens:Vector<Int>, symOut:Vector<Int>):Int {
		var cntNum = (symCnt + 3) & ~3;
		var cnts = new Vector<Int>(cntNum, 0);
		var usedSym = 0;
		for (sym in 0...symCnt)
			cnts[freqs[sym] < cntNum - 1 ? freqs[sym] : cntNum - 1]++;
		for (i in 1...cntNum) {
			var cnt = cnts[i];
			cnts[i] = usedSym;
			usedSym += cnt;
		}
		for (sym in 0...symCnt) {
			var freq = freqs[sym];
			if (freq != 0) {
				var idx = freq < cntNum - 1 ? freq : cntNum - 1;
				symOut[cnts[idx]++] = sym | (freq << SYM_BITS);
			} else
				lens[sym] = 0;
		}
		heapSort(symOut, cnts[cntNum - 2], cnts[cntNum - 1] - cnts[cntNum - 2]);
		return usedSym;
	}

	static function buildTree(a:Vector<Int>, symCnt:Int):Void {
		var i = 0, b = 0, e = 0;
		do {
			var m, n;
			if (i != symCnt && (b == e || (a[i] >>> SYM_BITS) <= (a[b] >>> SYM_BITS)))
				m = i++;
			else
				m = b++;
			if (i != symCnt && (b == e || (a[i] >>> SYM_BITS) <= (a[b] >>> SYM_BITS)))
				n = i++;
			else
				n = b++;
			var freqShift = (a[m] & ~SYM_MSK) + (a[n] & ~SYM_MSK);
			a[m] = (a[m] & SYM_MSK) | (e << SYM_BITS);
			a[n] = (a[n] & SYM_MSK) | (e << SYM_BITS);
			a[e] = (a[e] & SYM_MSK) | freqShift;
		} while (symCnt - ++e > 1);
	}

	static function genLenCnt(a:Vector<Int>, root:Int, lenCnt:Vector<Int>, maxCodeLen:Int):Void {
		for (i in 0...maxCodeLen + 1)
			lenCnt[i] = 0;
		lenCnt[1] = 2;
		a[root] &= SYM_MSK;
		var n = root - 1;
		while (n >= 0) {
			var p = a[n] >>> SYM_BITS;
			var pdepth = a[p] >>> SYM_BITS;
			var depth = pdepth + 1;
			var len = depth;
			a[n] = (a[n] & SYM_MSK) | (depth << SYM_BITS);
			if (len >= maxCodeLen) {
				len = maxCodeLen;
				do
					len-- while (lenCnt[len] == 0);
			}
			lenCnt[len]--;
			lenCnt[len + 1] += 2;
			n--;
		}
	}

	static function genCodes(a:Vector<Int>, lens:Vector<Int>, lenCnt:Vector<Int>, maxCodeWordLen:Int, symCnt:Int):Void {
		var nxt = new Vector<Int>(16, 0);
		var i = 0;
		var len = maxCodeWordLen;
		while (len >= 1) {
			var cnt = lenCnt[len];
			while (cnt-- > 0)
				lens[a[i++] & SYM_MSK] = len;
			len--;
		}
		for (len in 2...maxCodeWordLen + 1)
			nxt[len] = (nxt[len - 1] + lenCnt[len - 1]) << 1;
		for (sym in 0...symCnt)
			a[sym] = nxt[lens[sym]]++;
	}

	static function rev(c:Int, n:Int):Int {
		c = ((c & 0x5555) << 1) | ((c & 0xAAAA) >> 1);
		c = ((c & 0x3333) << 2) | ((c & 0xCCCC) >> 2);
		c = ((c & 0x0F0F) << 4) | ((c & 0xF0F0) >> 4);
		c = ((c & 0x00FF) << 8) | ((c & 0xFF00) >> 8);
		return c >> (16 - n);
	}

	static function huff(lens:Vector<Int>, codes:Vector<Int>, freqs:Vector<Int>, numSyms:Int, maxCodeLen:Int):Void {
		var a = codes;
		var lenCnt = new Vector<Int>(16, 0);
		var usedSyms = sortSym(numSyms, freqs, lens, a);
		if (usedSyms == 0)
			return;
		if (usedSyms == 1) {
			var s = a[0] & SYM_MSK;
			var i = s != 0 ? s : 1;
			codes[0] = 0;
			lens[0] = 1;
			codes[i] = 1;
			lens[i] = 1;
			return;
		}
		buildTree(a, usedSyms);
		genLenCnt(a, usedSyms - 2, lenCnt, maxCodeLen);
		genCodes(a, lens, lenCnt, maxCodeLen, numSyms);
		for (c in 0...numSyms)
			codes[c] = rev(codes[c], lens[c]);
	}

	function precode(freqs:Vector<Int>, items:Vector<Int>):Void {
		var at = 0;
		var runStart = 0;
		symLit = SYM_MAX;
		while (symLit > 257) {
			if (lenLit[symLit - 1] != 0)
				break;
			symLit--;
		}
		symOff = OFF_MAX;
		while (symOff > 1) {
			if (lenOff[symOff - 1] != 0)
				break;
			symOff--;
		}
		var total = symLit + symOff;
		var lens = new Vector<Int>(SYM_MAX + OFF_MAX, 0);
		for (i in 0...symLit)
			lens[i] = lenLit[i];
		for (i in 0...symOff)
			lens[symLit + i] = lenOff[i];
		do {
			var len = lens[runStart];
			var runEnd = runStart;
			do
				runEnd++ while (runEnd != total && len == lens[runEnd]);
			if (len == 0) {
				while (runEnd - runStart >= 11) {
					var n = (runEnd - runStart) - 11;
					var xbits = n < 0x7f ? n : 0x7f;
					freqs[18]++;
					items[at++] = 18 | (xbits << 5);
					runStart += 11 + xbits;
				}
				if (runEnd - runStart >= 3) {
					var n = (runEnd - runStart) - 3;
					var xbits = n < 0x7 ? n : 0x7;
					freqs[17]++;
					items[at++] = 17 | (xbits << 5);
					runStart += 3 + xbits;
				}
			} else if (runEnd - runStart >= 4) {
				freqs[len]++;
				items[at++] = len;
				runStart++;
				do {
					var xbits = (runEnd - runStart) - 3;
					xbits = xbits < 0x03 ? xbits : 0x03;
					items[at++] = 16 | (xbits << 5);
					runStart += 3 + xbits;
					freqs[16]++;
				} while (runEnd - runStart >= 3);
			}
			while (runStart != runEnd) {
				freqs[len]++;
				items[at++] = len;
				runStart++;
			}
		} while (runStart != total);
		symItems = at;
	}

	function matchCodes(dist:Int, len:Int):Void {
		codeLs = LSLOT[len];
		codeLc = 257 + codeLs;
		codeDx = ilog2(npow2(dist) >> 2);
		codeDc = codeDx != 0 ? ((codeDx + 1) << 1) + (dist > DXMAX[codeDx] ? 1 : 0) : dist - 1;
	}

	// Whether a dynamic Huffman block costs fewer bits than raw blocks would, sdefl_blk_type.
	function isDynamicCheaper(blkLen:Int, preItemLen:Int, preFreq:Vector<Int>, preLen:Vector<Int>):Bool {
		var dynCost = 0;
		dynCost += 5 + 5 + 4 + (3 * preItemLen);
		for (sym in 0...PRE_MAX)
			dynCost += preFreq[sym] * (X_PRE_BITS[sym] + preLen[sym]);
		for (sym in 0...256)
			dynCost += freqLit[sym] * lenLit[sym];
		dynCost += lenLit[EOB];
		for (sym in 257...286)
			dynCost += freqLit[sym] * (X_LEN_BITS[sym - 257] + lenLit[sym]);
		for (sym in 0...30)
			dynCost += freqOff[sym] * (X_OFF_BITS[sym] + lenOff[sym]);
		var fixCost = 8 * (5 * divRoundUp(blkLen, RAW_BLK_SIZE) + blkLen + 1 + 2);
		return dynCost < fixCost;
	}

	function match(dist:Int, len:Int):Void {
		matchCodes(dist, len);
		put(wordLit[codeLc], lenLit[codeLc]);
		put(len - LMIN[codeLs], LXN[codeLs]);
		put(wordOff[codeDc], lenOff[codeDc]);
		put(dist - DMIN[codeDc], codeDx);
	}

	function flush(isLast:Bool, blkBegin:Int, blkEnd:Int):Void {
		var blkLen = blkEnd - blkBegin;
		var codes = new Vector<Int>(PRE_MAX, 0);
		var lens = new Vector<Int>(PRE_MAX, 0);
		var freqs = new Vector<Int>(PRE_MAX, 0);
		var items = new Vector<Int>(SYM_MAX + OFF_MAX, 0);

		// The Huffman codes.
		freqLit[EOB]++;
		huff(lenLit, wordLit, freqLit, SYM_MAX, LIT_LEN_CODES);
		huff(lenOff, wordOff, freqOff, OFF_MAX, OFF_CODES);
		precode(freqs, items);
		huff(lens, codes, freqs, PRE_MAX, PRE_CODES);
		var itemCnt = PRE_MAX;
		while (itemCnt > 4) {
			if (lens[PERM[itemCnt - 1]] != 0)
				break;
			itemCnt--;
		}
		// The block.
		if (!isDynamicCheaper(blkLen, itemCnt, freqs, lens)) {
			// Raw blocks.
			var n = divRoundUp(blkLen, RAW_BLK_SIZE);
			for (i in 0...n) {
				var fin = isLast && (i + 1 == n);
				var amount = blkLen < RAW_BLK_SIZE ? blkLen : RAW_BLK_SIZE;
				put(fin ? 1 : 0, 1);
				put(0x00, 2);
				if (bitcnt != 0)
					put(0x00, 8 - bitcnt);
				put16(amount);
				put16(~amount & 0xFFFF);
				out.blit(q, input, blkBegin + i * RAW_BLK_SIZE, amount);
				q += amount;
				blkLen -= amount;
			}
		} else {
			// A dynamic Huffman block.
			put(isLast ? 1 : 0, 1);
			put(0x02, 2);
			put(symLit - 257, 5);
			put(symOff - 1, 5);
			put(itemCnt - 4, 4);
			for (i in 0...itemCnt)
				put(lens[PERM[i]], 3);
			for (i in 0...symItems) {
				var sym = items[i] & 0x1F;
				put(codes[sym], lens[sym]);
				if (sym < 16)
					continue;
				if (sym == 16)
					put(items[i] >> 5, 2);
				else if (sym == 17)
					put(items[i] >> 5, 3);
				else
					put(items[i] >> 5, 7);
			}
			// The block's sequences.
			for (i in 0...seqCnt) {
				if (seqOff[i] >= 0) {
					var off = seqOff[i];
					for (j in 0...seqLen[i]) {
						var c = input.get(off + j);
						put(wordLit[c], lenLit[c]);
					}
				} else
					match(-seqOff[i], seqLen[i]);
			}
			put(wordLit[EOB], lenLit[EOB]);
		}
		for (i in 0...SYM_MAX)
			freqLit[i] = 0;
		for (i in 0...OFF_MAX)
			freqOff[i] = 0;
		seqCnt = 0;
	}

	inline function seq(off:Int, len:Int):Void {
		seqOff[seqCnt] = off;
		seqLen[seqCnt] = len;
		seqCnt++;
	}

	function regMatch(off:Int, len:Int):Void {
		matchCodes(off, len);
		freqLit[codeLc]++;
		freqOff[codeDc]++;
	}

	// sdefl_fnd: the longest match for p, starting from matchLen and matchOff.
	function fnd(chainLen:Int, maxMatch:Int, p:Int):Void {
		var i = tbl[hash32(p)];
		var limit = ((p - WIN_SIZ) < NIL) ? NIL : (p - WIN_SIZ);
		while (i > limit) {
			if (input.get(i + matchLen) == input.get(p + matchLen) && uload32(i) == uload32(p)) {
				var n = MIN_MATCH;
				while (n < maxMatch && input.get(i + n) == input.get(p + n))
					n++;
				if (n > matchLen) {
					matchLen = n;
					matchOff = p - i;
					if (n == maxMatch)
						break;
				}
			}
			if (--chainLen == 0)
				break;
			i = prv[i & WIN_MSK];
		}
	}

	function compr():Void {
		var maxChain = (lvl < 8) ? (1 << (lvl + 1)) : (1 << 13);
		var i = 0, litlen = 0;
		do {
			var blkBegin = i;
			var blkEnd = ((i + BLK_MAX) < inLen) ? (i + BLK_MAX) : inLen;
			while (i < blkEnd) {
				var left = blkEnd - i;
				var maxMatch = (left > MAX_MATCH) ? MAX_MATCH : left;
				var niceMatch = PREF[lvl] < maxMatch ? PREF[lvl] : maxMatch;
				var run = 1, inc = 1, runInc = 0;
				matchOff = 0;
				matchLen = 0;
				if (maxMatch > MIN_MATCH)
					fnd(maxChain, maxMatch, i);
				if (lvl >= 5 && matchLen >= MIN_MATCH && matchLen + 1 < niceMatch) {
					var off = matchOff, len = matchLen;
					matchOff = 0;
					matchLen = 0;
					fnd(maxChain, len + 1, i + 1);
					len = (matchLen > len) ? 0 : len;
					matchOff = off;
					matchLen = len;
				}
				if (matchLen >= MIN_MATCH) {
					if (litlen != 0) {
						seq(i - litlen, litlen);
						litlen = 0;
					}
					seq(-matchOff, matchLen);
					regMatch(matchOff, matchLen);
					if (lvl < 2 && matchLen >= niceMatch)
						inc = matchLen;
					else
						run = matchLen;
				} else {
					freqLit[input.get(i)]++;
					litlen++;
				}
				runInc = run * inc;
				if (inLen - (i + runInc) > MIN_MATCH) {
					while (run-- > 0) {
						var h = hash32(i);
						prv[i & WIN_MSK] = tbl[h];
						tbl[h] = i;
						i += inc;
					}
				} else
					i += runInc;
			}
			if (litlen != 0) {
				seq(i - litlen, litlen);
				litlen = 0;
			}
			flush(blkEnd == inLen, blkBegin, blkEnd);
		} while (i < inLen);
		if (bitcnt != 0)
			put(0x00, 8 - bitcnt);
	}
}
