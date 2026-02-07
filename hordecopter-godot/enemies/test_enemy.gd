###############################################################
# enemies/test_enemy.gd
# Key Classes      • TestEnemy – wandering target dummy
# Key Functions    • apply_damage() – reduce health and despawn
#                 • configure_from_time() – set health scaling
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

@export var base_health: float = 4.0
@export var health_per_second: float = 0.25
@export var base_experience_reward: int = 1
@export var experience_token_scene: PackedScene
@export var test_enemy_wander_speed: float = 2.5
@export var test_enemy_seek_speed: float = 1.5
@export var test_enemy_wander_interval: float = 1.5
@export var test_enemy_turn_speed: float = 2.0
@export var test_enemy_climb_speed: float = 2.0
@export var test_enemy_climb_duration: float = 0.35

var test_enemy_experience_reward: int = 1
var test_enemy_configured: bool = false
var test_enemy_is_dead: bool = false
var test_enemy_wander_direction: Vector3 = Vector3.ZERO
var test_enemy_wander_elapsed: float = 0.0
var test_enemy_climb_timer: float = 0.0
var test_enemy_vertical_velocity: float = 0.0
var test_enemy_gravity: float = 0.0
var test_enemy_rng: RandomNumberGenerator = RandomNumberGenerator.new()
var test_enemy_target: Node3D


func _ready() -> void:
	super()
	test_enemy_rng.randomize()
	_pick_wander_direction()
	test_enemy_target = _find_player()
	_apply_initial_scaling()
	set_max_health(health)
	test_enemy_gravity = float(ProjectSettings.get_setting("physics/3d/default_gravity"))


func _physics_process(delta: float) -> void:
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
	if test_enemy_climb_timer > 0.0:
		test_enemy_climb_timer = max(0.0, test_enemy_climb_timer - delta)
		test_enemy_vertical_velocity = test_enemy_climb_speed
	else:
		test_enemy_vertical_velocity -= test_enemy_gravity * delta
	velocity = test_enemy_wander_direction * test_enemy_speed
	velocity.y = test_enemy_vertical_velocity
	move_and_slide()
	if is_on_floor() and test_enemy_climb_timer <= 0.0:
		test_enemy_vertical_velocity = 0.0
	var test_enemy_touching_prop: bool = false
	for test_enemy_slide_index in range(get_slide_collision_count()):
		var test_enemy_collision := get_slide_collision(test_enemy_slide_index)
		var test_enemy_collider := test_enemy_collision.get_collider()
		if test_enemy_collider != null and test_enemy_collider.is_in_group("props"):
			test_enemy_touching_prop = true
			break
	if test_enemy_touching_prop:
		test_enemy_climb_timer = test_enemy_climb_duration
	else:
		test_enemy_climb_timer = 0.0


func _pick_wander_direction() -> void:
	var test_enemy_angle: float = test_enemy_rng.randf_range(0.0, TAU)
	test_enemy_wander_direction = Vector3(cos(test_enemy_angle), 0.0, sin(test_enemy_angle))


func configure_from_time(time_seconds: float) -> void:
	var scaled_health := base_health + time_seconds * health_per_second
	health = max(1.0, scaled_health)
	set_max_health(health)
	test_enemy_experience_reward = EnemyExperienceManager.calculate_experience_from_health(
		base_experience_reward, health, base_health
	)
	test_enemy_configured = true


func configure_elite() -> void:
	if enemy_base_is_elite:
		return
	super()
	test_enemy_experience_reward = max(1, test_enemy_experience_reward * 2)


func _apply_initial_scaling() -> void:
	if test_enemy_configured:
		return
	if not is_equal_approx(health, base_health):
		test_enemy_experience_reward = EnemyExperienceManager.calculate_experience_from_health(
			base_experience_reward, health, base_health
		)
		return
	var game_state := get_tree().get_first_node_in_group("game_state")
	if game_state != null and game_state.has_method("get_elapsed_time"):
		configure_from_time(game_state.get_elapsed_time())
	else:
		test_enemy_experience_reward = EnemyExperienceManager.calculate_experience_from_health(
			base_experience_reward, health, base_health
		)


func _on_death() -> void:
	if test_enemy_is_dead:
		return
	test_enemy_is_dead = true
	_drop_experience()
	queue_free()


func _drop_experience() -> void:
	if experience_token_scene == null:
		push_warning("TestEnemy: experience_token_scene missing; no XP drop.")
		return
	var token := experience_token_scene.instantiate()
	var current_scene := get_tree().current_scene
	if current_scene == null:
		push_warning("TestEnemy: current scene missing; cannot drop XP token.")
		return
	current_scene.add_child(token)
	if token is Node3D:
		var token_node := token as Node3D
		token_node.global_position = global_position
	if token.has_method("configure_amount"):
		token.configure_amount(test_enemy_experience_reward)
