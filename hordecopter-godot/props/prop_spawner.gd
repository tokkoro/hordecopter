###############################################################
# props/prop_spawner.gd
# Key Classes      • PropSpawner – scatters static props with collisions
# Key Functions    • _spawn_props() – place props around the map
#                 • _load_prop_definitions() – load prop scenes and metadata
#                 • _spawn_loot_crate_drop() – deliver loot crates from the sky
# Critical Consts  • PROP_DEFAULT_PATHS – models to scatter
# Editor Exports   • prop_paths: Array[String] – list of model scene paths
#                 • prop_count: int – number of props to place
#                 • map_size: float – map width/length in meters
#                 • map_padding: float – keep props inside bounds
#                 • spawn_height: float – ground height for props
#                 • min_spacing: float – minimum spacing between props
#                 • cluster_size_min: int – minimum props per cluster
#                 • cluster_size_max: int – maximum props per cluster
#                 • cluster_radius: float – cluster scatter radius in meters
#                 • center_clear_radius: float – keep props away from center
#                 • loot_crate_scene: PackedScene – loot crate scene to drop
#                 • loot_crate_min_delay: float – minimum drop delay in seconds
#                 • loot_crate_max_delay: float – maximum drop delay in seconds
#                 • loot_crate_drop_height: float – height above ground to spawn
#                 • loot_crate_max_active: int – max number of active drops
# Dependencies     • res://models/tree.glb (optional)
#                 • res://models/rock.glb (optional)
#                 • res://models/bush.glb (optional)
# Last Major Rev   • 25-09-28 – initial prop scattering
###############################################################

class_name PropSpawner
extends Node3D

const PROP_DEFAULT_PATHS: Array[String] = [
	"res://models/tree.glb", "res://models/rock.glb", "res://models/bush.glb"
]

const PROP_COLLISION_SIZES := {
	"res://models/tree.glb": Vector3(1.3, 2.0, 1.3),
	"res://models/rock.glb": Vector3(1.7, 0.9, 1.7),
	"res://models/bush.glb": Vector3(1.3, 1.7, 1.3)
}

const PROP_SCALE_RANGES := {
	"res://models/tree.glb": Vector2(1.9, 2.6),
	"res://models/rock.glb": Vector2(0.8, 1.8),
	"res://models/bush.glb": Vector2(0.9, 1.9)
}

@export var prop_paths: Array[String] = PROP_DEFAULT_PATHS.duplicate()
@export var prop_count: int = 24
@export var map_size: float = 100.0
@export var map_padding: float = 6.0
@export var spawn_height: float = 0.0
@export var min_spacing: float = 5.0
@export var cluster_size_min: int = 2
@export var cluster_size_max: int = 5
@export var cluster_radius: float = 3.0
@export var center_clear_radius: float = 10.0
@export var max_attempts: int = 200
@export var loot_crate_scene: PackedScene = preload("res://props/loot_crate.tscn")
@export var loot_crate_min_delay: float = 6.0
@export var loot_crate_max_delay: float = 12.0
@export var loot_crate_drop_height: float = 18.0
@export var loot_crate_max_active: int = 3

var prop_spawner_rng: RandomNumberGenerator = RandomNumberGenerator.new()
var prop_spawner_loot_crate_timer: float = 0.0
var prop_spawner_loot_crate_target: float = 0.0


func _ready() -> void:
	prop_spawner_rng.randomize()
	_spawn_props()
	_schedule_next_loot_crate_drop()


func _process(delta: float) -> void:
	if loot_crate_scene == null:
		return
	if loot_crate_max_active > 0:
		var prop_spawner_active := get_tree().get_nodes_in_group("loot_crates").size()
		if prop_spawner_active >= loot_crate_max_active:
			return
	prop_spawner_loot_crate_timer += delta
	if prop_spawner_loot_crate_timer < prop_spawner_loot_crate_target:
		return
	_spawn_loot_crate_drop()
	_schedule_next_loot_crate_drop()


