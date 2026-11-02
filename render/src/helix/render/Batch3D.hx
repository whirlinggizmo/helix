package helix.render;

#if !macro
import helix.geometry.Camera3D;
import helix.math.Bounds3D;
import helix.math.Matrix3D;
import helix.platform.Blend;
import helix.platform.ColorChannels;
import helix.platform.CullFace;
import helix.platform.DepthTest;
import helix.services.shaders.ShaderValues;
#end

/** Provides 3D drawing through a camera or through views: meshes and models with their materials, lit, shadowed and fogged, skinned,
	morphed and instanced; the environment's background; and the batch draws, for what has no mesh: lines, debug shapes, billboards,
	points, triangles, and sprites, shapes and text in a plane.

	A program constructs one over its `Renderer`, and between `Renderer.beginFrame` and `endFrame` draws between `begin` (or
	`beginViews`) and `end`. Units are world units, right-handed with +y up; colors are 0xAARRGGBB, sRGB.

	**What `begin` reads.** The camera or views, `lights`, `environment`, `fog`, and the renderer's `exposure` and `toneMapping` are read
	at `begin` and hold until `end`.

	**Draw state.** `blend`, `depthTest`, `depthWrite`, `cull`, `colorWrite`, `polygonMode`, `pointSize`, `pointSizeAttenuated`,
	`shaderValues`, `customData`, `castShadows`, `receiveShadows`, `clipPlanes`, `fogged` and `toneMapped` are read at each draw, as
	`culling` and `shapeRegion` are. They are kept across `begin`s, `beginViews` and frames, as raylib's rlgl state is: a value set
	holds until the program sets another. `resetState` puts the draw state back to its defaults.

	**Views.** `begin(camera)` draws through one view, the camera's, filling the renderer's viewport. `beginViews` draws through several
	at once, each with its own matrices and rectangle: every draw is drawn once in each view, in the order given, so the two eyes of a
	headset or two split screens see one scene drawn once by the program. Lights are chosen, shadows fitted and draws culled for all the
	views together: a draw is skipped only when it is out of every view.

	**Light.** A material is shaded as its `shading` says by the lights in `lights` (any number; each draw by the 8 that reach it most:
	each light's brightness through its falloff at the nearest point of the draw's box and its cone at the box's center), the ambient
	light and environment map of `environment`, and its own maps, in linear light.

	**Shadows.** At most 4 lights cast, on every target: each of the first 4 lights in `lights` that casts (`Light3D.castsShadow`) has its
	map drawn before the pass the batch draws in, at `Renderer.endFrame`, from the meshes this batch drew casting that its volume holds,
	and is read by those drawn receiving (`LightShadow3D` says how). A mesh casts when both the batch's `castShadows` and its material's
	are on, and receives when both `receiveShadows` are. A caster is drawn as it is drawn in color: skinned, morphed, instanced, cut by
	`alphaCutoff`. The batch draws neither cast nor receive.

	**Targets.** What a target holds is its format's. Into an RGBA8 target or the screen, which hold sRGB, lit color and a material with
	`toneMapped` on are exposed and tone mapped by the renderer's `exposure` and `toneMapping`, everything is encoded, and the GPU
	blends the encoded values, so a blended surface mixes as sRGB colors do. Into an RGBA16F target, which holds linear light, everything
	is written linear, neither exposed, tone mapped nor encoded, and blends linearly: `PostProcess.draw` resolves it by the same pair.

	**The batch draws' colors are multiplied as stored.** A batch draw's vertex color, tint and texel are multiplied as the 0xAARRGGBB
	values and the texture store them, with no decode, as raylib and `Batch2D` multiply them: a 0x80 tint on a 0x80 texel gives 0x40.
	Into an sRGB target the product is written as it is, unless fog reaches it (`fogged`) or it is tone mapped (`toneMapped`): then it is
	decoded once, fogged, exposed and tone mapped as they say, and encoded. Into an RGBA16F target it is decoded once and written linear.

	**Points.** A point of `pointSize` 1, not attenuated, is the one pixel its position falls in, on every backend, shaded as its vertex;
	a larger one is a square facing the screen, made in the vertex stage, with its texture across it.

	**Sprites, shapes and text in a plane** (`drawSprite`, `drawTextureRegion`, the shapes from `fillTriangle` to `strokePolygon`,
	`drawText`, `drawTextLayout`) are what a layer drawing all its 2D through this batch needs, as raylib's rlgl does: wire and point
	modes and views (stereo) then reach its 2D too. Each is drawn in the plane z 0 of its transform, x across and y down the texture, as
	`Batch2D` draws it, so under an orthographic view whose y runs down (`View3D.setFromScreen`, raylib's 2D) it is upright in pixels; in
	a world whose y runs up, a transform scaled by -1 in y stands it up. They make their corners on the CPU as `Batch2D` does, and join
	one GPU draw with the batch draws around them that share their texture; shapes are drawn from `shapeRegion`. Lines, outlines and
	curves are made of triangles, as many as keep a curve's edge within a quarter of a unit of the plane (a pixel under
	`View3D.setFromScreen`); a thickness is in the plane's units, centered on the edge or the line. A program drawing only 2D uses
	`Batch2D`.

	**A program's shader** for the batch draws (`shaderValues`) is compiled by `compileShader` (a fragment stage over the batch's vertex
	stage) or `compileShaderStages`; a mesh's is its material's (`Material3D`). The batch fills, by name, what it declares; both batches
	fill the same names, so one shader serves both (`makeShaderExpr`). For a batch draw, the attributes:

	| Name | Type | What |
	|---|---|---|
	| `vertexPosition` | vec3 | The vertex, in world units, moved by the draw's transform. |
	| `vertexTexCoord` | vec2 | The texture coordinates, 0 to 1 across the texture, v down. |
	| `vertexNormal` | vec3 | `drawTriangles`' normal; 0, 0, 1 for the others. |
	| `vertexColor` | vec4 | The vertex's color times the tint, 0 to 1, as stored. |
	| `vertexCustomData` | vec4 | `customData` as the draw was made. |
	| `vertexCorner` | vec2 | A wide line's or a large point's corner, -1 to 1 (a line's x along it, start to end; y across it); 0, 0 for a vertex drawn where it is. |
	| `vertexLineEnd` | vec3 | The other end of a wide line's segment, in world units. |

	And the uniforms:

	| Name | Type | What |
	|---|---|---|
	| `baseColorTexture` | sampler2D | The draw's texture, the region's, the font's atlas, `shapeRegion`'s, or white. |
	| `fontKind` | int | As `Batch2D` fills it. |
	| `model`, `normalMatrix` | mat4 | Identity: the batch moves the vertices itself. |
	| `modelViewProjection` | mat4 | The view's `viewProjection`. |
	| `baseColor` | vec4 | White: a batch draw has no material. |
	| `lineWidth` | float | The draw's line width, in framebuffer pixels. |
	| `pointSize`, `pointSizeAttenuated` | float, int | The draw state's. |
	| `clipPlanes`, `clipPlaneCount` | vec4[4], int | The draw state's planes. |
	| `fogged`, `toneMapped` | int | The draw state's, 1 for true. |

	With them the view's names (`View3D`). A name the program writes on its values is overwritten by the batch's.

	**Names given by `Shader.withNames`** are filled exactly as names declared in the GLSL: a shader written for raylib's names, its
	`mvp`, `matView`, `colDiffuse` and `texture0` given as `modelViewProjection`, `viewMatrix`, `baseColor` and `baseColorTexture`, is
	filled as one declaring those names, a loose `viewMatrix` written per draw as `View3D` says. The batch shares the blocks itself:
	each draw reads the view's `View` block and the batch's `Lighting` (the `ShaderScene` written at `begin`) wherever the shader
	declares them, so the program sets no `ShaderValues.scene` and shares no block, and a scene it sets on its values is not read for
	them.

	**The batch's vertex stage** passes, read by name in a fragment stage: `texCoord` (vec2), `color` (vec4, as stored), `customData`
	(vec4), `normal` (vec3) and `worldPosition` (vec3, what the clip planes cut by).

	**A program's own vertex stage** (`compileShaderStages`, `makeShaderExpr`) may place its vertices itself, declaring the attributes,
	uniforms and outputs it uses, as raylib's GLSL 330 vertex stages do (`gl_Position = mvp * vec4(vertexPosition, 1.0)`). It then gives
	up what the batch's stage makes from `vertexCorner`: wide lines are drawn as one-pixel lines and large points as one-pixel points,
	their middles, as the build sees the stage doesn't call `placeBatchVertex`; and the planes cut it only where it writes
	`worldPosition`. Or it includes `batch.glsl` (`#include <helix/render/batch.glsl>`), which includes `view.glsl` and declares the
	attributes and uniforms above and the five outputs, so the stage declares none of them, and gives one function:

	```glsl
	// Places a batch draw's vertex as the batch's own stage does, from a position and a wide line's other end the stage may have moved
	// (pass vertexPosition and vertexLineEnd to change nothing): a wide line's or a large point's corner pushed out across the screen by
	// vertexCorner, lineWidth and pointSize. Returns the clip position, and writes the five outputs: worldPosition from the position
	// given, the others from their attributes. The stage may write any of them again after the call.
	vec4 placeBatchVertex(vec3 position, vec3 lineEnd);
	```

	A fragment stage is cut by `clipPlanes` before it runs, whichever compiled it: the macros wrap its `main`.

	**The lighting include.** `#include <helix/render/lighting.glsl>` (fragment stage) declares everything a lit shader reads, so the
	shader declares none of it: the shared block `Lighting`, written at each `begin` and shared with every draw; its shared textures;
	and the draw's own lights as loose uniforms (`lightCount`, `lightPositions`, `lightDirections`, `lightColors`, `lightCones` and
	`receiveShadows`, which `Material3D` lists), in the shader's own loose block. It includes `view.glsl` and `color.glsl`. A material's
	shader includes `material.glsl` instead, which includes this and reads the material's surface (`Material3D`).

	| Name | Type | What |
	|---|---|---|
	| `ambientLight` | vec4 | `environment`'s ambient light, linear radiance. |
	| `environmentIrradiance` | vec4[9] | Its map's spherical-harmonic irradiance. |
	| `environmentParams` | vec4 | Its intensity, last mip, rotation, and 1 when it has a map. |
	| `shadowMatrices` | mat4[24] | Each casting light's maps' matrices: a cascade or a cube face each. |
	| `shadowParams`, `shadowColors` | vec4[4] | Each casting light's first matrix, map count, bias and filter radius; its strength and color. |
	| `shadowCascadeSplits` | vec4 | Where the directional cascades end, in world units from the eye. |
	| `environmentTexture`, `brdfTexture`, `shadowTexture` | samplerCube, sampler2D, sampler2DArrayShadow | The prefiltered cube, the split-sum table, the shadow maps: shared textures. |

	Its functions are helix-render's own shaders' shading, so a program's material shades as the built-in ones do. Every vector is in
	world space. The three shadings apply each of the draw's lights through its falloff, cone and shadow (when the draw receives), the
	ambient light, `bakedLight`, and the environment map's diffuse and reflected light, and return linear light toward the eye. They
	leave out what a material adds after shading: its emissive light (`emissive`), fog (`applyFog`), the alpha cutoff (a `discard`), and
	exposure, tone mapping and encoding (`writeColor`); `material.glsl`'s `readMaterialSurface` and `writeMaterialColor` do all four.

	```glsl
	struct Surface {
		vec3 position;             // world units
		vec3 normal;               // world space, unit length, turned toward the viewer: a back face's normal flipped
		vec3 baseColor;            // linear
		float alpha;               // 0 to 1: what blend mixes by; the shadings ignore it
		float metallic;            // 0 to 1
		float roughness;           // 0 to 1, taken as at least 0.03
		float occlusion;           // 1 for none: scales the ambient, baked and environment light
		vec3 specularColor;        // linear: MetallicRoughness's specular color times its intensity, Phong's specular color
		float ior;
		float shininess;           // Phong's exponent
		float clearcoat;
		float clearcoatRoughness;
		vec3 clearcoatNormal;      // world space, unit length, turned as normal is
		vec3 sheenColor;           // linear
		float sheenRoughness;
		float environmentIntensity;
		vec3 bakedLight;           // linear irradiance from a light map, added as the ambient light is; 0 for none
		vec3 emissive;             // linear light it gives off; the shadings leave it out
	};
	// A surface at a point with a normal and a base color: alpha 1, bakedLight and emissive 0, its other fields Material3D's defaults.
	// The normal is taken as given: the shader turns it toward the viewer (gl_FrontFacing ? n : -n) for a face drawn from behind.
	Surface makeSurface(vec3 position, vec3 normal, vec3 baseColor);
	vec3 shadeMetallicRoughness(Surface surface);
	vec3 shadePhong(Surface surface);
	vec3 shadeLambert(Surface surface);
	// One of the draw's lights (0 to lightCount - 1) arriving at a point: its radiance through its falloff, cone and shadow, and the
	// unit direction toward it; for a shader shading by its own model.
	vec3 computeLightRadiance(int lightIndex, vec3 position, vec3 normal, out vec3 toLight);
	// A casting light's shadow at a point (its index is lightCones[i].z): 1 where lit, toward its color by its strength where shadowed.
	vec3 computeShadow(int shadowIndex, vec3 position, vec3 normal);
	// The ambient light and the environment map's irradiance reaching a surface facing a direction.
	vec3 computeAmbientLight(vec3 normal);
	// The environment map's prefiltered light from a direction, blurred by a roughness.
	vec3 computeEnvironmentLight(vec3 direction, float roughness);
	```

	**Order and batching.** Draws are drawn in the order they are called; nothing is sorted, so the program draws what is opaque first
	and what is blended after, farthest first. Each mesh is a GPU draw of its own a view, an instanced one one for all its copies. The
	batch draws join one GPU draw while they share a texture, the draw state and the shader values with nothing written to them between,
	and nothing else is drawn between them; a transform given to one, and `customData`, split nothing, as they are applied to the
	vertices as each draw is made. `Renderer.clearTarget` may be called with the batch open, and is recorded where it is called.

	**Culling.** With `culling` on, a draw whose box is out of every view's frustum (`View3D.isInView`) is skipped: a mesh's bounds moved
	by its transform, each instanced copy apart, a model mesh by mesh, a billboard by the sphere it can turn in, points, lines, shapes,
	sprites and text by the box around them, a draw list by its box. A skinned mesh's box is its joints': each joint's box of the
	vertices it moves, recorded at `Renderer.createMesh`, moved by the joint's skinning matrix, all joined; a morphed mesh's grows by its
	targets' reach. That box can be larger than the posed mesh; `GpuMesh3D.computeBounds` gives the exact one. A shadow pass culls its
	casters against the light's volume, not the views'.

	```haxe
	var batch = new Batch3D(renderer);
	var sun = new DirectionalLight3D();
	sun.direction.set(-1, -2, -1);
	sun.castsShadow = true;
	batch.lights.push(sun);
	batch.environment.setAmbient(0xff8090a0, .3);
	// each frame, between Renderer.beginFrame and endFrame:
	batch.begin(camera);
	batch.drawBackground();
	batch.drawModel(level, Matrix3D.fromTranslation(0, 0, 0, placement));
	batch.end();
	``` */
