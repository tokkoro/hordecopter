###############################################################
# props/loot_crate.gd
# Key Classes      • LootCrate – destructible crate that drops pickups
# Key Functions    • apply_damage() – reduce health and destroy crate
#                 • begin_drop() – start a parachute drop to the ground
#                 • _spawn_loot() – spawn pickups around the crate
# Critical Consts  • n/a
# Editor Exports   • max_health: float – crate hit points
#                 • drop_speed: float – descent speed while parachuting
#                 • drop_drift_speed: float – horizontal drift speed while dropping
#                 • experience_drop_count: int – XP droplets to spawn
#                 • drop_radius_min: float – min offset for drops
#                 • drop_radius_max: float – max offset for drops
#                 • experience_token_scene: PackedScene – XP droplet scene
#                 • bomb_pickup_scene: PackedScene – bomb pickup scene
#                 • clock_pickup_scene: PackedScene – time stop pickup scene
#                 • health_pack_scene: PackedScene – heal pickup scene
#                 • magnet_pickup_scene: PackedScene – magnet pickup scene
#                 • damage_label_scene: PackedScene – damage number visuals
# Dependencies     • res://items/experience_token.tscn
#                 • res://items/bomb_pickup.tscn
#                 • res://items/clock_pickup.tscn
#                 • res://items/health_pack.tscn
#                 • res://items/magnet_pickup.tscn
#                 • res://enemies/enemy_health_bar.tscn
#                 • res://ui/damage_label_3d.tscn
#                 • res://models/crate.glb
# Last Major Rev   • 25-09-28 – add loot crate drops
###############################################################

class_name LootCrate
extends StaticBody3D

const LOOT_CRATE_HIT_SFX: AudioStream = preload("res://sfx/monster_hit.sfxr")

@export var max_health: float = 6.0
@export var drop_speed: float = 2.5
@export var drop_drift_speed: float = 0.6
@export var experience_drop_count: int = 6
@export var drop_radius_min: float = 0.6
@export var drop_radius_max: float = 2.0
@export var experience_token_scene: PackedScene = preload("res://items/experience_token.tscn")
@export var bomb_pickup_scene: PackedScene = preload("res://items/bomb_pickup.tscn")
@export var clock_pickup_scene: PackedScene = preload("res://items/clock_pickup.tscn")
@export var health_pack_scene: PackedScene = preload("res://items/health_pack.tscn")
@export var magnet_pickup_scene: PackedScene = preload("res://items/magnet_pickup.tscn")
@export var damage_label_scene: PackedScene = preload("res://ui/damage_label_3d.tscn")

var loot_crate_health: float = 0.0
var loot_crate_max_health: float = 1.0
var loot_crate_rng: RandomNumberGenerator = RandomNumberGenerator.new()
var loot_crate_is_dead: bool = false
var loot_crate_drop_active: bool = false
var loot_crate_landing_height: float = 0.0
var loot_crate_drop_direction: Vector3 = Vector3.ZERO

@onready
var loot_crate_health_bar: EnemyHealthBar3D = get_node_or_null("HealthBar3D") as EnemyHealthBar3D
@onready var loot_crate_parachute: Node3D = get_node_or_null("Parachute") as Node3D


func _ready() -> void:
	add_to_group("props")
	add_to_group("enemy_targets")
	add_to_group("loot_crates")
	loot_crate_health = max(1.0, max_health)
	loot_crate_max_health = loot_crate_health
	_update_health_bar()
	loot_crate_rng.randomize()
	if loot_crate_parachute != null:
		loot_crate_parachute.visible = false
	set_physics_process(false)


func _physics_process(delta: float) -> void:
	if not loot_crate_drop_active:
		return
	var loot_crate_position := global_position
	loot_crate_position += loot_crate_drop_direction * drop_drift_speed * delta
	loot_crate_position.y = max(
		loot_crate_landing_height, loot_crate_position.y - drop_speed * delta
	)
	global_position = loot_crate_position
	if loot_crate_position.y <= loot_crate_landing_height + 0.01:
		_finish_drop()


func begin_drop(landing_height: float) -> void:
	loot_crate_drop_active = true
	loot_crate_landing_height = landing_height
	var loot_crate_angle := loot_crate_rng.randf_range(0.0, TAU)
	loot_crate_drop_direction = Vector3(cos(loot_crate_angle), 0.0, sin(loot_crate_angle))
	if loot_crate_parachute != null:
		loot_crate_parachute.visible = true
	set_physics_process(true)


