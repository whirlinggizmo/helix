package helix.asset;

/** How a fetch ended: a response of any HTTP status, a transport failure message, or cancellation. */
enum FetchResult {
	Response(value:FetchResponse);
	Failed(message:String);
	Cancelled;
}
