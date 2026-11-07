# Rlgl

[Back to the library](README.md)

## OpenGL version (rlGlVersion)


```haxe
static inline var RL_OPENGL_11:Int
static inline var RL_OPENGL_21:Int
static inline var RL_OPENGL_33:Int
static inline var RL_OPENGL_43:Int
static inline var RL_OPENGL_ES_20:Int
static inline var RL_OPENGL_ES_30:Int
```

- `RL_OPENGL_11`: OpenGL 1.1.
- `RL_OPENGL_21`: OpenGL 2.1 (GLSL 120).
- `RL_OPENGL_33`: OpenGL 3.3 (GLSL 330).
- `RL_OPENGL_43`: OpenGL 4.3 (using GLSL 330).
- `RL_OPENGL_ES_20`: OpenGL ES 2.0 (GLSL 100).
- `RL_OPENGL_ES_30`: OpenGL ES 3.0 (GLSL 300 es).

## Trace log level (rlTraceLogLevel)


```haxe
static inline var RL_LOG_ALL:Int
static inline var RL_LOG_TRACE:Int
static inline var RL_LOG_DEBUG:Int
static inline var RL_LOG_INFO:Int
static inline var RL_LOG_WARNING:Int
static inline var RL_LOG_ERROR:Int
static inline var RL_LOG_FATAL:Int
static inline var RL_LOG_NONE:Int
```

- `RL_LOG_ALL`: Display all logs.
- `RL_LOG_TRACE`: Trace logging, intended for internal use only.
- `RL_LOG_DEBUG`: Debug logging, used for internal debugging, it should be disabled on release builds.
- `RL_LOG_INFO`: Info logging, used for program execution info.
- `RL_LOG_WARNING`: Warning logging, used on recoverable failures.
- `RL_LOG_ERROR`: Error logging, used on unrecoverable failures.
- `RL_LOG_FATAL`: Fatal logging, used to abort program: exit(EXIT_FAILURE).
- `RL_LOG_NONE`: Disable logging.

## Texture pixel formats (rlPixelFormat)


```haxe
static inline var RL_PIXELFORMAT_UNCOMPRESSED_GRAYSCALE:Int
static inline var RL_PIXELFORMAT_UNCOMPRESSED_GRAY_ALPHA:Int
static inline var RL_PIXELFORMAT_UNCOMPRESSED_R5G6B5:Int
static inline var RL_PIXELFORMAT_UNCOMPRESSED_R8G8B8:Int
static inline var RL_PIXELFORMAT_UNCOMPRESSED_R5G5B5A1:Int
static inline var RL_PIXELFORMAT_UNCOMPRESSED_R4G4B4A4:Int
static inline var RL_PIXELFORMAT_UNCOMPRESSED_R8G8B8A8:Int
static inline var RL_PIXELFORMAT_UNCOMPRESSED_R32:Int
static inline var RL_PIXELFORMAT_UNCOMPRESSED_R32G32B32:Int
static inline var RL_PIXELFORMAT_UNCOMPRESSED_R32G32B32A32:Int
static inline var RL_PIXELFORMAT_UNCOMPRESSED_R16:Int
static inline var RL_PIXELFORMAT_UNCOMPRESSED_R16G16B16:Int
static inline var RL_PIXELFORMAT_UNCOMPRESSED_R16G16B16A16:Int
static inline var RL_PIXELFORMAT_COMPRESSED_DXT1_RGB:Int
static inline var RL_PIXELFORMAT_COMPRESSED_DXT1_RGBA:Int
static inline var RL_PIXELFORMAT_COMPRESSED_DXT3_RGBA:Int
static inline var RL_PIXELFORMAT_COMPRESSED_DXT5_RGBA:Int
static inline var RL_PIXELFORMAT_COMPRESSED_ETC1_RGB:Int
static inline var RL_PIXELFORMAT_COMPRESSED_ETC2_RGB:Int
static inline var RL_PIXELFORMAT_COMPRESSED_ETC2_EAC_RGBA:Int
static inline var RL_PIXELFORMAT_COMPRESSED_PVRT_RGB:Int
static inline var RL_PIXELFORMAT_COMPRESSED_PVRT_RGBA:Int
static inline var RL_PIXELFORMAT_COMPRESSED_ASTC_4x4_RGBA:Int
static inline var RL_PIXELFORMAT_COMPRESSED_ASTC_8x8_RGBA:Int
```

- `RL_PIXELFORMAT_UNCOMPRESSED_GRAYSCALE`: 8 bit per pixel (no alpha).
- `RL_PIXELFORMAT_UNCOMPRESSED_GRAY_ALPHA`: 8*2 bpp (2 channels).
- `RL_PIXELFORMAT_UNCOMPRESSED_R5G6B5`: 16 bpp.
- `RL_PIXELFORMAT_UNCOMPRESSED_R8G8B8`: 24 bpp.
- `RL_PIXELFORMAT_UNCOMPRESSED_R5G5B5A1`: 16 bpp (1 bit alpha).
- `RL_PIXELFORMAT_UNCOMPRESSED_R4G4B4A4`: 16 bpp (4 bit alpha).
- `RL_PIXELFORMAT_UNCOMPRESSED_R8G8B8A8`: 32 bpp.
- `RL_PIXELFORMAT_UNCOMPRESSED_R32`: 32 bpp (1 channel - float).
- `RL_PIXELFORMAT_UNCOMPRESSED_R32G32B32`: 32*3 bpp (3 channels - float).
- `RL_PIXELFORMAT_UNCOMPRESSED_R32G32B32A32`: 32*4 bpp (4 channels - float).
- `RL_PIXELFORMAT_UNCOMPRESSED_R16`: 16 bpp (1 channel - half float).
- `RL_PIXELFORMAT_UNCOMPRESSED_R16G16B16`: 16*3 bpp (3 channels - half float).
- `RL_PIXELFORMAT_UNCOMPRESSED_R16G16B16A16`: 16*4 bpp (4 channels - half float).
- `RL_PIXELFORMAT_COMPRESSED_DXT1_RGB`: 4 bpp (no alpha).
- `RL_PIXELFORMAT_COMPRESSED_DXT1_RGBA`: 4 bpp (1 bit alpha).
- `RL_PIXELFORMAT_COMPRESSED_DXT3_RGBA`: 8 bpp.
- `RL_PIXELFORMAT_COMPRESSED_DXT5_RGBA`: 8 bpp.
- `RL_PIXELFORMAT_COMPRESSED_ETC1_RGB`: 4 bpp.
- `RL_PIXELFORMAT_COMPRESSED_ETC2_RGB`: 4 bpp.
- `RL_PIXELFORMAT_COMPRESSED_ETC2_EAC_RGBA`: 8 bpp.
- `RL_PIXELFORMAT_COMPRESSED_PVRT_RGB`: 4 bpp.
- `RL_PIXELFORMAT_COMPRESSED_PVRT_RGBA`: 4 bpp.
- `RL_PIXELFORMAT_COMPRESSED_ASTC_4x4_RGBA`: 8 bpp.
- `RL_PIXELFORMAT_COMPRESSED_ASTC_8x8_RGBA`: 2 bpp.

## Texture parameters: filter mode (rlTextureFilter)


```haxe
static inline var RL_TEXTURE_FILTER_POINT:Int
static inline var RL_TEXTURE_FILTER_BILINEAR:Int
static inline var RL_TEXTURE_FILTER_TRILINEAR:Int
static inline var RL_TEXTURE_FILTER_ANISOTROPIC_4X:Int
static inline var RL_TEXTURE_FILTER_ANISOTROPIC_8X:Int
static inline var RL_TEXTURE_FILTER_ANISOTROPIC_16X:Int
```

- `RL_TEXTURE_FILTER_POINT`: No filter, just pixel approximation.
- `RL_TEXTURE_FILTER_BILINEAR`: Linear filtering.
- `RL_TEXTURE_FILTER_TRILINEAR`: Trilinear filtering (linear with mipmaps).
- `RL_TEXTURE_FILTER_ANISOTROPIC_4X`: Anisotropic filtering 4x.
- `RL_TEXTURE_FILTER_ANISOTROPIC_8X`: Anisotropic filtering 8x.
- `RL_TEXTURE_FILTER_ANISOTROPIC_16X`: Anisotropic filtering 16x.

## Color blending modes (pre-defined) (rlBlendMode)


```haxe
static inline var RL_BLEND_ALPHA:Int
static inline var RL_BLEND_ADDITIVE:Int
static inline var RL_BLEND_MULTIPLIED:Int
static inline var RL_BLEND_ADD_COLORS:Int
static inline var RL_BLEND_SUBTRACT_COLORS:Int
static inline var RL_BLEND_ALPHA_PREMULTIPLY:Int
static inline var RL_BLEND_CUSTOM:Int
static inline var RL_BLEND_CUSTOM_SEPARATE:Int
```

- `RL_BLEND_ALPHA`: Blend textures considering alpha (default).
- `RL_BLEND_ADDITIVE`: Blend textures adding colors.
- `RL_BLEND_MULTIPLIED`: Blend textures multiplying colors.
- `RL_BLEND_ADD_COLORS`: Blend textures adding colors (alternative).
- `RL_BLEND_SUBTRACT_COLORS`: Blend textures subtracting colors (alternative).
- `RL_BLEND_ALPHA_PREMULTIPLY`: Blend premultiplied textures considering alpha.
- `RL_BLEND_CUSTOM`: Blend textures using custom src/dst factors (use rlSetBlendFactors()).
- `RL_BLEND_CUSTOM_SEPARATE`: Blend textures using custom src/dst factors (use rlSetBlendFactorsSeparate()).

## Shader location point type (rlShaderLocationIndex)


