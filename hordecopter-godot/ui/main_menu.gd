###############################################################
# ui/main_menu.gd
# Key Classes      • MainMenu – start/quit menu controller
# Key Functions    • _start_game() – load gameplay scene
#                 • _quit_game() – exit application
# Critical Consts  • MAIN_MENU_GAME_SCENE – gameplay scene path
# Editor Exports   • n/a
# Dependencies     • res://theworld.tscn
# Last Major Rev   • 25-10-01 – add main menu flow
###############################################################

class_name MainMenu
extends Control

const MAIN_MENU_GAME_SCENE: String = "res://theworld.tscn"

@onready var main_menu_start_button_ready: Button = %StartButton
@onready var main_menu_quit_button_ready: Button = %QuitButton


func _ready() -> void:
	main_menu_start_button_ready.pressed.connect(_start_game)
	main_menu_quit_button_ready.pressed.connect(_quit_game)
	main_menu_start_button_ready.grab_focus()


func _start_game() -> void:
	get_tree().change_scene_to_file(MAIN_MENU_GAME_SCENE)


func _quit_game() -> void:
	get_tree().quit()