class Batch3D {
	#if !macro
	/** Gets or sets how the following batch draws are combined with what is under them: Alpha (`Blend.ALPHA`) until set; any factors
		and operations the platform's `Blend` takes. A mesh is blended as its material says, or as its draw's `MeshState3D` says. */
	public var blend(default, set):Blend = Blend.ALPHA;

	/** Gets or sets the following batch draws' depth test: LessEqual until set; Off draws them over everything drawn before. A mesh is
		tested as its material says, or as its draw's `MeshState3D` says. */
	public var depthTest(default, set):DepthTest = LessEqual;

	/** Gets or sets a value indicating whether the following batch draws write depth: true until set. A mesh writes depth as its
		material says, or as its draw's `MeshState3D` says. */
	public var depthWrite(default, set):Bool = true;

	/** Gets or sets which faces of the following batch draws' triangles aren't drawn: None until set, so both sides are. A mesh is culled
		as its material says, or as its draw's `MeshState3D` says. */
	public var cull(default, set):CullFace = None;

	/** Gets or sets the color channels the following batch draws write: all four until set. A mesh writes what its material's
		`colorWrite` says, or what its draw's `MeshState3D` says. */
	public var colorWrite(default, set):ColorChannels = All;

	/** Gets or sets how the following meshes' and batch draws' faces are drawn: filled, as their edges, or as their corners. Fill until
		set. */
	public var polygonMode(default, set):PolygonMode3D = Fill;