func _spawn_props() -> void:
	var prop_spawner_definitions := _load_prop_definitions()
	if prop_spawner_definitions.is_empty():
		push_warning("PropSpawner: no prop scenes found; nothing to spawn.")
		return
	if prop_count <= 0:
		return
	var prop_spawner_positions: Array[Vector3] = []
	var prop_spawner_centers: Array[Vector3] = []
	var prop_spawner_half: float = map_size * 0.5
	var prop_spawner_attempts: int = 0
	while prop_spawner_positions.size() < prop_count and prop_spawner_attempts < max_attempts:
		prop_spawner_attempts += 1
		var prop_spawner_center := _random_position(prop_spawner_half)
		if not _is_position_valid(prop_spawner_center, prop_spawner_centers):
			continue
		prop_spawner_centers.append(prop_spawner_center)
		var prop_spawner_remaining := prop_count - prop_spawner_positions.size()
		var prop_spawner_group_size := _resolve_cluster_size(prop_spawner_remaining)
		var prop_spawner_group_spawned: int = 0
		var prop_spawner_group_attempts: int = 0
		while (
			prop_spawner_group_spawned < prop_spawner_group_size
			and prop_spawner_group_attempts < max_attempts
		):
			prop_spawner_group_attempts += 1
			var prop_spawner_offset := _random_cluster_offset()
			var prop_spawner_position := prop_spawner_center + prop_spawner_offset
			if not _is_position_within_bounds(prop_spawner_position, prop_spawner_half):
				continue
			if prop_spawner_position.length() < center_clear_radius:
				continue
			prop_spawner_positions.append(prop_spawner_position)
			var prop_spawner_definition := prop_spawner_definitions[prop_spawner_rng.randi_range(
				0, prop_spawner_definitions.size() - 1
			)]
			_spawn_prop(prop_spawner_definition, prop_spawner_position)
			prop_spawner_group_spawned += 1


func _random_position(prop_spawner_half: float) -> Vector3:
	var prop_spawner_x := prop_spawner_rng.randf_range(
		-prop_spawner_half + map_padding, prop_spawner_half - map_padding
	)
	var prop_spawner_z := prop_spawner_rng.randf_range(
		-prop_spawner_half + map_padding, prop_spawner_half - map_padding
	)
	return Vector3(prop_spawner_x, spawn_height, prop_spawner_z)


func _random_cluster_offset() -> Vector3:
	var prop_spawner_radius: float = max(0.0, cluster_radius)
	if prop_spawner_radius <= 0.0:
		return Vector3.ZERO
	var prop_spawner_angle := prop_spawner_rng.randf_range(0.0, TAU)
	var prop_spawner_distance := prop_spawner_rng.randf_range(0.0, prop_spawner_radius)
	return Vector3(
		cos(prop_spawner_angle) * prop_spawner_distance,
		0.0,
		sin(prop_spawner_angle) * prop_spawner_distance
	)


func _is_position_valid(position: Vector3, existing: Array[Vector3]) -> bool:
	if position.length() < center_clear_radius:
		return false
	for prop_spawner_existing in existing:
		if position.distance_to(prop_spawner_existing) < min_spacing:
			return false
	return true


func _is_position_within_bounds(position: Vector3, prop_spawner_half: float) -> bool:
	var prop_spawner_limit: float = prop_spawner_half - map_padding
	if abs(position.x) > prop_spawner_limit:
		return false
	if abs(position.z) > prop_spawner_limit:
		return false
	return true


func _resolve_cluster_size(remaining: int) -> int:
	var prop_spawner_min: int = max(1, cluster_size_min)
	var prop_spawner_max: int = max(prop_spawner_min, cluster_size_max)
	var prop_spawner_target: int = prop_spawner_rng.randi_range(prop_spawner_min, prop_spawner_max)
	return min(remaining, prop_spawner_target)


func _load_prop_definitions() -> Array[Dictionary]:
	var prop_spawner_definitions: Array[Dictionary] = []
	for prop_spawner_path in prop_paths:
		if prop_spawner_path.is_empty():
			continue
		if not ResourceLoader.exists(prop_spawner_path):
			push_warning("PropSpawner: missing prop model at %s." % prop_spawner_path)
			continue
		var prop_spawner_scene := load(prop_spawner_path)
		if prop_spawner_scene is PackedScene:
			prop_spawner_definitions.append(
				_make_prop_definition(prop_spawner_scene, prop_spawner_path)
			)
		else:
			push_warning("PropSpawner: %s is not a PackedScene." % prop_spawner_path)
	return prop_spawner_definitions


