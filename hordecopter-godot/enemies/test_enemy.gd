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
# Dependencies     • res://enemies/enemy_experience_manager.gd
#                 • res://items/experience_token.tscn
#                 • res://enemies/enemy_health_bar.tscn
#                 • res://ui/damage_label_3d.tscn
# Last Major Rev   • 25-09-27 – add toggleable enemy health bar
###############################################################

class_name TestEnemy
extends CharacterBody3D

@export var health: float = 4.0
@export var base_health: float = 4.0
@export var health_per_second: float = 0.25
@export var base_experience_reward: int = 1
@export var experience_token_scene: PackedScene
@export var test_enemy_damage_label_scene: PackedScene = preload("res://ui/damage_label_3d.tscn")
@export var test_enemy_wander_speed: float = 2.5
@export var test_enemy_seek_speed: float = 1.5
@export var test_enemy_wander_interval: float = 1.5
@export var test_enemy_turn_speed: float = 2.0

var test_enemy_experience_reward: int = 1
var test_enemy_configured: bool = false
var test_enemy_is_dead: bool = false
var test_enemy_is_elite: bool = false
var test_enemy_wander_direction: Vector3 = Vector3.ZERO
var test_enemy_wander_elapsed: float = 0.0
var test_enemy_rng: RandomNumberGenerator = RandomNumberGenerator.new()
var test_enemy_max_health: float = 1.0
var test_enemy_target: Node3D

@onready
var test_enemy_health_bar: EnemyHealthBar3D = get_node_or_null("HealthBar3D") as EnemyHealthBar3D


func _ready() -> void:
	add_to_group("enemies")
	test_enemy_rng.randomize()
	_pick_wander_direction()
	test_enemy_target = _find_player()
	_apply_initial_scaling()
	test_enemy_max_health = max(1.0, health)
	_update_health_bar()


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
	velocity = test_enemy_wander_direction * test_enemy_speed
	move_and_slide()


func _pick_wander_direction() -> void:
	var test_enemy_angle: float = test_enemy_rng.randf_range(0.0, TAU)
	test_enemy_wander_direction = Vector3(cos(test_enemy_angle), 0.0, sin(test_enemy_angle))


func apply_damage(amount: float) -> void:
	_spawn_damage_label(amount)
	health -= amount
	_update_health_bar()
	if health <= 0.0 and not test_enemy_is_dead:
		test_enemy_is_dead = true
		_drop_experience()
		queue_free()


func configure_from_time(time_seconds: float) -> void:
	var scaled_health := base_health + time_seconds * health_per_second
	health = max(1.0, scaled_health)

	test_enemy_max_health = health
	test_enemy_experience_reward = EnemyExperienceManager.calculate_experience_from_health(
		base_experience_reward, health, base_health
	)
	test_enemy_configured = true
	_update_health_bar()


func configure_elite() -> void:
	if test_enemy_is_elite:
		return
	test_enemy_is_elite = true
	scale *= 2.0
	health *= 8.0
	test_enemy_max_health = max(1.0, health)
	test_enemy_experience_reward = max(1, test_enemy_experience_reward * 2)
	_update_health_bar()


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


func _update_health_bar() -> void:
	if test_enemy_health_bar == null:
		return
	test_enemy_health_bar.set_health(health, test_enemy_max_health)


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


func _spawn_damage_label(amount: float) -> void:
	if test_enemy_damage_label_scene == null:
		return
	var test_enemy_label_instance := test_enemy_damage_label_scene.instantiate()
	var test_enemy_scene := get_tree().current_scene
	if test_enemy_scene == null:
		return
	test_enemy_scene.add_child(test_enemy_label_instance)
	if test_enemy_label_instance is Node3D:
		var test_enemy_label_node := test_enemy_label_instance as Node3D
		test_enemy_label_node.global_position = global_position + Vector3(0.0, 1.5, 0.0)
	if test_enemy_label_instance.has_method("set_damage"):
		test_enemy_label_instance.set_damage(amount)


func _find_player() -> Node3D:
	var test_enemy_player := get_tree().get_first_node_in_group("player")
	if test_enemy_player is Node3D:
		return test_enemy_player
	return null