	/** Gets or sets the size of the following points (`drawPoints`, `PolygonMode3D.Points`), in framebuffer pixels: 1 until set. Below 0
		is clamped to 0.

		With `pointSizeAttenuated` on, under a perspective projection, a point is `pointSize × (viewportHeight / 2) / -z` framebuffer
		pixels across, where `viewportHeight` is its view's rectangle's height in framebuffer pixels and `-z` its distance in front of the
		eye along the view's axis: three.js's `size` with `sizeAttenuation`, so a three.js layer passes a material's `size` as it is (and,
		not attenuated, `size` times the device pixel ratio, as three.js does). A point so drawn is `pointSize` world units across only
		where the projection's vertical field of view is 90°. Under an orthographic projection it is not attenuated. */
	public var pointSize(default, set):Float = 1;

	/** Gets or sets a value indicating whether the following points shrink with distance, as `pointSize` gives the formula: false until
		set. */
	public var pointSizeAttenuated(default, set):Bool = false;

	/** Gets or sets the program's own shader the following batch draws are drawn with, as values over it carrying its own uniforms and
		textures, or null for the batch's: null until set. A mesh is drawn with its material's.

		Its shader is compiled by `compileShader` or `compileShaderStages`, and reads the names the class lists. Its values are read as
		each draw is made. */
	public var shaderValues(default, set):Null<ShaderValues> = null;

	/** Gets or sets four bytes each vertex of the following batch draws carries, for a program's shader to read as `customData`, as
		`Batch2D.customData` does: 0 until set. It splits nothing; the batch's own shader ignores it. */
	public var customData:Int = 0;

	/** Gets or sets a value indicating whether the following meshes and models cast shadows, where their material's `castShadows` is
		on too: true until set. */
	public var castShadows:Bool = true;

	/** Gets or sets a value indicating whether the following meshes and models are darkened by shadows, where their material's
		`receiveShadows` is on too: true until set. */
	public var receiveShadows:Bool = true;

	/** Gets the planes the following draws are cut by, a, b, c and d each, at most 4 planes: a point where a x + b y + c z + d is below
		0 isn't drawn. Empty until changed; changed in place, read at each draw. */
	public final clipPlanes:Array<Float> = [];

	/** Gets or sets a value indicating whether the following batch draws are faded by `fog`, as three.js's `PointsMaterial.fog` and
		`LineBasicMaterial.fog`: true until set. Nothing is faded while `fog` is null. A mesh is fogged as its material's `fog` says. */
	public var fogged:Bool = true;

