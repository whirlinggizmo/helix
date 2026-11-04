// helix-render's material include, fragment stage (Material3D lists its names): a material's colors, values and textures, the mesh
// vertex stage's outputs, readMaterialSurface, shadeMaterial and writeMaterialColor, as the built-in materials shade. Includes
// lighting.glsl, with color.glsl and view.glsl.
#ifndef HELIX_RENDER_MATERIAL_GLSL
#define HELIX_RENDER_MATERIAL_GLSL
#include <helix/render/shaders/lighting.glsl>

in vec3 worldPosition;
in vec3 normal;
in vec4 tangent;
in vec2 texCoord;
in vec2 texCoord2;
in vec4 color;

uniform vec4 baseColor;
uniform vec4 emissiveColor;
uniform vec4 specularColor;
uniform vec4 sheenColor;
uniform float metallic;
uniform float roughness;
uniform float normalScale;
uniform float alphaCutoff;
uniform float occlusionIntensity;
uniform float lightIntensity;
uniform float environmentIntensity;
uniform float specularIntensity;
uniform float shininess;
uniform float ior;
uniform float clearcoat;
uniform float clearcoatRoughness;
uniform float sheenRoughness;
uniform mat3 textureTransform;
uniform int shading;
uniform int fog;
uniform int flatShading;
uniform int vertexColors;
uniform int colorSpaceSrgb;
uniform sampler2D baseColorTexture;
uniform sampler2D alphaTexture;
uniform sampler2D metallicRoughnessTexture;
uniform sampler2D normalTexture;
uniform sampler2D occlusionTexture;
uniform sampler2D lightTexture;
uniform sampler2D emissiveTexture;
// Whether the base color texture is decoded from sRGB (its Texture2D.colorSpace, Auto as a color slot).
uniform int baseColorTextureSrgb;
// What the other maps need, a bit each: 1 the normal map read (a map, and a mesh with tangents); decoded from sRGB, 2 the emissive
// texture, 4 the metallic-roughness texture, 8 the normal map, 16 the occlusion map, 32 the light map; 64 a light map read.
uniform int textureFlags;

// A map's texel, decoded from sRGB where its flag in textureFlags is set.
vec4 helixReadMap(sampler2D map, vec2 uv, int flag) {
	vec4 texel = texture(map, uv);
	return (textureFlags & flag) != 0 ? decodeSrgb(texel) : texel;
}

Surface readMaterialSurface(vec2 uv) {
	vec4 texel = texture(baseColorTexture, uv);
	vec4 c;
	if (colorSpaceSrgb != 0) {
		c = baseColor * texel * color;
		c.rgb = decodeSrgb(c.rgb);
	} else
		c = decodeSrgb(baseColor) * (baseColorTextureSrgb != 0 ? decodeSrgb(texel) : texel) * color;
	c.a *= texture(alphaTexture, uv).g;
	if (c.a < alphaCutoff)
		discard;
	vec3 n;
	if (flatShading != 0) {
		n = normalize(cross(dFdx(worldPosition), dFdy(worldPosition)));
		if (dot(n, helixToEye(worldPosition)) < 0.0)
			n = -n;
	} else
		n = normalize(normal) * (gl_FrontFacing ? 1.0 : -1.0);
	vec3 geometric = n;
	if ((textureFlags & 1) != 0) {
		vec3 t = tangent.xyz - n * dot(n, tangent.xyz);
		if (dot(t, t) > 1e-12) {
			t = normalize(t);
			vec3 b = cross(n, t) * (tangent.w < 0.0 ? -1.0 : 1.0);
			vec3 m = helixReadMap(normalTexture, uv, 8).xyz * 2.0 - 1.0;
			m.xy *= normalScale;
			n = normalize(mat3(t, b, n) * m);
		}
	}
	Surface s = makeSurface(worldPosition, n, c.rgb);
	s.alpha = c.a;
	vec4 mr = helixReadMap(metallicRoughnessTexture, uv, 4);
	s.metallic = metallic * mr.b;
	s.roughness = max(roughness * mr.g, 0.03);
	s.occlusion = 1.0 + (helixReadMap(occlusionTexture, uv, 16).r - 1.0) * occlusionIntensity;
	s.specularColor = shading == 2 ? decodeSrgb(specularColor.rgb) : decodeSrgb(specularColor.rgb) * specularIntensity;
	s.ior = ior;
	s.shininess = shininess;
	s.clearcoat = clearcoat;
	s.clearcoatRoughness = clearcoatRoughness;
	s.clearcoatNormal = geometric;
	s.sheenColor = decodeSrgb(sheenColor.rgb);
	s.sheenRoughness = sheenRoughness;
	s.environmentIntensity = environmentIntensity;
	s.bakedLight = (textureFlags & 64) != 0 ? helixReadMap(lightTexture, uv, 32).rgb * lightIntensity : vec3(0.0);
	s.emissive = decodeSrgb(emissiveColor.rgb) * emissiveColor.a * helixReadMap(emissiveTexture, uv, 2).rgb;
	return s;
}

vec3 shadeMaterial(Surface surface) {
	if (shading == 1)
		return shadeLambert(surface);
	if (shading == 2)
		return shadePhong(surface);
	if (shading == 3)
		return shadeMetallicRoughness(surface);
	return surface.baseColor;
}

vec4 writeMaterialColor(Surface surface, vec3 light) {
	vec3 c = light + surface.emissive;
	if (fog != 0)
		c = applyFog(c, surface.position);
	return writeColor(vec4(c, surface.alpha));
}
#endif
