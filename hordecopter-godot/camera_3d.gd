extends Camera3D

@export var target_name: StringName = &"Hordecopter"
@export var follow_smooth: float = 8.0               # higher = snappier position follow
@export var look_smooth: float = 10.0                # higher = snappier look-at
@export var min_distance: float = 0.0                # optional clamp
@export var max_distance: float = 0.0                # 0 = disabled

@export var look_over_amount: float = 1.2

var target: Node3D
var local_offset: Vector3
var _smoothed_look_point: Vector3


func _ready() -> void:
	target = _find_node_by_name(get_tree().current_scene, target_name)
	if target == null:
		push_error("Missä on sun kopteri? %s" % [target_name])
		return

	local_offset = target.global_transform.basis.inverse() * (global_position - target.global_position)
	_smoothed_look_point = target.global_position

func _physics_process(delta: float) -> void:
	if target == null:
		return

	var desired_offset_world := target.global_transform.basis * local_offset
	var desired_pos := target.global_position + desired_offset_world

	if max_distance > 0.0:
		var to_cam := desired_pos - target.global_position
		var dist := to_cam.length()
		if min_distance > 0.0 and dist < min_distance:
			desired_pos = target.global_position + to_cam.normalized() * min_distance
		if dist > max_distance:
			desired_pos = target.global_position + to_cam.normalized() * max_distance

	var t_pos := 1.0 - exp(-follow_smooth * delta)
	global_position = global_position.lerp(desired_pos, t_pos)

	var t_look := 1.0 - exp(-look_smooth * delta)
	_smoothed_look_point = _smoothed_look_point.lerp(target.global_position, t_look)
	look_at(_smoothed_look_point + Vector3.UP * look_over_amount, Vector3.UP)

func _find_node_by_name(root: Node, name: StringName) -> Node3D:
	if root.name == name and root is Node3D:
		return root as Node3D
	for child in root.get_children():
		var found := _find_node_by_name(child, name)
		if found != null:
			return found
	return null
