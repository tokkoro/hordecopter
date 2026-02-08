###############################################################
# enemies/enemy_base.gd
# Key Classes      • EnemyBase – shared enemy health + damage flow
# Key Functions    • apply_damage() – handle damage and death flow
#                 • configure_elite() – scale elite stats
#                 • _find_player() – locate the player target
#                 • _apply_knockback() – push enemy away from hit
#                 • _trigger_hit_flash() – flash enemy on hit
# Critical Consts  • n/a
# Editor Exports   • health: float – hit points
#                 • base_health: float – baseline health
#                 • health_per_level: float – level scaling for health
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
const ENEMY_DEATH_SFX: AudioStream = preload("res://sfx/enemy_death.sfxr")
const ENEMY_BASE_FLASH_COLOR: Color = Color(1.0, 0.2, 0.2, 1.0)
const ENEMY_BASE_FLASH_DURATION: float = 0.12

@export var health: float = 4.0
@export var base_health: float = 4.0
@export var health_per_level: float = 0.25
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
var enemy_base_flash_timer: float = 0.0
var enemy_base_flash_materials: Array[StandardMaterial3D] = []
var enemy_base_flash_colors: Array[Color] = []

@onready
var enemy_base_health_bar: EnemyHealthBar3D = get_node_or_null("HealthBar3D") as EnemyHealthBar3D


func _ready() -> void:
	add_to_group("enemy_targets")
	lock_rotation = true
	if is_flying:
		gravity_scale = 0.0
	base_health = max(1.0, base_health)
	enemy_base_max_health = max(1.0, health)
	_apply_initial_scaling()
	set_max_health(health)
	_cache_flash_materials()


func _process(delta: float) -> void:
	_update_hit_flash(delta)
	if global_position.y < -10:
		_on_death(true)
	if enemy_base_time_stop_remaining <= 0.0:
		return
	enemy_base_time_stop_remaining = max(0.0, enemy_base_time_stop_remaining - delta)


func apply_damage(amount: float, knockback: float = 0.0, origin: Vector3 = Vector3.ZERO) -> void:
	_spawn_damage_label(amount)
	_play_hit_sfx()
	_trigger_hit_flash()
	_apply_knockback(knockback, origin)
	health -= amount
	_update_health_bar()
	if health <= 0.0:
		_on_death(false)


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


func configure_from_level(level: int) -> void:
	var enemy_base_level_step: int = maxi(0, level - 1)
	var enemy_base_scaled_health := base_health + float(enemy_base_level_step) * health_per_level
	health = max(1.0, enemy_base_scaled_health)
	set_max_health(health)
	_update_experience_reward()
	enemy_base_configured = true


func set_max_health(value: float) -> void:
	enemy_base_max_health = max(1.0, value)
	_update_health_bar()


func _on_death(force: bool) -> void:
	if enemy_base_is_dead:
		return
	enemy_base_is_dead = true
	if not force:
		_play_sfx_at(ENEMY_DEATH_SFX, global_position)
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
	if game_state != null and game_state.has_method("get_current_level"):
		configure_from_level(game_state.get_current_level())
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


func _cache_flash_materials() -> void:
	enemy_base_flash_materials.clear()
	enemy_base_flash_colors.clear()
	var meshes: Array[MeshInstance3D] = []
	_collect_mesh_instances(self, meshes)
	for mesh in meshes:
		if mesh.material_override is StandardMaterial3D:
			var material := mesh.material_override.duplicate()
			mesh.material_override = material
			enemy_base_flash_materials.append(material)
			enemy_base_flash_colors.append(material.albedo_color)


func _collect_mesh_instances(node: Node, meshes: Array[MeshInstance3D]) -> void:
	for child in node.get_children():
		if child is MeshInstance3D:
			meshes.append(child as MeshInstance3D)
		_collect_mesh_instances(child, meshes)


func _trigger_hit_flash() -> void:
	if enemy_base_flash_materials.is_empty():
		return
	enemy_base_flash_timer = ENEMY_BASE_FLASH_DURATION
	for material in enemy_base_flash_materials:
		if material != null:
			material.albedo_color = ENEMY_BASE_FLASH_COLOR


func _update_hit_flash(delta: float) -> void:
	if enemy_base_flash_timer <= 0.0:
		return
	enemy_base_flash_timer = max(0.0, enemy_base_flash_timer - delta)
	if enemy_base_flash_timer > 0.0:
		return
	for index in range(min(enemy_base_flash_materials.size(), enemy_base_flash_colors.size())):
		var material := enemy_base_flash_materials[index]
		if material != null:
			material.albedo_color = enemy_base_flash_colors[index]


func _apply_knockback(knockback: float, origin: Vector3) -> void:
	if knockback <= 0.0:
		return
	var direction := global_position - origin
	direction.y = 0.0
	if direction.length() < 0.01:
		direction = -global_transform.basis.z
	if direction.length() < 0.01:
		direction = Vector3.FORWARD
	apply_impulse(direction.normalized() * knockback)


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