	/** Gets or sets a value indicating whether the following batch draws are exposed and tone mapped into an sRGB target by the
		renderer's `exposure` and `toneMapping`, as lit color is: false until set, so their colors arrive as given; three.js's
		`PointsMaterial.toneMapped`, true there, is set per draw by a three.js layer. Into an RGBA16F target nothing is tone mapped as it
		is drawn (`Material3D.toneMapped`). A mesh is tone mapped as its material's `toneMapped` says. */
	public var toneMapped:Bool = false;

	/** Gets or sets the region the shapes (`fillTriangle` to `strokePolygon`) are drawn with: null until set, for the batch's own white
		texture.

		Shapes read the texel at the region's center alone, so it must be white there: `Texture2D.writeWhiteTexel` makes one on a sheet
		or an atlas, and shapes then join one GPU draw with its sprites or text, as raylib's `SetShapesTexture` does. Assigning it ends
		the open GPU draw. It is not draw state: `resetState` leaves it. */
	public var shapeRegion(default, set):Null<TextureRegion2D> = null;

	/** Gets the lights that light its lit materials, read at each `begin`: empty until the program adds some. */
	public final lights:Array<Light3D> = [];

	/** Gets or sets the ambient light, the environment map and the background, read at each `begin`: until set, an environment of its
		own with no light, so a lit material is lit by what the program sets alone, black under none. */
	public var environment:Environment3D = new Environment3D();

	/** Gets or sets the fog, read at each `begin`, or null for none: null until set. */
	public var fog:Null<Fog3D> = null;

	/** Gets or sets a value indicating whether draws out of view are skipped: true until set; read at each draw. */
	public var culling:Bool = true;

	/** Gets a value indicating whether it is open: from `begin` until `end`. */
	public var open(default, null):Bool = false;

	/** Creates a batch over a renderer, with its default shaders, built now: every shading (skinned, morphed and instanced too), the
		shadow casters, the background, and the batch draws' one shader (lines, points, triangles, shapes, sprites and text of every font
		kind).

		@param renderer  The renderer it records into. */
	public function new(renderer:Renderer) {}

	function set_blend(value:Blend):Blend {
		throw "helix-render: Batch3D.set_blend is not yet built (stage 1)";
	}

	function set_depthTest(value:DepthTest):DepthTest {
		throw "helix-render: Batch3D.set_depthTest is not yet built (stage 1)";
	}

	function set_depthWrite(value:Bool):Bool {
		throw "helix-render: Batch3D.set_depthWrite is not yet built (stage 1)";
	}

	function set_cull(value:CullFace):CullFace {
		throw "helix-render: Batch3D.set_cull is not yet built (stage 1)";
	}

	function set_colorWrite(value:ColorChannels):ColorChannels {
		throw "helix-render: Batch3D.set_colorWrite is not yet built (stage 1)";
	}

	function set_polygonMode(value:PolygonMode3D):PolygonMode3D {
		throw "helix-render: Batch3D.set_polygonMode is not yet built (stage 1)";
	}

	function set_pointSize(value:Float):Float {
		throw "helix-render: Batch3D.set_pointSize is not yet built (stage 1)";
	}

	function set_pointSizeAttenuated(value:Bool):Bool {
		throw "helix-render: Batch3D.set_pointSizeAttenuated is not yet built (stage 1)";
	}

	function set_shaderValues(value:Null<ShaderValues>):Null<ShaderValues> {
		throw "helix-render: Batch3D.set_shaderValues is not yet built (stage 1)";
	}

	function set_shapeRegion(value:Null<TextureRegion2D>):Null<TextureRegion2D> {
		throw "helix-render: Batch3D.set_shapeRegion is not yet built (stage 1)";
	}

	/** Puts the draw state back to its defaults: `blend` Alpha, `depthTest` LessEqual, `depthWrite` on, `cull` None, `colorWrite` all,
		`polygonMode` Fill, `pointSize` 1 not attenuated, no `shaderValues`, `customData` 0, `castShadows` and `receiveShadows` on, no
		`clipPlanes`, `fogged` on and `toneMapped` off.

		It may be called at any time, open or not. `lights`, `environment`, `fog`, `culling` and `shapeRegion` are left as they are. */
	public function resetState():Void {
		throw "helix-render: Batch3D.resetState is not yet built (stage 1)";
	}

	/** Opens the batch for drawing in the renderer's current pass through a camera, filling the renderer's viewport.

		The camera is read now, its aspect the viewport's, and so are `lights`, `environment`, `fog`, and the renderer's `exposure` and
		`toneMapping`: changing them after takes effect at the next `begin`. The draw state is kept as the program left it.
		@param camera  The camera.
		@throws String  No frame being recorded, or a batch (this or another) already open. */
	public function begin(camera:Camera3D):Void {
		throw "helix-render: Batch3D.begin is not yet built (stage 1)";
	}

	/** Opens the batch for drawing in the renderer's current pass through views, each draw drawn once in each.

		The views are read now, as `begin` reads a camera, and so are `lights`, `environment`, `fog`, and the renderer's `exposure` and
		`toneMapping`. The draw state is kept as the program left it.
		@param views  The views, in the order each draw is drawn in them; at least one.
		@throws String  No frame being recorded, a batch (this or another) already open, no views, or a view's rectangle outside the
			renderer's viewport. */
	public function beginViews(views:Array<View3D>):Void {
		throw "helix-render: Batch3D.beginViews is not yet built (stage 1)";
	}

	/** Closes the batch, so another can open or the pass can end.

		@throws String  The batch isn't open. */
	public function end():Void {
		throw "helix-render: Batch3D.end is not yet built (stage 1)";
	}

	/** Draws the environment's background behind everything: its map, turned, as bright and as blurred as `environment` says, at the far
		plane, depth-tested so it shows only where nothing nearer is drawn. Nothing when it has none.

		It is drawn where it is called; first, it costs every pixel; after the opaque meshes, only the ones they leave. */
	public function drawBackground():Void {
		throw "helix-render: Batch3D.drawBackground is not yet built (stage 4, environment maps)";
	}

