// Generated from structured shader reflection and shaders.json: the depth3d program.
class Depth3DProgram {
 public static inline var stride=48;
 public static inline var instanceStride=48;
 public static inline var skinStride=0;
 public static inline var vertexUniformBytes=64;
 public static inline var positionSlot=0;
 public static inline var positionOffset=0;
 public static inline var positionComponents=3;
 public static inline var model0Slot=1;
 public static inline var model0Offset=0;
 public static inline var model0Components=4;
 public static inline var model1Slot=2;
 public static inline var model1Offset=16;
 public static inline var model1Components=4;
 public static inline var model2Slot=3;
 public static inline var model2Offset=32;
 public static inline var model2Components=4;
 /** The program, as IGraphics.createShader takes it: with SDL_GPU's dialects in builds defining helix_sdl3_gpu, and in a browser build
  (the webgl2 backend) only the GLSL ES it reads. */
 public static function source():helix.graphics.ShaderSource
  #if helix_sdl3_gpu
  return {attributes: ["position", "i_model0", "i_model1", "i_model2"], glsl410: {vertex: "#version 410\n\nuniform vec4 depth3d_vs_params[4];\nlayout(location = 0) in vec3 position;\nlayout(location = 1) in vec4 i_model0;\nlayout(location = 2) in vec4 i_model1;\nlayout(location = 3) in vec4 i_model2;\n\nvoid main()\n{\n    vec4 _18 = vec4(position, 1.0);\n    gl_Position = mat4(depth3d_vs_params[0], depth3d_vs_params[1], depth3d_vs_params[2], depth3d_vs_params[3]) * vec4(dot(i_model0, _18), dot(i_model1, _18), dot(i_model2, _18), 1.0);\n}\n\n", fragment: "#version 410\n\nvoid main()\n{\n}\n\n"}, glsl300es: {vertex: "#version 300 es\n\nuniform vec4 depth3d_vs_params[4];\nlayout(location = 0) in vec3 position;\nlayout(location = 1) in vec4 i_model0;\nlayout(location = 2) in vec4 i_model1;\nlayout(location = 3) in vec4 i_model2;\n\nvoid main()\n{\n    vec4 _18 = vec4(position, 1.0);\n    gl_Position = mat4(depth3d_vs_params[0], depth3d_vs_params[1], depth3d_vs_params[2], depth3d_vs_params[3]) * vec4(dot(i_model0, _18), dot(i_model1, _18), dot(i_model2, _18), 1.0);\n}\n\n", fragment: "#version 300 es\nprecision mediump float;\nprecision highp int;\n\nvoid main()\n{\n}\n\n"}, uniformBlocks: [{slot: 0, stage: "vertex", size: 64, glslName: "depth3d_vs_params", vec4Count: 4}], textures: [], sdlGpu: Depth3DSdlGpu.stages()};
  #elseif (helix_backend == "webgl2")
  return {attributes: ["position", "i_model0", "i_model1", "i_model2"], glsl300es: {vertex: "#version 300 es\n\nuniform vec4 depth3d_vs_params[4];\nlayout(location = 0) in vec3 position;\nlayout(location = 1) in vec4 i_model0;\nlayout(location = 2) in vec4 i_model1;\nlayout(location = 3) in vec4 i_model2;\n\nvoid main()\n{\n    vec4 _18 = vec4(position, 1.0);\n    gl_Position = mat4(depth3d_vs_params[0], depth3d_vs_params[1], depth3d_vs_params[2], depth3d_vs_params[3]) * vec4(dot(i_model0, _18), dot(i_model1, _18), dot(i_model2, _18), 1.0);\n}\n\n", fragment: "#version 300 es\nprecision mediump float;\nprecision highp int;\n\nvoid main()\n{\n}\n\n"}, uniformBlocks: [{slot: 0, stage: "vertex", size: 64, glslName: "depth3d_vs_params", vec4Count: 4}], textures: []};
  #else
  return {attributes: ["position", "i_model0", "i_model1", "i_model2"], glsl410: {vertex: "#version 410\n\nuniform vec4 depth3d_vs_params[4];\nlayout(location = 0) in vec3 position;\nlayout(location = 1) in vec4 i_model0;\nlayout(location = 2) in vec4 i_model1;\nlayout(location = 3) in vec4 i_model2;\n\nvoid main()\n{\n    vec4 _18 = vec4(position, 1.0);\n    gl_Position = mat4(depth3d_vs_params[0], depth3d_vs_params[1], depth3d_vs_params[2], depth3d_vs_params[3]) * vec4(dot(i_model0, _18), dot(i_model1, _18), dot(i_model2, _18), 1.0);\n}\n\n", fragment: "#version 410\n\nvoid main()\n{\n}\n\n"}, glsl300es: {vertex: "#version 300 es\n\nuniform vec4 depth3d_vs_params[4];\nlayout(location = 0) in vec3 position;\nlayout(location = 1) in vec4 i_model0;\nlayout(location = 2) in vec4 i_model1;\nlayout(location = 3) in vec4 i_model2;\n\nvoid main()\n{\n    vec4 _18 = vec4(position, 1.0);\n    gl_Position = mat4(depth3d_vs_params[0], depth3d_vs_params[1], depth3d_vs_params[2], depth3d_vs_params[3]) * vec4(dot(i_model0, _18), dot(i_model1, _18), dot(i_model2, _18), 1.0);\n}\n\n", fragment: "#version 300 es\nprecision mediump float;\nprecision highp int;\n\nvoid main()\n{\n}\n\n"}, uniformBlocks: [{slot: 0, stage: "vertex", size: 64, glslName: "depth3d_vs_params", vec4Count: 4}], textures: []};
  #end
 /** Its vertex buffers by index (0 the vertices, 1 the instance records, 2 a skin's joints), as a PipelineDesc takes them. */
 public static function buffers():Array<helix.graphics.PipelineDesc.VertexBuffer>
  return [{stride: 48, instanced: false, attributes: [{slot: 0, componentCount: 3, offset: 0}]}, {stride: 48, instanced: true, attributes: [{slot: 1, componentCount: 4, offset: 0}, {slot: 2, componentCount: 4, offset: 16}, {slot: 3, componentCount: 4, offset: 32}]}];
}
