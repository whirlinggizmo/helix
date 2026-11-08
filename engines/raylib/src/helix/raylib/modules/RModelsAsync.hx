package helix.raylib.modules;

#if !macro
import helix.raylib.*;
import helix.raylib.Raylib.*;
import helix.math.Matrix3D;
import helix.raylib.internal.DefaultFont;
import helix.raylib.internal.Animations;
import helix.raylib.internal.Models;
import helix.raylib.internal.ObjModels;
import helix.formats.obj.MtlFile;
import helix.formats.obj.ObjFile;
import helix.raylib.internal.Runtime;
import helix.raylib.internal.Textures;
import helix.raylib.internal.CallbackFiles;
import helix.raylib.internal.WaveReader;
import helix.raylib.internal.Waves;
import helix.raylib.modules.RCore.*;
import helix.raylib.modules.RShapes.*;
import helix.raylib.modules.RTextures.*;
import helix.raylib.modules.RText.*;
import helix.raylib.modules.RModels.*;
import helix.raylib.modules.RAudio.*;
import helix.raylib.modules.RMath.*;
import helix.raylib.internal.Answers.*;
import helix.raylib.modules.RWindowAsync.*;
import helix.raylib.modules.RFilesAsync.*;
import helix.raylib.modules.RTexturesAsync.*;
import helix.raylib.modules.RTextAsync.*;
import helix.raylib.modules.RAudioAsync.*;
#end

/** Provides the async versions of rmodels' model, material and animation loads and mesh writes, replacing raylib's calls that wait
	for a file or a write.

	Each is written here, and `helix.raylib.extras.Models` forwards to each (`tools/gen_raylib.py`). */
@:noCompletion
@:allow(helix.raylib)
class RModelsAsync {
	#if !macro
	// LoadModelAsync's call where its file's name isn't known as the program builds (extras.Models.LoadModelAsync): the reader picked by its
	// extension as it runs, so both readers are in the program. A format helix-raylib doesn't read is refused.
	static function loadModel(fileName:String, loaded:Model->Void, ?failed:String->Void):Void {
		var path = normalize(fileName), lower = path.toLowerCase();
		var extension = lower.lastIndexOf(".") >= 0 ? lower.substr(lower.lastIndexOf(".")) : "";
		if (extension == ".iqm" || extension == ".vox" || extension == ".m3d") {
			Runtime.later(() -> refuse("LoadModelAsync", '$path: ${extension.substr(1).toUpperCase()} models are not supported; glTF, GLB and OBJ are',
				failed));
			return;
		}
		if (extension != ".glb" && extension != ".gltf" && extension != ".obj") {
			Runtime.later(() -> refuse("LoadModelAsync", '$path: only glTF, GLB and OBJ are read here', failed));
			return;
		}
		if (extension == ".obj")
			loadObjModel(fileName, loaded, failed);
		else
			loadGltfModel(fileName, loaded, failed);
	}

	// LoadModelAsync's call for a glTF or GLB file.
	static function loadGltfModel(fileName:String, loaded:Model->Void, ?failed:String->Void):Void {
		var path = normalize(fileName);
		if (Models.isKept(path)) {
			Runtime.later(() -> loaded(RModels.loadModel(path)));
			return;
		}
		Runtime.modelling();
		Runtime.models.loadGltf(path, read -> {
			// raylib gives a mesh without joints whose node is a bone's child to that bone: the nodes are the file's, read again.
			if (read.skeleton != null && read.skins.length > 0 && Lambda.exists(read.meshes, m -> m.jointIndices == null)) {
				Animations.read(path, file -> {
					Models.keep(read, defaultShader(), Animations.attached(file));
					loaded(RModels.loadModel(path));
				}, error -> refuse("LoadModelAsync", error, failed));
				return;
			}
			Models.keep(read, defaultShader());
			loaded(RModels.loadModel(path));
		}, error -> refuse("LoadModelAsync", error, failed));
	}

