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

const HUD_MAX_WEAPON_SLOTS: int = 6
const HUD_MAX_ITEM_SLOTS: int = 5

@export var show_experience_numbers: bool = false
@export var menu_select_sound: AudioStream = preload("res://sfx/menu_select.sfxr")
const LEVEL_UP :AudioStream= preload("uid://ccqsebs1ovo5c")

var hud_level_up_overlay: PanelContainer
var hud_level_up_buttons: Array[Button] = []
var hud_level_up_options: Array[Dictionary] = []
var hud_weapon_slots_container: HBoxContainer
var hud_weapon_slot_panels: Array[PanelContainer] = []
var hud_weapon_slot_icons: Array[TextureRect] = []
var hud_weapon_slot_labels: Array[Label] = []
var hud_item_slots_container: HBoxContainer
var hud_item_slot_panels: Array[PanelContainer] = []
var hud_item_slot_icons: Array[TextureRect] = []
var hud_item_slot_labels: Array[Label] = []

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
	_build_weapon_slots()
	update_weapon_slots([])
	_build_item_slots()
	update_item_slots([])
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
	hud_time_label.text = "%02d:%02d" % [minutes, seconds]


func update_level(level: int, progress: float, experience: int, experience_cap: int) -> void:
	hud_level_label.text = "  Level %d" % level
	hud_level_bar.value = clamp(progress, 0.0, 1.0)
	if show_experience_numbers:
		hud_experience_label.text = "%d / %d XP" % [experience, experience_cap]


func update_weapon_slots(weapon_data: Array[Dictionary]) -> void:
	if hud_weapon_slot_panels.is_empty():
		_build_weapon_slots()
	var slot_count := HUD_MAX_WEAPON_SLOTS
	for index in range(slot_count):
		var slot_panel := hud_weapon_slot_panels[index]
		var icon := hud_weapon_slot_icons[index]
		var label := hud_weapon_slot_labels[index]
		if index < weapon_data.size():
			var entry := weapon_data[index]
			var texture := entry.get("icon", null) as Texture2D
			var level := int(entry.get("level", 0))
			var unlocked := level > 0 and texture != null
			icon.texture = texture
			icon.visible = unlocked
			label.visible = unlocked
			label.text = "%d" % level if unlocked else ""
			slot_panel.modulate = Color(1, 1, 1, 1) if unlocked else Color(1, 1, 1, 0.35)
		else:
			icon.texture = null
			icon.visible = false
			label.text = ""
			label.visible = false
			slot_panel.modulate = Color(1, 1, 1, 0.35)


func update_item_slots(item_data: Array[Dictionary]) -> void:
	if hud_item_slot_panels.is_empty():
		_build_item_slots()
	var slot_count := HUD_MAX_ITEM_SLOTS
	for index in range(slot_count):
		var slot_panel := hud_item_slot_panels[index]
		var icon := hud_item_slot_icons[index]
		var label := hud_item_slot_labels[index]
		if index < item_data.size():
			var entry := item_data[index]
			var texture := entry.get("icon", null) as Texture2D
			var level := int(entry.get("level", 0))
			var unlocked := level > 0
			icon.texture = texture
			icon.visible = texture != null and unlocked
			label.visible = unlocked
			label.text = "%d" % level if unlocked else ""
			slot_panel.modulate = Color(1, 1, 1, 1) if unlocked else Color(1, 1, 1, 0.35)
		else:
			icon.texture = null
			icon.visible = false
			label.text = ""
			label.visible = false
			slot_panel.modulate = Color(1, 1, 1, 0.35)