```haxe
static inline var RL_SHADER_LOC_VERTEX_POSITION:Int
static inline var RL_SHADER_LOC_VERTEX_TEXCOORD01:Int
static inline var RL_SHADER_LOC_VERTEX_TEXCOORD02:Int
static inline var RL_SHADER_LOC_VERTEX_NORMAL:Int
static inline var RL_SHADER_LOC_VERTEX_TANGENT:Int
static inline var RL_SHADER_LOC_VERTEX_COLOR:Int
static inline var RL_SHADER_LOC_MATRIX_MVP:Int
static inline var RL_SHADER_LOC_MATRIX_VIEW:Int
static inline var RL_SHADER_LOC_MATRIX_PROJECTION:Int
static inline var RL_SHADER_LOC_MATRIX_MODEL:Int
static inline var RL_SHADER_LOC_MATRIX_NORMAL:Int
static inline var RL_SHADER_LOC_VECTOR_VIEW:Int
static inline var RL_SHADER_LOC_COLOR_DIFFUSE:Int
static inline var RL_SHADER_LOC_COLOR_SPECULAR:Int
static inline var RL_SHADER_LOC_COLOR_AMBIENT:Int
static inline var RL_SHADER_LOC_MAP_ALBEDO:Int
static inline var RL_SHADER_LOC_MAP_METALNESS:Int
static inline var RL_SHADER_LOC_MAP_NORMAL:Int
static inline var RL_SHADER_LOC_MAP_ROUGHNESS:Int
static inline var RL_SHADER_LOC_MAP_OCCLUSION:Int
static inline var RL_SHADER_LOC_MAP_EMISSION:Int
static inline var RL_SHADER_LOC_MAP_HEIGHT:Int
static inline var RL_SHADER_LOC_MAP_CUBEMAP:Int
static inline var RL_SHADER_LOC_MAP_IRRADIANCE:Int
static inline var RL_SHADER_LOC_MAP_PREFILTER:Int
static inline var RL_SHADER_LOC_MAP_BRDF:Int
```

- `RL_SHADER_LOC_VERTEX_POSITION`: Shader location: vertex attribute: position.
- `RL_SHADER_LOC_VERTEX_TEXCOORD01`: Shader location: vertex attribute: texcoord01.
- `RL_SHADER_LOC_VERTEX_TEXCOORD02`: Shader location: vertex attribute: texcoord02.
- `RL_SHADER_LOC_VERTEX_NORMAL`: Shader location: vertex attribute: normal.
- `RL_SHADER_LOC_VERTEX_TANGENT`: Shader location: vertex attribute: tangent.
- `RL_SHADER_LOC_VERTEX_COLOR`: Shader location: vertex attribute: color.
- `RL_SHADER_LOC_MATRIX_MVP`: Shader location: matrix uniform: model-view-projection.
- `RL_SHADER_LOC_MATRIX_VIEW`: Shader location: matrix uniform: view (camera transform).
- `RL_SHADER_LOC_MATRIX_PROJECTION`: Shader location: matrix uniform: projection.
- `RL_SHADER_LOC_MATRIX_MODEL`: Shader location: matrix uniform: model (transform).
- `RL_SHADER_LOC_MATRIX_NORMAL`: Shader location: matrix uniform: normal.
- `RL_SHADER_LOC_VECTOR_VIEW`: Shader location: vector uniform: view.
- `RL_SHADER_LOC_COLOR_DIFFUSE`: Shader location: vector uniform: diffuse color.
- `RL_SHADER_LOC_COLOR_SPECULAR`: Shader location: vector uniform: specular color.
- `RL_SHADER_LOC_COLOR_AMBIENT`: Shader location: vector uniform: ambient color.
- `RL_SHADER_LOC_MAP_ALBEDO`: Shader location: sampler2d texture: albedo (same as: RL_SHADER_LOC_MAP_DIFFUSE).
- `RL_SHADER_LOC_MAP_METALNESS`: Shader location: sampler2d texture: metalness (same as: RL_SHADER_LOC_MAP_SPECULAR).
- `RL_SHADER_LOC_MAP_NORMAL`: Shader location: sampler2d texture: normal.
- `RL_SHADER_LOC_MAP_ROUGHNESS`: Shader location: sampler2d texture: roughness.
- `RL_SHADER_LOC_MAP_OCCLUSION`: Shader location: sampler2d texture: occlusion.
- `RL_SHADER_LOC_MAP_EMISSION`: Shader location: sampler2d texture: emission.
- `RL_SHADER_LOC_MAP_HEIGHT`: Shader location: sampler2d texture: height.
- `RL_SHADER_LOC_MAP_CUBEMAP`: Shader location: samplerCube texture: cubemap.
- `RL_SHADER_LOC_MAP_IRRADIANCE`: Shader location: samplerCube texture: irradiance.
- `RL_SHADER_LOC_MAP_PREFILTER`: Shader location: samplerCube texture: prefilter.
- `RL_SHADER_LOC_MAP_BRDF`: Shader location: sampler2d texture: brdf.

## Shader uniform data type (rlShaderUniformDataType)


```haxe
static inline var RL_SHADER_UNIFORM_FLOAT:Int
static inline var RL_SHADER_UNIFORM_VEC2:Int
static inline var RL_SHADER_UNIFORM_VEC3:Int
static inline var RL_SHADER_UNIFORM_VEC4:Int
static inline var RL_SHADER_UNIFORM_INT:Int
static inline var RL_SHADER_UNIFORM_IVEC2:Int
static inline var RL_SHADER_UNIFORM_IVEC3:Int
static inline var RL_SHADER_UNIFORM_IVEC4:Int
static inline var RL_SHADER_UNIFORM_UINT:Int
static inline var RL_SHADER_UNIFORM_UIVEC2:Int
static inline var RL_SHADER_UNIFORM_UIVEC3:Int
static inline var RL_SHADER_UNIFORM_UIVEC4:Int
static inline var RL_SHADER_UNIFORM_SAMPLER2D:Int
```

- `RL_SHADER_UNIFORM_FLOAT`: Shader uniform type: float.
- `RL_SHADER_UNIFORM_VEC2`: Shader uniform type: vec2 (2 float).
- `RL_SHADER_UNIFORM_VEC3`: Shader uniform type: vec3 (3 float).
- `RL_SHADER_UNIFORM_VEC4`: Shader uniform type: vec4 (4 float).
- `RL_SHADER_UNIFORM_INT`: Shader uniform type: int.
- `RL_SHADER_UNIFORM_IVEC2`: Shader uniform type: ivec2 (2 int).
- `RL_SHADER_UNIFORM_IVEC3`: Shader uniform type: ivec3 (3 int).
- `RL_SHADER_UNIFORM_IVEC4`: Shader uniform type: ivec4 (4 int).
- `RL_SHADER_UNIFORM_UINT`: Shader uniform type: unsigned int.
- `RL_SHADER_UNIFORM_UIVEC2`: Shader uniform type: uivec2 (2 unsigned int).
- `RL_SHADER_UNIFORM_UIVEC3`: Shader uniform type: uivec3 (3 unsigned int).
- `RL_SHADER_UNIFORM_UIVEC4`: Shader uniform type: uivec4 (4 unsigned int).
- `RL_SHADER_UNIFORM_SAMPLER2D`: Shader uniform type: sampler2d.

## Shader attribute data types (rlShaderAttributeDataType)


```haxe
static inline var RL_SHADER_ATTRIB_FLOAT:Int
static inline var RL_SHADER_ATTRIB_VEC2:Int
static inline var RL_SHADER_ATTRIB_VEC3:Int
static inline var RL_SHADER_ATTRIB_VEC4:Int
```

- `RL_SHADER_ATTRIB_FLOAT`: Shader attribute type: float.
- `RL_SHADER_ATTRIB_VEC2`: Shader attribute type: vec2 (2 float).
- `RL_SHADER_ATTRIB_VEC3`: Shader attribute type: vec3 (3 float).
- `RL_SHADER_ATTRIB_VEC4`: Shader attribute type: vec4 (4 float).

## Framebuffer attachment type (rlFramebufferAttachType)


```haxe
static inline var RL_ATTACHMENT_COLOR_CHANNEL0:Int
static inline var RL_ATTACHMENT_COLOR_CHANNEL1:Int
static inline var RL_ATTACHMENT_COLOR_CHANNEL2:Int
static inline var RL_ATTACHMENT_COLOR_CHANNEL3:Int
static inline var RL_ATTACHMENT_COLOR_CHANNEL4:Int
static inline var RL_ATTACHMENT_COLOR_CHANNEL5:Int
static inline var RL_ATTACHMENT_COLOR_CHANNEL6:Int
static inline var RL_ATTACHMENT_COLOR_CHANNEL7:Int
static inline var RL_ATTACHMENT_DEPTH:Int
static inline var RL_ATTACHMENT_STENCIL:Int
```

- `RL_ATTACHMENT_COLOR_CHANNEL0`: Framebuffer attachment type: color 0.
- `RL_ATTACHMENT_COLOR_CHANNEL1`: Framebuffer attachment type: color 1.
- `RL_ATTACHMENT_COLOR_CHANNEL2`: Framebuffer attachment type: color 2.
- `RL_ATTACHMENT_COLOR_CHANNEL3`: Framebuffer attachment type: color 3.
- `RL_ATTACHMENT_COLOR_CHANNEL4`: Framebuffer attachment type: color 4.
- `RL_ATTACHMENT_COLOR_CHANNEL5`: Framebuffer attachment type: color 5.
- `RL_ATTACHMENT_COLOR_CHANNEL6`: Framebuffer attachment type: color 6.
- `RL_ATTACHMENT_COLOR_CHANNEL7`: Framebuffer attachment type: color 7.
- `RL_ATTACHMENT_DEPTH`: Framebuffer attachment type: depth.
- `RL_ATTACHMENT_STENCIL`: Framebuffer attachment type: stencil.

## Framebuffer texture attachment type (rlFramebufferAttachTextureType)


```haxe
static inline var RL_ATTACHMENT_CUBEMAP_POSITIVE_X:Int
static inline var RL_ATTACHMENT_CUBEMAP_NEGATIVE_X:Int
static inline var RL_ATTACHMENT_CUBEMAP_POSITIVE_Y:Int
static inline var RL_ATTACHMENT_CUBEMAP_NEGATIVE_Y:Int
static inline var RL_ATTACHMENT_CUBEMAP_POSITIVE_Z:Int
static inline var RL_ATTACHMENT_CUBEMAP_NEGATIVE_Z:Int
static inline var RL_ATTACHMENT_TEXTURE2D:Int
static inline var RL_ATTACHMENT_RENDERBUFFER:Int
```

- `RL_ATTACHMENT_CUBEMAP_POSITIVE_X`: Framebuffer texture attachment type: cubemap, +X side.
- `RL_ATTACHMENT_CUBEMAP_NEGATIVE_X`: Framebuffer texture attachment type: cubemap, -X side.
- `RL_ATTACHMENT_CUBEMAP_POSITIVE_Y`: Framebuffer texture attachment type: cubemap, +Y side.
- `RL_ATTACHMENT_CUBEMAP_NEGATIVE_Y`: Framebuffer texture attachment type: cubemap, -Y side.
- `RL_ATTACHMENT_CUBEMAP_POSITIVE_Z`: Framebuffer texture attachment type: cubemap, +Z side.
- `RL_ATTACHMENT_CUBEMAP_NEGATIVE_Z`: Framebuffer texture attachment type: cubemap, -Z side.
- `RL_ATTACHMENT_TEXTURE2D`: Framebuffer texture attachment type: texture2d.
- `RL_ATTACHMENT_RENDERBUFFER`: Framebuffer texture attachment type: renderbuffer.

