// helix-render's mesh vertex stage's names (Material3D lists them): the attributes, the per-draw uniforms and the six outputs, and
// placeVertex, which skins, instances and places a vertex as the materials' own stage does.
#ifndef HELIX_RENDER_MESH_GLSL
#define HELIX_RENDER_MESH_GLSL
#include <helix/render/view.glsl>

in vec3 vertexPosition;
in vec3 vertexNormal;
in vec4 vertexTangent;
in vec2 vertexTexCoord;
in vec2 vertexTexCoord2;
in vec4 vertexColor;
in vec4 vertexJoints;
in vec4 vertexWeights;
in mat4 instanceModel;
in vec4 instanceColor;
// A large point's corner, -1 to 1, as Batch3D's polygonMode Points draws one of pointSize; 0, 0 for a vertex drawn where it is.
in vec2 vertexCorner;

uniform mat4 model;
uniform mat4 normalMatrix;
uniform mat4 modelViewProjection;
uniform int skinned;
uniform int boneOffset;
uniform sampler2D boneTexture;
uniform vec4 morphWeights[16];
uniform int morphTargetCount;
uniform sampler2D morphTexture;
uniform mat3 textureTransform;
uniform int vertexColors;
uniform int colorSpaceSrgb;
uniform float pointSize;
uniform int pointSizeAttenuated;

out vec3 worldPosition;
out vec3 normal;
out vec4 tangent;
out vec2 texCoord;
out vec2 texCoord2;
out vec4 color;

// A bone's skinning matrix: four texels a bone, its columns, rows of whole bones, the draw's bones starting at boneOffset in the
// frame's one palette.
mat4 helixBoneMatrix(int bone) {
	bone += boneOffset;
	int perRow = textureSize(boneTexture, 0).x / 4;
	ivec2 at = ivec2((bone - bone / perRow * perRow) * 4, bone / perRow);
	return mat4(texelFetch(boneTexture, at, 0), texelFetch(boneTexture, at + ivec2(1, 0), 0), texelFetch(boneTexture, at + ivec2(2, 0), 0),
		texelFetch(boneTexture, at + ivec2(3, 0), 0));
}

vec4 placeVertex() {
	vec4 position = vec4(vertexPosition, 1.0);
	vec3 n = vertexNormal;
	vec3 t = vertexTangent.xyz;
	if (skinned != 0) {
		mat4 skin = vertexWeights.x * helixBoneMatrix(int(vertexJoints.x + 0.5)) + vertexWeights.y * helixBoneMatrix(int(vertexJoints.y + 0.5))
			+ vertexWeights.z * helixBoneMatrix(int(vertexJoints.z + 0.5)) + vertexWeights.w * helixBoneMatrix(int(vertexJoints.w + 0.5));
		position = skin * position;
		n = mat3(skin) * n;
		t = mat3(skin) * t;
	}
	position = instanceModel * position;
	n = mat3(instanceModel) * n;
	t = mat3(instanceModel) * t;
	vec4 world = model * position;
	worldPosition = world.xyz / world.w;
	normal = normalize(mat3(normalMatrix) * n + vec3(0.0, 0.0, 1e-20));
	tangent = vec4(normalize(mat3(model) * t + vec3(1e-20, 0.0, 0.0)), vertexTangent.w);
	texCoord = (textureTransform * vec3(vertexTexCoord, 1.0)).xy;
	texCoord2 = (textureTransform * vec3(vertexTexCoord2, 1.0)).xy;
	vec4 copy = colorSpaceSrgb != 0 ? instanceColor
		: vec4(mix(instanceColor.rgb / 12.92, pow((instanceColor.rgb + 0.055) / 1.055, vec3(2.4)), step(vec3(0.04045), instanceColor.rgb)),
			instanceColor.a);
	color = (vertexColors != 0 ? vertexColor : vec4(1.0)) * copy;
	vec4 clip = modelViewProjection * position;
	if (vertexCorner.x != 0.0 || vertexCorner.y != 0.0) {
		float size = pointSize;
		if (pointSizeAttenuated != 0 && projectionMatrix[2][3] != 0.0)
			size = pointSize * viewportSize.y * 0.5 / max(-(viewMatrix * world).z, 1e-6);
		clip.xy += vertexCorner * size / max(viewportSize.xy, vec2(1.0)) * clip.w;
	}
	return clip;
}
#endif
