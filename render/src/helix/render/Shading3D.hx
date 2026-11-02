package helix.render;

/** Specifies how a `Material3D` is shaded by the batch's lights. */
enum abstract Shading3D(Int) {
	/** Not lit: its colors as they are, three.js's MeshBasicMaterial and raylib's default. */
	var Unlit = 0;

	/** Diffuse light alone, by the angle to each light: three.js's MeshLambertMaterial. */
	var Lambert = 1;

	/** Diffuse light and a Blinn-Phong highlight of `specularColor` and `shininess`: three.js's MeshPhongMaterial, and what an OBJ
		material's Ks and Ns describe. */
	var Phong = 2;

	/** glTF's metallic-roughness model, with its clearcoat, sheen and specular extensions where set: three.js's MeshStandardMaterial and
		MeshPhysicalMaterial. */
	var MetallicRoughness = 3;
}
