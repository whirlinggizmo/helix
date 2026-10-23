package helix.asset;

import helix.asset.StorageService.Lease;

/** How leasing a stored file ended: the lease, Missing, a failure message, or cancellation. */
enum StorageSourceResult {
	Local(value:Lease);
	Missing;
	Failed(message:String);
	Cancelled;
}