	// LoadModelAsync's call for an OBJ file.
	static function loadObjModel(fileName:String, loaded:Model->Void, ?failed:String->Void):Void {
		var path = normalize(fileName);
		if (Models.isKept(path)) {
			Runtime.later(() -> loaded(RModels.loadModel(path)));
			return;
		}
		loadObj(path, loaded, failed);
	}

	// An OBJ file, the last library its mtllib lines name (one that can't be read logged and left out) and that library's textures (one that
	// can't be, logged and left none), then its model kept for its loads.
	static function loadObj(path:String, loaded:Model->Void, failed:Null<String->Void>):Void {
		Runtime.fetch(path, error -> {
			if (error != null) {
				refuse("LoadModelAsync", error, failed);
				return;
			}
			// raylib reads an empty file as one it can't read.
			var bytes = Runtime.files.get(path);
			if (bytes.length == 0) {
				refuse("LoadModelAsync", '$path: Unable to read obj file', failed);
				return;
			}
			var obj = try ObjFile.read(bytes, path) catch (e:String) {
				refuse("LoadModelAsync", '$path: $e', failed);
				return;
			}
			function made(library:Null<MtlFile>):Void
				withTextures(library, () -> {
					var shader = defaultShader();
					Models.keepMade(path, ObjModels.template(obj, library), library != null && library.materials.length > 0 ? () ->
						ObjModels.materials(library, shader) : () -> [Models.defaultMaterial(shader)]);
					loaded(RModels.loadModel(path));
				});
			var libraryPath = ObjModels.libraryPath(obj);
			if (libraryPath == null)
				made(null);
			else
				readLibrary(libraryPath, made, message -> {
					Runtime.log(4, 'MODEL: [$path] $message');
					made(null);
				});
		});
	}

	// An MTL file read, or why it couldn't be.
	static function readLibrary(path:String, done:MtlFile->Void, failed:String->Void):Void {
		Runtime.fetch(path, error -> {
			if (error != null) {
				failed(error);
				return;
			}
			var library = try MtlFile.read(Runtime.files.get(path), path) catch (e:String) {
				failed('$path: $e');
				return;
			}
			done(library);
		});
	}

	// Each texture a library's materials name brought in (one that can't be, logged), then done.
	static function withTextures(library:Null<MtlFile>, done:Void->Void):Void {
		var paths = ObjModels.texturePaths(library), left = paths.length + 1;
		function one():Void
			if (--left == 0)
				done();
		for (p in paths)
			Runtime.fetchImage(p, error -> {
				if (error != null)
					Runtime.log(4, 'TEXTURE: $error');
				one();
			});
		one();
	}

	/** Asynchronously loads a glTF or GLB file's animations, replacing raylib's `LoadModelAnimations`.

		A file without skins gives none. Only the file's first skin is read.

		IQM and M3D animations are refused, as is any file but glTF and GLB.

		Each animation is sampled 60 times a second, as raylib 6.2 samples it, with (int)(duration * 60) + 1 frames.

		Each frame's pose is its bones' transforms in the model.

		@param fileName  The file, as the program names it.
		@param loaded  Receives the animations, as many as the file has; their count is its length.
		@param failed  Optional. Receives why they couldn't be loaded; when omitted, it is logged. */
	static function LoadModelAnimationsAsync(fileName:String, loaded:Array<ModelAnimation>->Void, ?failed:String->Void):Void {
		var path = normalize(fileName), lower = path.toLowerCase();
		if (StringTools.endsWith(lower, ".iqm") || StringTools.endsWith(lower, ".m3d")) {
			Runtime.later(() -> refuse("LoadModelAnimationsAsync", '$path: ${lower.substr(-3).toUpperCase()} animations are not supported; glTF and GLB are',
				failed));
			return;
		}
		if (!(StringTools.endsWith(lower, ".glb") || StringTools.endsWith(lower, ".gltf"))) {
			Runtime.later(() -> refuse("LoadModelAnimationsAsync", '$path: only glTF and GLB are read here', failed));
			return;
		}
		Animations.read(path, file -> {
			var animations = try Animations.fromGltf(file, path) catch (e:Dynamic) {
				refuse("LoadModelAnimationsAsync", '$path: $e', failed);
				return;
			}
			loaded(animations);
		}, error -> refuse("LoadModelAnimationsAsync", error, failed));
	}

