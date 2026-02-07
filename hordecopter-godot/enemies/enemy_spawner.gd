###############################################################
# enemies/enemy_spawner.gd
# Key Classes      • EnemySpawner – timed enemy spawn controller
# Key Functions    • _spawn_group() – instance and place a batch of enemies
#                 • _spawn_medusa_flyer() – spawn a flying enemy outside the map
# Critical Consts  • n/a
# Editor Exports   • ground_enemy_scene: PackedScene – wandering enemy type
#                 • medusa_flyer_scene: PackedScene – flying enemy type
#                 • flyover_enemy_scene: PackedScene – legacy flyover type (unused)
#                 • spawn_interval: float – time between spawns
#                 • max_enemies: int – global enemy cap
#                 • group_size: int – count spawned per wave
#                 • map_size: float – world size in meters
#                 • spawn_height: float – ground enemy vertical offset
#                 • flyover_height: float – flyover enemy height
#                 • flyover_spawn_margin: float – extra distance from map edge
# Dependencies     • res://enemies/test_enemy.tscn (assigned in scene)
#                 • res://enemies/medusa_flyer.tscn
#                 • res://game_state.gd
# Last Major Rev   • 25-09-27 – add medusa flyer spawns
###############################################################

class_name EnemySpawner
extends Node3D

@export var ground_enemy_scene: PackedScene
@export var medusa_flyer_scene: PackedScene = preload("res://enemies/medusa_flyer.tscn")
@export var flyover_enemy_scene: PackedScene
@export var spawn_interval: float = 5.0
@export var max_enemies: int = 100
@export var group_size: int = 3
@export var map_size: float = 100.0
@export var spawn_height: float = 0.6
@export var flyover_height: float = 6.0
@export var flyover_spawn_margin: float = 20.0

var enemy_spawner_elapsed: float = 0.0
var enemy_spawner_rng: RandomNumberGenerator = RandomNumberGenerator.new()
var enemy_spawner_warned_missing_scene: bool = false
var enemy_spawner_warned_bad_interval: bool = false


func _ready() -> void:
	enemy_spawner_rng.randomize()


func _process(delta: float) -> void:
	if ground_enemy_scene == null:
		if not enemy_spawner_warned_missing_scene:
			enemy_spawner_warned_missing_scene = true
			push_warning("EnemySpawner: ground_enemy_scene is missing; cannot spawn enemies.")
	if medusa_flyer_scene == null:
		if not enemy_spawner_warned_missing_scene:
			enemy_spawner_warned_missing_scene = true
			push_warning("EnemySpawner: medusa_flyer_scene is missing; cannot spawn enemies.")
	if spawn_interval <= 0.0:
		if not enemy_spawner_warned_bad_interval:
			enemy_spawner_warned_bad_interval = true
			push_warning("EnemySpawner: spawn_interval must be > 0 to spawn enemies.")
		return
	enemy_spawner_elapsed += delta
	while enemy_spawner_elapsed >= spawn_interval:
		enemy_spawner_elapsed -= spawn_interval
		if _can_spawn(group_size):
			_spawn_group()
		else:
			break


func _can_spawn(requested_count: int) -> bool:
	return get_tree().get_nodes_in_group("enemies").size() + requested_count <= max_enemies


func _spawn_group() -> void:
	var enemy_spawner_pick_ground: bool = enemy_spawner_rng.randf() < 0.5
	for enemy_spawner_index in range(group_size):
		if enemy_spawner_pick_ground:
			_spawn_ground_enemy()
		else:
			_spawn_ground_enemy()
			#wa_spawn_medusa_flyer()


func _spawn_ground_enemy() -> void:
	var enemy_spawner_instance: Node3D = ground_enemy_scene.instantiate()
	get_tree().current_scene.add_child(enemy_spawner_instance)
	enemy_spawner_instance.global_position = _random_ground_position()
	_apply_time_scaling(enemy_spawner_instance)


func _spawn_medusa_flyer() -> void:
	if medusa_flyer_scene == null:
		return
	var enemy_spawner_instance: Node3D = medusa_flyer_scene.instantiate()
	var enemy_spawner_side: int = enemy_spawner_rng.randi_range(0, 3)
	var enemy_spawner_half: float = map_size * 0.5
	var enemy_spawner_margin: float = enemy_spawner_half + flyover_spawn_margin
	var enemy_spawner_position: Vector3 = Vector3.ZERO
	var enemy_spawner_direction: Vector3 = Vector3.ZERO
	match enemy_spawner_side:
		0:
			enemy_spawner_position = Vector3(
				-enemy_spawner_margin,
				flyover_height,
				enemy_spawner_rng.randf_range(-enemy_spawner_half, enemy_spawner_half)
			)
			enemy_spawner_direction = Vector3.RIGHT
		1:
			enemy_spawner_position = Vector3(
				enemy_spawner_margin,
				flyover_height,
				enemy_spawner_rng.randf_range(-enemy_spawner_half, enemy_spawner_half)
			)
			enemy_spawner_direction = Vector3.LEFT
		2:
			enemy_spawner_position = Vector3(
				enemy_spawner_rng.randf_range(-enemy_spawner_half, enemy_spawner_half),
				flyover_height,
				-enemy_spawner_margin
			)
			enemy_spawner_direction = Vector3.FORWARD
		3:
			enemy_spawner_position = Vector3(
				enemy_spawner_rng.randf_range(-enemy_spawner_half, enemy_spawner_half),
				flyover_height,
				enemy_spawner_margin
			)
			enemy_spawner_direction = Vector3.BACK
	get_tree().current_scene.add_child(enemy_spawner_instance)
	enemy_spawner_instance.global_position = enemy_spawner_position
	if enemy_spawner_instance.has_method("configure_spawn_direction"):
		enemy_spawner_instance.call("configure_spawn_direction", enemy_spawner_direction)


func _random_ground_position() -> Vector3:
	var enemy_spawner_half: float = map_size * 0.5
	return Vector3(
		enemy_spawner_rng.randf_range(-enemy_spawner_half, enemy_spawner_half),
		spawn_height,
		enemy_spawner_rng.randf_range(-enemy_spawner_half, enemy_spawner_half)
	)


func _apply_time_scaling(enemy_instance: Node) -> void:
	var game_state := get_tree().get_first_node_in_group("game_state")
	if game_state == null:
		push_warning("EnemySpawner: GameState not found; skipping time scaling.")
		return
	if not game_state.has_method("get_elapsed_time"):
		push_warning("EnemySpawner: GameState missing get_elapsed_time; skipping scaling.")
		return
	if enemy_instance.has_method("configure_from_time"):
		enemy_instance.configure_from_time(game_state.get_elapsed_time())
	else:
		push_warning("EnemySpawner: Enemy missing configure_from_time; skipping scaling.")
