package helix.box2d;

/** Version numbering scheme. */
class B2Version {
	/** Significant changes. */
	public var major:Int;

	/** Incremental changes. */
	public var minor:Int;

	/** Bug fixes. */
	public var revision:Int;

	/** Creates one, as C's initializer lists its fields.

		@param major  Optional. Significant changes.
		@param minor  Optional. Incremental changes.
		@param revision  Optional. Bug fixes. */
	public function new(major = 0, minor = 0, revision = 0) {
		helix.box2d.internal.Init.initB2Version(this);
		this.major = major;
		this.minor = minor;
		this.revision = revision;
	}
}
