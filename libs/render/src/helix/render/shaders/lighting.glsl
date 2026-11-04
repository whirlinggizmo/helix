// helix-render's lighting include, fragment stage (Batch3D lists its names): the Lighting block and its shared textures, the draw's own
// lights, the Surface a shading reads, and the shadings, in three.js's units and formulas (MeshLambertMaterial, MeshPhongMaterial,
// MeshStandardMaterial and MeshPhysicalMaterial's direct light, a point or spot light's decay 2, a spot's smoothstep between its cones, a
// hemisphere light's sky and ground). Includes color.glsl and view.glsl.
#ifndef HELIX_RENDER_LIGHTING_GLSL
#define HELIX_RENDER_LIGHTING_GLSL
#include <helix/render/shaders/color.glsl>

layout(std140) uniform Lighting {
	vec4 ambientLight;
	vec4 environmentIrradiance[9];
	vec4 environmentParams;
	mat4 shadowMatrices[24];
	vec4 shadowParams[4];
	vec4 shadowColors[4];
	vec4 shadowCascadeSplits;
};
uniform samplerCube environmentTexture;
uniform sampler2D brdfTexture;
uniform highp sampler2DArrayShadow shadowTexture;

uniform int lightCount;
uniform vec4 lightPositions[8];
uniform vec4 lightDirections[8];
uniform vec4 lightColors[8];
uniform vec4 lightCones[8];
uniform int receiveShadows;

struct Surface {
	vec3 position;
	vec3 normal;
	vec3 baseColor;
	float alpha;
	float metallic;
	float roughness;
	float occlusion;
	vec3 specularColor;
	float ior;
	float shininess;
	float clearcoat;
	float clearcoatRoughness;
	vec3 clearcoatNormal;
	vec3 sheenColor;
	float sheenRoughness;
	float environmentIntensity;
	vec3 bakedLight;
	vec3 emissive;
};

Surface makeSurface(vec3 position, vec3 normal, vec3 baseColor) {
	Surface s;
	s.position = position;
	s.normal = normal;
	s.baseColor = baseColor;
	s.alpha = 1.0;
	s.metallic = 0.0;
	s.roughness = 0.5;
	s.occlusion = 1.0;
	s.specularColor = vec3(1.0);
	s.ior = 1.5;
	s.shininess = 30.0;
	s.clearcoat = 0.0;
	s.clearcoatRoughness = 0.0;
	s.clearcoatNormal = normal;
	s.sheenColor = vec3(0.0);
	s.sheenRoughness = 0.0;
	s.environmentIntensity = 1.0;
	s.bakedLight = vec3(0.0);
	s.emissive = vec3(0.0);
	return s;
}

const float HELIX_PI = 3.14159265359;

// The unit direction from a point toward the eye: the eye's position under a perspective view, the view's axis under an orthographic one,
// as three.js has it.
vec3 helixToEye(vec3 position) {
	if (projectionMatrix[2][3] == 0.0)
		return normalize(vec3(viewMatrix[0][2], viewMatrix[1][2], viewMatrix[2][2]));
	return normalize(cameraPosition.xyz - position);
}

vec3 computeShadow(int shadowIndex, vec3 position, vec3 normal) {
	// Shadows are stage 3: nothing casts yet, so every point is lit.
	return vec3(1.0);
}