	/** Draws a mesh with a material, placed by a transform, its faces as `polygonMode` says.

		Its blend, depth test, depth write, cull and color channels are the material's, but for those `state` gives, which hold for
		this draw alone and change nothing in the material: a layer whose state is global, as raylib's rlgl is, keeps one `MeshState3D`
		and passes it each draw.

		@param mesh  The mesh.
		@param material  The material, read as it is now.
		@param transform  The mesh's place in the world, read now.
		@param skinning  Optional. Its skin's matrices (`Skin3D.computeSkinning`), read now, for a mesh with joints; the mesh is drawn
			unskinned when omitted.
		@param morphWeights  Optional. How much of each of its morph targets is added, read now, by target; none when omitted.
		@param tint  Optional. A color, 0xAARRGGBB, multiplying the material's `baseColor` for this draw alone, as raylib's `DrawModel`
			tint does; white when omitted.
		@param state  Optional. State this draw takes in place of the material's (`MeshState3D`), read now; the material's when
			omitted.
		@throws String  A disposed mesh, or a texture of the material disposed. */
	public function drawMesh(mesh:GpuMesh3D, material:Material3D, transform:Matrix3D, ?skinning:Array<Matrix3D>, ?morphWeights:Array<Float>, ?tint:Int,
			?state:MeshState3D):Void {
		throw "helix-render: Batch3D.drawMesh is not yet built (stage 1)";
	}

	/** Draws a mesh many times with one material, each copy placed by its own transform and tinted by its own color, in one GPU draw.

		A shader for it reads each copy's transform as `instanceModel`, its color as `instanceColor`, and the parent transform as
		`model`; the default does. A mesh's joints are ignored here. With `culling` on, the copies out of view are left out of the draw.
		@param mesh  The mesh.
		@param material  The material, read as it is now.
		@param transforms  Each copy's place in the parent's units, read now.
		@param colors  Optional. Each copy's color, 0xAARRGGBB, multiplying its base color, read now, indexed as `transforms`; white when
			omitted.
		@param transform  Optional. The parent all the copies are placed in, as an InstancedMesh's own place: each copy is at it times
			its own; identity when omitted.
		@param firstInstanceIndex  Optional. The index in `transforms` of the first copy drawn; defaults to 0.
		@param instanceCount  Optional. How many copies are drawn from it, as an InstancedMesh's `count`; every one to the end of
			`transforms` when omitted. None draws nothing.
		@throws String  A disposed mesh, a texture of the material disposed, or copies past the end of `transforms`. */
	public function drawMeshInstanced(mesh:GpuMesh3D, material:Material3D, transforms:Array<Matrix3D>, ?colors:Array<Int>, ?transform:Matrix3D,
			firstInstanceIndex = 0, ?instanceCount:Int):Void {
		throw "helix-render: Batch3D.drawMeshInstanced is not yet built (stage 1)";
	}

	/** Draws a model: each of its meshes with its material, placed by a transform, each skinned mesh posed by its skin.

		Each mesh's blend, depth test, depth write, cull and color channels are its material's, but for those `state` gives, as
		`drawMesh` takes them.

		@param model  The model.
		@param transform  The model's place in the world, read now.
		@param boneMatrices  Optional. Each of its skeleton's bones' place in the model (`Skeleton3D.computeWorld`), read now; the rest
			pose when omitted. Ignored for a model without a skeleton.
		@param tint  Optional. A color, 0xAARRGGBB, multiplying each material's `baseColor` for this draw alone, as raylib's `DrawModel`
			tint does; white when omitted.
		@param state  Optional. State every mesh of this draw takes in place of its material's (`MeshState3D`), read now; each
			material's when omitted.
		@throws String  A disposed model. */
	public function drawModel(model:GpuModel3D, transform:Matrix3D, ?boneMatrices:Array<Matrix3D>, ?tint:Int, ?state:MeshState3D):Void {
		throw "helix-render: Batch3D.drawModel is not yet built (stage 1)";
	}

	/** Draws a line between two points, one pixel wide.

		@param x0  The start's x.
		@param y0  The start's y.
		@param z0  The start's z.
		@param x1  The end's x.
		@param y1  The end's y.
		@param z1  The end's z.
		@param color  The color. */
	public function drawLine(x0:Float, y0:Float, z0:Float, x1:Float, y1:Float, z1:Float, color:Int):Void {
		throw "helix-render: Batch3D.drawLine is not yet built (stage 1)";
	}

	/** Draws lines through positions, as segments two by two or as one strip, of a width in pixels.

		A line wider than a pixel is a quad made in the vertex stage, facing the screen, the same on every backend.
		@param positions  The positions, x, y and z each, read now.
		@param color  The color of lines without colors of their own.
		@param colors  Optional. Each position's color, 0xAARRGGBB, blended along each line; `color` everywhere when omitted.
		@param width  Optional. The width, in framebuffer pixels, whatever the transform; defaults to 1.
		@param strip  Optional. Whether the positions are one line through them all, rather than a segment each two; defaults to false.
		@param transform  Optional. What the positions are moved by, as a Line's own place; identity when omitted. */
	public function drawLines(positions:Array<Float>, color:Int, ?colors:Array<Int>, width = 1., strip = false, ?transform:Matrix3D):Void {
		throw "helix-render: Batch3D.drawLines is not yet built (stage 1)";
	}

	/** Draws a box's twelve edges.

		@param bounds  The box, in world units.
		@param color  The color. */
	public function strokeBox(bounds:Bounds3D, color:Int):Void {
		throw "helix-render: Batch3D.strokeBox is not yet built (stage 1)";
	}

	/** Draws a sphere as three circles about its center, one square to each axis.

		@param x  The center's x.
		@param y  The center's y.
		@param z  The center's z.
		@param radius  The radius.
		@param color  The color. */
	public function strokeSphere(x:Float, y:Float, z:Float, radius:Float, color:Int):Void {
		throw "helix-render: Batch3D.strokeSphere is not yet built (stage 1)";
	}

	/** Draws a grid of lines on the ground (y 0), centered on the origin.

		@param lineCount  The number of lines each way.
		@param spacing  The distance between two lines.
		@param color  The color. */
	public function drawGrid(lineCount:Int, spacing:Float, color:Int):Void {
		throw "helix-render: Batch3D.drawGrid is not yet built (stage 1)";
	}

	/** Draws a transform's axes from its origin: x red, y green, z blue.

		@param transform  The transform, as a mesh would be placed by it.
		@param length  Each axis' length, before the transform's scale. */
	public function drawAxes(transform:Matrix3D, length:Float):Void {
		throw "helix-render: Batch3D.drawAxes is not yet built (stage 1)";
	}

