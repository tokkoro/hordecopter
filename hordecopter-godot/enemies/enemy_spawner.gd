###############################################################
# enemies/enemy_spawner.gd
# Key Classes      • EnemySpawner – timed enemy spawn controller
# Key Functions    • _spawn_group() – instance and place a batch of enemies
#                 • _spawn_flyover_enemy() – spawn a flying enemy outside the map
# Critical Consts  • n/a
# Editor Exports   • ground_enemy_scenes: Array[PackedScene] – wandering enemy types
#                 • flyover_enemy_scenes: Array[PackedScene] – flying enemy types
#                 • spawn_effect_scene: PackedScene – spawn cue visual
#                 • spawn_interval_max: float – initial time between spawns
#                 • spawn_interval_min: float – fastest time between spawns
#                 • spawn_ramp_duration: float – seconds to reach max difficulty
#                 • max_enemies: int – global enemy cap
#                 • group_size_min: int – count spawned per wave at start
#                 • group_size_max: int – count spawned per wave at peak
#                 • map_size: float – world size in meters
#                 • spawn_height: float – ground enemy vertical offset
#                 • flyover_height: float – flyover enemy height
#                 • flyover_spawn_margin: float – extra distance from map edge
#                 • spawn_cluster_radius: float – spacing for group spawns
# Dependencies     • res://enemies/test_enemy.tscn (assigned in scene)
#                 • res://enemies/medusa_flyer.tscn
#                 • res://enemies/enemy_spawn_effect.tscn
#                 • res://game_state.gd
# Last Major Rev   • 25-09-27 – add medusa flyer spawns
###############################################################

class_name EnemySpawner
extends Node3D

@export var ground_enemy_scenes: Array[PackedScene] = []
@export var spawn_effect_scene: PackedScene = preload("res://enemies/enemy_spawn_effect.tscn")
@export var spawn_interval_max: float = 6.0
@export var spawn_interval_min: float = 2.5
@export var spawn_ramp_duration: float = 180.0
@export var max_enemies: int = 100
@export var group_size_min: int = 1
@export var group_size_max: int = 5
@export var map_size: float = 100.0
@export var spawn_height: float = 0.6
@export var flyover_height: float = 6.0
@export var flyover_spawn_margin: float = 20.0
@export var spawn_cluster_radius: float = 3.0

var enemy_spawner_elapsed: float = 0.0
var enemy_spawner_elite_chance_step: float = 0.07
var enemy_spawner_elite_chance: float = enemy_spawner_elite_chance_step
var enemy_spawner_rng: RandomNumberGenerator = RandomNumberGenerator.new()
var enemy_spawner_warned_missing_scene: bool = false
var enemy_spawner_warned_bad_interval: bool = false

var enemy_pool

@onready var game_state: GameState = get_node("../GameState")


func _ready() -> void:
	enemy_spawner_rng.randomize()


func _process(delta: float) -> void:
	if ground_enemy_scenes.is_empty():
		if not enemy_spawner_warned_missing_scene:
			enemy_spawner_warned_missing_scene = true
			push_warning("EnemySpawner: no enemy scenes assigned; cannot spawn enemies.")
			return
	var enemy_spawner_interval := _resolve_spawn_interval()
	if enemy_spawner_interval <= 0.0:
		if not enemy_spawner_warned_bad_interval:
			enemy_spawner_warned_bad_interval = true
			push_warning("EnemySpawner: spawn_interval must be > 0 to spawn enemies.")
		return
	var enemy_spawner_group_size := _resolve_group_size()
	enemy_spawner_elapsed += delta
	while enemy_spawner_elapsed >= enemy_spawner_interval:
		enemy_spawner_elapsed -= enemy_spawner_interval
		if _can_spawn(enemy_spawner_group_size):
			_spawn_group(enemy_spawner_group_size)
		else:
			break


func _can_spawn(requested_count: int) -> bool:
	return get_tree().get_nodes_in_group("enemies").size() + requested_count <= max_enemies


func _spawn_group(enemy_spawner_group_size: int) -> void:
	var enemy := _pick_enemy_scene(ground_enemy_scenes)
	if enemy == null:
		return
	if "fly" in enemy.get_state().get_node_name(0):
		_spawn_flyover_group(enemy, enemy_spawner_group_size)
	else:
		_spawn_ground_group(enemy, enemy_spawner_group_size)


