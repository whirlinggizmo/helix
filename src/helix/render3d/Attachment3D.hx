package helix.render3d;

/** Where a rigid piece attaches to a skeleton (Node3D.findAttachment): the piece, and the joint it hangs from, null for none. */
typedef Attachment3D = {
	final piece:Node3D;
	final joint:Null<Node3D>;
}