vec3 computeLightRadiance(int lightIndex, vec3 position, vec3 normal, out vec3 toLight) {
	vec4 p = lightPositions[lightIndex];
	vec4 d = lightDirections[lightIndex];
	vec3 radiance = lightColors[lightIndex].rgb;
	int kind = int(d.w + 0.5);
	if (kind == 0) {
		toLight = -d.xyz;
		return radiance;
	}
	if (kind == 3) {
		// A hemisphere light arrives along the normal, its sky and its ground blended by how far the normal faces up.
		toLight = normal;
		return mix(p.rgb, radiance, 0.5 * dot(normal, d.xyz) + 0.5);
	}
	vec3 between = p.xyz - position;
	float distance = length(between);
	toLight = distance > 1e-6 ? between / distance : -d.xyz;
	float falloff = 1.0 / max(distance * distance, 0.01);
	if (p.w > 0.0) {
		float r = distance / p.w;
		float window = clamp(1.0 - r * r * r * r, 0.0, 1.0);
		falloff *= window * window;
	}
	if (kind == 2) {
		vec4 cone = lightCones[lightIndex];
		float angle = dot(-toLight, d.xyz);
		falloff *= cone.x - cone.y > 1e-6 ? smoothstep(cone.y, cone.x, angle) : step(cone.y, angle);
	}
	int shadow = int(lightCones[lightIndex].z);
	if (shadow >= 0 && receiveShadows != 0)
		radiance *= computeShadow(shadow, position, normal);
	return radiance * falloff;
}

vec3 computeAmbientLight(vec3 normal) {
	// The environment map's irradiance is stage 4: until it is built, the ambient light alone.
	return ambientLight.rgb;
}

vec3 computeEnvironmentLight(vec3 direction, float roughness) {
	// The environment map is stage 4: until it is built, none.
	return vec3(0.0);
}

// The light a surface's diffuse color takes from what lights it from no one direction: the ambient light, the environment's irradiance,
// the hemisphere lights and the baked light, darkened by its occlusion.
vec3 helixIndirectIrradiance(Surface surface) {
	vec3 irradiance = computeAmbientLight(surface.normal) + surface.bakedLight;
	for (int i = 0; i < 8; i++) {
		if (i >= lightCount)
			break;
		if (lightDirections[i].w > 2.5) {
			vec3 toLight;
			irradiance += computeLightRadiance(i, surface.position, surface.normal, toLight);
		}
	}
	return irradiance * surface.occlusion;
}

vec3 shadeLambert(Surface surface) {
	vec3 irradiance = helixIndirectIrradiance(surface);
	for (int i = 0; i < 8; i++) {
		if (i >= lightCount)
			break;
		if (lightDirections[i].w > 2.5)
			continue;
		vec3 toLight;
		vec3 radiance = computeLightRadiance(i, surface.position, surface.normal, toLight);
		irradiance += radiance * max(dot(surface.normal, toLight), 0.0);
	}
	return irradiance * surface.baseColor / HELIX_PI;
}

vec3 helixSchlick(vec3 f0, float f90, float cosine) {
	float f = pow(1.0 - cosine, 5.0);
	return f0 * (1.0 - f) + f90 * f;
}

vec3 shadePhong(Surface surface) {
	vec3 n = surface.normal, v = helixToEye(surface.position);
	vec3 irradiance = helixIndirectIrradiance(surface);
	vec3 specular = vec3(0.0);
	for (int i = 0; i < 8; i++) {
		if (i >= lightCount)
			break;
		if (lightDirections[i].w > 2.5)
			continue;
		vec3 l;
		vec3 radiance = computeLightRadiance(i, surface.position, n, l) * max(dot(n, l), 0.0);
		irradiance += radiance;
		vec3 h = normalize(l + v);
		float nh = max(dot(n, h), 0.0), vh = max(dot(v, h), 0.0);
		float d = (surface.shininess * 0.5 + 1.0) * pow(nh, surface.shininess) / HELIX_PI;
		specular += radiance * helixSchlick(surface.specularColor, 1.0, vh) * (0.25 * d);
	}
	return irradiance * surface.baseColor / HELIX_PI + specular;
}

