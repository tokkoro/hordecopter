###############################################################
# items/experience_token.gd
# Key Classes      • ExperienceToken – pickup that grants experience
# Key Functions    • configure_amount() – set token experience value
#                 • _collect() – grant experience and remove token
# Critical Consts  • n/a
# Editor Exports   • experience_amount: int – experience granted
#                 • pickup_radius: float – auto-collect range
#                 • magnet_radius: float – attraction range
#                 • magnet_speed: float – attraction speed
# Dependencies     • res://game_state.gd
# Last Major Rev   • 25-09-27 – initial experience token pickup
###############################################################

class_name ExperienceToken
extends Node3D

@export var experience_amount: int = 1
@export var pickup_radius: float = 1.25
@export var magnet_radius: float = 10.0
@export var magnet_speed: float = 6.0

@export var sleep_time: float = 3.0
@export var collect_sound: AudioStream = preload("res://sfx/collect.sfxr")

var start_time: float = 0

var experience_token_target: Node3D
var experience_token_warned_missing_target: bool = false
var experience_token_warned_missing_scene: bool = false
var experience_token_forced_magnet: bool = false


func _ready() -> void:
	add_to_group("experience_tokens")
	start_time = Time.get_ticks_msec()


func _physics_process(delta: float) -> void:
	var target := _get_target()
	if target == null:
		return
	var distance := global_position.distance_to(target.global_position)
	if distance <= pickup_radius:
		_collect()
		return
	if experience_token_forced_magnet:
		global_position = global_position.move_toward(
			target.global_position, magnet_speed * delta * 2.0
		)
		return
	if distance <= magnet_radius:
		var t = (Time.get_ticks_msec() - start_time) / (sleep_time * 1000)
		t = clampf(t, 0, 1)
		global_position = global_position.move_toward(
			target.global_position, magnet_speed * delta * t
		)


func configure_amount(amount: int) -> void:
	experience_amount = max(1, amount)


func apply_magnet() -> void:
	experience_token_forced_magnet = true
	start_time = 0


func _get_target() -> Node3D:
	if experience_token_target != null and is_instance_valid(experience_token_target):
		return experience_token_target
	var current_scene := get_tree().current_scene
	if current_scene == null:
		if not experience_token_warned_missing_scene:
			experience_token_warned_missing_scene = true
			push_warning("ExperienceToken: current scene missing; cannot find target.")
		return null
	var found := current_scene.find_child("Hordecopter", true, false)
	if found != null and found is Node3D:
		experience_token_target = found as Node3D
		return experience_token_target
	if not experience_token_warned_missing_target:
		experience_token_warned_missing_target = true
		push_warning("ExperienceToken: Hordecopter not found; token cannot be collected.")
	return null


func _collect() -> void:
	var game_state := get_tree().get_first_node_in_group("game_state")
	if game_state != null and game_state.has_method("add_experience"):
		game_state.add_experience(experience_amount)
	else:
		push_warning("ExperienceToken: GameState missing add_experience; XP not granted.")
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
