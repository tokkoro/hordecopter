###############################################################
# items/health_pack.gd
# Key Classes      • HealthPack – pickup that restores player health
# Key Functions    • _collect() – attempt to heal player
# Critical Consts  • n/a
# Editor Exports   • pickup_radius: float – collection radius
#                 • heal_amount: float – amount to heal
#                 • collect_sound: AudioStream – pickup sound
# Dependencies     • res://sfx/collect.sfxr
# Last Major Rev   • 25-09-28 – add health pack pickup
###############################################################

class_name HealthPack
extends Node3D

@export var pickup_radius: float = 1.5
@export var heal_amount: float = 25.0
@export var collect_sound: AudioStream = preload("res://sfx/collect.sfxr")

var health_pack_target: Node3D
var health_pack_warned_missing_target: bool = false
var health_pack_warned_missing_scene: bool = false


func _ready() -> void:
	add_to_group("pickups")


func _physics_process(_delta: float) -> void:
	var target := _get_target()
	if target == null:
		return
	if global_position.distance_to(target.global_position) <= pickup_radius:
		_collect(target)


func _get_target() -> Node3D:
	if health_pack_target != null and is_instance_valid(health_pack_target):
		return health_pack_target
	var current_scene := get_tree().current_scene
	if current_scene == null:
		if not health_pack_warned_missing_scene:
			health_pack_warned_missing_scene = true
			push_warning("HealthPack: current scene missing; cannot find target.")
		return null
	var found := current_scene.find_child("Hordecopter", true, false)
	if found != null and found is Node3D:
		health_pack_target = found as Node3D
		return health_pack_target
	if not health_pack_warned_missing_target:
		health_pack_warned_missing_target = true
		push_warning("HealthPack: Hordecopter not found; pickup cannot be collected.")
	return null


func _collect(target: Node3D) -> void:
	if target.has_method("apply_heal"):
		target.apply_heal(heal_amount)
	elif target.has_method("heal"):
		target.heal(heal_amount)
	elif target.has_method("add_health"):
		target.add_health(heal_amount)
	else:
		# TODO: hook into player health system once it is implemented.
		push_warning("HealthPack: player health system not available; TODO hook up healing.")
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