func apply_damage(amount: float, _knockback: float = 0.0, _origin: Vector3 = Vector3.ZERO) -> void:
	if amount <= 0.0:
		return
	_spawn_damage_label(amount)
	_play_hit_sfx()
	loot_crate_health -= amount
	_update_health_bar()
	if loot_crate_health <= 0.0:
		_on_destroyed()


func _spawn_loot() -> void:
	var current_scene := get_tree().current_scene
	if current_scene == null:
		return
	_spawn_experience_tokens(current_scene)
	_spawn_random_goodie(current_scene)


func _spawn_experience_tokens(current_scene: Node) -> void:
	if experience_token_scene == null:
		return
	var drop_count: int = max(1, experience_drop_count)
	for loot_crate_index in range(drop_count):
		var token := experience_token_scene.instantiate()
		current_scene.add_child(token)
		if token is Node3D:
			var token_node := token as Node3D
			token_node.global_position = global_position + _random_drop_offset()


func _spawn_pickup(current_scene: Node, pickup_scene: PackedScene) -> void:
	if pickup_scene == null:
		return
	var pickup_instance := pickup_scene.instantiate()
	current_scene.add_child(pickup_instance)
	if pickup_instance is Node3D:
		var pickup_node := pickup_instance as Node3D
		pickup_node.global_position = global_position + _random_drop_offset()


func _random_drop_offset() -> Vector3:
	var drop_radius := loot_crate_rng.randf_range(drop_radius_min, drop_radius_max)
	var drop_angle := loot_crate_rng.randf_range(0.0, TAU)
	return Vector3(cos(drop_angle) * drop_radius, 0.2, sin(drop_angle) * drop_radius)


func _spawn_random_goodie(current_scene: Node) -> void:
	var goodies: Array[PackedScene] = []
	if bomb_pickup_scene != null:
		goodies.append(bomb_pickup_scene)
	if clock_pickup_scene != null:
		goodies.append(clock_pickup_scene)
	if health_pack_scene != null:
		goodies.append(health_pack_scene)
	if magnet_pickup_scene != null:
		goodies.append(magnet_pickup_scene)
	if goodies.is_empty():
		return
	var choice_index := loot_crate_rng.randi_range(0, goodies.size() - 1)
	_spawn_pickup(current_scene, goodies[choice_index])


func _on_destroyed() -> void:
	if loot_crate_is_dead:
		return
	loot_crate_is_dead = true
	_spawn_loot()
	queue_free()


func _finish_drop() -> void:
	loot_crate_drop_active = false
	loot_crate_drop_direction = Vector3.ZERO
	if loot_crate_parachute != null:
		loot_crate_parachute.visible = false
	set_physics_process(false)


func _update_health_bar() -> void:
	if loot_crate_health_bar == null:
		push_warning("No health bar on loot crate")
		return
	loot_crate_health_bar.set_health(loot_crate_health, loot_crate_max_health)


func _spawn_damage_label(amount: float) -> void:
	if damage_label_scene == null:
		return
	var loot_crate_label_instance := damage_label_scene.instantiate()
	var loot_crate_scene := get_tree().current_scene
	if loot_crate_scene == null:
		return
	loot_crate_scene.add_child(loot_crate_label_instance)
	if loot_crate_label_instance is Node3D:
		var loot_crate_label_node := loot_crate_label_instance as Node3D
		loot_crate_label_node.global_position = global_position + Vector3(0.0, 1.5, 0.0)
	if loot_crate_label_instance.has_method("set_damage"):
		loot_crate_label_instance.set_damage(amount)


func _play_hit_sfx() -> void:
	_play_sfx_at(LOOT_CRATE_HIT_SFX, global_position)


func _play_sfx_at(stream: AudioStream, position: Vector3) -> void:
	if stream == null:
		push_warning("no stream for loot crate audio")
		return
	var current_scene := get_tree().current_scene
	if current_scene == null:
		push_warning("no scene for loot crate audio")
		return
	var player := AudioStreamPlayer3D.new()
	current_scene.add_child(player)
	player.stream = stream
	player.global_position = position
	player.finished.connect(player.queue_free)
	player.play()
