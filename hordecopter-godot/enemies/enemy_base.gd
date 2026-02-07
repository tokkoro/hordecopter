###############################################################
# enemies/enemy_base.gd
# Key Classes      • EnemyBase – shared enemy health + damage flow
# Key Functions    • apply_damage() – handle damage and death flow
#                 • configure_elite() – scale elite stats
#                 • _find_player() – locate the player target
# Critical Consts  • n/a
# Editor Exports   • health: float – hit points
#                 • base_health: float – baseline health
#                 • health_per_second: float – time scaling for health
#                 • base_experience_reward: int – base exp reward
#                 • experience_token_scene: PackedScene – drop scene
#                 • has_elite_form: bool – allow elite scaling
#                 • damage_label_scene: PackedScene – damage number visuals
# Dependencies     • res://enemies/enemy_health_bar.tscn
#                 • res://enemies/enemy_experience_manager.gd
#                 • res://items/experience_token.tscn
#                 • res://ui/damage_label_3d.tscn
# Last Major Rev   • 25-09-27 – add shared enemy base
###############################################################

class_name EnemyBase
extends RigidBody3D

const ENEMY_HIT_SFX: AudioStream = preload("res://sfx/monster_hit.sfxr")

@export var health: float = 4.0
@export var base_health: float = 4.0
@export var health_per_second: float = 0.25
@export var base_experience_reward: int = 1
@export var experience_token_scene: PackedScene
@export var has_elite_form: bool = true
@export var damage_label_scene: PackedScene = preload("res://ui/damage_label_3d.tscn")

@export var is_flying: bool = false

var enemy_base_max_health: float = 1.0
var enemy_base_is_elite: bool = false
var enemy_base_experience_reward: int = 1
var enemy_base_configured: bool = false
var enemy_base_is_dead: bool = false
var enemy_base_time_stop_remaining: float = 0.0

@onready
var enemy_base_health_bar: EnemyHealthBar3D = get_node_or_null("HealthBar3D") as EnemyHealthBar3D


func _ready() -> void:
	add_to_group("enemies")
	lock_rotation = true
	if is_flying:
		gravity_scale = 0.0
	base_health = max(1.0, base_health)
	enemy_base_max_health = max(1.0, health)
	_apply_initial_scaling()
	set_max_health(health)


func _process(delta: float) -> void:
	if enemy_base_time_stop_remaining <= 0.0:
		return
	enemy_base_time_stop_remaining = max(0.0, enemy_base_time_stop_remaining - delta)


func apply_damage(amount: float) -> void:
	_spawn_damage_label(amount)
	_play_hit_sfx()
	health -= amount
	_update_health_bar()
	if health <= 0.0:
		_on_death()


func configure_elite() -> void:
	if enemy_base_is_elite or not has_elite_form:
		return
	enemy_base_is_elite = true
	scale *= 2.0
	health *= 8.0
	enemy_base_max_health = max(1.0, health)
	_update_health_bar()
	enemy_base_experience_reward = max(1, enemy_base_experience_reward * 2)


func get_has_elite_form() -> bool:
	return has_elite_form


func apply_time_stop(duration: float) -> void:
	if duration <= 0.0:
		return
	enemy_base_time_stop_remaining = max(enemy_base_time_stop_remaining, duration)


func is_time_stopped() -> bool:
	return enemy_base_time_stop_remaining > 0.0


func configure_from_time(time_seconds: float) -> void:
	var scaled_health := base_health + time_seconds * health_per_second
	health = max(1.0, scaled_health)
	set_max_health(health)
	_update_experience_reward()
	enemy_base_configured = true


func set_max_health(value: float) -> void:
	enemy_base_max_health = max(1.0, value)
	_update_health_bar()


func _on_death() -> void:
	if enemy_base_is_dead:
		return
	enemy_base_is_dead = true
	_drop_experience()
	queue_free()


func _update_health_bar() -> void:
	if enemy_base_health_bar == null:
		push_warning("No health bar on enemy")
		return
	enemy_base_health_bar.set_health(health, enemy_base_max_health)


func _apply_initial_scaling() -> void:
	if enemy_base_configured:
		return
	if not is_equal_approx(health, base_health):
		_update_experience_reward()
		return
	var game_state := get_tree().get_first_node_in_group("game_state")
	if game_state != null and game_state.has_method("get_elapsed_time"):
		configure_from_time(game_state.get_elapsed_time())
	else:
		_update_experience_reward()


func _update_experience_reward() -> void:
	enemy_base_experience_reward = EnemyExperienceManager.calculate_experience_from_health(
		base_experience_reward, health, base_health
	)


func _drop_experience() -> void:
	if experience_token_scene == null:
		return
	var token := experience_token_scene.instantiate()
	var current_scene := get_tree().current_scene
	if current_scene == null:
		return
	current_scene.add_child(token)
	if token is Node3D:
		var token_node := token as Node3D
		token_node.global_position = global_position
	if token.has_method("configure_amount"):
		token.configure_amount(enemy_base_experience_reward)


func _spawn_damage_label(amount: float) -> void:
	if damage_label_scene == null:
		return
	var enemy_base_label_instance := damage_label_scene.instantiate()
	var enemy_base_scene := get_tree().current_scene
	if enemy_base_scene == null:
		return
	enemy_base_scene.add_child(enemy_base_label_instance)
	if enemy_base_label_instance is Node3D:
		var enemy_base_label_node := enemy_base_label_instance as Node3D
		enemy_base_label_node.global_position = global_position + Vector3(0.0, 1.5, 0.0)
	if enemy_base_label_instance.has_method("set_damage"):
		enemy_base_label_instance.set_damage(amount)


func _find_player() -> Node3D:
	var enemy_base_player := get_tree().get_first_node_in_group("player")
	if enemy_base_player is Node3D:
		return enemy_base_player
	return null


func _play_hit_sfx() -> void:
	_play_sfx_at(ENEMY_HIT_SFX, global_position)


func _play_sfx_at(stream: AudioStream, position: Vector3) -> void:
	if stream == null:
		push_warning("no stream for enemy audio")
		return
	var current_scene := get_tree().current_scene
	if current_scene == null:
		push_warning("no scene for enemy audio")
		return
	var player := AudioStreamPlayer3D.new()
	current_scene.add_child(player)
	player.stream = stream
	player.global_position = position
	player.finished.connect(player.queue_free)
	player.play()
