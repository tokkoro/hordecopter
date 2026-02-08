###############################################################
# ui/pause_menu.gd
# Key Classes      • PauseMenu – pause overlay + actions
# Key Functions    • pause_menu_show() – display pause UI
#                 • pause_menu_hide() – hide pause UI
#                 • _restart_game() – reload current scene
#                 • _quit_to_menu() – return to main menu
# Critical Consts  • PAUSE_MENU_MAIN_SCENE – menu scene path
# Editor Exports   • n/a
# Dependencies     • res://ui/main_menu.tscn
# Last Major Rev   • 25-10-01 – add pause menu controls
###############################################################

class_name PauseMenu
extends Control

const PAUSE_MENU_MAIN_SCENE: String = "res://ui/main_menu.tscn"

@onready var pause_menu_resume_button_ready: Button = %ResumeButton
@onready var pause_menu_restart_button_ready: Button = %RestartButton
@onready var pause_menu_menu_button_ready: Button = %MainMenuButton


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_process_unhandled_input(true)
	visible = false
	pause_menu_resume_button_ready.pressed.connect(pause_menu_hide)
	pause_menu_restart_button_ready.pressed.connect(_restart_game)
	pause_menu_menu_button_ready.pressed.connect(_quit_to_menu)


func _unhandled_input(event: InputEvent) -> void:
	if not event.is_action_pressed("ui_cancel"):
		return
	if get_tree().paused and not visible:
		return
	if visible:
		pause_menu_hide()
	else:
		pause_menu_show()


func pause_menu_show() -> void:
	get_tree().paused = true
	visible = true
	pause_menu_resume_button_ready.grab_focus()


func pause_menu_hide() -> void:
	visible = false
	get_tree().paused = false


func _restart_game() -> void:
	get_tree().paused = false
	get_tree().reload_current_scene()


func _quit_to_menu() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file(PAUSE_MENU_MAIN_SCENE)
