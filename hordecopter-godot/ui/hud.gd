###############################################################
# ui/hud.gd
# Key Classes      • GameHud – on-screen timer/level UI
# Key Functions    • update_time() – refresh timer text
#                 • update_level() – refresh level/progress bar
# Critical Consts  • n/a
# Editor Exports   • show_experience_numbers: bool – show xp text
# Dependencies     • res://game_state.gd
# Last Major Rev   • 25-09-27 – initial HUD for timer + level
###############################################################

class_name GameHud
extends CanvasLayer

@export var show_experience_numbers: bool = false

@onready var hud_time_label: Label = $MarginContainer/VBoxContainer/TimeLabel
@onready var hud_level_label: Label = $MarginContainer/VBoxContainer/LevelLabel
@onready var hud_level_bar: ProgressBar = $MarginContainer/VBoxContainer/LevelProgress
@onready var hud_experience_label: Label = $MarginContainer/VBoxContainer/ExperienceLabel


func _ready() -> void:
	add_to_group("hud")
	hud_level_bar.min_value = 0.0
	hud_level_bar.max_value = 1.0
	hud_level_bar.value = 0.0
	hud_experience_label.visible = show_experience_numbers


func update_time(time_seconds: float) -> void:
	var total_seconds := int(floor(time_seconds))
	var minutes := total_seconds / 60
	var seconds := total_seconds % 60
	hud_time_label.text = "Time %02d:%02d" % [minutes, seconds]


func update_level(level: int, progress: float, experience: int, experience_cap: int) -> void:
	hud_level_label.text = "Level %d" % level
	hud_level_bar.value = clamp(progress, 0.0, 1.0)
	if show_experience_numbers:
		hud_experience_label.text = "%d / %d XP" % [experience, experience_cap]
