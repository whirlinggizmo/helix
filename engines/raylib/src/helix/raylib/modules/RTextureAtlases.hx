package helix.raylib.modules;

#if !macro
import helix.raylib.*;
import helix.raylib.Raylib.*;
import helix.raylib.extras.TextureAtlas;
import helix.raylib.internal.Answers;
import helix.raylib.internal.Runtime;
#end

/** Provides helix-raylib's texture atlases, written here and forwarded by `helix.raylib.extras.Textures` (`tools/gen_raylib.py`). Its
	load is `Textures.LoadTextureAtlasAsync`, a macro choosing the atlas's reader by its file's extension as the program builds. */
@:noCompletion
@:allow(helix.raylib)
class RTextureAtlases {
	#if !macro
	/** Unloads an atlas's texture.

		@param atlas  The atlas. */
	static function UnloadTextureAtlas(atlas:TextureAtlas):Void {
		RTextures.UnloadTexture(atlas.texture);
	}

	/** Returns the rectangle of an image in an atlas, for a draw's source. Refused, with the name logged, for a name the atlas
		lacks.

		@param atlas  The atlas.
		@param name  The image's name, as the atlas's file names it, extension and all: `sword.png`.
		@param out  Optional. The rectangle to fill; a new one when omitted.
		@return  out, or the new rectangle, in pixels of the atlas's texture, or an empty rectangle when refused. */
	static function GetTextureAtlasRectangle(atlas:TextureAtlas, name:String, ?out:Rectangle):Rectangle {
		if (out == null)
			out = new Rectangle(0, 0, 0, 0);
		var at = atlas.indexOf(name);
		if (at < 0) {
			Runtime.log(LOG_WARNING, 'GetTextureAtlasRectangle: The atlas has no image named "$name"');
			out.x = out.y = out.width = out.height = 0;
			return out;
		}
		var r = atlas.rectangles;
		out.x = r[at * 4];
		out.y = r[at * 4 + 1];
		out.width = r[at * 4 + 2];
		out.height = r[at * 4 + 3];
		return out;
	}

	// LoadTextureAtlasAsync's call where the atlas's file name isn't known as the program builds: its reader chosen by its extension as
	// it runs, so both are in the program.
	static function loadAtlas(fileName:String, loaded:TextureAtlas->Void, ?failed:String->Void):Void {
		var extension = haxe.io.Path.extension(fileName).toLowerCase();
		if (extension == "json")
			loadJsonAtlas(fileName, loaded, failed);
		else if (extension == "xml")
			loadXmlAtlas(fileName, loaded, failed);
		else
			Answers.refuse("LoadTextureAtlasAsync", '[$fileName] Not an atlas: TexturePacker\'s JSON (.json) and Starling\'s XML (.xml) are read', failed);
	}

	// LoadTextureAtlasAsync's call for TexturePacker's JSON, its frames a hash or an array.
	static function loadJsonAtlas(fileName:String, loaded:TextureAtlas->Void, ?failed:String->Void):Void {
		read(fileName, parseJson, loaded, failed);
	}

	// An atlas from TexturePacker's JSON, its texture not loaded yet, or null, why in refusal.
	static function parseJson(text:String):Null<TextureAtlas> {
		var json:Dynamic = try haxe.Json.parse(text) catch (_:Dynamic) null;
		if (json == null)
			return refuse('It isn\'t JSON');
		var image:Null<String> = json.meta == null ? null : json.meta.image;
		if (image == null)
			return refuse('It names no texture (meta.image)');
		var frames:Dynamic = json.frames;
		if (frames == null)
			return refuse('It has no frames');
		var named:Array<{name:String, frame:Dynamic}> = [];
		// An array has a length, a hash of frames by name none.
		if ((frames.length : Null<Int>) != null)
			for (f in (frames : Array<Dynamic>))
				named.push({name: f.filename, frame: f});
		else
			for (name in Reflect.fields(frames))
				named.push({name: name, frame: Reflect.field(frames, name)});
		var atlas = new TextureAtlas();
		for (n in named) {
			if (n.frame.rotated == true)
				return refuse('Its image "${n.name}" is packed rotated, which isn\'t read: pack without rotation');
			var r:Dynamic = n.frame.frame;
			if (n.name == null || r == null)
				return refuse('A frame has no name or rectangle');
			atlas.add(n.name, r.x, r.y, r.w, r.h);
		}
		atlas.sheet = image;
		return atlas;
	}

	// LoadTextureAtlasAsync's call for Starling's XML, which Kenney's sheets are in.
	static function loadXmlAtlas(fileName:String, loaded:TextureAtlas->Void, ?failed:String->Void):Void {
		read(fileName, parseXml, loaded, failed);
	}