func _spawn_ground_group(enemy_scene: PackedScene, enemy_spawner_group_size: int) -> void:
	var enemy_spawner_base_position := _random_ground_position()
	for enemy_spawner_index in range(enemy_spawner_group_size):
		var enemy_spawner_position := enemy_spawner_base_position + _random_cluster_offset()
		_spawn_with_effect(enemy_scene, enemy_spawner_position, Callable())


func _spawn_flyover_group(enemy_scene: PackedScene, enemy_spawner_group_size: int) -> void:
	if enemy_scene == null:
		return
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
	var enemy_spawner_configure := Callable(self, "_configure_flyover_enemy").bind(
		enemy_spawner_direction
	)
	for enemy_spawner_index in range(enemy_spawner_group_size):
		var enemy_spawner_position_offset := _random_flyover_offset(enemy_spawner_side)
		var enemy_spawner_spawn := enemy_spawner_position + enemy_spawner_position_offset
		_spawn_with_effect(enemy_scene, enemy_spawner_spawn, enemy_spawner_configure)


func _spawn_ground_enemy(enemy_scene: PackedScene) -> void:
	var enemy_spawner_position := _random_ground_position()
	_spawn_with_effect(enemy_scene, enemy_spawner_position, Callable())


func _spawn_flyover_enemy(enemy_scene: PackedScene) -> void:
	if enemy_scene == null:
		return
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
	var enemy_spawner_configure := Callable(self, "_configure_flyover_enemy").bind(
		enemy_spawner_direction
	)
	_spawn_with_effect(enemy_scene, enemy_spawner_position, enemy_spawner_configure)


func _random_ground_position() -> Vector3:
	var enemy_spawner_half: float = map_size * 0.5
	return Vector3(
		enemy_spawner_rng.randf_range(-enemy_spawner_half, enemy_spawner_half),
		spawn_height,
		enemy_spawner_rng.randf_range(-enemy_spawner_half, enemy_spawner_half)
	)


func _random_cluster_offset() -> Vector3:
	var enemy_spawner_radius: float = max(0.0, spawn_cluster_radius)
	if enemy_spawner_radius <= 0.0:
		return Vector3.ZERO
	var enemy_spawner_angle := enemy_spawner_rng.randf_range(0.0, TAU)
	var enemy_spawner_distance := enemy_spawner_rng.randf_range(0.0, enemy_spawner_radius)
	return Vector3(
		cos(enemy_spawner_angle) * enemy_spawner_distance,
		0.0,
		sin(enemy_spawner_angle) * enemy_spawner_distance
	)


func _random_flyover_offset(enemy_spawner_side: int) -> Vector3:
	var enemy_spawner_offset := _random_cluster_offset()
	match enemy_spawner_side:
		0, 1:
			return Vector3(0.0, 0.0, enemy_spawner_offset.z)
		2, 3:
			return Vector3(enemy_spawner_offset.x, 0.0, 0.0)
	return Vector3.ZERO


func _apply_time_scaling(enemy_instance: Node) -> void:
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


func _spawn_with_effect(
	enemy_scene: PackedScene, spawn_position: Vector3, configure_callback: Callable
) -> void:
	if enemy_scene == null:
		return
	var enemy_spawner_effect := _create_spawn_effect(spawn_position)
	if enemy_spawner_effect == null:
		_spawn_enemy_instance(enemy_scene, spawn_position, configure_callback)
		return
	enemy_spawner_effect.spawn_ready.connect(
		_on_spawn_effect_ready.bind(enemy_scene, spawn_position, configure_callback)
	)


func _create_spawn_effect(spawn_position: Vector3) -> Node3D:
	if spawn_effect_scene == null:
		return null
	var enemy_spawner_effect: Node3D = spawn_effect_scene.instantiate()
	get_tree().current_scene.add_child(enemy_spawner_effect)
	enemy_spawner_effect.global_position = spawn_position
	return enemy_spawner_effect


