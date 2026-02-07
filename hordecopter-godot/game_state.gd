###############################################################
# game_state.gd
# Key Classes      • GameState – global timer and experience tracker
# Key Functions    • add_experience() – apply experience and handle leveling
#                 • get_elapsed_time() – report time since start
# Critical Consts  • n/a
# Editor Exports   • level_start: int – starting level
#                 • experience_start: int – starting experience value
#                 • experience_to_next_level: int – initial level threshold
#                 • experience_growth: float – growth multiplier per level
# Dependencies     • res://ui/hud.gd
# Last Major Rev   • 25-09-27 – add timer + experience progression
###############################################################

class_name GameState
extends Node

@export var level_start: int = 1
@export var experience_start: int = 0
@export var experience_to_next_level: int = 10
@export var experience_growth: float = 1.35

var game_state_elapsed_time: float = 0.0
var game_state_level: int = 1
var game_state_experience: int = 0
var game_state_experience_cap: int = 10
var game_state_hud: Node


func _ready() -> void:
	add_to_group("game_state")
	game_state_level = max(1, level_start)
	game_state_experience = max(0, experience_start)
	game_state_experience_cap = max(1, experience_to_next_level)
	game_state_hud = _find_hud()
	_refresh_hud()


func _process(delta: float) -> void:
	game_state_elapsed_time += delta
	_update_time_hud()


func add_experience(amount: int) -> void:
	if amount <= 0:
		return
	game_state_experience += amount
	while game_state_experience >= game_state_experience_cap:
		game_state_experience -= game_state_experience_cap
		game_state_level += 1
		game_state_experience_cap = int(round(game_state_experience_cap * experience_growth))
		game_state_experience_cap = max(1, game_state_experience_cap)
	_refresh_hud()


func get_elapsed_time() -> float:
	return game_state_elapsed_time


func get_experience_progress() -> float:
	return float(game_state_experience) / float(max(1, game_state_experience_cap))


func _find_hud() -> Node:
	var huds := get_tree().get_nodes_in_group("hud")
	if huds.size() > 0:
		return huds[0]
	return null


func _refresh_hud() -> void:
	if game_state_hud == null:
		return
	if game_state_hud.has_method("update_level"):
		game_state_hud.update_level(
			game_state_level,
			get_experience_progress(),
			game_state_experience,
			game_state_experience_cap
		)


func _update_time_hud() -> void:
	if game_state_hud == null:
		return
	if game_state_hud.has_method("update_time"):
		game_state_hud.update_time(game_state_elapsed_time)
