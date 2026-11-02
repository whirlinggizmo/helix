package helix.render;

/** Specifies how fog thickens with distance from the camera. */
enum abstract FogMode3D(Int) {
	/** From none at `Fog3D.near` to all fog at `Fog3D.far`: three.js's Fog. */
	var Linear = 0;

	/** 1 - e^-(density × distance)²: three.js's FogExp2. */
	var Exponential = 1;
}
