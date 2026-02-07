###############################################################
# game_state.gd
# Key Classes      • GameState – global timer and experience tracker
# Key Functions    • add_experience() – apply experience and handle leveling
#                 • get_elapsed_time() – report time since start
#                 • register_hud() – receive HUD instance from UI
#                 • are_enemy_health_bars_visible() – toggle state getter
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

signal level_up_requested(options: Array)

@export var level_start: int = 1
@export var experience_start: int = 0
@export var experience_to_next_level: int = 10
@export var experience_growth: float = 1.35
@export var clock_speed: float = 1.01

var game_state_elapsed_time: float = 0.0
var game_state_level: int = 1
var game_state_experience: int = 0
var game_state_experience_cap: int = 10
var game_state_hud: GameHud
var game_state_warned_missing_hud: bool = false

var game_state_show_enemy_health_bars: bool = false

var game_state_pending_level_ups: int = 0
var game_state_level_up_active: bool = false
var game_state_level_up_options: Array[Dictionary] = []
var game_state_debug_level_key_down: bool = false



func _ready() -> void:
	add_to_group("game_state")
	game_state_level = max(1, level_start)
	game_state_experience = max(0, experience_start)
	game_state_experience_cap = max(1, experience_to_next_level)
	game_state_hud = _find_hud()
	_refresh_hud()
	_apply_enemy_health_bar_visibility()


func _process(delta: float) -> void:
	game_state_elapsed_time += delta * clock_speed
	_handle_debug_level_up_input()
	_ensure_hud()
	_update_time_hud()
	_handle_enemy_health_toggle()


func add_experience(amount: int) -> void:
	if amount <= 0:
		return
	_ensure_hud()
	game_state_experience += amount
	var level_ups: int = 0
	while game_state_experience >= game_state_experience_cap:
		game_state_experience -= game_state_experience_cap
		game_state_level += 1
		level_ups += 1
		game_state_experience_cap = int(round(game_state_experience_cap * experience_growth))
		game_state_experience_cap = max(1, game_state_experience_cap)
	_refresh_hud()
	if level_ups > 0:
		game_state_pending_level_ups += level_ups
		_request_level_up_if_needed()


func get_elapsed_time() -> float:
	return game_state_elapsed_time


func are_enemy_health_bars_visible() -> bool:
	return game_state_show_enemy_health_bars


func get_experience_progress() -> float:
	return float(game_state_experience) / float(max(1, game_state_experience_cap))


func register_hud(hud: Node) -> void:
	game_state_hud = hud
	game_state_warned_missing_hud = false
	_refresh_hud()
	_update_time_hud()


func _find_hud() -> Node:
	var huds := get_tree().get_nodes_in_group("hud")
	if huds.size() > 0:
		return huds[0]
	return null


func _ensure_hud() -> void:
	if game_state_hud != null:
		return
	game_state_hud = _find_hud()
	if game_state_hud != null:
		game_state_warned_missing_hud = false


func _refresh_hud() -> void:
	if game_state_hud == null:
		# Expected while warming up a scene
		return
	if game_state_hud.has_method("update_level"):
		game_state_hud.update_level(
			game_state_level,
			get_experience_progress(),
			game_state_experience,
			game_state_experience_cap
		)
	else:
		push_warning("GameState: HUD missing update_level; skipping level UI update.")


func _update_time_hud() -> void:
	if game_state_hud == null:
		if not game_state_warned_missing_hud:
			game_state_warned_missing_hud = true
			push_warning("GameState: HUD not found; UI will not update.")
		return
	if game_state_hud.has_method("update_time"):
		game_state_hud.update_time(game_state_elapsed_time)
	else:
		push_warning("GameState: HUD missing update_time; skipping timer UI update.")


func _handle_enemy_health_toggle() -> void:
	if Input.is_action_just_pressed("p1_toggle_enemy_health_bars"):
		game_state_show_enemy_health_bars = not game_state_show_enemy_health_bars
		_apply_enemy_health_bar_visibility()


func _apply_enemy_health_bar_visibility() -> void:
	var health_bars := get_tree().get_nodes_in_group("enemy_health_bars")
	for health_bar in health_bars:
		if health_bar is Node3D:
			health_bar.visible = game_state_show_enemy_health_bars
		elif health_bar is CanvasItem:
			health_bar.visible = game_state_show_enemy_health_bars

func _handle_debug_level_up_input() -> void:
	var is_pressed := Input.is_key_pressed(KEY_L)
	if is_pressed and not game_state_debug_level_key_down:
		var needed := game_state_experience_cap - game_state_experience
		if needed > 0:
			add_experience(needed)
	game_state_debug_level_key_down = is_pressed


func resolve_level_up_choice(choice: Dictionary) -> void:
	var player := get_tree().get_first_node_in_group("player")
	if player != null and player.has_method("apply_level_up_choice"):
		player.apply_level_up_choice(choice)
	else:
		push_warning("GameState: Player missing apply_level_up_choice; skipping upgrade.")
	game_state_pending_level_ups = max(0, game_state_pending_level_ups - 1)
	game_state_level_up_active = false
	if game_state_pending_level_ups > 0:
		_request_level_up_if_needed()
		return
	get_tree().paused = false
	if game_state_hud != null and game_state_hud.has_method("hide_level_up_choices"):
		game_state_hud.hide_level_up_choices()


func _request_level_up_if_needed() -> void:
	if game_state_pending_level_ups <= 0:
		return
	if game_state_level_up_active:
		return
	var player := get_tree().get_first_node_in_group("player")
	var options: Array[Dictionary] = []
	if player != null and player.has_method("get_level_up_options"):
		options = player.get_level_up_options(3)
	if options.is_empty():
		game_state_pending_level_ups = max(0, game_state_pending_level_ups - 1)
		push_warning("GameState: No level-up options available; skipping choice.")
		if game_state_pending_level_ups > 0:
			_request_level_up_if_needed()
		return
	game_state_level_up_active = true
	game_state_level_up_options = options
	get_tree().paused = true
	if game_state_hud != null and game_state_hud.has_method("show_level_up_choices"):
		game_state_hud.show_level_up_choices(options)
	else:
		push_warning("GameState: HUD missing show_level_up_choices; cannot show upgrades.")