	/** Draws a texture's region facing the camera, upright with the camera's up and turned about its center, its center at a point.

		@param region  The region of the texture.
		@param x  The center's x.
		@param y  The center's y.
		@param z  The center's z.
		@param width  The width, in world units.
		@param height  The height, in world units.
		@param tint  Optional. The color its texels are multiplied by; defaults to white.
		@param rotation  Optional. Its turn in the screen's plane, in radians, clockwise; defaults to 0. */
	public function drawBillboard(region:TextureRegion2D, x:Float, y:Float, z:Float, width:Float, height:Float, tint:Int = 0xffffffff, rotation = 0.):Void {
		throw "helix-render: Batch3D.drawBillboard is not yet built (stage 1)";
	}

	/** Draws positions as points of `pointSize`, unlit, with the draw state.

		A point of 1 pixel is the pixel its position falls in; a larger one is a square facing the screen, its center at the position,
		with the texture across it, as three.js's PointsMaterial's map is.
		@param positions  The points' positions, x, y and z each, in world units; read now.
		@param color  The color of points without one of their own.
		@param colors  Optional. Each point's own color, 0xAARRGGBB; `color` for every point when omitted.
		@param texture  Optional. The texture across each square; white when omitted.
		@param transform  Optional. What the positions are moved by, as a Points object's own place; identity when omitted. A point's
			size is not scaled by it. */
	public function drawPoints(positions:Array<Float>, color:Int, ?colors:Array<Int>, ?texture:Texture2D, ?transform:Matrix3D):Void {
		throw "helix-render: Batch3D.drawPoints is not yet built (stage 1)";
	}

	/** Draws triangles as given, in world units: textured, colored by vertex, or both, unlit, for what has no mesh; as their edges or
		corners in another `polygonMode`.

		The arrays are read during the call, so they may be reused for the next. Normals are for a program's own shader
		(`shaderValues`), which may light them; the batch's own ignores them.
		@param texture  The texture, or null for white.
		@param positions  The vertices' positions, x, y and z each.
		@param texCoords  Optional. The texture coordinates, u and v each; 0, 0 for every vertex when omitted.
		@param colors  Optional. Each vertex's color, 0xAARRGGBB; white when omitted.
		@param indices  Optional. Three a triangle, indexing the vertices; when omitted, the vertices are the triangles in order.
		@param normals  Optional. Each vertex's normal, x, y and z; 0, 0, 1 for every vertex when omitted.
		@param transform  Optional. What the positions and normals are moved by; identity when omitted. */
	public function drawTriangles(texture:Null<Texture2D>, positions:Array<Float>, ?texCoords:Array<Float>, ?colors:Array<Int>, ?indices:Array<Int>,
			?normals:Array<Float>, ?transform:Matrix3D):Void {
		throw "helix-render: Batch3D.drawTriangles is not yet built (stage 1)";
	}

	/** Draws lines through points in a plane, one after another, joined at each point with a miter, or a bevel where the miter would
		reach past twice the thickness, as `Batch2D.drawPolyline` draws them; two points are one line, its ends square, cut at the points.

		@param points  The points, x and y each, in the plane's units; fewer than two draws nothing.
		@param thickness  The width, in the plane's units.
		@param color  The color.
		@param transform  Optional. The plane it is drawn in; identity, the world's xy plane, when omitted. */
	public function drawPolyline(points:Array<Float>, thickness:Float, color:Int, ?transform:Matrix3D):Void {
		throw "helix-render: Batch3D.drawPolyline is not yet built (stage 1)";
	}

	/** Fills a triangle in a plane.

		@param x0  The first corner, across.
		@param y0  The first corner, down.
		@param x1  The second corner, across.
		@param y1  The second corner, down.
		@param x2  The third corner, across.
		@param y2  The third corner, down.
		@param color  The color.
		@param transform  Optional. The plane it is drawn in; identity when omitted. */
	public function fillTriangle(x0:Float, y0:Float, x1:Float, y1:Float, x2:Float, y2:Float, color:Int, ?transform:Matrix3D):Void {
		throw "helix-render: Batch3D.fillTriangle is not yet built (stage 1)";
	}

	/** Fills a rectangle in a plane.

		@param x  The left edge.
		@param y  The top edge.
		@param width  The width.
		@param height  The height.
		@param color  The color.
		@param transform  Optional. The plane it is drawn in; identity when omitted. */
	public function fillRectangle(x:Float, y:Float, width:Float, height:Float, color:Int, ?transform:Matrix3D):Void {
		throw "helix-render: Batch3D.fillRectangle is not yet built (stage 1)";
	}

	/** Draws a rectangle's outline in a plane.

		@param x  The left edge.
		@param y  The top edge.
		@param width  The width.
		@param height  The height.
		@param thickness  The outline's width, centered on the edges.
		@param color  The color.
		@param transform  Optional. The plane it is drawn in; identity when omitted. */
	public function strokeRectangle(x:Float, y:Float, width:Float, height:Float, thickness:Float, color:Int, ?transform:Matrix3D):Void {
		throw "helix-render: Batch3D.strokeRectangle is not yet built (stage 1)";
	}

	/** Fills a rectangle with rounded corners in a plane.

		@param x  The left edge.
		@param y  The top edge.
		@param width  The width.
		@param height  The height.
		@param radius  The corners' radius, clamped to half the shorter side.
		@param color  The color.
		@param transform  Optional. The plane it is drawn in; identity when omitted. */
	public function fillRoundedRectangle(x:Float, y:Float, width:Float, height:Float, radius:Float, color:Int, ?transform:Matrix3D):Void {
		throw "helix-render: Batch3D.fillRoundedRectangle is not yet built (stage 1)";
	}

	/** Draws the outline of a rectangle with rounded corners in a plane.

		@param x  The left edge.
		@param y  The top edge.
		@param width  The width.
		@param height  The height.
		@param radius  The corners' radius, clamped to half the shorter side.
		@param thickness  The outline's width, centered on the edges.
		@param color  The color.
		@param transform  Optional. The plane it is drawn in; identity when omitted. */
	public function strokeRoundedRectangle(x:Float, y:Float, width:Float, height:Float, radius:Float, thickness:Float, color:Int, ?transform:Matrix3D):Void {
		throw "helix-render: Batch3D.strokeRoundedRectangle is not yet built (stage 1)";
	}

	/** Fills a circle in a plane.

		@param x  The center, across.
		@param y  The center, down.
		@param radius  The radius.
		@param color  The color.
		@param transform  Optional. The plane it is drawn in; identity when omitted. */
	public function fillCircle(x:Float, y:Float, radius:Float, color:Int, ?transform:Matrix3D):Void {
		throw "helix-render: Batch3D.fillCircle is not yet built (stage 1)";
	}

