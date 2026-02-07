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

var hud_level_up_overlay: PanelContainer
var hud_level_up_buttons: Array[Button] = []
var hud_level_up_options: Array[Dictionary] = []

@onready var hud_time_label: Label = $MarginContainer/VBoxContainer/TimeLabel
@onready var hud_level_label: Label = $MarginContainer/VBoxContainer/LevelLabel
@onready var hud_level_bar: ProgressBar = $MarginContainer/VBoxContainer/LevelProgress
@onready var hud_experience_label: Label = $MarginContainer/VBoxContainer/ExperienceLabel


func _ready() -> void:
	add_to_group("hud")
	process_mode = Node.PROCESS_MODE_ALWAYS
	hud_level_bar.min_value = 0.0
	hud_level_bar.max_value = 1.0
	hud_level_bar.value = 0.0
	hud_experience_label.visible = show_experience_numbers
	_build_level_up_menu()
	_register_with_game_state()


func _register_with_game_state() -> void:
	var game_state := get_tree().get_first_node_in_group("game_state")
	if game_state != null and game_state.has_method("register_hud"):
		game_state.register_hud(self)
	else:
		push_warning("GameHud: GameState missing register_hud; HUD may not update.")


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


func show_level_up_choices(options: Array[Dictionary]) -> void:
	hud_level_up_options = options
	if hud_level_up_overlay == null:
		_build_level_up_menu()
	for index in range(hud_level_up_buttons.size()):
		var button := hud_level_up_buttons[index]
		if index < options.size():
			var label := str(options[index].get("label", "Option %d" % [index + 1]))
			button.text = label
			button.visible = true
			button.disabled = false
		else:
			button.visible = false
			button.disabled = true
	hud_level_up_overlay.visible = true
	if hud_level_up_buttons.size() > 0:
		hud_level_up_buttons[0].grab_focus()


func hide_level_up_choices() -> void:
	if hud_level_up_overlay != null:
		hud_level_up_overlay.visible = false
	hud_level_up_options.clear()


func _build_level_up_menu() -> void:
	if hud_level_up_overlay != null:
		return
	hud_level_up_overlay = PanelContainer.new()
	hud_level_up_overlay.name = "LevelUpOverlay"
	hud_level_up_overlay.visible = false
	hud_level_up_overlay.process_mode = Node.PROCESS_MODE_ALWAYS
	hud_level_up_overlay.anchor_left = 0.5
	hud_level_up_overlay.anchor_top = 0.5
	hud_level_up_overlay.anchor_right = 0.5
	hud_level_up_overlay.anchor_bottom = 0.5
	hud_level_up_overlay.offset_left = -220.0
	hud_level_up_overlay.offset_top = -140.0
	hud_level_up_overlay.offset_right = 220.0
	hud_level_up_overlay.offset_bottom = 140.0

	var margin := MarginContainer.new()
	margin.anchor_left = 0.0
	margin.anchor_top = 0.0
	margin.anchor_right = 1.0
	margin.anchor_bottom = 1.0
	margin.offset_left = 12.0
	margin.offset_top = 12.0
	margin.offset_right = -12.0
	margin.offset_bottom = -12.0

	var vbox := VBoxContainer.new()
	vbox.anchor_left = 0.0
	vbox.anchor_top = 0.0
	vbox.anchor_right = 1.0
	vbox.anchor_bottom = 1.0
	vbox.offset_left = 0.0
	vbox.offset_top = 0.0
	vbox.offset_right = 0.0
	vbox.offset_bottom = 0.0
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER

	var title := Label.new()
	title.text = "Level Up! Choose an upgrade"
	vbox.add_child(title)

	for index in range(3):
		var button := Button.new()
		button.text = "Option %d" % [index + 1]
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.pressed.connect(_on_level_up_option_pressed.bind(index))
		hud_level_up_buttons.append(button)
		vbox.add_child(button)

	margin.add_child(vbox)
	hud_level_up_overlay.add_child(margin)
	add_child(hud_level_up_overlay)


func _on_level_up_option_pressed(index: int) -> void:
	if index < 0 or index >= hud_level_up_options.size():
		return
	var choice := hud_level_up_options[index]
	hide_level_up_choices()
	var game_state := get_tree().get_first_node_in_group("game_state")
	if game_state != null and game_state.has_method("resolve_level_up_choice"):
		game_state.resolve_level_up_choice(choice)
	else:
		push_warning("GameHud: GameState missing resolve_level_up_choice; cannot apply upgrade.")
