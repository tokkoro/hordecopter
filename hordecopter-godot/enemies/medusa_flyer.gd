###############################################################
# enemies/medusa_flyer.gd
# Key Classes      • MedusaFlyer – airborne seeker with sine bob
# Key Functions    • configure_spawn_direction() – fallback travel heading
#                 • apply_damage() – reduce health and despawn
#                 • _find_player() – locate the player target
# Critical Consts  • n/a
# Editor Exports   • health: float – hit points
#                 • move_speed: float – travel speed
#                 • wave_amplitude: float – vertical wave height
#                 • wave_frequency: float – wave cycles per second
# Dependencies     • res://enemies/enemy_health_bar.tscn
# Last Major Rev   • 25-09-27 – add toggleable enemy health bar
###############################################################

class_name MedusaFlyer
extends CharacterBody3D

@export var health: float = 4.0
@export var move_speed: float = 16.0
@export var wave_amplitude: float = 1.6
@export var wave_frequency: float = 0.8

var medusa_flyer_direction: Vector3 = Vector3.FORWARD
var medusa_flyer_target: Node3D
var medusa_flyer_time: float = 0.0
var medusa_flyer_base_height: float = 0.0
var medusa_flyer_max_health: float = 1.0

@onready
var medusa_flyer_health_bar: EnemyHealthBar3D = get_node_or_null("HealthBar3D") as EnemyHealthBar3D


func _ready() -> void:
	add_to_group("enemies")
	medusa_flyer_direction = medusa_flyer_direction.normalized()
	medusa_flyer_target = _find_player()
	medusa_flyer_base_height = global_position.y
	medusa_flyer_max_health = max(1.0, health)
	_update_health_bar()
	if medusa_flyer_target == null:
		push_warning("MedusaFlyer: player target not found; using fallback direction.")


func _physics_process(delta: float) -> void:
	medusa_flyer_time += delta
	if medusa_flyer_target == null:
		medusa_flyer_target = _find_player()
	var medusa_flyer_move_direction: Vector3 = medusa_flyer_direction
	var medusa_flyer_target_height: float = medusa_flyer_base_height
	if medusa_flyer_target != null:
		var medusa_flyer_to_target: Vector3 = medusa_flyer_target.global_position - global_position
		medusa_flyer_target_height = medusa_flyer_target.global_position.y
		medusa_flyer_to_target.y = 0.0
		if medusa_flyer_to_target.length() > 0.01:
			medusa_flyer_move_direction = medusa_flyer_to_target.normalized()
	var medusa_flyer_desired_y: float = (
		medusa_flyer_target_height + sin(medusa_flyer_time * TAU * wave_frequency) * wave_amplitude
	)
	var medusa_flyer_vertical_velocity: float = (
		(medusa_flyer_desired_y - global_position.y) / max(delta, 0.000001)
	)
	velocity = medusa_flyer_move_direction * move_speed
	velocity.y = medusa_flyer_vertical_velocity
	move_and_slide()


func configure_spawn_direction(direction: Vector3) -> void:
	if direction != Vector3.ZERO:
		medusa_flyer_direction = direction.normalized()


func apply_damage(amount: float) -> void:
	health -= amount
	_update_health_bar()
	if health <= 0.0:
		queue_free()


func _update_health_bar() -> void:
	if medusa_flyer_health_bar == null:
		return
	medusa_flyer_health_bar.set_health(health, medusa_flyer_max_health)


func _find_player() -> Node3D:
	var medusa_flyer_player := get_tree().get_first_node_in_group("player")
	if medusa_flyer_player is Node3D:
		return medusa_flyer_player
	return null