	/** Draws a circle's outline in a plane.

		@param x  The center, across.
		@param y  The center, down.
		@param radius  The radius.
		@param thickness  The outline's width, centered on the circle.
		@param color  The color.
		@param transform  Optional. The plane it is drawn in; identity when omitted. */
	public function strokeCircle(x:Float, y:Float, radius:Float, thickness:Float, color:Int, ?transform:Matrix3D):Void {
		throw "helix-render: Batch3D.strokeCircle is not yet built (stage 1)";
	}

	/** Fills an ellipse in a plane, its axes across and down.

		@param x  The center, across.
		@param y  The center, down.
		@param radiusX  The radius across.
		@param radiusY  The radius down.
		@param color  The color.
		@param transform  Optional. The plane it is drawn in; identity when omitted. */
	public function fillEllipse(x:Float, y:Float, radiusX:Float, radiusY:Float, color:Int, ?transform:Matrix3D):Void {
		throw "helix-render: Batch3D.fillEllipse is not yet built (stage 1)";
	}

	/** Draws an ellipse's outline in a plane.

		@param x  The center, across.
		@param y  The center, down.
		@param radiusX  The radius across.
		@param radiusY  The radius down.
		@param thickness  The outline's width, centered on the ellipse.
		@param color  The color.
		@param transform  Optional. The plane it is drawn in; identity when omitted. */
	public function strokeEllipse(x:Float, y:Float, radiusX:Float, radiusY:Float, thickness:Float, color:Int, ?transform:Matrix3D):Void {
		throw "helix-render: Batch3D.strokeEllipse is not yet built (stage 1)";
	}

	/** Fills a polygon in a plane, convex or not, whose edges don't cross.

		@param points  The corners in order, x and y each, either way round; fewer than three draws nothing.
		@param color  The color.
		@param transform  Optional. The plane it is drawn in; identity when omitted.
		@return  False when its edges cross, and nothing is drawn. */
	public function fillPolygon(points:Array<Float>, color:Int, ?transform:Matrix3D):Bool {
		throw "helix-render: Batch3D.fillPolygon is not yet built (stage 1)";
	}

	/** Draws a polygon's outline in a plane: lines through its corners and back to the first, joined as `drawPolyline` joins them.

		@param points  The corners in order, x and y each; fewer than two draws nothing.
		@param thickness  The outline's width, centered on the edges.
		@param color  The color.
		@param transform  Optional. The plane it is drawn in; identity when omitted. */
	public function strokePolygon(points:Array<Float>, thickness:Float, color:Int, ?transform:Matrix3D):Void {
		throw "helix-render: Batch3D.strokePolygon is not yet built (stage 1)";
	}

	/** Draws a texture's region in a plane, turned and scaled about its origin, the origin at a point, as `Batch2D.drawSprite` draws it.

		It lies in the plane z 0 of the transform, x across and y down the texture.
		@param region  The region of the texture.
		@param x  Where the origin goes, across.
		@param y  Where the origin goes, down the texture.
		@param rotation  Optional. The turn about the origin, in radians, from x toward y; defaults to 0.
		@param scaleX  Optional. The scale across; defaults to 1, a unit a texel.
		@param scaleY  Optional. The scale down; defaults to 1.
		@param tint  Optional. The color its texels are multiplied by; defaults to white.
		@param flipX  Optional. Whether it is mirrored across about its origin, after its scale; defaults to false.
		@param flipY  Optional. Whether it is mirrored down about its origin, after its scale; defaults to false.
		@param originX  Optional. The point it turns about and is placed by, in texels from the region's left; the region's `originX` when
			omitted.
		@param originY  Optional. That point, in texels from the region's top; the region's `originY` when omitted.
		@param transform  Optional. The plane it is drawn in; identity, the world's xy plane, when omitted. */
	public function drawSprite(region:TextureRegion2D, x:Float, y:Float, rotation = 0., scaleX = 1., scaleY = 1., tint:Int = 0xffffffff, flipX = false,
			flipY = false, ?originX:Float, ?originY:Float, ?transform:Matrix3D):Void {
		throw "helix-render: Batch3D.drawSprite is not yet built (stage 1)";
	}

	/** Draws a rectangle of a texture into a rectangle in a plane, turned about an origin, as `Batch2D.drawTextureRegion` draws it (raylib's
		`DrawTexturePro`): no region is made for it.

		@param texture  The texture.
		@param regionX  The part's left edge, in texels from the texture's left.
		@param regionY  The part's top edge, in texels from the texture's top.
		@param regionWidth  The part's width, in texels; negative mirrors it across.
		@param regionHeight  The part's height, in texels; negative mirrors it down.
		@param x  Where the origin goes, across.
		@param y  Where the origin goes, down the texture.
		@param width  The width it is drawn at.
		@param height  The height it is drawn at.
		@param rotation  Optional. The turn about the origin, in radians, from x toward y; defaults to 0.
		@param originX  Optional. The point it turns about and is placed by, from the drawn rectangle's left; defaults to 0.
		@param originY  Optional. That point, from the drawn rectangle's top; defaults to 0.
		@param tint  Optional. The color its texels are multiplied by; defaults to white.
		@param transform  Optional. The plane it is drawn in; identity when omitted. */
	public function drawTextureRegion(texture:Texture2D, regionX:Float, regionY:Float, regionWidth:Float, regionHeight:Float, x:Float, y:Float, width:Float,
			height:Float, rotation = 0., originX = 0., originY = 0., tint:Int = 0xffffffff, ?transform:Matrix3D):Void {
		throw "helix-render: Batch3D.drawTextureRegion is not yet built (stage 1)";
	}

	/** Draws text in a font in a plane, as `Batch2D.drawText` draws it: line by line, left-aligned, its first line's top at a point.

		@param font  The font.
		@param text  The text; a character the font lacks is skipped.
		@param x  The left edge.
		@param y  The top of the first line, lines following down the texture.
		@param color  Optional. The color; defaults to white.
		@param size  Optional. The size, as the font's size is measured; the font's own, a unit a pixel of it, when omitted.
		@param letterSpacing  Optional. Space added after each character; defaults to 0.
		@param kerned  Optional. Whether pairs of characters are kerned as the font gives them; defaults to true. raylib's `DrawTextEx`
			doesn't kern.
		@param transform  Optional. The plane it is drawn in; identity when omitted. */
	public function drawText(font:GpuFont2D, text:String, x:Float, y:Float, color:Int = 0xffffffff, ?size:Float, letterSpacing = 0., kerned = true,
			?transform:Matrix3D):Void {
		throw "helix-render: Batch3D.drawText is not yet built (stage 1)";
	}

