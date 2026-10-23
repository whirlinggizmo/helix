package helix.asset;

/** Body bytes received so far, and the total from Content-Length, or null when unknown (or the body is compressed). */
typedef FetchProgress = {final receivedBytes:Int; final totalBytes:Null<Int>;}
