###############################################################
# items/clock_pickup.gd
# Key Classes      • ClockPickup – pickup that stops enemy movement
# Key Functions    • _collect() – apply time stop to enemies
# Critical Consts  • n/a
# Editor Exports   • pickup_radius: float – collection radius
#                 • stop_duration: float – enemy stop time in seconds
#                 • collect_sound: AudioStream – pickup sound
# Dependencies     • res://sfx/collect.sfxr
# Last Major Rev   • 25-09-28 – add clock pickup effect
###############################################################

class_name ClockPickup
extends Node3D

@export var pickup_radius: float = 1.5
@export var stop_duration: float = 5.0
@export var collect_sound: AudioStream = preload("res://sfx/collect.sfxr")

var clock_pickup_target: Node3D
var clock_pickup_warned_missing_target: bool = false
var clock_pickup_warned_missing_scene: bool = false


func _ready() -> void:
	add_to_group("pickups")


func _physics_process(_delta: float) -> void:
	var target := _get_target()
	if target == null:
		return
	if global_position.distance_to(target.global_position) <= pickup_radius:
		_collect()


func _get_target() -> Node3D:
	if clock_pickup_target != null and is_instance_valid(clock_pickup_target):
		return clock_pickup_target
	var current_scene := get_tree().current_scene
	if current_scene == null:
		if not clock_pickup_warned_missing_scene:
			clock_pickup_warned_missing_scene = true
			push_warning("ClockPickup: current scene missing; cannot find target.")
		return null
	var found := current_scene.find_child("Hordecopter", true, false)
	if found != null and found is Node3D:
		clock_pickup_target = found as Node3D
		return clock_pickup_target
	if not clock_pickup_warned_missing_target:
		clock_pickup_warned_missing_target = true
		push_warning("ClockPickup: Hordecopter not found; pickup cannot be collected.")
	return null


func _collect() -> void:
	var enemies := get_tree().get_nodes_in_group("enemy_targets")
	for enemy in enemies:
		if enemy != null and enemy.has_method("apply_time_stop"):
			enemy.apply_time_stop(stop_duration)
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
