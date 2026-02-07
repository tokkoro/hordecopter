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
# Last Major Rev   • 25-09-26 – initial spawner
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


func _ready() -> void:
	enemy_spawner_rng.randomize()


func _process(delta: float) -> void:
	if enemy_scene == null:
		return
	if spawn_interval <= 0.0:
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


func _random_offset() -> Vector3:
	var enemy_spawner_angle: float = enemy_spawner_rng.randf_range(0.0, TAU)
	var enemy_spawner_radius: float = sqrt(enemy_spawner_rng.randf()) * spawn_radius
	return Vector3(
		cos(enemy_spawner_angle) * enemy_spawner_radius,
		spawn_height,
		sin(enemy_spawner_angle) * enemy_spawner_radius
	)
