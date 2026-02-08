###############################################################
# enemies/enemy_health_bar.gd
# Key Classes      • EnemyHealthBar3D – 3D enemy health meter
# Key Functions    • set_health() – update bar from current/max values
#                 • set_ratio() – update bar from ratio
# Critical Consts  • n/a
# Editor Exports   • bar_width: float – base width for the fill mesh
# Dependencies     • n/a
# Last Major Rev   • 25-09-27 – add toggleable enemy health bar
###############################################################

class_name EnemyHealthBar3D
extends Node3D

@export var bar_width: float = 1.0
@export var always_visible = false
@export var fade_when_full = false

var enemy_health_bar_max_health: float = 1.0
var enemy_health_bar_base_width: float = 1.0
var enemy_health_bar_background_color: Color = Color.WHITE
var enemy_health_bar_fill_color: Color = Color.WHITE

@onready var bar_background: MeshInstance3D = $Background
@onready var bar_fill: MeshInstance3D = $Fill


func _ready() -> void:
	add_to_group("enemy_health_bars")
	enemy_health_bar_base_width = _resolve_base_width()
	_cache_base_colors()
	visible = always_visible or _resolve_initial_visibility()


func set_health(current_health: float, max_health: float) -> void:
	enemy_health_bar_max_health = max(1.0, max_health)
	_update_ratio(current_health / enemy_health_bar_max_health)


func set_ratio(ratio: float) -> void:
	_update_ratio(ratio)


func _resolve_base_width() -> float:
	if bar_fill.mesh is BoxMesh:
		return (bar_fill.mesh as BoxMesh).size.x
	return bar_width


func _resolve_initial_visibility() -> bool:
	var game_state := get_tree().get_first_node_in_group("game_state")
	if game_state != null and game_state.has_method("are_enemy_health_bars_visible"):
		return game_state.are_enemy_health_bars_visible()
	return false


func _update_ratio(ratio: float) -> void:
	var clamped_ratio: float = clampf(ratio, 0.0, 1.0)
	bar_fill.scale.x = clamped_ratio
	bar_fill.position.x = -0.5 * enemy_health_bar_base_width * (1.0 - clamped_ratio)
	_apply_full_fade(clamped_ratio)


func _cache_base_colors() -> void:
	if bar_background.material_override is StandardMaterial3D:
		var background_material := bar_background.material_override as StandardMaterial3D
		enemy_health_bar_background_color = background_material.albedo_color
		bar_background.material_override = background_material.duplicate()
	if bar_fill.material_override is StandardMaterial3D:
		var fill_material := bar_fill.material_override as StandardMaterial3D
		enemy_health_bar_fill_color = fill_material.albedo_color
		bar_fill.material_override = fill_material.duplicate()


func _apply_full_fade(ratio: float) -> void:
	if not fade_when_full:
		_set_material_alpha(bar_background, enemy_health_bar_background_color, 1.0)
		_set_material_alpha(bar_fill, enemy_health_bar_fill_color, 1.0)
		return
	var fade_ratio := clampf((ratio - 0.9) / 0.1, 0.0, 1.0)
	var fade_alpha := 1.0 - fade_ratio
	_set_material_alpha(bar_background, enemy_health_bar_background_color, fade_alpha)
	_set_material_alpha(bar_fill, enemy_health_bar_fill_color, fade_alpha)


func _set_material_alpha(mesh_instance: MeshInstance3D, base_color: Color, alpha: float) -> void:
	if mesh_instance.material_override is StandardMaterial3D:
		var material := mesh_instance.material_override as StandardMaterial3D
		var next_color := base_color
		next_color.a = alpha
		material.albedo_color = next_color
