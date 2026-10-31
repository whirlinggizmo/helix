import helix.formats.bmfont.BmFontFile;

/** Checks BmFontFile with the library alone, on a small .fnt made here: info and common, two pages resolved against the file's
	directory (a quoted name with a space), its glyphs and kerning, unknown tags and keys skipped, Windows line ends, and what throws. */
class BmFontTests {
	static var checks = 0;

	static function check(value:Bool, message:String):Void {
		if (!value)
			throw message;
		checks++;
	}

	// The String a call throws, or null when it doesn't.
	static function thrown(call:Void->Void):Null<String> {
		try
			call()
		catch (e:String)
			return e;
		return null;
	}

	static function main():Void {
		var text = [
			'info face="Open Sans" size=-32 bold=0 italic=0 charset="" unicode=1 stretchH=100 smooth=1 aa=1 padding=0,0,0,0 spacing=1,1',
			'common lineHeight=36 base=29 scaleW=256 scaleH=128 pages=2 packed=0',
			'page id=0 file="title 0.png"',
			'page id=1 file=title_1.png',
			'chars count=2',
			'char id=65   x=10   y=20   width=18   height=22   xoffset=-1   yoffset=7    xadvance=17   page=0  chnl=15',
			'char id=8364 x=0 y=0 width=16 height=21 xoffset=1 yoffset=8 xadvance=18 page=1 chnl=4',
			'kernings count=1',
			'kerning first=65 second=86 amount=-2',
			'future thing=1',
			''
		].join("\r\n");
		var font = BmFontFile.read(text, "assets/fonts/title.fnt");
		check(font.face == "Open Sans" && font.size == -32, "info: a quoted face with a space, a negative size");
		check(font.lineHeight == 36 && font.base == 29 && font.scaleWidth == 256 && font.scaleHeight == 128, "common: line height, base, page size");
		check(font.pages.length == 2 && font.pages[0].id == 0 && font.pages[0].path == "assets/fonts/title 0.png",
			"page: a quoted file resolved against the .fnt's directory");
		check(font.pages[1].id == 1 && font.pages[1].path == "assets/fonts/title_1.png", "page: an unquoted file");
		check(font.chars.length == 2, "chars: each char line");
		var a = font.chars[0];
		check(a.id == 65 && a.x == 10 && a.y == 20 && a.width == 18 && a.height == 22, "char: its rectangle, over runs of spaces");
		check(a.xOffset == -1 && a.yOffset == 7 && a.xAdvance == 17 && a.page == 0 && a.channel == 15, "char: placement, page and channel");
		var euro = font.chars[1];
		check(euro.id == 8364 && euro.page == 1 && euro.channel == 4 && euro.xAdvance == 18, "char: a codepoint past ASCII, another page");
		check(font.kernings.length == 1 && font.kernings[0].first == 65 && font.kernings[0].second == 86 && font.kernings[0].amount == -2, "kerning: a pair");
		var bare = BmFontFile.read("common lineHeight=10\nchar id=32\n", "plain.fnt");
		check(bare.face == "" && bare.size == 0 && bare.base == 0 && bare.pages.length == 0 && bare.kernings.length == 0,
			"what a file omits reads as empty or 0");
		check(bare.chars[0].id == 32 && bare.chars[0].xAdvance == 0, "a key a line omits reads as 0");
		check(BmFontFile.read("common lineHeight=1\npage id=0 file=\"a.png\"", "a.fnt").pages[0].path == "a.png",
			"a .fnt with no directory leaves its pages' paths as given");
		check(thrown(() -> BmFontFile.read("info face=x\n", "x.fnt")) != null, "no common line throws");
		check(thrown(() -> BmFontFile.read("BMF\x03", "x.fnt")) != null, "the binary format throws");
		check(thrown(() -> BmFontFile.read('<?xml version="1.0"?><font></font>', "x.fnt")) != null, "the XML format throws");
		check(thrown(() -> BmFontFile.read("common lineHeight=tall\n", "x.fnt")) != null, "a number that isn't one throws");
		var report = haxe.Json.stringify({passed: true, checks: checks});
		#if js
		js.Syntax.code("console.log({0})", report);
		#else
		Sys.println(report);
		#end
	}
}
