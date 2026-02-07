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
extends EnemyBase

@export var flyover_speed: float = 4.0

var flyover_enemy_direction: Vector3 = Vector3.FORWARD


func _ready() -> void:
	super()
	flyover_enemy_direction = flyover_enemy_direction.normalized()


func _physics_process(_delta: float) -> void:
	velocity = flyover_enemy_direction * flyover_speed
	move_and_slide()


func configure_flyover(direction: Vector3) -> void:
	if direction != Vector3.ZERO:
		flyover_enemy_direction = direction.normalized()


func configure_spawn_direction(direction: Vector3) -> void:
	configure_flyover(direction)
