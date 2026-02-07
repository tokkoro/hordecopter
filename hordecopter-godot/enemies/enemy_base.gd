###############################################################
# enemies/enemy_base.gd
# Key Classes      • EnemyBase – shared enemy health + damage flow
# Key Functions    • apply_damage() – handle damage and death flow
#                 • configure_elite() – scale elite stats
#                 • _find_player() – locate the player target
# Critical Consts  • n/a
# Editor Exports   • health: float – hit points
#                 • damage_label_scene: PackedScene – damage number visuals
# Dependencies     • res://enemies/enemy_health_bar.tscn
#                 • res://ui/damage_label_3d.tscn
# Last Major Rev   • 25-09-27 – add shared enemy base
###############################################################

class_name EnemyBase
extends CharacterBody3D

@export var health: float = 4.0
@export var damage_label_scene: PackedScene = preload("res://ui/damage_label_3d.tscn")

const ENEMY_HIT_SFX: AudioStream = preload("res://sfx/monster_hit.sfxr")


var enemy_base_max_health: float = 1.0
var enemy_base_is_elite: bool = false

@onready
var enemy_base_health_bar: EnemyHealthBar3D = get_node_or_null("HealthBar3D") as EnemyHealthBar3D


func _ready() -> void:
	add_to_group("enemies")
	enemy_base_max_health = max(1.0, health)
	_update_health_bar()


func apply_damage(amount: float) -> void:
	_spawn_damage_label(amount)
	_play_hit_sfx()
	health -= amount
	_update_health_bar()
	if health <= 0.0:
		_on_death()


func configure_elite() -> void:
	if enemy_base_is_elite:
		return
	enemy_base_is_elite = true
	scale *= 2.0
	health *= 8.0
	enemy_base_max_health = max(1.0, health)
	_update_health_bar()


func set_max_health(value: float) -> void:
	enemy_base_max_health = max(1.0, value)
	_update_health_bar()


func _on_death() -> void:
	queue_free()


func _update_health_bar() -> void:
	if enemy_base_health_bar == null:
		return
	enemy_base_health_bar.set_health(health, enemy_base_max_health)


func _spawn_damage_label(amount: float) -> void:
	if damage_label_scene == null:
		return
	var enemy_base_label_instance := damage_label_scene.instantiate()
	var enemy_base_scene := get_tree().current_scene
	if enemy_base_scene == null:
		return
	enemy_base_scene.add_child(enemy_base_label_instance)
	if enemy_base_label_instance is Node3D:
		var enemy_base_label_node := enemy_base_label_instance as Node3D
		enemy_base_label_node.global_position = global_position + Vector3(0.0, 1.5, 0.0)
	if enemy_base_label_instance.has_method("set_damage"):
		enemy_base_label_instance.set_damage(amount)


func _find_player() -> Node3D:
	var enemy_base_player := get_tree().get_first_node_in_group("player")
	if enemy_base_player is Node3D:
		return enemy_base_player
	return null

func _play_hit_sfx() -> void:
	_play_sfx_at(ENEMY_HIT_SFX, global_position)


func _play_sfx_at(stream: AudioStream, position: Vector3) -> void:
	if stream == null:
		push_warning("no stream for enemy audio")
		return
	var current_scene := get_tree().current_scene
	if current_scene == null:
		push_warning("no scene for enemy audio")
		return
	var player := AudioStreamPlayer3D.new()
	current_scene.add_child(player)
	player.stream = stream
	player.global_position = position
	player.finished.connect(player.queue_free)
	player.play()
