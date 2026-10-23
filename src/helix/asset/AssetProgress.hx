package helix.asset;

/** Load progress: phase ("locating", "downloading", "storing" or "ready"), bytes received, and total bytes, or null when unknown. */
typedef AssetProgress = {final phase:String; final receivedBytes:Int; final totalBytes:Null<Int>;}
