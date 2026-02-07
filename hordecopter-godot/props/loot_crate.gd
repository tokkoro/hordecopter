###############################################################
# props/loot_crate.gd
# Key Classes      • LootCrate – destructible crate that drops pickups
# Key Functions    • apply_damage() – reduce health and destroy crate
#                 • _spawn_loot() – spawn pickups around the crate
# Critical Consts  • n/a
# Editor Exports   • max_health: float – crate hit points
#                 • experience_drop_count: int – XP droplets to spawn
#                 • drop_radius_min: float – min offset for drops
#                 • drop_radius_max: float – max offset for drops
#                 • experience_token_scene: PackedScene – XP droplet scene
#                 • bomb_pickup_scene: PackedScene – bomb pickup scene
#                 • clock_pickup_scene: PackedScene – time stop pickup scene
#                 • health_pack_scene: PackedScene – heal pickup scene
# Dependencies     • res://items/experience_token.tscn
#                 • res://items/bomb_pickup.tscn
#                 • res://items/clock_pickup.tscn
#                 • res://items/health_pack.tscn
#                 • res://models/crate.glb
# Last Major Rev   • 25-09-28 – add loot crate drops
###############################################################

class_name LootCrate
extends StaticBody3D

@export var max_health: float = 6.0
@export var experience_drop_count: int = 6
@export var drop_radius_min: float = 0.6
@export var drop_radius_max: float = 2.0
@export var experience_token_scene: PackedScene = preload("res://items/experience_token.tscn")
@export var bomb_pickup_scene: PackedScene = preload("res://items/bomb_pickup.tscn")
@export var clock_pickup_scene: PackedScene = preload("res://items/clock_pickup.tscn")
@export var health_pack_scene: PackedScene = preload("res://items/health_pack.tscn")

var loot_crate_health: float = 0.0
var loot_crate_rng: RandomNumberGenerator = RandomNumberGenerator.new()


func _ready() -> void:
	add_to_group("props")
	loot_crate_health = max(1.0, max_health)
	loot_crate_rng.randomize()


func apply_damage(amount: float) -> void:
	if amount <= 0.0:
		return
	loot_crate_health -= amount
	if loot_crate_health <= 0.0:
		_spawn_loot()
		queue_free()


func _spawn_loot() -> void:
	var current_scene := get_tree().current_scene
	if current_scene == null:
		return
	_spawn_experience_tokens(current_scene)
	_spawn_pickup(current_scene, bomb_pickup_scene)
	_spawn_pickup(current_scene, clock_pickup_scene)
	_spawn_pickup(current_scene, health_pack_scene)


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
