class_name LaserBeam
extends Node3D

@export var lifetime: float = 0.05
@export var line_path: NodePath = NodePath("Line3D")

var _line: Line3D


func _ready() -> void:
	_line = get_node(line_path) as Line3D
	var timer := get_tree().create_timer(lifetime)
	timer.timeout.connect(queue_free)


func configure(start: Vector3, end: Vector3, color: Color, width: float) -> void:
	global_position = start
	var local_end := end - start
	_line.clear_points()
	_line.add_point(Vector3.ZERO)
	_line.add_point(local_end)
	_line.width = width
	_line.default_color = color