	// An atlas from Starling's XML, its texture not loaded yet, or null, why in refusal. Read by elements, as Haxe's Xml links run-time
	// type inspection into a page: the TextureAtlas element's imagePath and each SubTexture's attributes.
	static function parseXml(text:String):Null<TextureAtlas> {
		var atlas:Null<TextureAtlas> = null;
		var at = 0;
		while (true) {
			var open = text.indexOf("<", at);
			if (open < 0)
				break;
			if (text.substr(open, 4) == "<!--") {
				var close = text.indexOf("-->", open);
				at = close < 0 ? text.length : close + 3;
				continue;
			}
			var close = text.indexOf(">", open);
			if (close < 0)
				return refuse('It isn\'t XML: an element isn\'t closed');
			var element = text.substring(open + 1, close);
			at = close + 1;
			// A closing tag, the XML declaration or a doctype: no element of the atlas.
			var first = element.charAt(0);
			if (first == "/" || first == "?" || first == "!")
				continue;
			var attributes = attributesOf(element);
			if (attributes == null)
				return refuse('It isn\'t XML: an element\'s attributes don\'t read');
			var name = elementName(element);
			if (name == "TextureAtlas") {
				var image = attributes.get("imagePath");
				if (image == null)
					return refuse('It names no texture (imagePath)');
				atlas = new TextureAtlas();
				atlas.sheet = image;
			} else if (name == "SubTexture") {
				if (atlas == null)
					return refuse('It has no TextureAtlas element');
				var imageName = attributes.get("name");
				if (imageName == null)
					return refuse('A SubTexture has no name');
				if (attributes.get("rotated") == "true")
					return refuse('Its image "$imageName" is packed rotated, which isn\'t read: pack without rotation');
				inline function number(key:String):Float {
					var value = Std.parseFloat(attributes.get(key));
					return Math.isNaN(value) ? 0 : value;
				}
				atlas.add(imageName, number("x"), number("y"), number("width"), number("height"));
			}
		}
		return atlas == null ? refuse('It has no TextureAtlas element') : atlas;
	}

	// An element's name, from the text between its < and >.
	static function elementName(element:String):String {
		var end = 0;
		while (end < element.length && !isSpace(element.charCodeAt(end)) && element.charAt(end) != "/")
			end++;
		return element.substr(0, end);
	}

	// An element's attributes, by name, their entities decoded: null when they don't read as name="value" or name='value'.
	static function attributesOf(element:String):Null<Map<String, String>> {
		var attributes = new Map<String, String>();
		var at = elementName(element).length;
		while (true) {
			while (at < element.length && (isSpace(element.charCodeAt(at)) || element.charAt(at) == "/" || element.charAt(at) == "?"))
				at++;
			if (at >= element.length)
				return attributes;
			var equals = element.indexOf("=", at);
			if (equals < 0)
				return null;
			var name = StringTools.trim(element.substring(at, equals));
			var quoteAt = equals + 1;
			while (quoteAt < element.length && isSpace(element.charCodeAt(quoteAt)))
				quoteAt++;
			var quote = element.charAt(quoteAt);
			if (quote != '"' && quote != "'")
				return null;
			var end = element.indexOf(quote, quoteAt + 1);
			if (end < 0)
				return null;
			attributes.set(name, StringTools.htmlUnescape(element.substring(quoteAt + 1, end)));
			at = end + 1;
		}
	}

	static function isSpace(code:Null<Int>):Bool
		return code == " ".code || code == "\t".code || code == "\n".code || code == "\r".code;

	// Why the last parse refused its file.
	static var refusal:String;

	// Refuses a parse, keeping why: null.
	static function refuse(why:String):Null<TextureAtlas> {
		refusal = why;
		return null;
	}

	// Reads an atlas's file, parses it (null, why in refusal, when refused), and loads the texture it names beside it.
	static function read(fileName:String, parse:String->Null<TextureAtlas>, loaded:TextureAtlas->Void, failed:Null<String->Void>):Void {
		RFilesAsync.LoadFileTextAsync(fileName, text -> {
			var atlas = parse(text);
			if (atlas == null) {
				Answers.refuse("LoadTextureAtlasAsync", '[$fileName] $refusal', failed);
				return;
			}
			var sheet = haxe.io.Path.join([haxe.io.Path.directory(fileName), atlas.sheet]);
			if (haxe.io.Path.extension(sheet).toLowerCase() == "gif") {
				Answers.refuse("LoadTextureAtlasAsync", '[$fileName] Its texture $sheet is a GIF file, which an atlas doesn\'t read: save it as PNG', failed);
				return;
			}
			RTexturesAsync.loadPlainTexture(sheet, texture -> {
				atlas.texture = texture;
				loaded(atlas);
			},
				error -> Answers.refuse("LoadTextureAtlasAsync", '[$fileName] Its texture: $error', failed));
		}, error -> Answers.refuse("LoadTextureAtlasAsync", error, failed));
	}
	#end
}
