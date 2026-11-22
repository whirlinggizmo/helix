/* helix-jolt's C ABI over Jolt Physics: flat calls of numbers alone, the same natively (hxcpp) and in jolt.wasm.

   A call's vectors and records cross through two shared areas instead of pointers: hj_io_f's 64 floats and hj_io_i's 64 ints for a
   call's small values (a body's settings in, a transform out), and hj_bulk's buffer for arrays (a mesh's vertices, the poses of many
   bodies), which grows to what a call asks. Shapes and constraints are handles (indices into tables here), worlds too, and bodies their
   Jolt ids, so Haxe holds plain integers on both targets. A handle of -1 is none. */
#ifndef HJ_H
#define HJ_H

#include <stdint.h>

#ifdef __EMSCRIPTEN__
#define HJ_API __attribute__((used, visibility("default")))
#else
#define HJ_API
#endif

#ifdef __cplusplus
extern "C" {
#endif

/* The shared areas. */
HJ_API float *hj_io_f(void);
HJ_API int32_t *hj_io_i(void);
HJ_API void *hj_bulk(int32_t bytes);

/* Jolt's allocator, factory and types, once. */
HJ_API void hj_init(void);

/* Worlds. hj_world_create reads the layer tables from the bulk buffer: num_object_layers ints, each object layer's broad phase layer,
   then num_object_layers squared ints, 1 where two object layers collide. */
HJ_API int32_t hj_world_create(int32_t max_bodies, int32_t max_body_pairs, int32_t max_contacts, int32_t num_object_layers,
                               int32_t num_broad_phase_layers);
HJ_API void hj_world_destroy(int32_t world);
HJ_API void hj_world_step(int32_t world, float delta_time, int32_t collision_steps);
HJ_API void hj_world_set_gravity(int32_t world, float x, float y, float z);
HJ_API void hj_world_get_gravity(int32_t world);
HJ_API void hj_world_get_settings(int32_t world);
HJ_API void hj_world_set_settings(int32_t world);
HJ_API int32_t hj_world_num_bodies(int32_t world);
HJ_API int32_t hj_world_num_active_bodies(int32_t world);
HJ_API int32_t hj_world_max_bodies(int32_t world);
HJ_API int32_t hj_world_get_bodies(int32_t world, int32_t active);
HJ_API void hj_world_get_bounds(int32_t world);
HJ_API void hj_world_optimize_broad_phase(int32_t world);
HJ_API int32_t hj_world_were_in_contact(int32_t world, int32_t body1, int32_t body2);

/* Shapes made directly. */
HJ_API int32_t hj_shape_box(float half_x, float half_y, float half_z, float convex_radius);
HJ_API int32_t hj_shape_sphere(float radius);
HJ_API int32_t hj_shape_capsule(float half_height, float radius);
HJ_API int32_t hj_shape_cylinder(float half_height, float radius, float convex_radius);
HJ_API int32_t hj_shape_scaled(int32_t shape, float x, float y, float z);
HJ_API int32_t hj_shape_offset_center_of_mass(int32_t shape, float x, float y, float z);
HJ_API int32_t hj_shape_plane(float normal_x, float normal_y, float normal_z, float constant, float half_extent);
HJ_API int32_t hj_shape_empty(float x, float y, float z);

/* Shapes made from settings: each returns the shape, or -1 with the reason in hj_shape_error's bulk bytes. */
HJ_API int32_t hj_shape_tapered_capsule(float half_height, float top_radius, float bottom_radius, float density, int32_t user_data);
/* Reads num_points times x, y, z floats from the bulk buffer. */
HJ_API int32_t hj_shape_convex_hull(int32_t num_points, float max_convex_radius, float hull_tolerance, float density, int32_t user_data);
/* Reads num_vertices times x, y, z floats, then num_triangles times three int indices, from the bulk buffer. */
HJ_API int32_t hj_shape_mesh(int32_t num_vertices, int32_t num_triangles, int32_t max_triangles_per_leaf, int32_t user_data);
/* Reads sample_count squared height floats from the bulk buffer; offset and scale from hj_io_f's first six. */
HJ_API int32_t hj_shape_height_field(int32_t sample_count, int32_t block_size, int32_t bits_per_sample, int32_t user_data);
/* Reads num_parts times seven floats (position, rotation), then num_parts times two ints (shape, user data), from the bulk buffer. */
HJ_API int32_t hj_shape_static_compound(int32_t num_parts, int32_t user_data);
HJ_API int32_t hj_shape_rotated_translated(int32_t shape, float x, float y, float z, float qx, float qy, float qz, float qw, int32_t user_data);
/* The last failure's reason as UTF-8 in the bulk buffer; its length. */
HJ_API int32_t hj_shape_error(void);

/* A shape's count, type and values. Results of more than one number go to hj_io_f. */
HJ_API int32_t hj_shape_get_ref_count(int32_t shape);
HJ_API void hj_shape_add_ref(int32_t shape);
HJ_API void hj_shape_release(int32_t shape);
HJ_API int32_t hj_shape_get_type(int32_t shape);
HJ_API int32_t hj_shape_get_sub_type(int32_t shape);
HJ_API int32_t hj_shape_must_be_static(int32_t shape);
HJ_API void hj_shape_get_local_bounds(int32_t shape);
HJ_API void hj_shape_get_center_of_mass(int32_t shape);
HJ_API float hj_shape_get_volume(int32_t shape);
HJ_API void hj_shape_get_mass_properties(int32_t shape);
HJ_API int32_t hj_shape_get_user_data(int32_t shape);
HJ_API void hj_shape_set_user_data(int32_t shape, int32_t user_data);
HJ_API float hj_shape_get_density(int32_t shape);
HJ_API void hj_shape_set_density(int32_t shape, float density);
/* A box's half extent, a sphere's, capsule's or cylinder's radius and half height, a scaled shape's scale, into hj_io_f. */
HJ_API void hj_shape_get_dimensions(int32_t shape);
/* The world normal of a shape placed at a center of mass, rotation and scale (hj_io_f's first ten), at a point (the next three). */
HJ_API void hj_shape_get_world_surface_normal(int32_t shape, int32_t sub_shape_id);

/* Bodies. hj_body_create reads its settings from hj_io_f and hj_io_i (BodyCreationSettings' order, in BodyInterface.hx). */
HJ_API int32_t hj_body_create(int32_t world, int32_t shape, int32_t add, int32_t activation);
HJ_API void hj_body_destroy(int32_t world, int32_t body);
HJ_API void hj_body_add(int32_t world, int32_t body, int32_t activation);
HJ_API void hj_body_remove(int32_t world, int32_t body);
HJ_API int32_t hj_body_is_added(int32_t world, int32_t body);
HJ_API int32_t hj_body_get_shape(int32_t world, int32_t body);
HJ_API void hj_body_set_shape(int32_t world, int32_t body, int32_t shape, int32_t update_mass, int32_t activation);
HJ_API void hj_body_set_object_layer(int32_t world, int32_t body, int32_t layer);
HJ_API int32_t hj_body_get_object_layer(int32_t world, int32_t body);
HJ_API void hj_body_set_position_and_rotation(int32_t world, int32_t body, float x, float y, float z, float qx, float qy, float qz,
                                              float qw, int32_t activation);
HJ_API void hj_body_set_position(int32_t world, int32_t body, float x, float y, float z, int32_t activation);
HJ_API void hj_body_set_rotation(int32_t world, int32_t body, float qx, float qy, float qz, float qw, int32_t activation);
/* Position x, y, z then rotation x, y, z, w into hj_io_f. */
HJ_API void hj_body_get_position_and_rotation(int32_t world, int32_t body);
/* 16 floats by columns into hj_io_f. */
HJ_API void hj_body_get_world_transform(int32_t world, int32_t body);
HJ_API void hj_body_get_center_of_mass_transform(int32_t world, int32_t body);
HJ_API void hj_body_move_kinematic(int32_t world, int32_t body, float x, float y, float z, float qx, float qy, float qz, float qw,
                                   float delta_time);
HJ_API void hj_body_set_linear_velocity(int32_t world, int32_t body, float x, float y, float z);
HJ_API void hj_body_add_linear_velocity(int32_t world, int32_t body, float x, float y, float z);
HJ_API void hj_body_set_angular_velocity(int32_t world, int32_t body, float x, float y, float z);
/* Linear velocity x, y, z then angular x, y, z into hj_io_f. */
HJ_API void hj_body_get_velocities(int32_t world, int32_t body);
HJ_API void hj_body_get_point_velocity(int32_t world, int32_t body, float x, float y, float z);
HJ_API void hj_body_add_force(int32_t world, int32_t body, float x, float y, float z, int32_t at_point, float px, float py, float pz,
                              int32_t activation);
HJ_API void hj_body_add_torque(int32_t world, int32_t body, float x, float y, float z, int32_t activation);
HJ_API void hj_body_add_impulse(int32_t world, int32_t body, float x, float y, float z, int32_t at_point, float px, float py, float pz);
HJ_API void hj_body_add_angular_impulse(int32_t world, int32_t body, float x, float y, float z);
HJ_API void hj_body_activate(int32_t world, int32_t body);
HJ_API void hj_body_deactivate(int32_t world, int32_t body);
HJ_API int32_t hj_body_is_active(int32_t world, int32_t body);
HJ_API void hj_body_set_motion_type(int32_t world, int32_t body, int32_t motion_type, int32_t activation);
HJ_API int32_t hj_body_get_motion_type(int32_t world, int32_t body);
HJ_API void hj_body_set_motion_quality(int32_t world, int32_t body, int32_t motion_quality);
HJ_API void hj_body_set_restitution(int32_t world, int32_t body, float restitution);
HJ_API float hj_body_get_restitution(int32_t world, int32_t body);
HJ_API void hj_body_set_friction(int32_t world, int32_t body, float friction);
HJ_API float hj_body_get_friction(int32_t world, int32_t body);
HJ_API void hj_body_set_gravity_factor(int32_t world, int32_t body, float factor);
HJ_API float hj_body_get_gravity_factor(int32_t world, int32_t body);
HJ_API void hj_body_set_is_sensor(int32_t world, int32_t body, int32_t is_sensor);
HJ_API int32_t hj_body_is_sensor(int32_t world, int32_t body);
HJ_API void hj_body_set_user_data(int32_t world, int32_t body, int32_t user_data);
HJ_API int32_t hj_body_get_user_data(int32_t world, int32_t body);
/* Min x, y, z then max x, y, z into hj_io_f. */
HJ_API void hj_body_get_world_space_bounds(int32_t world, int32_t body);
/* The center of mass, rotation and scale of the body's shape (hj_shape_get_world_surface_normal's ten) into hj_io_f, its shape returned. */
HJ_API int32_t hj_body_get_transformed_shape(int32_t world, int32_t body);
HJ_API void hj_body_get_world_space_surface_normal(int32_t world, int32_t body, int32_t sub_shape_id, float x, float y, float z);

/* A step's contacts. hj_world_get_contacts writes them into the bulk buffer, 48 bytes each: ints type (0 added, 1 persisted, 2 removed),
   body 1, body 2, sub shape 1, sub shape 2, then floats normal x, y, z, point x, y, z, penetration depth. */
HJ_API void hj_world_set_contact_queue(int32_t world, int32_t max_events, int32_t record_persisted);
HJ_API int32_t hj_world_get_contacts(int32_t world);
HJ_API int32_t hj_world_get_dropped_contacts(int32_t world);

/* Many bodies at once: reads count body ids from the bulk buffer, and writes 7 (position, rotation) or 16 (a transform by columns)
   floats a body after them, from byte offset count * 4. Returns the bodies read. */
HJ_API int32_t hj_bodies_get_positions_and_rotations(int32_t world, int32_t count);
HJ_API int32_t hj_bodies_get_world_transforms(int32_t world, int32_t count);

/* Queries: each reads its filters from hj_io_i (Filters in hj_queries.cpp), runs into the collector `collector` names (0 all, 1
   closest, 2 any), writes its hits into the bulk buffer and returns how many. A ray's hit is 12 bytes (body, sub shape, fraction), a
   point's 8 (body, sub shape), a shape's 52 (contact points, penetration axis, depth, sub shapes, body), a cast shape's 60 (a shape's
   then fraction, back face). */
HJ_API int32_t hj_query_cast_ray(int32_t world, float ox, float oy, float oz, float dx, float dy, float dz, int32_t back_face_triangles,
                                 int32_t back_face_convex, int32_t treat_convex_as_solid, int32_t collector);
HJ_API int32_t hj_query_collide_point(int32_t world, float x, float y, float z, int32_t collector);
HJ_API int32_t hj_query_collide_shape(int32_t world, int32_t shape, float max_separation_distance, int32_t back_face_mode, int32_t collector);
HJ_API int32_t hj_query_cast_shape(int32_t world, int32_t shape, int32_t back_face_triangles, int32_t back_face_convex,
                                   int32_t return_deepest_point, int32_t collector);
HJ_API int32_t hj_body_exists(int32_t world, int32_t body);
HJ_API void hj_shape_get_transformed_world(int32_t shape);
HJ_API int32_t hj_total_memory(void);
HJ_API int32_t hj_free_memory(void);

/* Constraints, by world and handle. hj_constraint_create reads its kind's settings (0 fixed, 1 point, 2 distance, 3 hinge, 4 slider,
   5 cone, 6 six axes) from hj_io_f and hj_io_i, six axes' from the bulk buffer (hj_constraints.cpp). */
HJ_API int32_t hj_constraint_create(int32_t world, int32_t kind, int32_t body1, int32_t body2);
HJ_API void hj_constraint_add(int32_t world, int32_t constraint);
HJ_API void hj_constraint_remove(int32_t world, int32_t constraint);
HJ_API int32_t hj_constraint_get_ref_count(int32_t world, int32_t constraint);
HJ_API void hj_constraint_add_ref(int32_t world, int32_t constraint);
HJ_API void hj_constraint_release(int32_t world, int32_t constraint);
HJ_API int32_t hj_constraint_get_sub_type(int32_t world, int32_t constraint);
HJ_API void hj_constraint_set_enabled(int32_t world, int32_t constraint, int32_t enabled);
HJ_API int32_t hj_constraint_get_enabled(int32_t world, int32_t constraint);
HJ_API void hj_constraint_set_user_data(int32_t world, int32_t constraint, int32_t user_data);
HJ_API int32_t hj_constraint_get_user_data(int32_t world, int32_t constraint);
HJ_API int32_t hj_constraint_get_body(int32_t world, int32_t constraint, int32_t second);
HJ_API float hj_constraint_get_float(int32_t world, int32_t constraint, int32_t what);
HJ_API void hj_constraint_set_float(int32_t world, int32_t constraint, int32_t what, float value);
HJ_API void hj_constraint_set_range(int32_t world, int32_t constraint, float min, float max);
HJ_API void hj_constraint_set_motor_state(int32_t world, int32_t constraint, int32_t axis, int32_t state);
HJ_API int32_t hj_constraint_get_motor_state(int32_t world, int32_t constraint, int32_t axis);
HJ_API void hj_constraint_get_motor(int32_t world, int32_t constraint, int32_t axis);
HJ_API void hj_constraint_set_motor(int32_t world, int32_t constraint, int32_t axis);
HJ_API void hj_constraint_six_dof_set_limits(int32_t world, int32_t constraint, int32_t translation);
HJ_API void hj_constraint_six_dof_set_target(int32_t world, int32_t constraint, int32_t which);

#ifdef __cplusplus
}
#endif

#endif