	/** Draws laid-out text in a plane, wrapped and aligned as its layout says, as `Batch2D.drawTextLayout` draws it.

		@param layout  The layout.
		@param x  The left edge of the layout's box, in which its lines are aligned: the box is `maxWidth` wide, or as wide as its widest
			line when `maxWidth` is 0.
		@param y  The top of the first line.
		@param color  Optional. The color; defaults to white.
		@param transform  Optional. The plane it is drawn in; identity when omitted. */
	public function drawTextLayout(layout:TextLayout2D, x:Float, y:Float, color:Int = 0xffffffff, ?transform:Matrix3D):Void {
		throw "helix-render: Batch3D.drawTextLayout is not yet built (stage 1)";
	}

	/** Replays a draw list: its calls in the order recorded, in its own units placed by a transform.

		With `culling` on, a list whose box (`DrawList3D.bounds`), so placed, is out of every view is skipped whole. Its calls are drawn
		with the draw state as it is now, `customData` among it.
		@param list  The list.
		@param transform  Its place in the world, read now.
		@throws String  A mesh, model or texture it holds disposed. */
	public function drawList(list:DrawList3D, transform:Matrix3D):Void {
		throw "helix-render: Batch3D.drawList is not yet built (stage 1)";
	}
	#end

	/** Compiles a fragment stage over the batch's vertex stage, for a `Batch3D`'s batch draws (`shaderValues`).

		It compiles while the program builds, as helix-services' `Shader.compile` compiles one, and returns it as a value in the program: its
		vertex stage drawn the right way up into a render target whatever it writes (`ShaderOptions.clipScale`) and able to draw
		one-pixel points (`ShaderOptions.points`), helix-render's includes found (`#include <helix/render/color.glsl>`). A name the class
		lists declared with another type stops the build at the call.
		The fragment stage is GLSL as helix-services' `Shader.compile` takes it: `#version 300 es` or 330 to 440 (GL's form), or
		`#version 450` (Vulkan's), the batch's vertex stage given in the same form; GLSL ES 100 (raylib's) is not taken, and a layer
		adapts it first. The vertex stage passes `texCoord` (vec2), `color` (vec4), `customData` (vec4), `normal` (vec3) and
		`worldPosition` (vec3), read by name; the fragment stage is cut by `clipPlanes` before its `main` runs.
		@param fragment  The fragment stage's file, relative to the file holding the call.
		@param options  Optional. Defines, includes and a file to watch, as `Shader.compile` takes them.
		@return  The shader, for a `ShaderValues` over it. */
	public static macro function compileShader(fragment:String,
			?options:haxe.macro.Expr.ExprOf<helix.services.shaders.ShaderOptions>):haxe.macro.Expr.ExprOf<helix.services.shaders.Shader> {
		throw "helix-render: Batch3D.compileShader is not yet built (stage 1)";
	}

	/** Compiles a vertex and a fragment stage, both the program's, for a `Batch3D`'s batch draws (`shaderValues`).

		It compiles while the program builds, as helix-services' `Shader.compile` compiles one, and returns it as a value in the program: its
		vertex stage drawn the right way up into a render target whatever it writes (`ShaderOptions.clipScale`) and able to draw
		one-pixel points (`ShaderOptions.points`), helix-render's includes found (`#include <helix/render/color.glsl>`). A name the class
		lists declared with another type stops the build at the call.
		Both stages are GLSL in one form, as helix-services' `Shader.compile` takes it: `#version 300 es` or 330 to 440, or
		`#version 450`. The vertex stage may place its vertices itself, declaring what it reads; wide lines and large points are then
		drawn as their one-pixel middles. Placed by `placeBatchVertex(position, lineEnd)` (`#include <helix/render/batch.glsl>`), they are
		drawn wide and large, as the class says.
		@param vertex  The vertex stage's file, relative to the file holding the call.
		@param fragment  The fragment stage's file, relative to the file holding the call.
		@param options  Optional. Defines, includes and a file to watch.
		@return  The shader, for a `ShaderValues` over it. */
	public static macro function compileShaderStages(vertex:String, fragment:String,
			?options:haxe.macro.Expr.ExprOf<helix.services.shaders.ShaderOptions>):haxe.macro.Expr.ExprOf<helix.services.shaders.Shader> {
		throw "helix-render: Batch3D.compileShaderStages is not yet built (stage 1)";
	}

	#if macro
	/** Returns the expression of a shader compiled for helix-render from two stages' text, for a layer's macro that makes or adapts the
		text itself, as `Shader.makeExpr` returns one: helix-ray's `LoadShader`, whose one shader draws rlgl's batch here, its meshes as a
		`Material3D`'s, and a `Batch2D`'s draws, every one filling the same names, so one `Shader.withNames` map serves them all
		(`mvp` to `modelViewProjection`, `colDiffuse` to `baseColor`, white where no material sets it).

		The texts are GLSL in one form, as `compileShaderStages` takes them, the vertex stage placing its vertices itself or by
		`placeBatchVertex`; the fragment stage is cut by `clipPlanes`, as there. Names the shader is given by `withNames` are filled as
		declared ones, and the batch shares `View` and `Lighting` with each draw itself (the class says so). The
		options are `Shader.makeExpr`'s, and the shader is compiled with them as given but for what helix-render sets itself: `clipScale`
		and `points` on, whatever the options say; helix-render's includes (`helix/render/batch.glsl`, `mesh.glsl`, `material.glsl`,
		`lighting.glsl`, `view.glsl`, `color.glsl`) added to `includes`, where a text given under one of their names stops the build; the
		blocks `View` and `Lighting` added to `shared` where the shader declares them; and its check of the names the classes list run
		after the options' own `check`.
		@param vertex  The vertex stage: a name for messages and its GLSL.
		@param fragment  The fragment stage: a name for messages and its GLSL.
		@param options  The options, as `Shader.makeExpr` takes them.
		@param pos  Where an error is reported.
		@return  An expression of type `Shader`. */
	public static function makeShaderExpr(vertex:{name:String, text:String}, fragment:{name:String, text:String},
			options:helix.services.shaders.ShaderBuildOptions, pos:haxe.macro.Expr.Position):haxe.macro.Expr {
		throw "helix-render: Batch3D.makeShaderExpr is not yet built (stage 1)";
	}
	#end
}