## Face culling mode (rlCullMode)


```haxe
static inline var RL_CULL_FACE_FRONT:Int
static inline var RL_CULL_FACE_BACK:Int
```

- `RL_CULL_FACE_FRONT`: Face culling mode: `RL_CULL_FACE_FRONT`.
- `RL_CULL_FACE_BACK`: Face culling mode: `RL_CULL_FACE_BACK`.

## rlgl.h's defines


```haxe
static inline var RL_DEFAULT_BATCH_BUFFER_ELEMENTS:Int
static inline var RL_DEFAULT_BATCH_BUFFERS:Int
static inline var RL_DEFAULT_BATCH_DRAWCALLS:Int
static inline var RL_DEFAULT_BATCH_MAX_TEXTURE_UNITS:Int
static inline var RL_MAX_MATRIX_STACK_SIZE:Int
static inline var RL_MAX_SHADER_LOCATIONS:Int
static inline var RL_CULL_DISTANCE_NEAR:Float
static inline var RL_CULL_DISTANCE_FAR:Float
static inline var RL_TEXTURE_WRAP_S:Int
static inline var RL_TEXTURE_WRAP_T:Int
static inline var RL_TEXTURE_MAG_FILTER:Int
static inline var RL_TEXTURE_MIN_FILTER:Int
static inline var RL_TEXTURE_FILTER_NEAREST:Int
static inline var RL_TEXTURE_FILTER_LINEAR:Int
static inline var RL_TEXTURE_FILTER_MIP_NEAREST:Int
static inline var RL_TEXTURE_FILTER_NEAREST_MIP_LINEAR:Int
static inline var RL_TEXTURE_FILTER_LINEAR_MIP_NEAREST:Int
static inline var RL_TEXTURE_FILTER_MIP_LINEAR:Int
static inline var RL_TEXTURE_FILTER_ANISOTROPIC:Int
static inline var RL_TEXTURE_MIPMAP_BIAS_RATIO:Int
static inline var RL_TEXTURE_WRAP_REPEAT:Int
static inline var RL_TEXTURE_WRAP_CLAMP:Int
static inline var RL_TEXTURE_WRAP_MIRROR_REPEAT:Int
static inline var RL_TEXTURE_WRAP_MIRROR_CLAMP:Int
static inline var RL_MODELVIEW:Int
static inline var RL_PROJECTION:Int
static inline var RL_TEXTURE:Int
static inline var RL_LINES:Int
static inline var RL_TRIANGLES:Int
static inline var RL_QUADS:Int
static inline var RL_UNSIGNED_BYTE:Int
static inline var RL_FLOAT:Int
static inline var RL_STREAM_DRAW:Int
static inline var RL_STREAM_READ:Int
static inline var RL_STREAM_COPY:Int
static inline var RL_STATIC_DRAW:Int
static inline var RL_STATIC_READ:Int
static inline var RL_STATIC_COPY:Int
static inline var RL_DYNAMIC_DRAW:Int
static inline var RL_DYNAMIC_READ:Int
static inline var RL_DYNAMIC_COPY:Int
static inline var RL_FRAGMENT_SHADER:Int
static inline var RL_VERTEX_SHADER:Int
static inline var RL_COMPUTE_SHADER:Int
static inline var RL_ZERO:Int
static inline var RL_ONE:Int
static inline var RL_SRC_COLOR:Int
static inline var RL_ONE_MINUS_SRC_COLOR:Int
static inline var RL_SRC_ALPHA:Int
static inline var RL_ONE_MINUS_SRC_ALPHA:Int
static inline var RL_DST_ALPHA:Int
static inline var RL_ONE_MINUS_DST_ALPHA:Int
static inline var RL_DST_COLOR:Int
static inline var RL_ONE_MINUS_DST_COLOR:Int
static inline var RL_SRC_ALPHA_SATURATE:Int
static inline var RL_CONSTANT_COLOR:Int
static inline var RL_ONE_MINUS_CONSTANT_COLOR:Int
static inline var RL_CONSTANT_ALPHA:Int
static inline var RL_ONE_MINUS_CONSTANT_ALPHA:Int
static inline var RL_FUNC_ADD:Int
static inline var RL_MIN:Int
static inline var RL_MAX:Int
static inline var RL_FUNC_SUBTRACT:Int
static inline var RL_FUNC_REVERSE_SUBTRACT:Int
static inline var RL_BLEND_EQUATION:Int
static inline var RL_BLEND_EQUATION_RGB:Int
static inline var RL_BLEND_EQUATION_ALPHA:Int
static inline var RL_BLEND_DST_RGB:Int
static inline var RL_BLEND_SRC_RGB:Int
static inline var RL_BLEND_DST_ALPHA:Int
static inline var RL_BLEND_SRC_ALPHA:Int
static inline var RL_BLEND_COLOR:Int
static inline var RL_READ_FRAMEBUFFER:Int
static inline var RL_DRAW_FRAMEBUFFER:Int
static inline var RL_DEFAULT_SHADER_ATTRIB_LOCATION_POSITION:Int
static inline var RL_DEFAULT_SHADER_ATTRIB_LOCATION_TEXCOORD:Int
static inline var RL_DEFAULT_SHADER_ATTRIB_LOCATION_NORMAL:Int
static inline var RL_DEFAULT_SHADER_ATTRIB_LOCATION_COLOR:Int
static inline var RL_DEFAULT_SHADER_ATTRIB_LOCATION_TANGENT:Int
static inline var RL_DEFAULT_SHADER_ATTRIB_LOCATION_TEXCOORD2:Int
static inline var RL_DEFAULT_SHADER_ATTRIB_LOCATION_INDICES:Int
static inline var RL_DEFAULT_SHADER_ATTRIB_LOCATION_BONEIDS:Int
static inline var RL_DEFAULT_SHADER_ATTRIB_LOCATION_BONEWEIGHTS:Int
static inline var PI:Float
```

- `RL_DEFAULT_BATCH_BUFFER_ELEMENTS`: rlgl.h's `RL_DEFAULT_BATCH_BUFFER_ELEMENTS`.
- `RL_DEFAULT_BATCH_BUFFERS`: Default number of batch buffers (multi-buffering).
- `RL_DEFAULT_BATCH_DRAWCALLS`: Default number of batch draw calls (by state changes: mode, texture).
- `RL_DEFAULT_BATCH_MAX_TEXTURE_UNITS`: Maximum number of textures units that can be activated on batch drawing (SetShaderValueTexture()).
- `RL_MAX_MATRIX_STACK_SIZE`: Maximum size of Matrix stack.
- `RL_MAX_SHADER_LOCATIONS`: Maximum number of shader locations supported.
- `RL_CULL_DISTANCE_NEAR`: Default near cull distance.
- `RL_CULL_DISTANCE_FAR`: Default far cull distance.
- `RL_TEXTURE_WRAP_S`: GL_TEXTURE_WRAP_S.
- `RL_TEXTURE_WRAP_T`: GL_TEXTURE_WRAP_T.
- `RL_TEXTURE_MAG_FILTER`: GL_TEXTURE_MAG_FILTER.
- `RL_TEXTURE_MIN_FILTER`: GL_TEXTURE_MIN_FILTER.
- `RL_TEXTURE_FILTER_NEAREST`: GL_NEAREST.
- `RL_TEXTURE_FILTER_LINEAR`: GL_LINEAR.
- `RL_TEXTURE_FILTER_MIP_NEAREST`: GL_NEAREST_MIPMAP_NEAREST.
- `RL_TEXTURE_FILTER_NEAREST_MIP_LINEAR`: GL_NEAREST_MIPMAP_LINEAR.
- `RL_TEXTURE_FILTER_LINEAR_MIP_NEAREST`: GL_LINEAR_MIPMAP_NEAREST.
- `RL_TEXTURE_FILTER_MIP_LINEAR`: GL_LINEAR_MIPMAP_LINEAR.
- `RL_TEXTURE_FILTER_ANISOTROPIC`: Anisotropic filter (custom identifier).
- `RL_TEXTURE_MIPMAP_BIAS_RATIO`: Texture mipmap bias, percentage ratio (custom identifier).
- `RL_TEXTURE_WRAP_REPEAT`: GL_REPEAT.
- `RL_TEXTURE_WRAP_CLAMP`: GL_CLAMP_TO_EDGE.
- `RL_TEXTURE_WRAP_MIRROR_REPEAT`: GL_MIRRORED_REPEAT.
- `RL_TEXTURE_WRAP_MIRROR_CLAMP`: GL_MIRROR_CLAMP_EXT.
- `RL_MODELVIEW`: GL_MODELVIEW.
- `RL_PROJECTION`: GL_PROJECTION.
- `RL_TEXTURE`: GL_TEXTURE.
- `RL_LINES`: GL_LINES.
- `RL_TRIANGLES`: GL_TRIANGLES.
- `RL_QUADS`: GL_QUADS.
- `RL_UNSIGNED_BYTE`: GL_UNSIGNED_BYTE.
- `RL_FLOAT`: GL_FLOAT.
- `RL_STREAM_DRAW`: GL_STREAM_DRAW.
- `RL_STREAM_READ`: GL_STREAM_READ.
- `RL_STREAM_COPY`: GL_STREAM_COPY.
- `RL_STATIC_DRAW`: GL_STATIC_DRAW.
- `RL_STATIC_READ`: GL_STATIC_READ.
- `RL_STATIC_COPY`: GL_STATIC_COPY.
- `RL_DYNAMIC_DRAW`: GL_DYNAMIC_DRAW.
- `RL_DYNAMIC_READ`: GL_DYNAMIC_READ.
- `RL_DYNAMIC_COPY`: GL_DYNAMIC_COPY.
- `RL_FRAGMENT_SHADER`: GL_FRAGMENT_SHADER.
- `RL_VERTEX_SHADER`: GL_VERTEX_SHADER.
- `RL_COMPUTE_SHADER`: GL_COMPUTE_SHADER.
- `RL_ZERO`: GL_ZERO.
- `RL_ONE`: GL_ONE.
- `RL_SRC_COLOR`: GL_SRC_COLOR.
- `RL_ONE_MINUS_SRC_COLOR`: GL_ONE_MINUS_SRC_COLOR.
- `RL_SRC_ALPHA`: GL_SRC_ALPHA.
- `RL_ONE_MINUS_SRC_ALPHA`: GL_ONE_MINUS_SRC_ALPHA.
- `RL_DST_ALPHA`: GL_DST_ALPHA.
- `RL_ONE_MINUS_DST_ALPHA`: GL_ONE_MINUS_DST_ALPHA.
- `RL_DST_COLOR`: GL_DST_COLOR.
- `RL_ONE_MINUS_DST_COLOR`: GL_ONE_MINUS_DST_COLOR.
- `RL_SRC_ALPHA_SATURATE`: GL_SRC_ALPHA_SATURATE.
- `RL_CONSTANT_COLOR`: GL_CONSTANT_COLOR.
- `RL_ONE_MINUS_CONSTANT_COLOR`: GL_ONE_MINUS_CONSTANT_COLOR.
- `RL_CONSTANT_ALPHA`: GL_CONSTANT_ALPHA.
- `RL_ONE_MINUS_CONSTANT_ALPHA`: GL_ONE_MINUS_CONSTANT_ALPHA.
- `RL_FUNC_ADD`: GL_FUNC_ADD.
- `RL_MIN`: GL_MIN.
- `RL_MAX`: GL_MAX.
- `RL_FUNC_SUBTRACT`: GL_FUNC_SUBTRACT.
- `RL_FUNC_REVERSE_SUBTRACT`: GL_FUNC_REVERSE_SUBTRACT.
- `RL_BLEND_EQUATION`: GL_BLEND_EQUATION.
- `RL_BLEND_EQUATION_RGB`: GL_BLEND_EQUATION_RGB   // (Same as BLEND_EQUATION).
- `RL_BLEND_EQUATION_ALPHA`: GL_BLEND_EQUATION_ALPHA.
- `RL_BLEND_DST_RGB`: GL_BLEND_DST_RGB.
- `RL_BLEND_SRC_RGB`: GL_BLEND_SRC_RGB.
- `RL_BLEND_DST_ALPHA`: GL_BLEND_DST_ALPHA.
- `RL_BLEND_SRC_ALPHA`: GL_BLEND_SRC_ALPHA.
- `RL_BLEND_COLOR`: GL_BLEND_COLOR.
- `RL_READ_FRAMEBUFFER`: GL_READ_FRAMEBUFFER.
- `RL_DRAW_FRAMEBUFFER`: GL_DRAW_FRAMEBUFFER.
- `RL_DEFAULT_SHADER_ATTRIB_LOCATION_POSITION`: rlgl.h's `RL_DEFAULT_SHADER_ATTRIB_LOCATION_POSITION`.
- `RL_DEFAULT_SHADER_ATTRIB_LOCATION_TEXCOORD`: rlgl.h's `RL_DEFAULT_SHADER_ATTRIB_LOCATION_TEXCOORD`.
- `RL_DEFAULT_SHADER_ATTRIB_LOCATION_NORMAL`: rlgl.h's `RL_DEFAULT_SHADER_ATTRIB_LOCATION_NORMAL`.
- `RL_DEFAULT_SHADER_ATTRIB_LOCATION_COLOR`: rlgl.h's `RL_DEFAULT_SHADER_ATTRIB_LOCATION_COLOR`.
- `RL_DEFAULT_SHADER_ATTRIB_LOCATION_TANGENT`: rlgl.h's `RL_DEFAULT_SHADER_ATTRIB_LOCATION_TANGENT`.
- `RL_DEFAULT_SHADER_ATTRIB_LOCATION_TEXCOORD2`: rlgl.h's `RL_DEFAULT_SHADER_ATTRIB_LOCATION_TEXCOORD2`.
- `RL_DEFAULT_SHADER_ATTRIB_LOCATION_INDICES`: rlgl.h's `RL_DEFAULT_SHADER_ATTRIB_LOCATION_INDICES`.
- `RL_DEFAULT_SHADER_ATTRIB_LOCATION_BONEIDS`: rlgl.h's `RL_DEFAULT_SHADER_ATTRIB_LOCATION_BONEIDS`.
- `RL_DEFAULT_SHADER_ATTRIB_LOCATION_BONEWEIGHTS`: rlgl.h's `RL_DEFAULT_SHADER_ATTRIB_LOCATION_BONEWEIGHTS`.
- `PI`: rlgl.h's `PI`.

