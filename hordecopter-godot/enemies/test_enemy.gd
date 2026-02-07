###############################################################
# enemies/test_enemy.gd
# Key Classes      • TestEnemy – wandering target dummy
# Key Functions    • apply_damage() – reduce health and despawn
#                 • configure_from_time() – set health scaling
#                 • _pick_wander_direction() – choose a new wander heading
# Critical Consts  • n/a
# Editor Exports   • health: float – hit points
#                 • base_health: float – baseline health
#                 • health_per_second: float – time scaling for health
#                 • base_experience_reward: int – base exp reward
#                 • experience_token_scene: PackedScene – drop scene
# Dependencies     • res://enemies/enemy_experience_manager.gd
#                 • res://items/experience_token.tscn
# Last Major Rev   • 25-09-27 – move XP scaling into shared manager
###############################################################

class_name TestEnemy
extends CharacterBody3D

@export var health: float = 4.0
@export var base_health: float = 4.0
@export var health_per_second: float = 0.25
@export var base_experience_reward: int = 1
@export var experience_token_scene: PackedScene
@export var test_enemy_wander_speed: float = 2.5
@export var test_enemy_wander_interval: float = 1.5

var test_enemy_experience_reward: int = 1
var test_enemy_configured: bool = false
var test_enemy_is_dead: bool = false
var test_enemy_wander_direction: Vector3 = Vector3.ZERO
var test_enemy_wander_elapsed: float = 0.0
var test_enemy_rng: RandomNumberGenerator = RandomNumberGenerator.new()


func _ready() -> void:
	add_to_group("enemies")
	test_enemy_rng.randomize()
	_pick_wander_direction()
	_apply_initial_scaling()


func _physics_process(delta: float) -> void:
	test_enemy_wander_elapsed += delta
	if test_enemy_wander_elapsed >= test_enemy_wander_interval:
		test_enemy_wander_elapsed = 0.0
		_pick_wander_direction()
	velocity = test_enemy_wander_direction * test_enemy_wander_speed
	move_and_slide()


func _pick_wander_direction() -> void:
	var test_enemy_angle: float = test_enemy_rng.randf_range(0.0, TAU)
	test_enemy_wander_direction = Vector3(cos(test_enemy_angle), 0.0, sin(test_enemy_angle))


func apply_damage(amount: float) -> void:
	health -= amount
	if health <= 0.0 and not test_enemy_is_dead:
		test_enemy_is_dead = true
		_drop_experience()
		queue_free()


func configure_from_time(time_seconds: float) -> void:
	var scaled_health := base_health + time_seconds * health_per_second
	health = max(1.0, scaled_health)
	test_enemy_experience_reward = EnemyExperienceManager.calculate_experience_from_health(
		base_experience_reward, health, base_health
	)
	test_enemy_configured = true


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
