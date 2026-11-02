// helix-render's color conversions, either stage (View3D lists them): sRGB to linear and back, the renderer's exposure and tone mapping
// (three.js's curves), the fog, and what a target is written. Declares toneMapped, which writeColor reads.
#ifndef HELIX_RENDER_COLOR_GLSL
#define HELIX_RENDER_COLOR_GLSL
#include <helix/render/view.glsl>

uniform int toneMapped;

vec3 decodeSrgb(vec3 color) {
	vec3 c = max(color, vec3(0.0));
	return mix(c / 12.92, pow((c + 0.055) / 1.055, vec3(2.4)), step(vec3(0.04045), c));
}

vec4 decodeSrgb(vec4 color) {
	return vec4(decodeSrgb(color.rgb), color.a);
}

vec3 encodeSrgb(vec3 linear) {
	vec3 c = max(linear, vec3(0.0));
	return mix(c * 12.92, 1.055 * pow(c, vec3(1.0 / 2.4)) - 0.055, step(vec3(0.0031308), c));
}

vec4 encodeSrgb(vec4 linear) {
	return vec4(encodeSrgb(linear.rgb), linear.a);
}

vec3 helixAcesFit(vec3 v) {
	vec3 a = v * (v + 0.0245786) - 0.000090537;
	vec3 b = v * (0.983729 * v + 0.4329510) + 0.238081;
	return a / b;
}

vec3 helixAgxContrast(vec3 x) {
	vec3 x2 = x * x;
	vec3 x4 = x2 * x2;
	return 15.5 * x4 * x2 - 40.14 * x4 * x + 31.96 * x4 - 6.868 * x2 * x + 0.4298 * x2 + 0.1191 * x - 0.00232;
}

vec3 applyToneMapping(vec3 linear) {
	if (toneMapping == 0)
		return min(linear, vec3(1.0));
	vec3 color = linear * exposure;
	if (toneMapping == 1)
		return clamp(color, 0.0, 1.0);
	if (toneMapping == 2)
		return clamp(color / (vec3(1.0) + color), 0.0, 1.0);
	if (toneMapping == 3) {
		color = max(vec3(0.0), color - 0.004);
		return pow((color * (6.2 * color + 0.5)) / (color * (6.2 * color + 1.7) + 0.06), vec3(2.2));
	}
	if (toneMapping == 4) {
		mat3 inputMatrix = mat3(vec3(0.59719, 0.07600, 0.02840), vec3(0.35458, 0.90834, 0.13383), vec3(0.04823, 0.01566, 0.83777));
		mat3 outputMatrix = mat3(vec3(1.60475, -0.10208, -0.00327), vec3(-0.53108, 1.10813, -0.07276), vec3(-0.07367, -0.00605, 1.07602));
		color = outputMatrix * helixAcesFit(inputMatrix * (color / 0.6));
		return clamp(color, 0.0, 1.0);
	}
	if (toneMapping == 5) {
		mat3 toRec2020 = mat3(vec3(0.6274, 0.0691, 0.0164), vec3(0.3293, 0.9195, 0.0880), vec3(0.0433, 0.0113, 0.8956));
		mat3 fromRec2020 = mat3(vec3(1.6605, -0.1246, -0.0182), vec3(-0.5876, 1.1329, -0.1006), vec3(-0.0728, -0.0083, 1.1187));
		mat3 inset = mat3(vec3(0.856627153315983, 0.137318972929847, 0.11189821299995),
			vec3(0.0951212405381588, 0.761241990602591, 0.0767994186031903), vec3(0.0482516061458583, 0.101439036467562, 0.811302368396859));
		mat3 outset = mat3(vec3(1.1271005818144368, -0.1413297634984383, -0.14132976349843826),
			vec3(-0.11060664309660323, 1.157823702216272, -0.11060664309660294),
			vec3(-0.016493938717834573, -0.016493938717834257, 1.2519364065950405));
		color = inset * (toRec2020 * color);
		color = log2(max(color, vec3(1e-10)));
		color = clamp((color + 12.47393) / (4.026069 + 12.47393), 0.0, 1.0);
		color = outset * helixAgxContrast(color);
		color = pow(max(vec3(0.0), color), vec3(2.2));
		return clamp(fromRec2020 * color, 0.0, 1.0);
	}
	// Khronos PBR Neutral.
	float lowest = min(color.r, min(color.g, color.b));
	float offset = lowest < 0.08 ? lowest - 6.25 * lowest * lowest : 0.04;
	color -= offset;
	float peak = max(color.r, max(color.g, color.b));
	if (peak < 0.76)
		return color;
	float d = 0.24;
	float newPeak = 1.0 - d * d / (peak + d - 0.76);
	color *= newPeak / peak;
	float g = 1.0 - 1.0 / (0.15 * (peak - newPeak) + 1.0);
	return mix(color, vec3(newPeak), g);
}

vec3 applyFog(vec3 linear, vec3 worldPosition) {
	if (fogParams.x < 0.5)
		return linear;
	float distance = length(worldPosition - cameraPosition.xyz);
	float amount;
	if (fogParams.x < 1.5)
		amount = clamp((distance - fogParams.y) / max(fogParams.z - fogParams.y, 1e-6), 0.0, 1.0);
	else
		amount = 1.0 - exp(-fogParams.w * fogParams.w * distance * distance);
	return mix(linear, decodeSrgb(fogColor.rgb), amount);
}

vec4 encodeColor(vec4 linear) {
	if (linearTarget != 0)
		return linear;
	return vec4(encodeSrgb(clamp(linear.rgb, 0.0, 1.0)), linear.a);
}

vec4 writeColor(vec4 linear) {
	if (linearTarget == 0 && toneMapped != 0)
		linear.rgb = applyToneMapping(linear.rgb);
	return encodeColor(linear);
}
#endif
