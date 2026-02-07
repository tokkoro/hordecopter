###############################################################
# items/magnet_pickup.gd
# Key Classes      • MagnetPickup – pickup that attracts all XP
# Key Functions    • _collect() – trigger experience token magnet
# Critical Consts  • n/a
# Editor Exports   • pickup_radius: float – collection radius
#                 • collect_sound: AudioStream – pickup sound
# Dependencies     • res://sfx/collect.sfxr
#                 • res://items/experience_token.gd
# Last Major Rev   • 25-09-28 – add magnet pickup effect
###############################################################

class_name MagnetPickup
extends Node3D

@export var pickup_radius: float = 1.5
@export var collect_sound: AudioStream = preload("res://sfx/collect.sfxr")

var magnet_pickup_target: Node3D
var magnet_pickup_warned_missing_target: bool = false
var magnet_pickup_warned_missing_scene: bool = false


func _ready() -> void:
	add_to_group("pickups")


func _physics_process(_delta: float) -> void:
	var target := _get_target()
	if target == null:
		return
	if global_position.distance_to(target.global_position) <= pickup_radius:
		_collect()


func _get_target() -> Node3D:
	if magnet_pickup_target != null and is_instance_valid(magnet_pickup_target):
		return magnet_pickup_target
	var current_scene := get_tree().current_scene
	if current_scene == null:
		if not magnet_pickup_warned_missing_scene:
			magnet_pickup_warned_missing_scene = true
			push_warning("MagnetPickup: current scene missing; cannot find target.")
		return null
	var found := current_scene.find_child("Hordecopter", true, false)
	if found != null and found is Node3D:
		magnet_pickup_target = found as Node3D
		return magnet_pickup_target
	if not magnet_pickup_warned_missing_target:
		magnet_pickup_warned_missing_target = true
		push_warning("MagnetPickup: Hordecopter not found; pickup cannot be collected.")
	return null


func _collect() -> void:
	var tokens := get_tree().get_nodes_in_group("experience_tokens")
	for token in tokens:
		if token != null and token.has_method("apply_magnet"):
			token.apply_magnet()
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