func _on_spawn_effect_ready(
	enemy_scene: PackedScene, spawn_position: Vector3, configure_callback: Callable
) -> void:
	_spawn_enemy_instance(enemy_scene, spawn_position, configure_callback)


func _spawn_enemy_instance(
	enemy_scene: PackedScene, spawn_position: Vector3, configure_callback: Callable
) -> void:
	var enemy_spawner_instance: Node3D = enemy_scene.instantiate()
	get_tree().current_scene.add_child(enemy_spawner_instance)
	enemy_spawner_instance.global_position = spawn_position
	if configure_callback.is_valid():
		configure_callback.call(enemy_spawner_instance)
	_apply_time_scaling(enemy_spawner_instance)
	_apply_elite_roll(enemy_spawner_instance)


func _apply_elite_roll(enemy_instance: Node3D) -> void:
	if not _can_apply_elite(enemy_instance):
		return
	var enemy_spawner_is_elite: bool = enemy_spawner_rng.randf() <= enemy_spawner_elite_chance
	if enemy_spawner_is_elite:
		enemy_spawner_elite_chance = enemy_spawner_elite_chance_step
		if enemy_instance.has_method("configure_elite"):
			enemy_instance.call("configure_elite")
	else:
		enemy_spawner_elite_chance = min(
			1.0, enemy_spawner_elite_chance + enemy_spawner_elite_chance_step
		)


func _can_apply_elite(enemy_instance: Node3D) -> bool:
	if enemy_instance.has_method("get_has_elite_form"):
		return enemy_instance.call("get_has_elite_form")
	return true


func _configure_flyover_enemy(enemy_instance: Node3D, travel_direction: Vector3) -> void:
	if enemy_instance.has_method("configure_spawn_direction"):
		enemy_instance.call("configure_spawn_direction", travel_direction)
	elif enemy_instance.has_method("configure_flyover"):
		enemy_instance.call("configure_flyover", travel_direction)


func _has_valid_scene(enemy_scenes: Array[PackedScene]) -> bool:
	for enemy_spawner_scene in enemy_scenes:
		if enemy_spawner_scene != null:
			return true
	return false


func _pick_enemy_scene(enemy_scenes: Array[PackedScene]) -> PackedScene:
	if enemy_scenes.is_empty():
		return null
	var enemy_spawner_candidates: Array[PackedScene] = []
	# time per 2min on max index
	var time_based_max_size = int(game_state.get_elapsed_time() / 120)

	for enemy_spawner_scene in enemy_scenes:
		if enemy_spawner_scene != null:
			enemy_spawner_candidates.append(enemy_spawner_scene)
		else:
			push_warning("Sun vihu puuttuu!")
		if enemy_spawner_candidates.size() >= time_based_max_size:
			break

	if enemy_spawner_candidates.is_empty():
		push_warning("Sun vihu vaihtoehdot puuttuu!")
		return null

	var index = enemy_spawner_candidates.size() - 1
	while index > 0:
		if randf() > 0.5:
			return enemy_spawner_candidates[index]
		index -= 1
	return enemy_spawner_candidates[0]


func _resolve_spawn_interval() -> float:
	var enemy_spawner_elapsed_time := _get_elapsed_time()
	var enemy_spawner_ratio := _resolve_spawn_ratio(enemy_spawner_elapsed_time)
	return lerp(spawn_interval_max, spawn_interval_min, enemy_spawner_ratio)


func _resolve_group_size() -> int:
	var enemy_spawner_elapsed_time := _get_elapsed_time()
	var enemy_spawner_ratio := _resolve_spawn_ratio(enemy_spawner_elapsed_time)
	var enemy_spawner_size: float = lerp(
		float(group_size_min), float(group_size_max), enemy_spawner_ratio
	)
	return max(1, int(round(enemy_spawner_size)))


func _resolve_spawn_ratio(enemy_spawner_elapsed_time: float) -> float:
	if spawn_ramp_duration <= 0.0:
		return 1.0
	return clamp(enemy_spawner_elapsed_time / spawn_ramp_duration, 0.0, 1.0)


func _get_elapsed_time() -> float:
	if game_state != null and game_state.has_method("get_elapsed_time"):
		return float(game_state.get_elapsed_time())
	return 0.0
