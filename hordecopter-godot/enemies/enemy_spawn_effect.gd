###############################################################
# enemies/enemy_spawn_effect.gd
# Key Classes      • EnemySpawnEffect – visual grow/fade spawn cue
# Key Functions    • _emit_spawn_ready() – signal enemy spawn timing
# Critical Consts  • n/a
# Editor Exports   • growth_duration: float – scale-up duration
#                 • fade_duration: float – fade-out duration
#                 • start_scale: float – initial size multiplier
#                 • end_scale: float – final size multiplier
#                 • spawn_color: Color – effect tint/alpha
# Dependencies     • res://enemies/enemy_spawn_effect.tscn
# Last Major Rev   • 25-10-01 – add spawn cue grow/fade visuals
###############################################################

class_name EnemySpawnEffect
extends Node3D

signal spawn_ready

@export var growth_duration: float = 0.6
@export var fade_duration: float = 0.4
@export var start_scale: float = 0.2
@export var end_scale: float = 1.0
@export var spawn_color: Color = Color(0.7, 0.2, 1.0, 0.8)

var spawn_fx_material: StandardMaterial3D
@onready var spawn_fx_mesh: MeshInstance3D = $Sphere


func _ready() -> void:
	spawn_fx_material = StandardMaterial3D.new()
	spawn_fx_material.albedo_color = spawn_color
	spawn_fx_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	spawn_fx_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	spawn_fx_mesh.material_override = spawn_fx_material
	scale = Vector3.ONE * start_scale
	var spawn_fx_tween := create_tween()
	spawn_fx_tween.tween_property(self, "scale", Vector3.ONE * end_scale, growth_duration)
	spawn_fx_tween.tween_callback(_emit_spawn_ready)
	spawn_fx_tween.tween_property(spawn_fx_material, "albedo_color:a", 0.0, fade_duration)
	spawn_fx_tween.tween_callback(queue_free)


func _emit_spawn_ready() -> void:
	spawn_ready.emit()
