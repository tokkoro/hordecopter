###############################################################
# ui/damage_label_3d.gd
# Key Classes      • DamageLabel3D – floating damage text label
# Key Functions    • set_damage() – set displayed damage amount
#                 • _process() – animate upward float and fade
# Critical Consts  • n/a
# Editor Exports   • float_duration: float – lifetime in seconds
#                 • float_speed: float – vertical speed per second
# Dependencies     • n/a
# Last Major Rev   • 25-09-27 – add floating damage label behavior
###############################################################

class_name DamageLabel3D
extends Node3D

@export var float_duration: float = 2.0
@export var float_speed: float = 0.9

var damage_label_elapsed: float = 0.0
var damage_label_base_color: Color = Color.WHITE

@onready var damage_label_text: Label3D = $Label3D


func _ready() -> void:
	damage_label_base_color = damage_label_text.modulate
	_update_alpha(1.0)


func _process(delta: float) -> void:
	damage_label_elapsed += delta
	global_position.y += float_speed * delta
	var damage_label_ratio: float = 0.0
	if float_duration > 0.0:
		damage_label_ratio = damage_label_elapsed / float_duration
	var damage_label_alpha: float = 1.0 - clampf(damage_label_ratio, 0.0, 1.0)
	_update_alpha(damage_label_alpha)
	if damage_label_elapsed >= float_duration:
		queue_free()


func set_damage(amount: float) -> void:
	var damage_label_rounded: int = int(round(amount))
	damage_label_text.text = str(damage_label_rounded)


func _update_alpha(alpha: float) -> void:
	var damage_label_color: Color = damage_label_base_color
	damage_label_color.a = alpha
	damage_label_text.modulate = damage_label_color
