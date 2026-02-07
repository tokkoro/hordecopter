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
@export var pickup_radius: float = 1.5
@export var magnet_radius: float = 6.0
@export var magnet_speed: float = 8.0

var experience_token_target: Node3D


func _ready() -> void:
	add_to_group("experience_tokens")


func _physics_process(delta: float) -> void:
	var target := _get_target()
	if target == null:
		return
	var distance := global_position.distance_to(target.global_position)
	if distance <= pickup_radius:
		_collect()
		return
	if distance <= magnet_radius:
		global_position = global_position.move_toward(target.global_position, magnet_speed * delta)


func configure_amount(amount: int) -> void:
	experience_amount = max(1, amount)


func _get_target() -> Node3D:
	if experience_token_target != null and is_instance_valid(experience_token_target):
		return experience_token_target
	var current_scene := get_tree().current_scene
	if current_scene == null:
		return null
	var found := current_scene.find_child("Hordecopter", true, false)
	if found != null and found is Node3D:
		experience_token_target = found as Node3D
		return experience_token_target
	return null


func _collect() -> void:
	var game_state := get_tree().get_first_node_in_group("game_state")
	if game_state != null and game_state.has_method("add_experience"):
		game_state.add_experience(experience_amount)
	queue_free()
