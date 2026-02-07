###############################################################
# items/bomb_pickup.gd
# Key Classes      • BombPickup – pickup that detonates enemies
# Key Functions    • _collect() – apply bomb damage to enemies
# Critical Consts  • BOMB_DAMAGE – damage dealt to each enemy
# Editor Exports   • pickup_radius: float – collection radius
#                 • collect_sound: AudioStream – pickup sound
# Dependencies     • res://sfx/collect.sfxr
# Last Major Rev   • 25-09-28 – add bomb pickup effect
###############################################################

class_name BombPickup
extends Node3D

const BOMB_DAMAGE: float = 1000.0

@export var pickup_radius: float = 1.5
@export var collect_sound: AudioStream = preload("res://sfx/collect.sfxr")

var bomb_pickup_target: Node3D
var bomb_pickup_warned_missing_target: bool = false
var bomb_pickup_warned_missing_scene: bool = false


func _ready() -> void:
	add_to_group("pickups")


func _physics_process(_delta: float) -> void:
	var target := _get_target()
	if target == null:
		return
	if global_position.distance_to(target.global_position) <= pickup_radius:
		_collect()


func _get_target() -> Node3D:
	if bomb_pickup_target != null and is_instance_valid(bomb_pickup_target):
		return bomb_pickup_target
	var current_scene := get_tree().current_scene
	if current_scene == null:
		if not bomb_pickup_warned_missing_scene:
			bomb_pickup_warned_missing_scene = true
			push_warning("BombPickup: current scene missing; cannot find target.")
		return null
	var found := current_scene.find_child("Hordecopter", true, false)
	if found != null and found is Node3D:
		bomb_pickup_target = found as Node3D
		return bomb_pickup_target
	if not bomb_pickup_warned_missing_target:
		bomb_pickup_warned_missing_target = true
		push_warning("BombPickup: Hordecopter not found; pickup cannot be collected.")
	return null


func _collect() -> void:
	var enemies := get_tree().get_nodes_in_group("enemies")
	for enemy in enemies:
		if enemy != null and enemy.has_method("apply_damage"):
			enemy.apply_damage(BOMB_DAMAGE)
	_play_sfx_at(collect_sound, global_position)
	queue_free()


func _play_sfx_at(stream: AudioStream, position: Vector3) -> void:
	if stream == null:
		return
	var current_scene := get_tree().current_scene
	if current_scene == null:
		return
	var player := AudioStreamPlayer3D.new()
	current_scene.add_child(player)
	player.stream = stream
	player.global_position = position
	player.finished.connect(player.queue_free)
	player.play()
