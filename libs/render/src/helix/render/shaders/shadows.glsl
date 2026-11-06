// helix-render's shadows include, fragment stage, read by lighting.glsl under HELIX_RENDER_SHADOWS (set unless a program is built with
// -D helix_render_no_shadows): a casting light's shadow at a point from the Lighting block's maps, biased in texels (docs/DECISIONS.md 49).
// A casting light's shadowParams: x its first matrix, plus 32 times its map count, 256 times its kind (0 a directional light whose
// cascade is picked by the view's depth, shadowCascadeSplits its ends; 1 a directional light over its own box, its map picked by where
// the point falls; 2 a spot; 3 a point, a cube face a map) and 1024 times its filter radius in sixteenths of a texel; y its constant
// bias, z its slope bias and w its normal offset, in texels. shadowColors: its color, linear, and its strength. A spot's or a point's
// near plane is its far plane's distance over 512.
const float HELIX_SHADOW_NEAR = 1.0 / 512.0;

// The shadow map's comparisons at a point (x, y across the layer, z its depth, 0 to 1), filtered over a radius in texels: one lookup at
// 0, a 3 x 3 grid to 1, then a disc of 16, each lookup itself the comparisons of its four nearest texels, blended.
float helixShadowFilter(vec3 at, float layer, float radius, float texel) {
	if (radius <= 0.0)
		return texture(shadowTexture, vec4(at.xy, layer, at.z));
	float sum = 0.0;
	if (radius <= 1.0) {
		for (int y = -1; y <= 1; y++)
			for (int x = -1; x <= 1; x++)
				sum += texture(shadowTexture, vec4(at.xy + vec2(float(x), float(y)) * radius * texel, layer, at.z));
		return sum / 9.0;
	}
	for (int i = 0; i < 16; i++) {
		float r = sqrt((float(i) + 0.5) / 16.0) * radius;
		float a = float(i) * 2.39996323;
		sum += texture(shadowTexture, vec4(at.xy + vec2(cos(a), sin(a)) * r * texel, layer, at.z));
	}
	return sum / 16.0;
}

// A casting light's shadow at a point, the light arriving from toLight: its map picked, the lookup moved off the surface along its
// normal and toward the light by the biases, each a number of the map's texels at the point, filtered, faded over the map's last tenth,
// and turned into what it leaves of the light.
vec3 helixShadow(int shadowIndex, vec3 position, vec3 normal, vec3 toLight) {
	vec4 params = shadowParams[shadowIndex];
	float packed = params.x;
	int first = int(mod(packed, 32.0));
	int count = int(mod(floor(packed / 32.0), 8.0));
	int kind = int(mod(floor(packed / 256.0), 4.0));
	float radius = floor(packed / 1024.0) / 16.0;
	float size = float(textureSize(shadowTexture, 0).x);
	float margin = 2.0 * (radius + 1.5) / size;
	int k = count - 1;
	if (kind == 0) {
		float depth = -(viewMatrix * vec4(position, 1.0)).z;
		for (int i = 0; i < 3; i++)
			if (i < count - 1 && depth < shadowCascadeSplits[i]) {
				k = i;
				break;
			}
	} else if (kind != 2) {
		for (int i = 0; i < 6; i++) {
			if (i >= count - 1)
				break;
			vec4 c = shadowMatrices[first + i] * vec4(position, 1.0);
			vec3 n = c.xyz / c.w;
			if (c.w > 0.0 && abs(n.x) <= 1.0 - margin && abs(n.y) <= 1.0 - margin && abs(n.z) <= 1.0) {
				k = i;
				break;
			}
		}
	}
	mat4 m = shadowMatrices[first + k];
	vec4 clip = m * vec4(position, 1.0);
	if (clip.w <= 0.0)
		return vec3(1.0);
	vec3 ndc = clip.xyz / clip.w;
	float fade;
	if (kind == 0)
		fade = -(viewMatrix * vec4(position, 1.0)).z / shadowCascadeSplits[count - 1];
	else if (kind == 1)
		fade = k == count - 1 ? max(abs(ndc.x), abs(ndc.y)) : 0.0;
	else {
		float reach = 2.0 * HELIX_SHADOW_NEAR / (1.0 + HELIX_SHADOW_NEAR - ndc.z * (1.0 - HELIX_SHADOW_NEAR));
		fade = kind == 2 ? max(reach, max(abs(ndc.x), abs(ndc.y))) : reach;
	}
	fade = smoothstep(0.9, 1.0, fade);
	if (fade >= 1.0)
		return vec3(1.0);
	// A texel's width in the world at the point: 2 over the map's size, over how fast x across the map grows with distance there.
	float texel = 2.0 * clip.w / (size * length(vec3(m[0][0], m[1][0], m[2][0])));
	float cosine = clamp(dot(normal, toLight), -1.0, 1.0);
	float sine = sqrt(max(1.0 - cosine * cosine, 0.0));
	float slope = min(sine / max(abs(cosine), 1e-3), 3.0);
	vec3 moved = position + normal * (params.w * texel * (1.0 + sine)) + toLight * (texel * (params.y + params.z * slope));
	vec4 c = m * vec4(moved, 1.0);
	vec3 at = c.xyz / c.w * 0.5 + 0.5;
	float lit = at.z >= 1.0 ? 1.0 : helixShadowFilter(at, float(first + k), radius, 1.0 / size);
	vec4 color = shadowColors[shadowIndex];
	return mix(vec3(1.0), mix(vec3(1.0), color.rgb, color.a), (1.0 - lit) * (1.0 - fade));
}
