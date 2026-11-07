package helix.raylib.modules;

#if !macro
import helix.raylib.*;
import helix.raylib.Raylib.*;
import helix.raylib.modules.RCore.*;
import helix.raylib.modules.RShapes.*;
import helix.raylib.modules.RTextures.*;
import helix.raylib.modules.RText.*;
import helix.raylib.Raygui.*;
import helix.raylib.internal.Answers.*;
import helix.raylib.modules.RGui.*;
#end

/** Provides the async versions of raygui's style and icon loads. They take the place of raygui's calls that wait for a file.

	`helix.raylib.extras.Gui` forwards to each (`tools/gen_raylib.py`). */
@:noCompletion
@:allow(helix.raylib)
class RGuiAsync {
	#if !macro
	/** Asynchronously loads a style file (.rgs) over the current style, in place of raygui's `GuiLoadStyle`.

		The default style is loaded first if it isn't yet.

		A text file's first line starts with '#'. It reads:
		- each `p <control> <property> 0x<value>` line, which sets that property.
		- the `f <size> <charmap> <font>` line, which loads the font at its size with the charmap file's characters. Both files are
		  beside the style file.

		A font that can't be loaded leaves raylib's default font at size 10.

		A text file's last line is read only when a line break ends it, as in raygui.

		A binary file sets its properties, and its font when it holds one.

		@param fileName  The style file.
		@param done  Optional. Called once the style is loaded, at a later poll.
		@param failed  Optional. Receives why it couldn't be read; when omitted, it is logged. */
	static function GuiLoadStyleAsync(fileName:String, ?done:Void->Void, ?failed:String->Void):Void {
		RFilesAsync.LoadFileDataAsync(fileName, data -> {
			if (!guiStyleLoaded)
				GuiLoadStyleDefault();
			if (data.length == 0 || data.get(0) != "#".code) {
				loadStyleFromMemory(data);
				if (done != null)
					done();
				return;
			}
			var text = data.toString(), lines = text.split("\n");
			// raygui reads a line, then stops at the file's end before reading the line it last read, so a last line with no break after
			// it is never read.
			lines.pop();
			var directory = GetDirectoryPath(fileName);
			function from(i:Int):Void {
				while (i < lines.length) {
					var line = lines[i++];
					if (StringTools.startsWith(line, "p ")) {
						var words = line.split(" ").filter(w -> w != "");
						if (words.length >= 4 && StringTools.startsWith(words[3], "0x"))
							GuiSetStyle(Std.parseInt(words[1]), Std.parseInt(words[2]), hex(words[3].substr(2)));
					} else if (StringTools.startsWith(line, "f ")) {
						var words = line.split(" ").filter(w -> w != "");
						var fontSize = words.length > 1 ? Std.parseInt(words[1]) : 0;
						var charmap = words.length > 2 ? words[2] : "";
						var fontFile = words.length > 3 ? StringTools.rtrim(words.slice(3).join(" ")) : "";
						loadStyleFont(directory, fontSize, charmap, fontFile, () -> from(i));
						return;
					}
				}
				if (done != null)
					done();
			} from(0);
		}, error -> refuse("GuiLoadStyleAsync", error, failed));
	}

	/** Asynchronously loads an icon file (.rgi) over raygui's icons, in place of raygui's `GuiLoadIcons`.

		The file's icons replace raygui's from the first, as raygui reads them.

		A file that isn't an icon file changes nothing.

		@param fileName  The icon file.
		@param loadIconsName  Whether the icons' names are read.
		@param loaded  Receives the icons' names, in order, or null when they weren't read or the file isn't an icon file.
		@param failed  Optional. Receives why it couldn't be read; when omitted, it is logged. */
	static function GuiLoadIconsAsync(fileName:String, loadIconsName:Bool, loaded:Array<String>->Void, ?failed:String->Void):Void {
		RFilesAsync.LoadFileDataAsync(fileName, data -> {
			if (data.length < 12 || data.getString(0, 4) != "rGI ") {
				loaded(null);
				return;
			}
			var iconCount = data.getUInt16(8), iconSize = data.getUInt16(10), p = 12;
			var names:Null<Array<String>> = null;
			if (loadIconsName)
				names = [
					for (i in 0...iconCount) {
						var start = p + i * ICON_MAX_NAME_LENGTH, end = start;
						while (end < start + ICON_MAX_NAME_LENGTH && end < data.length && data.get(end) != 0)
							end++;
						data.getString(start, end - start);
					}
				];
			p += iconCount * ICON_MAX_NAME_LENGTH;
			var bits = icons(),
				words = Std.int(iconCount * (iconSize * iconSize / 32));
			for (i in 0...words)
				if (p + i * 4 + 4 <= data.length)
					bits[i] = data.getInt32(p + i * 4);
			loaded(names);
		}, error -> refuse("GuiLoadIconsAsync", error, failed));
	}

	// A hexadecimal number as sscanf's %x reads it, its leading digits, as 32 bits.
	static function hex(digits:String):Int {
		var value = 0;
		for (i in 0...digits.length) {
			var c = digits.charCodeAt(i),
				d = c >= "0".code
					&& c <= "9".code ? c - "0".code : c >= "a".code
						&& c <= "f".code ? c - "a".code + 10 : c >= "A".code && c <= "F".code ? c - "A".code + 10 : -1;
			if (d < 0)
				break;
			value = (value << 4) | d;
		}
		return value;
	}

	// A style file's font line, as raygui reads it: its charmap's characters, then the font at its size, set as the gui's font, or
	// raylib's default font at size 10 when it can't be loaded; then next.
	static function loadStyleFont(directory:String, fontSize:Int, charmap:String, fontFile:String, next:Void->Void):Void {
		function withCodepoints(codepoints:Null<Array<Int>>):Void {
			function use(font:Null<Font>):Void {
				if (font == null || font.texture == null || font.texture.id == 0) {
					font = GetFontDefault();
					GuiSetStyle(DEFAULT, TEXT_SIZE, 10);
					GuiSetStyle(DEFAULT, TEXT_SPACING, 1);
				}
				if (font.texture.id > 0 && font.glyphCount > 0)
					GuiSetFont(font);
				next();
			}
			if (fontFile == "") {
				use(null);
				return;
			}
			var count = codepoints == null ? 0 : codepoints.length;
			RTextAsync.LoadFontExAsync('$directory/$fontFile', fontSize, count > 0 ? codepoints : null, count, use, _ -> use(null));
		}
		if (charmap != "" && !StringTools.startsWith(charmap, "0"))
			RFilesAsync.LoadFileTextAsync('$directory/$charmap', text -> withCodepoints(LoadCodepoints(text, [0])), _ -> withCodepoints(null));
		else
			withCodepoints(null);
	}
	#end
}
