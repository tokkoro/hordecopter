###############################################################
# enemies/flyover_enemy.gd
# Key Classes      • FlyoverEnemy – high-speed flyover target
# Key Functions    • configure_flyover() – set travel direction
#                 • apply_damage() – reduce health and despawn
# Critical Consts  • n/a
# Editor Exports   • health: float – hit points
#                 • flyover_speed: float – travel speed
# Dependencies     • res://enemies/enemy_health_bar.tscn
# Last Major Rev   • 25-09-27 – add toggleable enemy health bar
###############################################################

class_name FlyoverEnemy
extends CharacterBody3D

@export var health: float = 4.0
@export var flyover_speed: float = 4.0

var flyover_enemy_direction: Vector3 = Vector3.FORWARD
var flyover_enemy_max_health: float = 1.0

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
	health -= amount
	_update_health_bar()
	if health <= 0.0:
		queue_free()


func _update_health_bar() -> void:
	if flyover_enemy_health_bar == null:
		return
	flyover_enemy_health_bar.set_health(health, flyover_enemy_max_health)
