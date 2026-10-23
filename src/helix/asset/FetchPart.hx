package helix.asset;

import haxe.io.Bytes;

/** A part of a response's body as it arrives: the response's HTTP status and headers (lower-case names), the total from Content-Length or null
	when unknown (or the body is compressed), and the part's bytes. */
typedef FetchPart = {final status:Int; final headers:Map<String, String>; final totalBytes:Null<Int>; final bytes:Bytes;}