func show_level_up_choices(options: Array[Dictionary]) -> void:
	hud_level_up_options = options
	if hud_level_up_overlay == null:
		_build_level_up_menu()
	for index in range(hud_level_up_buttons.size()):
		var button := hud_level_up_buttons[index]
		if index < options.size():
			var label := str(options[index].get("label", "Option %d" % [index + 1]))
			var icon := options[index].get("icon", null) as Texture2D
			button.text = label
			button.icon = icon
			button.visible = true
			button.disabled = false
		else:
			button.icon = null
			button.visible = false
			button.disabled = true
	hud_level_up_overlay.visible = true
	if hud_level_up_buttons.size() > 0:
		hud_level_up_buttons[0].grab_focus()

	var player := AudioStreamPlayer.new()
	player.stream = LEVEL_UP
	player.process_mode = Node.PROCESS_MODE_ALWAYS
	player.finished.connect(player.queue_free)
	add_child(player)
	player.play()


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

	var speed_note := Label.new()
	speed_note.text = "Movement speed +10%"
	speed_note.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	speed_note.add_theme_font_size_override("font_size", 12)
	vbox.add_child(speed_note)

	for index in range(3):
		var button := Button.new()
		button.text = "Option %d" % [index + 1]
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.icon_alignment = HORIZONTAL_ALIGNMENT_LEFT
		button.expand_icon = true
		button.custom_minimum_size = Vector2(0, 100)
		button.pressed.connect(_on_level_up_option_pressed.bind(index))
		hud_level_up_buttons.append(button)
		vbox.add_child(button)

	margin.add_child(vbox)
	hud_level_up_overlay.add_child(margin)
	add_child(hud_level_up_overlay)


func _build_weapon_slots() -> void:
	if hud_weapon_slots_container != null:
		return
	var container := MarginContainer.new()
	container.name = "WeaponSlots"
	container.anchor_left = 1.0
	container.anchor_top = 1.0
	container.anchor_right = 1.0
	container.anchor_bottom = 1.0
	container.offset_left = -360.0
	container.offset_top = -72.0
	container.offset_right = -20.0
	container.offset_bottom = -20.0
	container.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	container.grow_vertical = Control.GROW_DIRECTION_BEGIN

	hud_weapon_slots_container = HBoxContainer.new()
	hud_weapon_slots_container.name = "WeaponSlotRow"
	hud_weapon_slots_container.add_theme_constant_override("separation", 8)
	container.add_child(hud_weapon_slots_container)
	add_child(container)

	for index in range(HUD_MAX_WEAPON_SLOTS):
		var slot_panel := PanelContainer.new()
		slot_panel.name = "WeaponSlot%d" % [index + 1]
		slot_panel.custom_minimum_size = Vector2(48, 48)

		var slot_root := Control.new()
		slot_root.custom_minimum_size = Vector2(48, 48)
		slot_panel.add_child(slot_root)

		var icon := TextureRect.new()
		icon.name = "Icon"
		icon.anchor_left = 0.0
		icon.anchor_top = 0.0
		icon.anchor_right = 1.0
		icon.anchor_bottom = 1.0
		icon.offset_left = 0.0
		icon.offset_top = 0.0
		icon.offset_right = 0.0
		icon.offset_bottom = 0.0
		icon.expand_mode = TextureRect.EXPAND_FIT_WIDTH
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		slot_root.add_child(icon)

		var slot_label := Label.new()
		slot_label.name = "SlotLabel"
		slot_label.text = "%d" % [index + 1]
		slot_label.anchor_left = 0.0
		slot_label.anchor_top = 0.0
		slot_label.anchor_right = 0.0
		slot_label.anchor_bottom = 0.0
		slot_label.offset_left = 4.0
		slot_label.offset_top = 2.0
		slot_label.offset_right = 20.0
		slot_label.offset_bottom = 18.0
		slot_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		slot_label.vertical_alignment = VERTICAL_ALIGNMENT_TOP
		slot_label.add_theme_font_size_override("font_size", 12)
		slot_root.add_child(slot_label)

		var level_label := Label.new()
		level_label.name = "LevelLabel"
		level_label.anchor_left = 0.0
		level_label.anchor_top = 0.0
		level_label.anchor_right = 1.0
		level_label.anchor_bottom = 1.0
		level_label.offset_left = 0.0
		level_label.offset_top = 0.0
		level_label.offset_right = -4.0
		level_label.offset_bottom = -2.0
		level_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		level_label.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
		level_label.add_theme_font_size_override("font_size", 14)
		slot_root.add_child(level_label)

		hud_weapon_slot_panels.append(slot_panel)
		hud_weapon_slot_icons.append(icon)
		hud_weapon_slot_labels.append(level_label)
		hud_weapon_slots_container.add_child(slot_panel)