## rlgl: the matrix stack, immediate drawing and render state


```haxe
static function rlMatrixMode(mode:Int):Void
static function rlPushMatrix():Void
static function rlPopMatrix():Void
static function rlLoadIdentity():Void
static function rlTranslatef(x:Float, y:Float, z:Float):Void
static function rlRotatef(angle:Float, x:Float, y:Float, z:Float):Void
static function rlScalef(x:Float, y:Float, z:Float):Void
static function rlMultMatrixf(matf:Array<Float>):Void
static function rlOrtho(left:Float, right:Float, bottom:Float, top:Float, znear:Float, zfar:Float):Void
static function rlFrustum(left:Float, right:Float, bottom:Float, top:Float, znear:Float, zfar:Float):Void
static function rlGetMatrixModelview():Matrix
static function rlGetMatrixProjection():Matrix
static function rlGetMatrixTransform():Matrix
static function rlSetMatrixModelview(view:Matrix):Void
static function rlSetMatrixProjection(proj:Matrix):Void
static function rlGetCullDistanceNear():Float
static function rlGetCullDistanceFar():Float
static function rlBegin(mode:Int):Void
static function rlEnd():Void
static function rlVertex2i(x:Int, y:Int):Void
static function rlVertex2f(x:Float, y:Float):Void
static function rlVertex3f(x:Float, y:Float, z:Float):Void
static function rlTexCoord2f(x:Float, y:Float):Void
static function rlNormal3f(x:Float, y:Float, z:Float):Void
static function rlColor4ub(r:Int, g:Int, b:Int, a:Int):Void
static function rlColor3f(x:Float, y:Float, z:Float):Void
static function rlColor4f(x:Float, y:Float, z:Float, w:Float):Void
static function rlSetTexture(id:Int):Void
static function rlSetBlendMode(mode:Int):Void
static function rlSetBlendFactors(glSrcFactor:Int, glDstFactor:Int, glEquation:Int):Void
static function rlSetBlendFactorsSeparate(glSrcRGB:Int, glDstRGB:Int, glSrcAlpha:Int, glDstAlpha:Int, glEqRGB:Int, glEqAlpha:Int):Void
static function rlColorMask(r:Bool, g:Bool, b:Bool, a:Bool):Void
static function rlDrawRenderBatchActive():Void
static function rlCheckRenderBatchLimit(vCount:Int):Bool
static function rlEnableColorBlend():Void
static function rlDisableColorBlend():Void
static function rlEnableDepthTest():Void
static function rlDisableDepthTest():Void
static function rlEnableDepthMask():Void
static function rlDisableDepthMask():Void
static function rlEnableBackfaceCulling():Void
static function rlDisableBackfaceCulling():Void
static function rlSetCullFace(mode:Int):Void
static function rlEnableWireMode():Void
static function rlEnablePointMode():Void
static function rlDisableWireMode():Void
static function rlEnableScissorTest():Void
static function rlDisableScissorTest():Void
static function rlScissor(x:Int, y:Int, width:Int, height:Int):Void
static function rlViewport(x:Int, y:Int, width:Int, height:Int):Void
static function rlSetClipPlanes(nearPlane:Float, farPlane:Float):Void
static function rlClearColor(r:Int, g:Int, b:Int, a:Int):Void
static function rlClearScreenBuffers():Void
static function rlSetLineWidth(width:Float):Void
static function rlGetLineWidth():Float
static function rlEnableSmoothLines():Void
static function rlDisableSmoothLines():Void
static function rlSetFramebufferWidth(width:Int):Void
static function rlGetFramebufferWidth():Int
static function rlSetFramebufferHeight(height:Int):Void
static function rlGetFramebufferHeight():Int
static function rlGetPixelFormatName(format:Int):String
static function rlEnableStereoRender():Void
static function rlDisableStereoRender():Void
static function rlIsStereoRenderEnabled():Bool
static function rlGetMatrixProjectionStereo(eye:Int):Matrix
static function rlGetMatrixViewOffsetStereo(eye:Int):Matrix
static function rlSetMatrixProjectionStereo(right:Matrix, left:Matrix):Void
static function rlSetMatrixViewOffsetStereo(right:Matrix, left:Matrix):Void
```

- `rlMatrixMode`: Chooses the matrix the next matrix calls change.
  - `mode`: The matrix, `RL_MODELVIEW` or `RL_PROJECTION`. `RL_TEXTURE` changes nothing.

  `RL_MODELVIEW` is the view, or between `rlPushMatrix` and `rlPopMatrix` the transform the next vertices are moved by.

  `RL_PROJECTION` is the projection.
- `rlPushMatrix`: Saves the current matrix, to go back to with `rlPopMatrix`.
  In `RL_MODELVIEW`, the matrix calls until `rlPopMatrix` move the vertices drawn after them.

  At most 32 are saved at once. A push past them saves nothing, changes nothing and logs an error.
- `rlPopMatrix`: Goes back to the matrix last saved by `rlPushMatrix`.
- `rlLoadIdentity`: Makes the current matrix the identity.
- `rlTranslatef`: Moves by an offset before the current matrix.
  - `x`: The x offset.
  - `y`: The y offset.
  - `z`: The z offset.
- `rlRotatef`: Turns about an axis before the current matrix.
  - `angle`: The angle, in degrees.
  - `x`: The axis's x.
  - `y`: Its y.
  - `z`: Its z.
- `rlScalef`: Scales before the current matrix.
  - `x`: The x scale.
  - `y`: The y scale.
  - `z`: The z scale.
- `rlMultMatrixf`: Applies a matrix before the current one.
  - `matf`: The matrix's 16 numbers, by columns, as raylib's `MatrixToFloat` gives them.
- `rlOrtho`: Applies an orthographic projection before the current matrix.
  - `left`: The left plane.
  - `right`: The right plane.
  - `bottom`: The bottom plane.
  - `top`: The top plane.
  - `znear`: The near plane.
  - `zfar`: The far plane.
- `rlFrustum`: Applies a perspective projection before the current matrix, by its near plane's edges.
  - `left`: The near plane's left edge.
  - `right`: Its right edge.
  - `bottom`: Its bottom edge.
  - `top`: Its top edge.
  - `znear`: The near plane.
  - `zfar`: The far plane.
- `rlGetMatrixModelview`: Returns the view, which is the screen's, `BeginMode2D`'s or `BeginMode3D`'s.
  - returns: The matrix.
- `rlGetMatrixProjection`: Returns the projection.
  - returns: The matrix.
