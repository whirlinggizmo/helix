import haxe.io.Bytes;
import haxe.io.BytesBuffer;
import helix.formats.audio.AudioHeader;

/** Checks AudioHeader with the library alone, on headers made by hand. Lengths: WAV (integer samples, data sizes of 0 and 0xFFFFFFFF, a fact
	chunk, a byte rate, extensible), Ogg (Vorbis, Opus with its pre-skip, FLAC and Speex; another stream's page, a broken page and an
	unknown position skipped; no last bytes), FLAC (with an ID3v2 tag before it; an unknown length), MP3 (a Xing frame count, MPEG-2's,
	VBRI's, a constant bitrate's estimate with ID3v2 and ID3v1 tags, layer II) and what it can't tell. Each length was checked against
	ffprobe on files ffmpeg made. Channels: each kind's, mono and stereo, and what it can't tell. Rates: each kind's, Opus's 48 kHz,
	MPEG-2's halved, and what it can't tell. */
class AudioHeaderTests {
	static var checks = 0;

	static function check(value:Bool, message:String):Void {
		if (!value)
			throw message;
		checks++;
	}

	static function near(a:Float, b:Float):Bool
		return Math.abs(a - b) < 1e-9;

	static function bytes(build:BytesBuffer->Void):Bytes {
		var b = new BytesBuffer();
		build(b);
		return b.getBytes();
	}

	static function u16(b:BytesBuffer, v:Int):Void {
		b.addByte(v & 0xFF);
		b.addByte((v >> 8) & 0xFF);
	}

	static function be32(b:BytesBuffer, v:Int):Void {
		b.addByte(v >>> 24);
		b.addByte((v >> 16) & 0xFF);
		b.addByte((v >> 8) & 0xFF);
		b.addByte(v & 0xFF);
	}

	// A WAV file's header, up to its data chunk's samples.
	static function wav(tag:Int, channels:Int, rate:Int, bits:Int, dataSize:Int, ?fact:Int, extensible = false):Bytes {
		return bytes(b -> {
			b.addString("RIFFxxxxWAVEfmt ");
			b.addInt32(extensible ? 40 : 16);
			u16(b, extensible ? 0xFFFE : tag);
			u16(b, channels);
			b.addInt32(rate);
			b.addInt32(rate * channels * bits >> 3);
			u16(b, channels * bits >> 3);
			u16(b, bits);
			if (extensible) {
				u16(b, 22);
				u16(b, bits);
				b.addInt32(3);
				u16(b, tag);
				for (_ in 0...14)
					b.addByte(0);
			}
			if (fact != null) {
				b.addString("fact");
				b.addInt32(4);
				b.addInt32(fact);
			}
			b.addString("LIST");
			b.addInt32(3);
			b.addString("abc");
			b.addByte(0);
			b.addString("data");
			b.addInt32(dataSize);
		});
	}

	static var crcTable:Array<Int>;

	// An Ogg page of one packet: its stream, its position (high and low 32 bits) and its CRC.
	static function page(serial:Int, high:Int, low:Int, packet:Bytes):Bytes {
		var segments = [];
		var left = packet.length;
		while (left >= 255) {
			segments.push(255);
			left -= 255;
		}
		segments.push(left);
		var page = bytes(b -> {
			b.addString("OggS");
			b.addByte(0);
			b.addByte(0);
			b.addInt32(low);
			b.addInt32(high);
			b.addInt32(serial);
			b.addInt32(0);
			b.addInt32(0);
			b.addByte(segments.length);
			for (s in segments)
				b.addByte(s);
			b.add(packet);
		});
		if (crcTable == null)
			crcTable = [
				for (i in 0...256) {
					var r = i << 24;
					for (_ in 0...8)
						r = (r & 0x80000000) != 0 ? (r << 1) ^ 0x04C11DB7 : r << 1;
					r;
				}
			];
		var crc = 0;
		for (i in 0...page.length)
			crc = (crc << 8) ^ crcTable[((crc >>> 24) ^ page.get(i)) & 0xFF];
		page.setInt32(22, crc);
		return page;
	}

	static function join(parts:Array<Bytes>):Bytes
		return bytes(b -> for (p in parts)
			b.add(p));

	static function vorbisHead(rate:Int):Bytes
		return bytes(b -> {
			b.addByte(1);
			b.addString("vorbis");
			b.addInt32(0);
			b.addByte(2);
			b.addInt32(rate);
			for (_ in 0...16)
				b.addByte(0);
		});