func _build_item_slots() -> void:
	if hud_item_slots_container != null:
		return
	var container := MarginContainer.new()
	container.name = "ItemSlots"
	container.anchor_left = 1.0
	container.anchor_top = 1.0
	container.anchor_right = 1.0
	container.anchor_bottom = 1.0
	container.offset_left = -360.0
	container.offset_top = -132.0
	container.offset_right = -20.0
	container.offset_bottom = -84.0
	container.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	container.grow_vertical = Control.GROW_DIRECTION_BEGIN

	hud_item_slots_container = HBoxContainer.new()
	hud_item_slots_container.name = "ItemSlotRow"
	hud_item_slots_container.add_theme_constant_override("separation", 8)
	container.add_child(hud_item_slots_container)
	add_child(container)

	for index in range(HUD_MAX_ITEM_SLOTS):
		var slot_panel := PanelContainer.new()
		slot_panel.name = "ItemSlot%d" % [index + 1]
		slot_panel.custom_minimum_size = Vector2(48, 48)

		var slot_root := Control.new()
		slot_root.custom_minimum_size = Vector2(48, 48)
		slot_panel.add_child(slot_root)

		var icon := TextureRect.new()
		icon.name = "Icon"
		icon.anchor_left = 0.0
		icon.anchor_top = 0.0
		icon.anchor_right = 1.0
		icon.anchor_bottom = 1.0
		icon.offset_left = 0.0
		icon.offset_top = 0.0
		icon.offset_right = 0.0
		icon.offset_bottom = 0.0
		icon.expand_mode = TextureRect.EXPAND_FIT_WIDTH
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		slot_root.add_child(icon)

		var slot_label := Label.new()
		slot_label.name = "SlotLabel"
		slot_label.text = "%d" % [index + 1]
		slot_label.anchor_left = 0.0
		slot_label.anchor_top = 0.0
		slot_label.anchor_right = 0.0
		slot_label.anchor_bottom = 0.0
		slot_label.offset_left = 4.0
		slot_label.offset_top = 2.0
		slot_label.offset_right = 20.0
		slot_label.offset_bottom = 18.0
		slot_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		slot_label.vertical_alignment = VERTICAL_ALIGNMENT_TOP
		slot_label.add_theme_font_size_override("font_size", 12)
		slot_root.add_child(slot_label)

		var level_label := Label.new()
		level_label.name = "LevelLabel"
		level_label.anchor_left = 0.0
		level_label.anchor_top = 0.0
		level_label.anchor_right = 1.0
		level_label.anchor_bottom = 1.0
		level_label.offset_left = 0.0
		level_label.offset_top = 0.0
		level_label.offset_right = -4.0
		level_label.offset_bottom = -2.0
		level_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		level_label.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
		level_label.add_theme_font_size_override("font_size", 14)
		slot_root.add_child(level_label)

		hud_item_slot_panels.append(slot_panel)
		hud_item_slot_icons.append(icon)
		hud_item_slot_labels.append(level_label)
		hud_item_slots_container.add_child(slot_panel)


func _on_level_up_option_pressed(index: int) -> void:
	if index < 0 or index >= hud_level_up_options.size():
		return
	var choice := hud_level_up_options[index]
	hide_level_up_choices()
	_play_menu_select_sfx()
	var game_state := get_tree().get_first_node_in_group("game_state")
	if game_state != null and game_state.has_method("resolve_level_up_choice"):
		game_state.resolve_level_up_choice(choice)
	else:
		push_warning("GameHud: GameState missing resolve_level_up_choice; cannot apply upgrade.")


func _play_menu_select_sfx() -> void:
	if menu_select_sound == null:
		return
	var player := AudioStreamPlayer.new()
	player.stream = menu_select_sound
	player.process_mode = Node.PROCESS_MODE_ALWAYS
	player.finished.connect(player.queue_free)
	add_child(player)
	player.play()
