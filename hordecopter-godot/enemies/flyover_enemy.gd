###############################################################
# enemies/flyover_enemy.gd
# Key Classes      • FlyoverEnemy – seeker target with sinusoidal motion
# Key Functions    • configure_flyover() – set fallback travel direction
#                 • apply_damage() – reduce health and despawn
#                 • _find_player() – locate the player target
# Critical Consts  • n/a
# Editor Exports   • health: float – hit points
#                 • flyover_speed: float – travel speed
#                 • flyover_wave_amplitude: float – vertical wave height
#                 • flyover_wave_frequency: float – wave cycles per second
# Dependencies     • n/a
# Last Major Rev   • 25-09-27 – add player seek + sine movement
###############################################################

class_name FlyoverEnemy
extends CharacterBody3D

@export var health: float = 10.0
@export var flyover_speed: float = 18.0
@export var flyover_wave_amplitude: float = 1.5
@export var flyover_wave_frequency: float = 0.8

var flyover_enemy_direction: Vector3 = Vector3.FORWARD
var flyover_enemy_target: Node3D
var flyover_enemy_time: float = 0.0


func _ready() -> void:
	add_to_group("enemies")
	flyover_enemy_direction = flyover_enemy_direction.normalized()
	flyover_enemy_target = _find_player()
	if flyover_enemy_target == null:
		push_warning("FlyoverEnemy: player target not found; using fallback direction.")


func _physics_process(delta: float) -> void:
	flyover_enemy_time += delta
	if flyover_enemy_target == null:
		flyover_enemy_target = _find_player()
	var flyover_enemy_move_direction: Vector3 = flyover_enemy_direction
	var flyover_enemy_target_height: float = global_position.y
	if flyover_enemy_target != null:
		var flyover_enemy_to_target: Vector3 = (
			flyover_enemy_target.global_position - global_position
		)
		flyover_enemy_target_height = flyover_enemy_target.global_position.y
		flyover_enemy_to_target.y = 0.0
		if flyover_enemy_to_target.length() > 0.01:
			flyover_enemy_move_direction = flyover_enemy_to_target.normalized()
	var flyover_enemy_desired_y: float = (
		flyover_enemy_target_height
		+ sin(flyover_enemy_time * TAU * flyover_wave_frequency) * flyover_wave_amplitude
	)
	var flyover_enemy_vertical_velocity: float = (
		(flyover_enemy_desired_y - global_position.y) / max(delta, 0.000001)
	)
	velocity = flyover_enemy_move_direction * flyover_speed
	velocity.y = flyover_enemy_vertical_velocity
	move_and_slide()


func configure_flyover(direction: Vector3) -> void:
	if direction != Vector3.ZERO:
		flyover_enemy_direction = direction.normalized()


func apply_damage(amount: float) -> void:
	health -= amount
	if health <= 0.0:
		queue_free()


func _find_player() -> Node3D:
	var flyover_enemy_player := get_tree().get_first_node_in_group("player")
	if flyover_enemy_player is Node3D:
		return flyover_enemy_player
	return null
