###############################################################
# enemies/test_enemy.gd
# Key Classes      • TestEnemy – simple target dummy
# Key Functions    • apply_damage() – reduce health and despawn
# Critical Consts  • n/a
# Editor Exports   • health: float – hit points
# Dependencies     • n/a
# Last Major Rev   • 25-09-20 – initial test enemy
###############################################################

class_name TestEnemy
extends StaticBody3D

@export var health: float = 12.0


func _ready() -> void:
	add_to_group("enemies")


func apply_damage(amount: float) -> void:
	health -= amount
	if health <= 0.0:
		queue_free()