- `rlGetMatrixTransform`: Returns the transform `rlPushMatrix` started, or the identity when none is pushed.
  - returns: The matrix.
- `rlSetMatrixModelview`: Sets the view.
  - `view`: The matrix.
- `rlSetMatrixProjection`: Sets the projection.
  - `proj`: The matrix.
- `rlGetCullDistanceNear`: Returns the near distance cameras see from, 0.01 until `rlSetClipPlanes` sets it.
  - returns: The distance.
- `rlGetCullDistanceFar`: Returns the far distance cameras see to, 1000 until `rlSetClipPlanes` sets it.
  - returns: The distance.
- `rlBegin`: Starts adding vertices until `rlEnd`, each 2 a line, 3 a triangle or 4 a quad.
  - `mode`: `RL_LINES`, `RL_TRIANGLES` or `RL_QUADS`.

  A mode other than the last one's starts a new draw call, which takes the texture `rlSetTexture` last set and sets the white texture for the next. A second change of mode without another `rlSetTexture` then draws untextured.

  The same mode again keeps the draw call and its texture.
- `rlEnd`: Ends the vertices `rlBegin` started.
  A shape left short of its vertices isn't drawn.
- `rlVertex2i`: Adds a vertex, with the color, texture coordinate and normal set last.
  - `x`: The x.
  - `y`: The y.
- `rlVertex2f`: Adds a vertex, with the color, texture coordinate and normal set last.
  - `x`: The x.
  - `y`: The y.
- `rlVertex3f`: Adds a vertex, with the color, texture coordinate and normal set last.
  - `x`: The x.
  - `y`: The y.
  - `z`: The z.
- `rlTexCoord2f`: Sets the next vertices' texture coordinate.
  - `x`: The u.
  - `y`: The v.
- `rlNormal3f`: Sets the next vertices' normal, made length 1.
  - `x`: The x.
  - `y`: The y.
  - `z`: The z.

  The transform `rlPushMatrix` started, when there is one, turns the normal.
- `rlColor4ub`: Sets the next vertices' color.
  - `r`: The red, 0 to 255.
  - `g`: The green.
  - `b`: The blue.
  - `a`: The alpha.
- `rlColor3f`: Sets the next vertices' color, opaque.
  - `x`: The red, 0 to 1.
  - `y`: The green.
  - `z`: The blue.
- `rlColor4f`: Sets the next vertices' color.
  - `x`: The red, 0 to 1.
  - `y`: The green.
  - `z`: The blue.
  - `w`: The alpha.
- `rlSetTexture`: Sets the texture the next vertices draw with.
  - `id`: The texture's id (`Texture2D.id`), or 0 to keep the texture the next vertices have.

  The draw call the next change of mode (`rlBegin`) starts also draws with the texture.

  0 keeps the texture the next vertices have, and the next change of mode starts with the white texture.
- `rlSetBlendMode`: Sets how the next draws blend, as `BeginBlendMode` does.
  - `mode`: The mode (`RL_BLEND_*`, the same as `BLEND_*`).
- `rlSetBlendFactors`: Sets the GL factors and equation `RL_BLEND_CUSTOM` blends by, red, green, blue and alpha alike, as `glBlendFunc` and `glBlendEquation` take them. See `rlSetBlendFactorsSeparate` for blending color apart from alpha.
  - `glSrcFactor`: The source's factor (`RL_ZERO`, `RL_ONE`, `RL_SRC_COLOR`, ...).
  - `glDstFactor`: The destination's factor.
  - `glEquation`: How they combine (`RL_FUNC_ADD`, `RL_FUNC_SUBTRACT`, `RL_FUNC_REVERSE_SUBTRACT`, `RL_MIN`, `RL_MAX`).

  The factors take effect at the next `rlSetBlendMode(RL_BLEND_CUSTOM)`, even in that mode already.

  A value GL doesn't have leaves the factors, or the equation, unchanged.

  raylib sets no blend color, so `RL_CONSTANT_COLOR` and `RL_CONSTANT_ALPHA` are 0 and their `RL_ONE_MINUS_` forms 1.
- `rlSetBlendFactorsSeparate`: Sets the GL factors and equations `RL_BLEND_CUSTOM_SEPARATE` blends by, for red, green and blue apart from alpha, as `glBlendFuncSeparate` and `glBlendEquationSeparate` take them. See `rlSetBlendFactors` for blending every channel alike.
  - `glSrcRGB`: The source color's factor.
  - `glDstRGB`: The destination color's factor.
  - `glSrcAlpha`: The source alpha's factor.
  - `glDstAlpha`: The destination alpha's factor.
  - `glEqRGB`: How the colors combine.
  - `glEqAlpha`: How the alphas combine.

  The factors take effect at the next `rlSetBlendMode(RL_BLEND_CUSTOM_SEPARATE)`, even in that mode already.
- `rlColorMask`: Sets which color channels the next draws write, as `glColorMask` does.
  - `r`: Whether red is written.
  - `g`: Whether green is written.
  - `b`: Whether blue is written.
  - `a`: Whether alpha is written.

  The batch isn't drawn first, so the vertices waiting in it are masked too.

  `ClearBackground` clears every channel whatever the mask.
- `rlDrawRenderBatchActive`: Draws the vertices waiting in rlgl's batch now, with the state as it is.
  rlgl's state calls don't draw the batch, so a program calls this before and after changing one for the shapes between.

  A change of mode, shader, blending, scissor or pass also draws the batch.
- `rlCheckRenderBatchLimit`: Returns whether the next vertices would overflow rlgl's batch, which is never.
  - `vCount`: The vertices.
  - returns: False.

  The batch has no such limit and is drawn only as it is flushed (`rlDrawRenderBatchActive`).
- `rlEnableColorBlend`: Blends the next draws by the blend mode.
  On when raylib starts.

  The batch isn't drawn first, so the vertices waiting in it change too. See `rlDrawRenderBatchActive` for drawing them first.
- `rlDisableColorBlend`: Stops blending the next draws, so they replace what is drawn there.
  The batch isn't drawn first, so the vertices waiting in it change too. See `rlDrawRenderBatchActive` for drawing them first.
- `rlEnableDepthTest`: Tests the next draws' depth, keeping only what is as near as or nearer than what is drawn there.
  `BeginMode3D` turns the test on.

  The batch isn't drawn first, so the vertices waiting in it change too. See `rlDrawRenderBatchActive` for drawing them first.
- `rlDisableDepthTest`: Stops testing the next draws' depth.
  Off when raylib starts, and `EndMode3D` turns the test off.

  The batch isn't drawn first, so the vertices waiting in it change too. See `rlDrawRenderBatchActive` for drawing them first.
- `rlEnableDepthMask`: Lets the next draws that test depth write it.
  On when raylib starts.

  The batch isn't drawn first, so the vertices waiting in it change too. See `rlDrawRenderBatchActive` for drawing them first.
- `rlDisableDepthMask`: Stops the next draws writing depth, so what is drawn after isn't hidden by them.
  Used for drawing something see-through.

  The batch isn't drawn first, so the vertices waiting in it change too. See `rlDrawRenderBatchActive` for drawing them first.
- `rlEnableBackfaceCulling`: Leaves out the backs of the next triangles, or the fronts by `rlSetCullFace`.
  On when raylib starts.

  A triangle's front is the side from which its corners run counterclockwise.

  The batch isn't drawn first, so the vertices waiting in it change too. See `rlDrawRenderBatchActive` for drawing them first.
- `rlDisableBackfaceCulling`: Draws both sides of the next triangles.
  The batch isn't drawn first, so the vertices waiting in it change too. See `rlDrawRenderBatchActive` for drawing them first.
- `rlSetCullFace`: Chooses which side of triangles culling leaves out.
  - `mode`: The side, `RL_CULL_FACE_BACK` (the default) or `RL_CULL_FACE_FRONT`.

  The batch isn't drawn first, so the vertices waiting in it change too. See `rlDrawRenderBatchActive` for drawing them first.
- `rlEnableWireMode`: Draws triangles as their edges from now on, as GL's line mode does. See `rlEnablePointMode` for drawing their corners.
  A model drawn after the call is drawn so at once, and the shapes in rlgl's batch when the batch is next drawn (`rlDrawRenderBatchActive`).

  Works in a page too, the edges drawn as lines.

  Culling still leaves out the triangles GL would cull, by their facing on the screen. That facing ignores a shader that moves the vertices.

  Ends point mode.

  The batch isn't drawn first, so the vertices waiting in it change too. See `rlDrawRenderBatchActive` for drawing them first.
- `rlEnablePointMode`: Draws triangles as their corners from now on, one pixel each, as desktop GL's point mode does. See `rlEnableWireMode` for drawing their edges.
  A model drawn after the call is drawn so at once, each index of its triangles or, without indices, each vertex of its whole triangles. The triangles in rlgl's batch are drawn so when the batch is next drawn.

  Drawn as points on every backend, a page too.

  Lines are still drawn as lines.

  Culling still leaves out the triangles GL would cull, by their facing on the screen.

  A shader's own `gl_PointSize` is ignored. Every point is one pixel, the size every backend draws.

  `rlDisableWireMode` ends point mode, and `rlEnableWireMode` replaces it.

  The batch isn't drawn first, so the vertices waiting in it change too. See `rlDrawRenderBatchActive` for drawing them first.
- `rlDisableWireMode`: Draws the next triangles filled, ending wire mode or point mode.
  Filled when raylib starts.

  The batch isn't drawn first, so the vertices waiting in it change too. See `rlDrawRenderBatchActive` for drawing them first.
- `rlEnableScissorTest`: Clips the next draws to the rectangle `rlScissor` last set, or to the whole pass until one is set.
- `rlDisableScissorTest`: Stops clipping the next draws, as `EndScissorMode` does.
- `rlScissor`: Sets the rectangle that clips the next draws while the scissor test is on, in the framebuffer's pixels from its bottom left, as GL takes it. See `BeginScissorMode` for setting one from the top left in the screen's pixels.
  - `x`: Its left edge.
  - `y`: Its bottom edge, from the bottom.
  - `width`: Its width.
  - `height`: Its height.
- `rlViewport`: Sets the rectangle the next draws fill, as GL takes it, until the next pass begins.
  - `x`: Its left edge, in framebuffer pixels.
  - `y`: Its bottom edge, from the bottom.
  - `width`: Its width.
  - `height`: Its height.

  The next pass (`BeginDrawing`, `BeginTextureMode`, `EndTextureMode`) fills the whole framebuffer again.

  The projection is unchanged, so what is drawn is squeezed into the rectangle.