func _make_prop_definition(
	prop_spawner_scene: PackedScene, prop_spawner_path: String
) -> Dictionary:
	var prop_spawner_collision_size: Vector3 = PROP_COLLISION_SIZES.get(
		prop_spawner_path, Vector3(2.0, 2.0, 2.0)
	)
	var prop_spawner_scale_range: Vector2 = PROP_SCALE_RANGES.get(
		prop_spawner_path, Vector2(0.9, 1.1)
	)
	return {
		"scene": prop_spawner_scene,
		"collision_size": prop_spawner_collision_size,
		"scale_range": prop_spawner_scale_range
	}


func _spawn_prop(prop_spawner_definition: Dictionary, position: Vector3) -> void:
	var prop_spawner_scene := prop_spawner_definition["scene"] as PackedScene
	var prop_spawner_instance := prop_spawner_scene.instantiate()
	var prop_spawner_scale_value := _resolve_scale_value(prop_spawner_definition)
	if prop_spawner_instance is StaticBody3D:
		var prop_spawner_body := prop_spawner_instance as StaticBody3D
		add_child(prop_spawner_body)
		prop_spawner_body.global_position = position
		prop_spawner_body.add_to_group("props")
		_apply_prop_transform(prop_spawner_body, prop_spawner_scale_value)
		return
	var prop_spawner_body := StaticBody3D.new()
	add_child(prop_spawner_body)
	prop_spawner_body.global_position = position
	prop_spawner_body.add_to_group("props")
	prop_spawner_body.add_child(prop_spawner_instance)

	_apply_prop_transform(prop_spawner_instance, prop_spawner_scale_value)
	var prop_spawner_collision_size: Vector3 = (
		prop_spawner_definition["collision_size"] * prop_spawner_scale_value
	)
	var prop_spawner_shape := BoxShape3D.new()
	prop_spawner_shape.size = prop_spawner_collision_size
	var prop_spawner_collision := CollisionShape3D.new()
	prop_spawner_collision.shape = prop_spawner_shape
	prop_spawner_collision.position = Vector3(0.0, prop_spawner_collision_size.y * 0.5, 0.0)
	prop_spawner_body.add_child(prop_spawner_collision)


func _apply_prop_transform(prop_spawner_node: Node, prop_spawner_scale_value: float) -> void:
	if not prop_spawner_node is Node3D:
		return
	var prop_spawner_node_3d := prop_spawner_node as Node3D
	prop_spawner_node_3d.scale = Vector3.ONE * prop_spawner_scale_value
	prop_spawner_node_3d.rotation.y = prop_spawner_rng.randf_range(0.0, TAU)


func _resolve_scale_value(prop_spawner_definition: Dictionary) -> float:
	var prop_spawner_scale_range: Vector2 = prop_spawner_definition["scale_range"]
	return prop_spawner_rng.randf_range(prop_spawner_scale_range.x, prop_spawner_scale_range.y)


func _schedule_next_loot_crate_drop() -> void:
	prop_spawner_loot_crate_timer = 0.0
	var prop_spawner_min: float = max(1.0, loot_crate_min_delay)
	var prop_spawner_max: float = max(prop_spawner_min, loot_crate_max_delay)
	prop_spawner_loot_crate_target = prop_spawner_rng.randf_range(
		prop_spawner_min, prop_spawner_max
	)


func _spawn_loot_crate_drop() -> void:
	if loot_crate_scene == null:
		return
	var prop_spawner_landing_position := _random_position(map_size * 0.5)
	var prop_spawner_spawn_position := prop_spawner_landing_position
	prop_spawner_spawn_position.y = spawn_height + loot_crate_drop_height
	var prop_spawner_crate_instance: Node = loot_crate_scene.instantiate()
	if not prop_spawner_crate_instance is Node3D:
		return
	add_child(prop_spawner_crate_instance)
	var prop_spawner_crate_node := prop_spawner_crate_instance as Node3D
	prop_spawner_crate_node.global_position = prop_spawner_spawn_position
	if prop_spawner_crate_node.has_method("begin_drop"):
		prop_spawner_crate_node.call_deferred("begin_drop", spawn_height)
