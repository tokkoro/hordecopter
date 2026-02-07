###############################################################
# enemies/flyover_enemy.gd
# Key Classes      • FlyoverEnemy – high-speed flyover target
# Key Functions    • configure_flyover() – set travel direction
#                 • apply_damage() – reduce health and despawn
# Critical Consts  • n/a
# Editor Exports   • health: float – hit points
#                 • flyover_speed: float – travel speed
# Dependencies     • res://enemies/enemy_health_bar.tscn
#                 • res://ui/damage_label_3d.tscn
# Last Major Rev   • 25-09-27 – add toggleable enemy health bar
###############################################################

class_name FlyoverEnemy
extends CharacterBody3D

const FLYOVER_ENEMY_HIT_SFX: AudioStream = preload("res://sfx/monster_hit.sfxr")

@export var health: float = 4.0
@export var flyover_speed: float = 4.0
@export var flyover_enemy_damage_label_scene: PackedScene = preload("res://ui/damage_label_3d.tscn")

var flyover_enemy_direction: Vector3 = Vector3.FORWARD
var flyover_enemy_max_health: float = 1.0
var flyover_enemy_is_elite: bool = false

@onready
var flyover_enemy_health_bar: EnemyHealthBar3D = get_node_or_null("HealthBar3D") as EnemyHealthBar3D


func _ready() -> void:
	add_to_group("enemies")
	flyover_enemy_direction = flyover_enemy_direction.normalized()
	flyover_enemy_max_health = max(1.0, health)
	_update_health_bar()


func _physics_process(_delta: float) -> void:
	velocity = flyover_enemy_direction * flyover_speed
	move_and_slide()


func configure_flyover(direction: Vector3) -> void:
	if direction != Vector3.ZERO:
		flyover_enemy_direction = direction.normalized()


func apply_damage(amount: float) -> void:
	_play_hit_sfx()
	_spawn_damage_label(amount)
	health -= amount
	_update_health_bar()
	if health <= 0.0:
		queue_free()


func configure_elite() -> void:
	if flyover_enemy_is_elite:
		return
	flyover_enemy_is_elite = true
	scale *= 2.0
	health *= 8.0
	flyover_enemy_max_health = max(1.0, health)
	_update_health_bar()


func _update_health_bar() -> void:
	if flyover_enemy_health_bar == null:
		return
	flyover_enemy_health_bar.set_health(health, flyover_enemy_max_health)


func _spawn_damage_label(amount: float) -> void:
	if flyover_enemy_damage_label_scene == null:
		return
	var flyover_enemy_label_instance := flyover_enemy_damage_label_scene.instantiate()
	var flyover_enemy_scene := get_tree().current_scene
	if flyover_enemy_scene == null:
		return
	flyover_enemy_scene.add_child(flyover_enemy_label_instance)
	if flyover_enemy_label_instance is Node3D:
		var flyover_enemy_label_node := flyover_enemy_label_instance as Node3D
		flyover_enemy_label_node.global_position = global_position + Vector3(0.0, 1.5, 0.0)
	if flyover_enemy_label_instance.has_method("set_damage"):
		flyover_enemy_label_instance.set_damage(amount)


func _play_hit_sfx() -> void:
	_play_sfx_at(FLYOVER_ENEMY_HIT_SFX, global_position)


func _play_sfx_at(stream: AudioStream, position: Vector3) -> void:
	if stream == null:
		return
	var current_scene := get_tree().current_scene
	if current_scene == null:
		return
	var player := AudioStreamPlayer3D.new()
	player.stream = stream
	player.global_position = position
	player.finished.connect(player.queue_free)
	current_scene.add_child(player)
	player.play()