- `rlSetClipPlanes`: Sets the near and far distances for `BeginMode3D`'s cameras, and for the rays and projections of cameras after the call.
  - `nearPlane`: The near distance, 0.01 until set.
  - `farPlane`: The far distance, 1000 until set.
- `rlClearColor`: Sets the color `rlClearScreenBuffers` clears to.
  - `r`: Red, 0 to 255.
  - `g`: Green.
  - `b`: Blue.
  - `a`: Alpha.
- `rlClearScreenBuffers`: Clears the color and depth of what is drawn into, the color to `rlClearColor`'s, black until set. See `ClearBackground` for clearing to a given color.
- `rlSetLineWidth`: Sets the line width, which only `rlGetLineWidth` reads.
  - `width`: The width, in pixels.

  Lines stay 1 pixel wide on every target, the only width GL 3.3's core profile and WebGL draw.
- `rlGetLineWidth`: Returns the width `rlSetLineWidth` last set, 1 until then.
  - returns: The width.
- `rlEnableSmoothLines`: Asks for smoothed lines, which changes nothing on any target. See `FLAG_MSAA_4X_HINT` for smoothing every edge.
  GL 3.3's core profile and WebGL don't smooth lines.
- `rlDisableSmoothLines`: Stops asking for smoothed lines, which changes nothing on any target.
- `rlSetFramebufferWidth`: Sets the width rlgl records for the framebuffer drawn into, until the next pass begins.
  - `width`: The width, in pixels.

  Only `rlGetFramebufferWidth` reads the width. Drawing ignores it.

  `BeginTextureMode` and `EndTextureMode` set it too.
- `rlGetFramebufferWidth`: Returns the width of what is drawn into, or the width `rlSetFramebufferWidth` set since this pass began.
  - returns: The width.

  In `BeginTextureMode` the width is the render texture's. Otherwise it is the screen's, in framebuffer pixels.
- `rlSetFramebufferHeight`: Sets the height rlgl records for the framebuffer drawn into, until the next pass begins.
  - `height`: The height, in pixels.

  Only `rlGetFramebufferHeight` reads the height. Drawing ignores it.
- `rlGetFramebufferHeight`: Returns the height of what is drawn into, or the height `rlSetFramebufferHeight` set since this pass began, as `rlGetFramebufferWidth` returns the width.
  - returns: The height.
- `rlGetPixelFormatName`: Returns a pixel format's name as rlgl writes it in its log, such as "R8G8B8A8" for `RL_PIXELFORMAT_UNCOMPRESSED_R8G8B8A8`.
  - `format`: The format (`RL_PIXELFORMAT_*`).
  - returns: The name, or "UNKNOWN" for another number.
- `rlEnableStereoRender`: Turns stereo rendering on, drawing each flush of the batch and each mesh twice, once for each eye. See `BeginVrStereoMode` for turning stereo on with a config's matrices.
  Starts at the next flush of the batch, the vertices already waiting in it included, and at the next mesh drawn.

  Eye 0 is drawn in the left half of what is drawn into, through its view offset and projection (`rlSetMatrixViewOffsetStereo`, `rlSetMatrixProjectionStereo`). Eye 1 is drawn in the right half.

  After the batch the viewport is the whole again. After a mesh the viewport stays the right half.
- `rlDisableStereoRender`: Turns stereo rendering off, from the next flush of the batch and the next mesh drawn.
- `rlIsStereoRenderEnabled`: Returns whether stereo rendering is on (`rlEnableStereoRender`).
  - returns: True when it is.
- `rlGetMatrixProjectionStereo`: Returns an eye's projection in stereo rendering, as `rlSetMatrixProjectionStereo` set it.
  - `eye`: The eye: 0, drawn in the left half, or 1.
  - returns: The matrix.

  Zero until set, and for an eye other than 0 or 1.
- `rlGetMatrixViewOffsetStereo`: Returns an eye's view offset in stereo rendering, as `rlSetMatrixViewOffsetStereo` set it.
  - `eye`: The eye: 0, drawn in the left half, or 1.
  - returns: The matrix.

  Zero until set, and for an eye other than 0 or 1.
- `rlSetMatrixProjectionStereo`: Sets each eye's projection in stereo rendering, used in place of the projection from the batch's next flush.
  - `right`: Eye 0's projection, drawn in the left half (raylib names it the right).
  - `left`: Eye 1's, drawn in the right half.

  A mesh's mvp takes the eye's projection, while its `matProjection` stays the projection.
- `rlSetMatrixViewOffsetStereo`: Sets each eye's view offset in stereo rendering, applied after the view from the batch's next flush and in a mesh's mvp.
  - `right`: Eye 0's offset, drawn in the left half (raylib names it the right).
  - `left`: Eye 1's, drawn in the right half.

```haxe
static macro function rlEnableVertexArray(vaoId:Int):Bool
static macro function rlDisableVertexArray():Void
static macro function rlEnableVertexBuffer(id:Int):Void
static macro function rlDisableVertexBuffer():Void
static macro function rlEnableVertexBufferElement(id:Int):Void
static macro function rlDisableVertexBufferElement():Void
static macro function rlEnableVertexAttribute(index:Int):Void
static macro function rlDisableVertexAttribute(index:Int):Void
static macro function rlEnableStatePointer(vertexAttribType:Int, buffer:Dynamic):Void
static macro function rlDisableStatePointer(vertexAttribType:Int):Void
static macro function rlActiveTextureSlot(slot:Int):Void
static macro function rlEnableTexture(id:Int):Void
static macro function rlDisableTexture():Void
static macro function rlEnableTextureCubemap(id:Int):Void
static macro function rlDisableTextureCubemap():Void
static macro function rlTextureParameters(id:Int, param:Int, value:Int):Void
static macro function rlCubemapParameters(id:Int, param:Int, value:Int):Void
static macro function rlEnableShader(id:Int):Void
static macro function rlDisableShader():Void
static macro function rlEnableFramebuffer(id:Int):Void
static macro function rlDisableFramebuffer():Void
static macro function rlGetActiveFramebuffer():Int
static macro function rlActiveDrawBuffers(count:Int):Void
static macro function rlBlitFramebuffer(srcX:Int, srcY:Int, srcWidth:Int, srcHeight:Int, dstX:Int, dstY:Int, dstWidth:Int, dstHeight:Int, bufferMask:Int):Void
static macro function rlBindFramebuffer(target:Int, framebuffer:Int):Void
static macro function rlCheckErrors():Void
static macro function rlglInit(width:Int, height:Int):Void
static macro function rlglClose():Void
static macro function rlLoadExtensions(loader:Dynamic):Void
static macro function rlGetVersion():Int
static macro function rlGetTextureIdDefault():Int
static macro function rlGetShaderIdDefault():Int
static macro function rlGetShaderLocsDefault():Array<Int>
static macro function rlLoadRenderBatch(numBuffers:Int, bufferElements:Int):Dynamic
static macro function rlUnloadRenderBatch(batch:Dynamic):Void
static macro function rlDrawRenderBatch(batch:Dynamic):Void
static macro function rlSetRenderBatchActive(batch:Dynamic):Void
static macro function rlLoadVertexArray():Int
static macro function rlLoadVertexBuffer(buffer:Dynamic, size:Int, isDynamic:Bool):Int
static macro function rlLoadVertexBufferElement(buffer:Dynamic, size:Int, isDynamic:Bool):Int
static macro function rlUpdateVertexBuffer(bufferId:Int, data:Dynamic, dataSize:Int, offset:Int):Void
static macro function rlUpdateVertexBufferElements(id:Int, data:Dynamic, dataSize:Int, offset:Int):Void
static macro function rlUnloadVertexArray(vaoId:Int):Void
static macro function rlUnloadVertexBuffer(vboId:Int):Void
static macro function rlSetVertexAttribute(index:Int, compSize:Int, type:Int, normalized:Bool, stride:Int, offset:Int):Void
static macro function rlSetVertexAttributeDivisor(index:Int, divisor:Int):Void
static macro function rlSetVertexAttributeDefault(locIndex:Int, value:Dynamic, attribType:Int, count:Int):Void
static macro function rlDrawVertexArray(offset:Int, count:Int):Void
static macro function rlDrawVertexArrayElements(offset:Int, count:Int, buffer:Dynamic):Void
static macro function rlDrawVertexArrayInstanced(offset:Int, count:Int, instances:Int):Void
static macro function rlDrawVertexArrayElementsInstanced(offset:Int, count:Int, buffer:Dynamic, instances:Int):Void
static macro function rlLoadTexture(data:Dynamic, width:Int, height:Int, format:Int, mipmapCount:Int):Int
static macro function rlLoadTextureDepth(width:Int, height:Int, useRenderBuffer:Bool):Int
static macro function rlLoadTextureCubemap(data:Dynamic, size:Int, format:Int, mipmapCount:Int):Int
static macro function rlUpdateTexture(id:Int, offsetX:Int, offsetY:Int, width:Int, height:Int, format:Int, data:Dynamic):Void
static macro function rlGetGlTextureFormats(format:Int, glInternalFormat:Array<Int>, glFormat:Array<Int>, glType:Array<Int>):Void
static macro function rlUnloadTexture(id:Int):Void
static macro function rlGenTextureMipmaps(id:Int, width:Int, height:Int, format:Int, mipmaps:Array<Int>):Void
static macro function rlReadTexturePixels(id:Int, width:Int, height:Int, format:Int):Dynamic
static macro function rlReadScreenPixels(width:Int, height:Int):haxe.io.Bytes
static macro function rlLoadFramebuffer():Int
static macro function rlFramebufferAttach(fboId:Int, texId:Int, attachType:Int, texType:Int, mipLevel:Int):Void
static macro function rlFramebufferComplete(id:Int):Bool
static macro function rlUnloadFramebuffer(id:Int):Void
static macro function rlLoadShaderCode(vsCode:String, fsCode:String):Int
static macro function rlCompileShader(shaderCode:String, type:Int):Int
static macro function rlLoadShaderProgram(vShaderId:Int, fShaderId:Int):Int
static macro function rlUnloadShaderProgram(id:Int):Void
static macro function rlGetLocationUniform(shaderId:Int, uniformName:String):Int
static macro function rlGetLocationAttrib(shaderId:Int, attribName:String):Int
static macro function rlSetUniform(locIndex:Int, value:Dynamic, uniformType:Int, count:Int):Void
static macro function rlSetUniformMatrix(locIndex:Int, mat:Matrix):Void
static macro function rlSetUniformMatrices(locIndex:Int, mat:Array<Matrix>, count:Int):Void
static macro function rlSetUniformSampler(locIndex:Int, textureId:Int):Void
static macro function rlSetShader(id:Int, locs:Array<Int>):Void
static macro function rlLoadComputeShaderProgram(shaderId:Int):Int
static macro function rlComputeShaderDispatch(groupX:Int, groupY:Int, groupZ:Int):Void
static macro function rlLoadShaderBuffer(size:Int, data:Dynamic, usageHint:Int):Int
static macro function rlUnloadShaderBuffer(ssboId:Int):Void
static macro function rlUpdateShaderBuffer(id:Int, data:Dynamic, dataSize:Int, offset:Int):Void
static macro function rlBindShaderBuffer(id:Int, index:Int):Void
static macro function rlReadShaderBuffer(id:Int, dest:Dynamic, count:Int, offset:Int):Void
static macro function rlCopyShaderBuffer(destId:Int, srcId:Int, destOffset:Int, srcOffset:Int, count:Int):Void
static macro function rlGetShaderBufferSize(id:Int):Int
static macro function rlBindImageTexture(id:Int, index:Int, format:Int, readonly:Bool):Void
static macro function rlLoadDrawCube():Void
static macro function rlLoadDrawQuad():Void
```