	// FLAC's STREAMINFO block, the last metadata block, of a rate and a count of frames.
	static function streamInfo(rate:Int, frames:Int):Bytes
		return bytes(b -> {
			b.addByte(0x80);
			b.addByte(0);
			b.addByte(0);
			b.addByte(34);
			for (_ in 0...10)
				b.addByte(0x10);
			b.addByte(rate >> 12);
			b.addByte((rate >> 4) & 0xFF);
			b.addByte(((rate & 0xF) << 4) | (1 << 1));
			b.addByte(0xF0);
			be32(b, frames);
			for (_ in 0...16)
				b.addByte(0);
		});

	// An ID3v2 tag of a body's size.
	static function id3(size:Int):Bytes
		return bytes(b -> {
			b.addString("ID3");
			b.addByte(3);
			b.addByte(0);
			b.addByte(0);
			b.addByte((size >> 21) & 0x7F);
			b.addByte((size >> 14) & 0x7F);
			b.addByte((size >> 7) & 0x7F);
			b.addByte(size & 0x7F);
			for (_ in 0...size)
				b.addByte(0);
		});

	// An MPEG audio frame: its four header bytes, a tag at an offset (or none), the rest zero.
	static function frame(header:Int, length:Int, ?tag:String, offset = 0, count = 0):Bytes {
		var f = Bytes.alloc(length);
		f.set(0, header >>> 24);
		f.set(1, (header >> 16) & 0xFF);
		f.set(2, (header >> 8) & 0xFF);
		f.set(3, header & 0xFF);
		if (tag != null) {
			f.blit(offset, Bytes.ofString(tag), 0, 4);
			if (tag == "VBRI") {
				f.set(offset + 14, count >>> 24);
				f.set(offset + 15, (count >> 16) & 0xFF);
				f.set(offset + 16, (count >> 8) & 0xFF);
				f.set(offset + 17, count & 0xFF);
			} else {
				f.set(offset + 7, 1);
				f.set(offset + 8, count >>> 24);
				f.set(offset + 9, (count >> 16) & 0xFF);
				f.set(offset + 10, (count >> 8) & 0xFF);
				f.set(offset + 11, count & 0xFF);
			}
		}
		return f;
	}

	static function frames(header:Int, length:Int, count:Int):Array<Bytes>
		return [for (_ in 0...count) frame(header, length)];

