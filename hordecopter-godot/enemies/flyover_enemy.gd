###############################################################
# enemies/flyover_enemy.gd
# Key Classes      • FlyoverEnemy – high-speed flyover target
# Key Functions    • configure_flyover() – set travel direction
#                 • apply_damage() – reduce health and despawn
# Critical Consts  • n/a
# Editor Exports   • health: float – hit points
#                 • flyover_speed: float – travel speed
# Dependencies     • n/a
# Last Major Rev   • 25-09-26 – initial flyover enemy
###############################################################

class_name FlyoverEnemy
extends CharacterBody3D

@export var health: float = 4.0
@export var flyover_speed: float = 18.0

var flyover_enemy_direction: Vector3 = Vector3.FORWARD


func _ready() -> void:
	add_to_group("enemies")
	flyover_enemy_direction = flyover_enemy_direction.normalized()


func _physics_process(_delta: float) -> void:
	velocity = flyover_enemy_direction * flyover_speed
	move_and_slide()


func configure_flyover(direction: Vector3) -> void:
	if direction != Vector3.ZERO:
		flyover_enemy_direction = direction.normalized()


func apply_damage(amount: float) -> void:
	health -= amount
	if health <= 0.0:
		queue_free()
