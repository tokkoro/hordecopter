###############################################################
# enemies/test_enemy.gd
# Key Classes      • TestEnemy – wandering target dummy
# Key Functions    • apply_damage() – reduce health and despawn
#                 • _pick_wander_direction() – choose a new wander heading
#                 • _find_player() – locate the player target
# Critical Consts  • n/a
# Editor Exports   • health: float – hit points
#                 • base_health: float – baseline health
#                 • health_per_second: float – time scaling for health
#                 • base_experience_reward: int – base exp reward
#                 • experience_token_scene: PackedScene – drop scene
#                 • test_enemy_climb_speed: float – vertical climb speed
#                 • test_enemy_climb_duration: float – climb time after bump
# Dependencies     • res://enemies/enemy_experience_manager.gd
#                 • res://items/experience_token.tscn
#                 • res://enemies/enemy_health_bar.tscn
#                 • res://ui/damage_label_3d.tscn
# Last Major Rev   • 25-09-27 – add toggleable enemy health bar
###############################################################

class_name TestEnemy
extends EnemyBase

@export var test_enemy_wander_speed: float = 2.5
@export var test_enemy_seek_speed: float = 1.5
@export var test_enemy_wander_interval: float = 1.5
@export var test_enemy_turn_speed: float = 2.0
@export var test_enemy_climb_speed: float = 2.0
@export var test_enemy_climb_duration: float = 0.35

var test_enemy_wander_direction: Vector3 = Vector3.ZERO
var test_enemy_wander_elapsed: float = 0.0
var test_enemy_climb_timer: float = 0.0
var test_enemy_rng: RandomNumberGenerator = RandomNumberGenerator.new()
var test_enemy_target: Node3D
var test_enemy_touching_prop: bool = false


func _ready() -> void:
	super()
	test_enemy_rng.randomize()
	_pick_wander_direction()
	test_enemy_target = _find_player()
	contact_monitor = true
	max_contacts_reported = 4


func _physics_process(delta: float) -> void:
	if is_time_stopped():
		linear_velocity = Vector3.ZERO
		angular_velocity = Vector3.ZERO
		return
	if test_enemy_target == null:
		test_enemy_target = _find_player()
	var test_enemy_has_target: bool = test_enemy_target != null
	if not test_enemy_has_target:
		test_enemy_wander_elapsed += delta
		if test_enemy_wander_elapsed >= test_enemy_wander_interval:
			test_enemy_wander_elapsed = 0.0
			_pick_wander_direction()
	else:
		test_enemy_wander_elapsed = 0.0
	var test_enemy_desired_direction: Vector3 = test_enemy_wander_direction
	if test_enemy_has_target:
		var test_enemy_to_target := test_enemy_target.global_position - global_position
		test_enemy_to_target.y = 0.0
		if test_enemy_to_target.length() > 0.01:
			test_enemy_desired_direction = test_enemy_to_target.normalized()
	var test_enemy_turn_weight: float = clamp(test_enemy_turn_speed * delta, 0.0, 1.0)
	if test_enemy_wander_direction.length() < 0.01:
		test_enemy_wander_direction = test_enemy_desired_direction
	else:
		test_enemy_wander_direction = test_enemy_wander_direction.slerp(
			test_enemy_desired_direction, test_enemy_turn_weight
		)
	if test_enemy_wander_direction.length() > 0.01:
		var test_enemy_yaw := atan2(test_enemy_wander_direction.x, test_enemy_wander_direction.z)
		rotation.y = lerp_angle(rotation.y, test_enemy_yaw, test_enemy_turn_weight)
	var test_enemy_speed: float = test_enemy_wander_speed
	if test_enemy_has_target:
		test_enemy_speed = test_enemy_seek_speed
	if test_enemy_touching_prop:
		test_enemy_climb_timer = test_enemy_climb_duration
	else:
		test_enemy_climb_timer = 0.0
	if test_enemy_climb_timer > 0.0:
		test_enemy_climb_timer = max(0.0, test_enemy_climb_timer - delta)
	var test_enemy_velocity := linear_velocity
	test_enemy_velocity.x = test_enemy_wander_direction.x * test_enemy_speed
	test_enemy_velocity.z = test_enemy_wander_direction.z * test_enemy_speed
	if test_enemy_climb_timer > 0.0:
		test_enemy_velocity.y = test_enemy_climb_speed
	linear_velocity = test_enemy_velocity


func _integrate_forces(state: PhysicsDirectBodyState3D) -> void:
	var test_enemy_prop_contact := false
	for test_enemy_contact_index in range(state.get_contact_count()):
		var test_enemy_collider := state.get_contact_collider_object(test_enemy_contact_index)
		if test_enemy_collider is Node and test_enemy_collider.is_in_group("props"):
			test_enemy_prop_contact = true
			break
	test_enemy_touching_prop = test_enemy_prop_contact


func _pick_wander_direction() -> void:
	var test_enemy_angle: float = test_enemy_rng.randf_range(0.0, TAU)
	test_enemy_wander_direction = Vector3(cos(test_enemy_angle), 0.0, sin(test_enemy_angle))
