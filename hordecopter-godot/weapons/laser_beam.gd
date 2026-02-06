###############################################################
# weapons/laser_beam.gd
# Key Classes      • LaserBeam – short-lived beam visual
# Key Functions    • configure() – set segment, color, width
# Critical Consts  • n/a
# Editor Exports   • lifetime: float – beam lifetime
# Dependencies     • n/a
# Last Major Rev   • 25-09-20 – initial laser beam effect
###############################################################

class_name LaserBeam
extends Node3D

@export var lifetime: float = 0.05
@export var beam_mesh_path: NodePath = NodePath("BeamMesh")

var _beam_mesh: MeshInstance3D
var _beam_material: StandardMaterial3D


func _ready() -> void:
	_beam_mesh = get_node(beam_mesh_path) as MeshInstance3D
	if _beam_mesh != null:
		_beam_material = _beam_mesh.get_active_material(0) as StandardMaterial3D
	var timer := get_tree().create_timer(lifetime)
	timer.timeout.connect(queue_free)


func configure(start: Vector3, end: Vector3, color: Color, width: float) -> void:
	if _beam_mesh == null:
		return
	var length := start.distance_to(end)
	var midpoint := start.lerp(end, 0.5)
	global_position = midpoint
	look_at(end, Vector3.UP)
	_beam_mesh.scale = Vector3(width, width, length)
	if _beam_material != null:
		_beam_material.albedo_color = color