// GGX's highlight, three.js's BRDF_GGX: Schlick's Fresnel, the height-correlated Smith visibility and the GGX distribution.
vec3 helixGgx(vec3 l, vec3 v, vec3 n, vec3 f0, float f90, float roughness) {
	float a = roughness * roughness, a2 = a * a;
	vec3 h = normalize(l + v);
	float nl = clamp(dot(n, l), 0.0, 1.0), nv = clamp(dot(n, v), 0.0, 1.0), nh = clamp(dot(n, h), 0.0, 1.0), vh = clamp(dot(v, h), 0.0, 1.0);
	float gv = nl * sqrt(a2 + (1.0 - a2) * nv * nv), gl = nv * sqrt(a2 + (1.0 - a2) * nl * nl);
	float visibility = 0.5 / max(gv + gl, 1e-6);
	float denominator = nh * nh * (a2 - 1.0) + 1.0;
	float distribution = a2 / (HELIX_PI * denominator * denominator);
	return helixSchlick(f0, f90, vh) * (visibility * distribution);
}

// The sheen's highlight, three.js's BRDF_Sheen: Charlie's distribution and Neubelt's visibility.
vec3 helixSheen(vec3 l, vec3 v, vec3 n, vec3 color, float roughness) {
	vec3 h = normalize(l + v);
	float nl = clamp(dot(n, l), 0.0, 1.0), nv = clamp(dot(n, v), 0.0, 1.0), nh = clamp(dot(n, h), 0.0, 1.0);
	float a = roughness * roughness, inverse = 1.0 / a;
	float sin2 = max(1.0 - nh * nh, 0.0078125);
	float d = (2.0 + inverse) * pow(sin2, inverse * 0.5) / (2.0 * HELIX_PI);
	float visibility = clamp(1.0 / (4.0 * (nl + nv - nl * nv)), 0.0, 1.0);
	return color * (d * visibility);
}

vec3 shadeMetallicRoughness(Surface surface) {
	vec3 n = surface.normal, v = helixToEye(surface.position);
	float roughness = clamp(surface.roughness, 0.03, 1.0);
	float coatRoughness = clamp(surface.clearcoatRoughness, 0.03, 1.0);
	float sheenRoughness = clamp(surface.sheenRoughness, 0.07, 1.0);
	float dielectric = (surface.ior - 1.0) / (surface.ior + 1.0);
	vec3 f0 = mix(min(vec3(dielectric * dielectric) * surface.specularColor, vec3(1.0)), surface.baseColor, surface.metallic);
	vec3 diffuseColor = surface.baseColor * (1.0 - surface.metallic);
	vec3 diffuse = helixIndirectIrradiance(surface) * diffuseColor / HELIX_PI;
	vec3 specular = vec3(0.0), coat = vec3(0.0), sheen = vec3(0.0);
	for (int i = 0; i < 8; i++) {
		if (i >= lightCount)
			break;
		if (lightDirections[i].w > 2.5)
			continue;
		vec3 l;
		vec3 radiance = computeLightRadiance(i, surface.position, n, l);
		vec3 irradiance = radiance * clamp(dot(n, l), 0.0, 1.0);
		diffuse += irradiance * diffuseColor / HELIX_PI;
		specular += irradiance * helixGgx(l, v, n, f0, 1.0, roughness);
		if (surface.clearcoat > 0.0)
			coat += radiance * clamp(dot(surface.clearcoatNormal, l), 0.0, 1.0)
				* helixGgx(l, v, surface.clearcoatNormal, vec3(0.04), 1.0, coatRoughness);
		if (surface.sheenColor != vec3(0.0))
			sheen += irradiance * helixSheen(l, v, n, surface.sheenColor, sheenRoughness);
	}
	// The environment map's reflection is stage 4.
	vec3 light = diffuse + specular;
	if (surface.sheenColor != vec3(0.0))
		light = light * (1.0 - 0.157 * max(surface.sheenColor.r, max(surface.sheenColor.g, surface.sheenColor.b))) + sheen;
	if (surface.clearcoat > 0.0) {
		float fresnel = helixSchlick(vec3(0.04), 1.0, clamp(dot(surface.clearcoatNormal, v), 0.0, 1.0)).x;
		light = light * (1.0 - surface.clearcoat * fresnel) + coat * surface.clearcoat;
	}
	return light;
}
#endif