- `rlEnableVertexArray`: Refuses to compile on every target, replacing rlgl's `rlEnableVertexArray` (enabling a vertex array). See `UploadMesh` for uploading a mesh and `DrawMesh` for drawing one.
- `rlDisableVertexArray`: Refuses to compile on every target, replacing rlgl's `rlDisableVertexArray` (disabling a vertex array). See `UploadMesh` for uploading a mesh and `DrawMesh` for drawing one.
- `rlEnableVertexBuffer`: Refuses to compile on every target, replacing rlgl's `rlEnableVertexBuffer` (enabling a vertex buffer). See `UploadMesh` for uploading a mesh and `DrawMesh` for drawing one.
- `rlDisableVertexBuffer`: Refuses to compile on every target, replacing rlgl's `rlDisableVertexBuffer` (disabling a vertex buffer). See `UploadMesh` for uploading a mesh and `DrawMesh` for drawing one.
- `rlEnableVertexBufferElement`: Refuses to compile on every target, replacing rlgl's `rlEnableVertexBufferElement` (enabling an element buffer). See `UploadMesh` for uploading a mesh and `DrawMesh` for drawing one.
- `rlDisableVertexBufferElement`: Refuses to compile on every target, replacing rlgl's `rlDisableVertexBufferElement` (disabling an element buffer). See `UploadMesh` for uploading a mesh and `DrawMesh` for drawing one.
- `rlEnableVertexAttribute`: Refuses to compile on every target, replacing rlgl's `rlEnableVertexAttribute` (enabling a vertex attribute). See `UploadMesh` for uploading a mesh and `DrawMesh` for drawing one.
- `rlDisableVertexAttribute`: Refuses to compile on every target, replacing rlgl's `rlDisableVertexAttribute` (disabling a vertex attribute). See `UploadMesh` for uploading a mesh and `DrawMesh` for drawing one.
- `rlEnableStatePointer`: Refuses to compile on every target, replacing rlgl's `rlEnableStatePointer` (enabling an attribute state pointer). See `UploadMesh` for uploading a mesh and `DrawMesh` for drawing one.
- `rlDisableStatePointer`: Refuses to compile on every target, replacing rlgl's `rlDisableStatePointer` (disabling an attribute state pointer). See `UploadMesh` for uploading a mesh and `DrawMesh` for drawing one.
- `rlActiveTextureSlot`: Refuses to compile on every target, replacing rlgl's `rlActiveTextureSlot` (choosing a texture slot). See `LoadTextureFromImage` for making a texture and `rlSetTexture` for drawing vertices with one.
- `rlEnableTexture`: Refuses to compile on every target, replacing rlgl's `rlEnableTexture` (binding a texture). See `LoadTextureFromImage` for making a texture and `rlSetTexture` for drawing vertices with one.
- `rlDisableTexture`: Refuses to compile on every target, replacing rlgl's `rlDisableTexture` (unbinding the texture). See `LoadTextureFromImage` for making a texture and `rlSetTexture` for drawing vertices with one.
- `rlEnableTextureCubemap`: Refuses to compile on every target, replacing rlgl's `rlEnableTextureCubemap` (binding a cubemap). See `LoadTextureFromImage` for making a texture and `rlSetTexture` for drawing vertices with one.
- `rlDisableTextureCubemap`: Refuses to compile on every target, replacing rlgl's `rlDisableTextureCubemap` (unbinding the cubemap). See `LoadTextureFromImage` for making a texture and `rlSetTexture` for drawing vertices with one.
- `rlTextureParameters`: Refuses to compile on every target, replacing rlgl's `rlTextureParameters` (setting a texture's filter or wrap). See `LoadTextureFromImage` for making a texture and `rlSetTexture` for drawing vertices with one.
- `rlCubemapParameters`: Refuses to compile on every target, replacing rlgl's `rlCubemapParameters` (setting a cubemap's filter or wrap). See `LoadTextureFromImage` for making a texture and `rlSetTexture` for drawing vertices with one.
- `rlEnableShader`: Refuses to compile on every target, replacing rlgl's `rlEnableShader` (binding a shader program). See `LoadCompiledShaderAsync` for making a shader and `BeginShaderMode` for drawing with one.
- `rlDisableShader`: Refuses to compile on every target, replacing rlgl's `rlDisableShader` (unbinding the shader program). See `LoadCompiledShaderAsync` for making a shader and `BeginShaderMode` for drawing with one.
- `rlEnableFramebuffer`: Refuses to compile on every target, replacing rlgl's `rlEnableFramebuffer` (binding a framebuffer). See `LoadRenderTexture` for making a render texture and `BeginTextureMode` for drawing into one.
- `rlDisableFramebuffer`: Refuses to compile on every target, replacing rlgl's `rlDisableFramebuffer` (going back to the default framebuffer). See `LoadRenderTexture` for making a render texture and `BeginTextureMode` for drawing into one.
- `rlGetActiveFramebuffer`: Refuses to compile on every target, replacing rlgl's `rlGetActiveFramebuffer` (getting the bound framebuffer). See `LoadRenderTexture` for making a render texture and `BeginTextureMode` for drawing into one.
- `rlActiveDrawBuffers`: Refuses to compile on every target, replacing rlgl's `rlActiveDrawBuffers` (choosing several color buffers to draw into). See `LoadRenderTexture` for making a render texture and `BeginTextureMode` for drawing into one.
- `rlBlitFramebuffer`: Refuses to compile on every target, replacing rlgl's `rlBlitFramebuffer` (copying the bound framebuffer to the main one). See `LoadRenderTexture` for making a render texture and `BeginTextureMode` for drawing into one.
- `rlBindFramebuffer`: Refuses to compile on every target, replacing rlgl's `rlBindFramebuffer` (binding a framebuffer to a target). See `LoadRenderTexture` for making a render texture and `BeginTextureMode` for drawing into one.
- `rlCheckErrors`: Refuses to compile on every target, replacing rlgl's `rlCheckErrors` (logging OpenGL's error codes). See `InitWindow` for setting up what helix-raylib draws with.
- `rlglInit`: Refuses to compile on every target, replacing rlgl's `rlglInit` (setting up rlgl's buffers, shaders, textures and state). See `InitWindow` for setting up what helix-raylib draws with.
- `rlglClose`: Refuses to compile on every target, replacing rlgl's `rlglClose` (closing rlgl's buffers, shaders and textures). See `InitWindow` for setting up what helix-raylib draws with.
- `rlLoadExtensions`: Refuses to compile on every target, replacing rlgl's `rlLoadExtensions` (loading OpenGL's extensions). See `InitWindow` for setting up what helix-raylib draws with.
- `rlGetVersion`: Refuses to compile on every target, replacing rlgl's `rlGetVersion` (getting the OpenGL version). See `InitWindow` for setting up what helix-raylib draws with.
- `rlGetTextureIdDefault`: Refuses to compile on every target, replacing rlgl's `rlGetTextureIdDefault` (getting the default texture's id). See `LoadTextureFromImage` for making a texture and `rlSetTexture` for drawing vertices with one.
- `rlGetShaderIdDefault`: Refuses to compile on every target, replacing rlgl's `rlGetShaderIdDefault` (getting the default shader's id). See `LoadCompiledShaderAsync` for making a shader and `BeginShaderMode` for drawing with one.
- `rlGetShaderLocsDefault`: Refuses to compile on every target, replacing rlgl's `rlGetShaderLocsDefault` (getting the default shader's locations). See `LoadShader` for making a shader and `BeginShaderMode` for drawing with one.
- `rlLoadRenderBatch`: Refuses to compile on every target, replacing rlgl's `rlLoadRenderBatch` (making a render batch). See `rlDrawRenderBatchActive` for drawing the frame's one batch.
- `rlUnloadRenderBatch`: Refuses to compile on every target, replacing rlgl's `rlUnloadRenderBatch` (unloading a render batch). See `rlDrawRenderBatchActive` for drawing the frame's one batch.
- `rlDrawRenderBatch`: Refuses to compile on every target, replacing rlgl's `rlDrawRenderBatch` (drawing a render batch). See `rlDrawRenderBatchActive` for drawing the frame's one batch.
- `rlSetRenderBatchActive`: Refuses to compile on every target, replacing rlgl's `rlSetRenderBatchActive` (choosing the render batch rlgl adds to). See `rlDrawRenderBatchActive` for drawing the frame's one batch.
- `rlLoadVertexArray`: Refuses to compile on every target, replacing rlgl's `rlLoadVertexArray` (making a vertex array). See `UploadMesh` for uploading a mesh and `DrawMesh` for drawing one.
- `rlLoadVertexBuffer`: Refuses to compile on every target, replacing rlgl's `rlLoadVertexBuffer` (making a vertex buffer). See `UploadMesh` for uploading a mesh and `DrawMesh` for drawing one.
- `rlLoadVertexBufferElement`: Refuses to compile on every target, replacing rlgl's `rlLoadVertexBufferElement` (making an element buffer). See `UploadMesh` for uploading a mesh and `DrawMesh` for drawing one.
- `rlUpdateVertexBuffer`: Refuses to compile on every target, replacing rlgl's `rlUpdateVertexBuffer` (updating a vertex buffer's data). See `UploadMesh` for uploading a mesh and `DrawMesh` for drawing one.
- `rlUpdateVertexBufferElements`: Refuses to compile on every target, replacing rlgl's `rlUpdateVertexBufferElements` (updating an element buffer's data). See `UploadMesh` for uploading a mesh and `DrawMesh` for drawing one.
- `rlUnloadVertexArray`: Refuses to compile on every target, replacing rlgl's `rlUnloadVertexArray` (unloading a vertex array). See `UploadMesh` for uploading a mesh and `DrawMesh` for drawing one.
- `rlUnloadVertexBuffer`: Refuses to compile on every target, replacing rlgl's `rlUnloadVertexBuffer` (unloading a vertex buffer). See `UploadMesh` for uploading a mesh and `DrawMesh` for drawing one.
- `rlSetVertexAttribute`: Refuses to compile on every target, replacing rlgl's `rlSetVertexAttribute` (setting a vertex attribute's layout). See `UploadMesh` for uploading a mesh and `DrawMesh` for drawing one.
- `rlSetVertexAttributeDivisor`: Refuses to compile on every target, replacing rlgl's `rlSetVertexAttributeDivisor` (setting a vertex attribute's divisor). See `UploadMesh` for uploading a mesh and `DrawMesh` for drawing one.
- `rlSetVertexAttributeDefault`: Refuses to compile on every target, replacing rlgl's `rlSetVertexAttributeDefault` (setting a vertex attribute's default value). See `UploadMesh` for uploading a mesh and `DrawMesh` for drawing one.
- `rlDrawVertexArray`: Refuses to compile on every target, replacing rlgl's `rlDrawVertexArray` (drawing the bound vertex array). See `UploadMesh` for uploading a mesh and `DrawMesh` for drawing one.
- `rlDrawVertexArrayElements`: Refuses to compile on every target, replacing rlgl's `rlDrawVertexArrayElements` (drawing the bound vertex array's elements). See `UploadMesh` for uploading a mesh and `DrawMesh` for drawing one.
- `rlDrawVertexArrayInstanced`: Refuses to compile on every target, replacing rlgl's `rlDrawVertexArrayInstanced` (drawing instances of the bound vertex array). See `UploadMesh` for uploading a mesh and `DrawMesh` for drawing one.
- `rlDrawVertexArrayElementsInstanced`: Refuses to compile on every target, replacing rlgl's `rlDrawVertexArrayElementsInstanced` (drawing instances of the bound vertex array's elements). See `UploadMesh` for uploading a mesh and `DrawMesh` for drawing one.
- `rlLoadTexture`: Refuses to compile on every target, replacing rlgl's `rlLoadTexture` (making a texture from data). See `LoadTextureFromImage` for making a texture and `rlSetTexture` for drawing vertices with one.
- `rlLoadTextureDepth`: Refuses to compile on every target, replacing rlgl's `rlLoadTextureDepth` (making a depth texture or renderbuffer). See `LoadTextureFromImage` for making a texture and `rlSetTexture` for drawing vertices with one.
- `rlLoadTextureCubemap`: Refuses to compile on every target, replacing rlgl's `rlLoadTextureCubemap` (making a cubemap from data). See `LoadTextureFromImage` for making a texture and `rlSetTexture` for drawing vertices with one.
- `rlUpdateTexture`: Refuses to compile on every target, replacing rlgl's `rlUpdateTexture` (updating a texture's pixels). See `LoadTextureFromImage` for making a texture and `rlSetTexture` for drawing vertices with one.
- `rlGetGlTextureFormats`: Refuses to compile on every target, replacing rlgl's `rlGetGlTextureFormats` (getting a format's OpenGL formats). See `LoadTextureFromImage` for making a texture and `rlSetTexture` for drawing vertices with one.
- `rlUnloadTexture`: Refuses to compile on every target, replacing rlgl's `rlUnloadTexture` (unloading a texture). See `LoadTextureFromImage` for making a texture and `rlSetTexture` for drawing vertices with one.
- `rlGenTextureMipmaps`: Refuses to compile on every target, replacing rlgl's `rlGenTextureMipmaps` (making a texture's mipmaps). See `LoadTextureFromImage` for making a texture and `rlSetTexture` for drawing vertices with one.
- `rlReadTexturePixels`: Refuses to compile on every target, replacing rlgl's `rlReadTexturePixels` (reading a texture's pixels). See `LoadTextureFromImage` for making a texture and `rlSetTexture` for drawing vertices with one.
- `rlReadScreenPixels`: Refuses to compile on every target, replacing rlgl's `rlReadScreenPixels` (reading the screen's pixels). See `LoadRenderTexture` for making a render texture and `BeginTextureMode` for drawing into one.
- `rlLoadFramebuffer`: Refuses to compile on every target, replacing rlgl's `rlLoadFramebuffer` (making an empty framebuffer). See `LoadRenderTexture` for making a render texture and `BeginTextureMode` for drawing into one.
- `rlFramebufferAttach`: Refuses to compile on every target, replacing rlgl's `rlFramebufferAttach` (attaching a texture or renderbuffer to a framebuffer). See `LoadRenderTexture` for making a render texture and `BeginTextureMode` for drawing into one.
- `rlFramebufferComplete`: Refuses to compile on every target, replacing rlgl's `rlFramebufferComplete` (checking whether a framebuffer is complete). See `LoadRenderTexture` for making a render texture and `BeginTextureMode` for drawing into one.
- `rlUnloadFramebuffer`: Refuses to compile on every target, replacing rlgl's `rlUnloadFramebuffer` (unloading a framebuffer). See `LoadRenderTexture` for making a render texture and `BeginTextureMode` for drawing into one.
- `rlLoadShaderCode`: Refuses to compile on every target, replacing rlgl's `rlLoadShaderCode` (making a shader from source). See `LoadCompiledShaderAsync` for making a shader and `BeginShaderMode` for drawing with one.
- `rlCompileShader`: Refuses to compile on every target, replacing rlgl's `rlCompileShader` (compiling one stage of a shader). See `LoadCompiledShaderAsync` for making a shader and `BeginShaderMode` for drawing with one.
- `rlLoadShaderProgram`: Refuses to compile on every target, replacing rlgl's `rlLoadShaderProgram` (linking a shader program). See `LoadCompiledShaderAsync` for making a shader and `BeginShaderMode` for drawing with one.
- `rlUnloadShaderProgram`: Refuses to compile on every target, replacing rlgl's `rlUnloadShaderProgram` (unloading a shader program). See `LoadCompiledShaderAsync` for making a shader and `BeginShaderMode` for drawing with one.
- `rlGetLocationUniform`: Refuses to compile on every target, replacing rlgl's `rlGetLocationUniform` (finding a uniform's location). See `LoadCompiledShaderAsync` for making a shader and `BeginShaderMode` for drawing with one.
- `rlGetLocationAttrib`: Refuses to compile on every target, replacing rlgl's `rlGetLocationAttrib` (finding an attribute's location). See `LoadCompiledShaderAsync` for making a shader and `BeginShaderMode` for drawing with one.
- `rlSetUniform`: Refuses to compile on every target, replacing rlgl's `rlSetUniform` (setting a uniform's value). See `LoadCompiledShaderAsync` for making a shader and `BeginShaderMode` for drawing with one.
- `rlSetUniformMatrix`: Refuses to compile on every target, replacing rlgl's `rlSetUniformMatrix` (setting a matrix uniform). See `LoadCompiledShaderAsync` for making a shader and `BeginShaderMode` for drawing with one.
- `rlSetUniformMatrices`: Refuses to compile on every target, replacing rlgl's `rlSetUniformMatrices` (setting an array of matrix uniforms). See `LoadShader` for making a shader and `BeginShaderMode` for drawing with one.
- `rlSetUniformSampler`: Refuses to compile on every target, replacing rlgl's `rlSetUniformSampler` (setting a sampler uniform). See `LoadCompiledShaderAsync` for making a shader and `BeginShaderMode` for drawing with one.
- `rlSetShader`: Refuses to compile on every target, replacing rlgl's `rlSetShader` (choosing the shader rlgl draws with). See `LoadCompiledShaderAsync` for making a shader and `BeginShaderMode` for drawing with one.
- `rlLoadComputeShaderProgram`: Refuses to compile on every target, replacing rlgl's `rlLoadComputeShaderProgram` (making a compute shader program). No target has compute shaders or shader storage buffers, as WebGL2 has none.
- `rlComputeShaderDispatch`: Refuses to compile on every target, replacing rlgl's `rlComputeShaderDispatch` (running a compute shader). No target has compute shaders or shader storage buffers, as WebGL2 has none.
- `rlLoadShaderBuffer`: Refuses to compile on every target, replacing rlgl's `rlLoadShaderBuffer` (making a shader storage buffer). No target has compute shaders or shader storage buffers, as WebGL2 has none.
- `rlUnloadShaderBuffer`: Refuses to compile on every target, replacing rlgl's `rlUnloadShaderBuffer` (unloading a shader storage buffer). No target has compute shaders or shader storage buffers, as WebGL2 has none.
- `rlUpdateShaderBuffer`: Refuses to compile on every target, replacing rlgl's `rlUpdateShaderBuffer` (updating a shader storage buffer's data). No target has compute shaders or shader storage buffers, as WebGL2 has none.
- `rlBindShaderBuffer`: Refuses to compile on every target, replacing rlgl's `rlBindShaderBuffer` (binding a shader storage buffer). No target has compute shaders or shader storage buffers, as WebGL2 has none.
- `rlReadShaderBuffer`: Refuses to compile on every target, replacing rlgl's `rlReadShaderBuffer` (reading a shader storage buffer's data). No target has compute shaders or shader storage buffers, as WebGL2 has none.
- `rlCopyShaderBuffer`: Refuses to compile on every target, replacing rlgl's `rlCopyShaderBuffer` (copying between shader storage buffers). No target has compute shaders or shader storage buffers, as WebGL2 has none.
- `rlGetShaderBufferSize`: Refuses to compile on every target, replacing rlgl's `rlGetShaderBufferSize` (getting a shader storage buffer's size). No target has compute shaders or shader storage buffers, as WebGL2 has none.
- `rlBindImageTexture`: Refuses to compile on every target, replacing rlgl's `rlBindImageTexture` (binding an image texture). See `LoadTextureFromImage` for making a texture and `rlSetTexture` for drawing vertices with one.
- `rlLoadDrawCube`: Refuses to compile on every target, replacing rlgl's `rlLoadDrawCube` (drawing a cube). See `InitWindow` for setting up what helix-raylib draws with.
- `rlLoadDrawQuad`: Refuses to compile on every target, replacing rlgl's `rlLoadDrawQuad` (drawing a quad). See `InitWindow` for setting up what helix-raylib draws with.