	/** Asynchronously loads an .mtl file's materials with the textures they name, replacing raylib's `LoadMaterials`. See `LoadModelAsync` for loading an OBJ file with the materials its `mtllib` names.

		The program holds each material until `UnloadMaterial`.

		Each starts as raylib's default material, and reads these fields as raylib's `ProcessMaterialsOBJ` does:

		- `map_Kd`, the diffuse texture, or with none MTL's `Kd`, the diffuse color (alpha 255).
		- `map_Ks` and MTL's `Ks`, the specular texture and color.
		- `bump` or `map_bump`, the normal map's texture. The normal map's color is white and its value is MTL's `Ns`, the specular
		  exponent.
		- MTL's `Ke`, the emission color.
		- `disp`, the height map's texture.

		A field a material doesn't give defaults to tinyobj_loader_c's default, as raylib has it. Each color is black and the specular
		exponent is 1.

		A texture's path is resolved against the file's directory. A texture that can't be read is none (id 0) and is logged.

		A file that breaks the format fails.

		@param fileName  The file, as the program names it: an .mtl file.
		@param loaded  Receives the materials, in the file's order; their count is its length.
		@param failed  Optional. Receives why they couldn't be loaded (the file isn't an .mtl file, can't be found or can't be read); when
			omitted, it is logged. */
	static function LoadMaterialsAsync(fileName:String, loaded:Array<Material>->Void, ?failed:String->Void):Void {
		var path = normalize(fileName);
		if (!StringTools.endsWith(path.toLowerCase(), ".mtl")) {
			Runtime.later(() -> refuse("LoadMaterialsAsync", '$path: only .mtl files are read here', failed));
			return;
		}
		readLibrary(path, library -> withTextures(library, () -> loaded(ObjModels.materials(library, defaultShader()))),
			error -> refuse("LoadMaterialsAsync", error, failed));
	}

	/** Asynchronously writes a mesh as an OBJ file through `SaveFileTextAsync`, replacing raylib's `ExportMesh`.
		See `ExportMeshAsCodeAsync` for writing a C header.

		Positions and texture coordinates are written to 6 places, normals to 4, and each face as a triangle, as raylib's `ExportMesh`
		writes them.

		@param mesh  The mesh, with positions, texture coordinates and normals.
		@param fileName  The file; only ".obj" is written.
		@param done  Optional. Called once the file is written, or once it is refused, at a later poll.
		@param failed  Optional. Receives why it wasn't, such as another extension; when omitted, it is logged. */
	static function ExportMeshAsync(mesh:Mesh, fileName:String, ?done:Void->Void, ?failed:String->Void):Void {
		if (!IsFileExtension(fileName, ".obj"))
			Runtime.later(() -> refuse("ExportMeshAsync", '$fileName: only .obj files are written', failed));
		else
			exportText("ExportMeshAsync", fileName, RModels.meshObj(mesh), null, done, failed);
	}

	/** Asynchronously writes a mesh as a C header through `SaveFileTextAsync`, replacing raylib's `ExportMeshAsCode`. See `ExportMeshAsync` for writing an OBJ file.

		The mesh\'s counts are written as defines, and each array it has as 20 values a line, floats to 3 places, as raylib's `ExportMeshAsCode`
		writes them.

		@param mesh  The mesh.
		@param fileName  The file; its name, upper case, names the defines and the arrays.
		@param done  Optional. Called once the file is written, or once it is refused, at a later poll.
		@param failed  Optional. Receives why it wasn't; when omitted, it is logged. */
	static function ExportMeshAsCodeAsync(mesh:Mesh, fileName:String, ?done:Void->Void, ?failed:String->Void):Void {
		exportText("ExportMeshAsCodeAsync", fileName, RModels.meshAsCode(mesh, fileName), null, done, failed);
	}
	#end
}
