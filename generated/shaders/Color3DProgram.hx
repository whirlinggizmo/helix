// Generated from structured shader reflection and shaders.json: the color3d program.
class Color3DProgram {
 public static inline var stride=28;
 public static inline var instanceStride=0;
 public static inline var skinStride=0;
 public static inline var vertexUniformBytes=64;
 public static inline var positionSlot=0;
 public static inline var positionOffset=0;
 public static inline var positionComponents=3;
 public static inline var colorSlot=1;
 public static inline var colorOffset=12;
 public static inline var colorComponents=4;
 /** The program, as IGraphics.createShader takes it: with SDL_GPU's dialects in builds defining helix_sdl3_gpu, and in a browser build
  (the webgl2 backend) only the GLSL ES it reads. */
 public static function source():helix.graphics.ShaderSource
  #if helix_sdl3_gpu
  return {attributes: ["position", "color"], glsl410: {vertex: "#version 410\n\nuniform vec4 color3d_params[4];\nlayout(location = 0) in vec3 position;\nlayout(location = 0) out vec4 tint;\nlayout(location = 1) in vec4 color;\n\nvoid main()\n{\n    gl_Position = mat4(color3d_params[0], color3d_params[1], color3d_params[2], color3d_params[3]) * vec4(position, 1.0);\n    tint = color;\n}\n\n", fragment: "#version 410\n\nlayout(location = 0) out vec4 fragColor;\nlayout(location = 0) in vec4 tint;\n\nvoid main()\n{\n    fragColor = tint;\n}\n\n"}, glsl300es: {vertex: "#version 300 es\n\nuniform vec4 color3d_params[4];\nlayout(location = 0) in vec3 position;\nout vec4 tint;\nlayout(location = 1) in vec4 color;\n\nvoid main()\n{\n    gl_Position = mat4(color3d_params[0], color3d_params[1], color3d_params[2], color3d_params[3]) * vec4(position, 1.0);\n    tint = color;\n}\n\n", fragment: "#version 300 es\nprecision mediump float;\nprecision highp int;\n\nlayout(location = 0) out highp vec4 fragColor;\nin highp vec4 tint;\n\nvoid main()\n{\n    fragColor = tint;\n}\n\n"}, uniformBlocks: [{slot: 0, stage: "vertex", size: 64, glslName: "color3d_params", vec4Count: 4}], textures: [], sdlGpu: Color3DSdlGpu.stages()};
  #elseif (helix_backend == "webgl2")
  return {attributes: ["position", "color"], glsl300es: {vertex: "#version 300 es\n\nuniform vec4 color3d_params[4];\nlayout(location = 0) in vec3 position;\nout vec4 tint;\nlayout(location = 1) in vec4 color;\n\nvoid main()\n{\n    gl_Position = mat4(color3d_params[0], color3d_params[1], color3d_params[2], color3d_params[3]) * vec4(position, 1.0);\n    tint = color;\n}\n\n", fragment: "#version 300 es\nprecision mediump float;\nprecision highp int;\n\nlayout(location = 0) out highp vec4 fragColor;\nin highp vec4 tint;\n\nvoid main()\n{\n    fragColor = tint;\n}\n\n"}, uniformBlocks: [{slot: 0, stage: "vertex", size: 64, glslName: "color3d_params", vec4Count: 4}], textures: []};
  #else
  return {attributes: ["position", "color"], glsl410: {vertex: "#version 410\n\nuniform vec4 color3d_params[4];\nlayout(location = 0) in vec3 position;\nlayout(location = 0) out vec4 tint;\nlayout(location = 1) in vec4 color;\n\nvoid main()\n{\n    gl_Position = mat4(color3d_params[0], color3d_params[1], color3d_params[2], color3d_params[3]) * vec4(position, 1.0);\n    tint = color;\n}\n\n", fragment: "#version 410\n\nlayout(location = 0) out vec4 fragColor;\nlayout(location = 0) in vec4 tint;\n\nvoid main()\n{\n    fragColor = tint;\n}\n\n"}, glsl300es: {vertex: "#version 300 es\n\nuniform vec4 color3d_params[4];\nlayout(location = 0) in vec3 position;\nout vec4 tint;\nlayout(location = 1) in vec4 color;\n\nvoid main()\n{\n    gl_Position = mat4(color3d_params[0], color3d_params[1], color3d_params[2], color3d_params[3]) * vec4(position, 1.0);\n    tint = color;\n}\n\n", fragment: "#version 300 es\nprecision mediump float;\nprecision highp int;\n\nlayout(location = 0) out highp vec4 fragColor;\nin highp vec4 tint;\n\nvoid main()\n{\n    fragColor = tint;\n}\n\n"}, uniformBlocks: [{slot: 0, stage: "vertex", size: 64, glslName: "color3d_params", vec4Count: 4}], textures: []};
  #end
 /** Its vertex buffers by index (0 the vertices, 1 the instance records, 2 a skin's joints), as a PipelineDesc takes them. */
 public static function buffers():Array<helix.graphics.PipelineDesc.VertexBuffer>
  return [{stride: 28, instanced: false, attributes: [{slot: 0, componentCount: 3, offset: 0}, {slot: 1, componentCount: 4, offset: 12}]}];
}
