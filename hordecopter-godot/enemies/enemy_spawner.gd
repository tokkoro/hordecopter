###############################################################
# enemies/enemy_spawner.gd
# Key Classes      • EnemySpawner – timed enemy spawn controller
# Key Functions    • _spawn_enemy() – instance and place an enemy
# Critical Consts  • n/a
# Editor Exports   • enemy_scene: PackedScene – enemy to spawn
#                 • spawn_interval: float – time between spawns
#                 • max_enemies: int – global enemy cap
#                 • spawn_radius: float – radius around spawner
#                 • spawn_height: float – vertical spawn offset
# Dependencies     • res://enemies/test_enemy.tscn (assigned in scene)
#                 • res://game_state.gd
# Last Major Rev   • 25-09-27 – add time-based enemy scaling
###############################################################

class_name EnemySpawner
extends Node3D

@export var enemy_scene: PackedScene
@export var spawn_interval: float = 1.0
@export var max_enemies: int = 100
@export var spawn_radius: float = 20.0
@export var spawn_height: float = 0.6

var enemy_spawner_elapsed: float = 0.0
var enemy_spawner_rng: RandomNumberGenerator = RandomNumberGenerator.new()
var enemy_spawner_warned_missing_scene: bool = false
var enemy_spawner_warned_bad_interval: bool = false


func _ready() -> void:
	enemy_spawner_rng.randomize()


func _process(delta: float) -> void:
	if enemy_scene == null:
		if not enemy_spawner_warned_missing_scene:
			enemy_spawner_warned_missing_scene = true
			push_warning("EnemySpawner: enemy_scene is missing; cannot spawn enemies.")
		return
	if spawn_interval <= 0.0:
		if not enemy_spawner_warned_bad_interval:
			enemy_spawner_warned_bad_interval = true
			push_warning("EnemySpawner: spawn_interval must be > 0 to spawn enemies.")
		return
	enemy_spawner_elapsed += delta
	while enemy_spawner_elapsed >= spawn_interval:
		enemy_spawner_elapsed -= spawn_interval
		if _can_spawn():
			_spawn_enemy()
		else:
			break


func _can_spawn() -> bool:
	return get_tree().get_nodes_in_group("enemies").size() < max_enemies


func _spawn_enemy() -> void:
	var enemy_spawner_instance: Node3D = enemy_scene.instantiate()
	var enemy_spawner_offset: Vector3 = _random_offset()
	enemy_spawner_instance.global_position = global_position + enemy_spawner_offset
	get_tree().current_scene.add_child(enemy_spawner_instance)
	_apply_time_scaling(enemy_spawner_instance)


func _random_offset() -> Vector3:
	var enemy_spawner_angle: float = enemy_spawner_rng.randf_range(0.0, TAU)
	var enemy_spawner_radius: float = sqrt(enemy_spawner_rng.randf()) * spawn_radius
	return Vector3(
		cos(enemy_spawner_angle) * enemy_spawner_radius,
		spawn_height,
		sin(enemy_spawner_angle) * enemy_spawner_radius
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
