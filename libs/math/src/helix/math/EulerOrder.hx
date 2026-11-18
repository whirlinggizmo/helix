package helix.math;

/** Specifies the order three turns around x, y and z are made in. Each order is named as raylib, three.js and glm name it: by the
	product of the three rotation matrices, so the last letter's turn is made first. Every turn is around the world's axes. */
enum abstract EulerOrder(Int) {
	/** Around x first, then y, then z. */
	var ZYX = 0;

	/** Around z first, then y, then x. */
	var XYZ = 1;

	/** Around z first, then x, then y. */
	var YXZ = 2;

	/** Around y first, then x, then z. */
	var ZXY = 3;

	/** Around x first, then z, then y. */
	var YZX = 4;

	/** Around y first, then z, then x. */
	var XZY = 5;
}
