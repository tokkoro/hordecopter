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
#                 • res://ui/damage_label_3d.tscn
# Last Major Rev   • 25-09-27 – add toggleable enemy health bar
###############################################################

class_name MedusaFlyer
extends EnemyBase

@export var move_speed: float = 4.0
@export var wave_amplitude: float = 1.6
@export var wave_frequency: float = 0.8

var medusa_flyer_direction: Vector3 = Vector3.FORWARD
var medusa_flyer_target: Node3D
var medusa_flyer_time: float = 0.0
var medusa_flyer_base_height: float = 0.0
@onready var medusa_flyer_head: Node3D = $MedusaHead


func _ready() -> void:
	super()
	medusa_flyer_direction = medusa_flyer_direction.normalized()
	medusa_flyer_target = _find_player()
	medusa_flyer_base_height = global_position.y
	if medusa_flyer_target == null:
		push_warning("MedusaFlyer: player target not found; using fallback direction.")


func _physics_process(delta: float) -> void:
	if is_time_stopped():
		velocity = Vector3.ZERO
		move_and_slide()
		return
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
	_update_facing(medusa_flyer_move_direction)
	move_and_slide()


func configure_spawn_direction(direction: Vector3) -> void:
	if direction != Vector3.ZERO:
		medusa_flyer_direction = direction.normalized()


func _update_facing(direction: Vector3) -> void:
	if medusa_flyer_head == null:
		return
	if direction.length() <= 0.01:
		return
	medusa_flyer_head.look_at(medusa_flyer_head.global_position + direction, Vector3.UP)
	medusa_flyer_head.rotate_y(PI)
