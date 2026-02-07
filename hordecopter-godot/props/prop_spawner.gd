###############################################################
# props/prop_spawner.gd
# Key Classes      • PropSpawner – scatters static props with collisions
# Key Functions    • _spawn_props() – place props around the map
#                 • _load_prop_definitions() – load prop scenes and metadata
# Critical Consts  • PROP_DEFAULT_PATHS – models to scatter
# Editor Exports   • prop_paths: Array[String] – list of model scene paths
#                 • prop_count: int – number of props to place
#                 • map_size: float – map width/length in meters
#                 • map_padding: float – keep props inside bounds
#                 • spawn_height: float – ground height for props
#                 • min_spacing: float – minimum spacing between props
#                 • center_clear_radius: float – keep props away from center
# Dependencies     • res://models/tree.glb (optional)
#                 • res://models/rock.glb (optional)
#                 • res://models/bush.glb (optional)
# Last Major Rev   • 25-09-28 – initial prop scattering
###############################################################

class_name PropSpawner
extends Node3D

const PROP_DEFAULT_PATHS: Array[String] = [
	"res://models/tree.glb",
	"res://models/rock.glb",
	"res://models/bush.glb",
	"res://props/loot_crate.tscn"
]

const PROP_COLLISION_SIZES := {
	"res://models/tree.glb": Vector3(1.3, 2.0, 1.3),
	"res://models/rock.glb": Vector3(1.7, 0.9, 1.7),
	"res://models/bush.glb": Vector3(1.3, 1.7, 1.3),
	"res://props/loot_crate.tscn": Vector3(1.2, 1.2, 1.2)
}

const PROP_SCALE_RANGES := {
	"res://models/tree.glb": Vector2(1.9, 2.6),
	"res://models/rock.glb": Vector2(0.8, 1.8),
	"res://models/bush.glb": Vector2(0.9, 1.9),
	"res://props/loot_crate.tscn": Vector2(1.0, 1.0)
}

@export var prop_paths: Array[String] = PROP_DEFAULT_PATHS.duplicate()
@export var prop_count: int = 24
@export var map_size: float = 100.0
@export var map_padding: float = 6.0
@export var spawn_height: float = 0.0
@export var min_spacing: float = 5.0
@export var center_clear_radius: float = 10.0
@export var max_attempts: int = 200

var prop_spawner_rng: RandomNumberGenerator = RandomNumberGenerator.new()


func _ready() -> void:
	prop_spawner_rng.randomize()
	_spawn_props()


func _spawn_props() -> void:
	var prop_spawner_definitions := _load_prop_definitions()
	if prop_spawner_definitions.is_empty():
		push_warning("PropSpawner: no prop scenes found; nothing to spawn.")
		return
	if prop_count <= 0:
		return
	var prop_spawner_positions: Array[Vector3] = []
	var prop_spawner_half: float = map_size * 0.5
	var prop_spawner_attempts: int = 0
	while prop_spawner_positions.size() < prop_count and prop_spawner_attempts < max_attempts:
		prop_spawner_attempts += 1
		var prop_spawner_position := _random_position(prop_spawner_half)
		if not _is_position_valid(prop_spawner_position, prop_spawner_positions):
			continue
		prop_spawner_positions.append(prop_spawner_position)
		var prop_spawner_definition := prop_spawner_definitions[prop_spawner_rng.randi_range(
			0, prop_spawner_definitions.size() - 1
		)]
		_spawn_prop(prop_spawner_definition, prop_spawner_position)


func _random_position(prop_spawner_half: float) -> Vector3:
	var prop_spawner_x := prop_spawner_rng.randf_range(
		-prop_spawner_half + map_padding, prop_spawner_half - map_padding
	)
	var prop_spawner_z := prop_spawner_rng.randf_range(
		-prop_spawner_half + map_padding, prop_spawner_half - map_padding
	)
	return Vector3(prop_spawner_x, spawn_height, prop_spawner_z)


func _is_position_valid(position: Vector3, existing: Array[Vector3]) -> bool:
	if position.length() < center_clear_radius:
		return false
	for prop_spawner_existing in existing:
		if position.distance_to(prop_spawner_existing) < min_spacing:
			return false
	return true


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