	static function main():Void {
		// WAV.
		var head = wav(1, 2, 44100, 16, 176400);
		check(near(AudioHeader.readDuration(head, head.length + 176400), 1), "WAV: 16-bit stereo, a second");
		check(near(AudioHeader.readDuration(head, head.length + 1000), 250 / 44100), "WAV: a data size past the end stops at it");
		var streamed = wav(1, 1, 8000, 8, -1);
		check(near(AudioHeader.readDuration(streamed, streamed.length + 4000), 0.5), "WAV: a data size of 0xFFFFFFFF runs to the end");
		var unsized = wav(1, 1, 8000, 8, 0);
		check(near(AudioHeader.readDuration(unsized, unsized.length + 2000), 0.25), "WAV: a data size of 0 runs to the end");
		var adpcm = wav(2, 1, 22050, 4, 11500, 33075);
		check(near(AudioHeader.readDuration(adpcm, adpcm.length + 11500), 1.5), "WAV: MS ADPCM, by its fact chunk");
		var mp3InWav = wav(0x55, 1, 22050, 0, 8000);
		mp3InWav.setInt32(28, 4000);
		check(near(AudioHeader.readDuration(mp3InWav, mp3InWav.length + 8000), 2), "WAV: MP3 in WAV, by its byte rate");
		var extensible = wav(3, 2, 48000, 32, 384000, true);
		check(near(AudioHeader.readDuration(extensible, extensible.length + 384000), 1), "WAV: extensible, floating point");

		// Ogg: Vorbis, then Opus, FLAC and Speex.
		var first = page(7, 0, 0, vorbisHead(44100));
		var middle = page(7, 0, 44100, Bytes.alloc(300));
		var other = page(9, 0, 999999, Bytes.alloc(20));
		var last = page(7, 0, 66150, Bytes.alloc(500));
		var vorbis = join([first, middle, last, other]);
		check(near(AudioHeader.readDuration(vorbis, vorbis.length), 1.5), "Ogg Vorbis: the last page's position, another stream's skipped");
		var tail = vorbis.sub(first.length + 100, vorbis.length - first.length - 100);
		check(near(AudioHeader.readDuration(first, tail, vorbis.length), 1.5), "Ogg Vorbis: from its first and last bytes");
		check(AudioHeader.readDuration(first, vorbis.length) == 0, "Ogg: 0 without its last bytes");
		var broken = last.sub(0, last.length);
		broken.set(broken.length - 1, 1);
		check(near(AudioHeader.readDuration(join([first, middle, broken]), first.length + middle.length + broken.length), 1),
			"Ogg: a page whose CRC is wrong skipped");
		var unknown = page(7, -1, -1, Bytes.alloc(10));
		check(near(AudioHeader.readDuration(join([first, middle, unknown]), first.length + middle.length + unknown.length), 1),
			"Ogg: a page of no position skipped");
		var long = page(7, 1, 0, Bytes.alloc(10));
		check(near(AudioHeader.readDuration(join([first, long]), first.length + long.length), 4294967296 / 44100), "Ogg: a 64-bit position");

		var opusHead = bytes(b -> {
			b.addString("OpusHead");
			b.addByte(1);
			b.addByte(2);
			u16(b, 312);
			b.addInt32(44100);
			u16(b, 0);
			b.addByte(0);
		});
		var opus = join([page(3, 0, 0, opusHead), page(3, 0, 96312, Bytes.alloc(50))]);
		check(near(AudioHeader.readDuration(opus, opus.length), 2), "Ogg Opus: at 48 kHz, less its pre-skip");

		var flacHead = bytes(b -> {
			b.addByte(0x7F);
			b.addString("FLAC");
			b.addByte(1);
			b.addByte(0);
			b.addByte(0);
			b.addByte(1);
			b.addString("fLaC");
			b.add(streamInfo(96000, 0));
		});
		var oggFlac = join([page(5, 0, 0, flacHead), page(5, 0, 240000, Bytes.alloc(50))]);
		check(near(AudioHeader.readDuration(oggFlac, oggFlac.length), 2.5), "Ogg FLAC");

		var speexHead = bytes(b -> {
			b.addString("Speex   ");
			for (_ in 0...28)
				b.addByte(0);
			b.addInt32(16000);
			for (_ in 0...8)
				b.addByte(0);
			b.addInt32(1);
			for (_ in 0...28)
				b.addByte(0);
		});
		var speex = join([page(4, 0, 0, speexHead), page(4, 0, 8000, Bytes.alloc(50))]);
		check(near(AudioHeader.readDuration(speex, speex.length), 0.5), "Ogg Speex");

		// FLAC.
		var flac = join([Bytes.ofString("fLaC"), streamInfo(44100, 88200), Bytes.alloc(100)]);
		check(near(AudioHeader.readDuration(flac, 100000), 2), "FLAC: STREAMINFO's frames over its rate");
		var tagged = join([id3(300), flac]);
		check(near(AudioHeader.readDuration(tagged, 100000), 2), "FLAC: after an ID3v2 tag");
		check(AudioHeader.readDuration(join([Bytes.ofString("fLaC"), streamInfo(44100, 0)]), 100000) == 0, "FLAC: 0 when it doesn't record its frames");

		// MP3: MPEG-1 layer III, 128 kbps at 44.1 kHz, stereo: 417 bytes a frame.
		var header = 0xFFFB9000;
		var xing = join([id3(500), frame(header, 417, "Xing", 36, 1000)].concat(frames(header, 417, 5)));
		check(near(AudioHeader.readDuration(xing, 400000), 1000 * 1152 / 44100), "MP3: Xing's frames");
		var info = join([frame(0xFFFB90C0, 417, "Info", 21, 300)].concat(frames(0xFFFB90C0, 417, 3)));
		check(near(AudioHeader.readDuration(info, 125100), 300 * 1152 / 44100), "MP3: a mono Info frame's frames");
		// MPEG-2 layer III, 32 kbps at 22.05 kHz: 104 bytes a frame, 576 samples.
		var mpeg2 = join([frame(0xFFF34000, 104, "Xing", 21, 400)].concat(frames(0xFFF34000, 104, 3)));
		check(near(AudioHeader.readDuration(mpeg2, 41600), 400 * 576 / 22050), "MP3: MPEG-2's Xing frames");
		var vbri = join([frame(header, 417, "VBRI", 36, 500)].concat(frames(header, 417, 3)));
		check(near(AudioHeader.readDuration(vbri, 200000), 500 * 1152 / 44100), "MP3: VBRI's frames");
		var cbr = join([id3(1000)].concat(frames(header, 417, 20)));
		var size = 1010 + 417 * 300 + 128;
		var id3v1 = Bytes.alloc(128);
		id3v1.blit(0, Bytes.ofString("TAG"), 0, 3);
		check(near(AudioHeader.readDuration(cbr, id3v1, size), 417 * 300 * 8 / 128000), "MP3: a constant bitrate's estimate, less its tags");
		check(near(AudioHeader.readDuration(cbr, size), (417 * 300 + 128) * 8 / 128000), "MP3: an ID3v1 tag counted when the end is omitted");
		var junk = join([id3(10), Bytes.ofString("junk")].concat(frames(header, 417, 3)));
		check(near(AudioHeader.readDuration(junk, 20 + 4 + 417 * 3), 417 * 3 * 8 / 128000), "MP3: bytes between the tag and the first frame skipped");
		// MPEG-1 layer II, 192 kbps at 44.1 kHz: 626 bytes a frame.
		var layer2 = join(frames(0xFFFDA000, 626, 4));
		check(near(AudioHeader.readDuration(layer2, 626 * 100), 626 * 100 * 8 / 192000), "MP2: a constant bitrate's estimate");

		// Channels.
		check(AudioHeader.readChannelCount(head) == 2, "channels: WAV stereo");
		check(AudioHeader.readChannelCount(streamed) == 1, "channels: WAV mono");
		check(AudioHeader.readChannelCount(extensible) == 2, "channels: WAV extensible");
		check(AudioHeader.readChannelCount(first) == 2, "channels: Ogg Vorbis");
		check(AudioHeader.readChannelCount(opus) == 2, "channels: Ogg Opus");
		check(AudioHeader.readChannelCount(oggFlac) == 2, "channels: Ogg FLAC");
		check(AudioHeader.readChannelCount(speex) == 1, "channels: Ogg Speex");
		check(AudioHeader.readChannelCount(tagged) == 2, "channels: FLAC after an ID3v2 tag");
		check(AudioHeader.readChannelCount(xing) == 2, "channels: MP3 stereo after an ID3v2 tag");
		check(AudioHeader.readChannelCount(info) == 1, "channels: MP3 mono");
		check(AudioHeader.readChannelCount(layer2) == 2, "channels: MP2");
		check(AudioHeader.readChannelCount(Bytes.ofString("not a sound file")) == 0, "channels: an unknown kind is 0");
		check(AudioHeader.readChannelCount(Bytes.alloc(0)) == 0, "channels: no bytes is 0");
		check(AudioHeader.readChannelCount(Bytes.ofString("RIFF\x00\x00\x00\x00WAVE")) == 0, "channels: a WAV file cut before its fmt chunk is 0");

		check(AudioHeader.readSampleRate(head) == 44100, "rate: WAV");
		check(AudioHeader.readSampleRate(streamed) == 8000, "rate: WAV at 8 kHz");
		check(AudioHeader.readSampleRate(extensible) == 48000, "rate: WAV extensible");
		check(AudioHeader.readSampleRate(first) == 44100, "rate: Ogg Vorbis");
		check(AudioHeader.readSampleRate(opus) == 48000, "rate: Ogg Opus decodes at 48 kHz");
		check(AudioHeader.readSampleRate(oggFlac) == 96000, "rate: Ogg FLAC");
		check(AudioHeader.readSampleRate(speex) == 16000, "rate: Ogg Speex");
		check(AudioHeader.readSampleRate(flac) == 44100, "rate: FLAC");
		check(AudioHeader.readSampleRate(tagged) == 44100, "rate: FLAC after an ID3v2 tag");
		check(AudioHeader.readSampleRate(xing) == 44100, "rate: MP3 after an ID3v2 tag");
		check(AudioHeader.readSampleRate(mpeg2) == 22050, "rate: MPEG-2 halves MPEG-1's");
		check(AudioHeader.readSampleRate(layer2) == 44100, "rate: MP2");
		check(AudioHeader.readSampleRate(Bytes.ofString("not a sound file")) == 0, "rate: an unknown kind is 0");
		check(AudioHeader.readSampleRate(Bytes.alloc(0)) == 0, "rate: no bytes is 0");
		check(AudioHeader.readSampleRate(Bytes.ofString("RIFF\x00\x00\x00\x00WAVE")) == 0, "rate: a WAV file cut before its fmt chunk is 0");

		// What it can't tell.
		check(AudioHeader.readDuration(Bytes.ofString("not a sound file"), 16) == 0, "an unknown kind is 0");
		check(AudioHeader.readDuration(Bytes.alloc(0), 0) == 0, "no bytes is 0");
		check(AudioHeader.readDuration(Bytes.ofString("RIFF\x00\x00\x00\x00WAVEfmt "), 1000) == 0, "a WAV file cut before its data chunk is 0");
		var adts = Bytes.alloc(64);
		adts.set(0, 0xFF);
		adts.set(1, 0xF1);
		check(AudioHeader.readDuration(adts, 64) == 0, "AAC's ADTS frames are 0");
		var report = haxe.Json.stringify({passed: true, checks: checks});
		#if js
		js.Syntax.code("console.log({0})", report);
		#else
		Sys.println(report);
		#end
	}
}
