package helix.asset;

import haxe.io.Bytes;

/** A complete response: HTTP status, headers with lower-case names, and the whole body. */
typedef FetchResponse = {final status:Int; final headers:Map<String, String>; final bytes:Bytes;}
