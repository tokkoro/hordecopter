class_name Hordecopter
extends RigidBody3D

@export var auto_float: bool = true
@export var my_camera_name: StringName = &"Camera3D"
@export var auto_float_power_max: float = 2000.0
# PID multipliers
@export var kp: float = 25.0
@export var ki: float = 2.0
@export var kd: float = 12.0
@export var d_filter_hz: float = -1.0
@export var rotation_speed: float = 50.0

var my_camera: Camera3D
var auto_float_target_altitude: float = 10.0
var show_info: bool = false
var upward_power: float = 100_000.0
var sideward_power: float = 100_000.0
var forward_power: float = 100_000.0
var max_y_speed: float = 10.0
var max_x_speed: float = 10.0
var max_z_speed: float = 10.0
var _i: float = 0.0
var _prev_error: float = 0.0
var _d_state: float = 0.0
@onready var propellit: Node = get_node("rollaus_pivot_piste")
@onready var infotext: Label3D = get_node("infotext")


func _ready() -> void:
	print("hello world")
	my_camera = _find_node_by_name(get_tree().current_scene, my_camera_name)
	if my_camera == null:
		push_error("Missä on mun kamera? %s" % [my_camera_name])
		return


func _physics_process(delta: float) -> void:
	# handle _p1_ inputs
	var up_force_input = 0
	if Input.is_action_pressed("p1_thrust_up"):
		up_force_input = 1
	if Input.is_action_pressed("p1_thurst_down"):
		up_force_input = -1

	if up_force_input == 0:
		if not auto_float:
			auto_float_target_altitude = global_position.y
			auto_float = true
	else:
		auto_float = false
		apply_force(Vector3.UP * upward_power * delta * up_force_input)

	var directions = get_camera_xz_basis(my_camera)

	var side_force_input = 0
	if Input.is_action_pressed("p1_thrust_right"):
		side_force_input = 1
	if Input.is_action_pressed("p1_thurst_left"):
		side_force_input = -1

	if side_force_input != 0:
		apply_force(directions["right"] * sideward_power * delta * side_force_input)

	var forward_force_input = 0
	if Input.is_action_pressed("p1_thrust_forward"):
		forward_force_input = 1
	if Input.is_action_pressed("p1_thurst_backward"):
		forward_force_input = -1

	if forward_force_input != 0:
		apply_force(directions["forward"] * forward_power * delta * forward_force_input)

	var auto_float_debug_value: float = 0.0
	## AUTO FLOAT SYSTEM
	if auto_float:
		var y := global_position.y
		var error := auto_float_target_altitude - y

		# I: integral part
		_i += error * delta
		_i = clamp(_i, -50, 50)  # clampping

		#D: derivative
		var d_raw: float = (error - _prev_error) / max(delta, 0.000001)

		# first order low-pass derivative
		if d_filter_hz > 0.0:
			var alpha := 1.0 - exp(-TAU * d_filter_hz * delta)
			_d_state = lerp(_d_state, d_raw, alpha)
		else:
			_d_state = d_raw
		_prev_error = error

		#PID force:
		var u := kp * error + ki * _i + kd * _d_state

		#gravity
		var g := float(ProjectSettings.get_setting("physics/3d/default_gravity"))
		var hover_force := mass * g

		#total force
		var force_y := hover_force + u
		auto_float_debug_value = force_y
		#limit
		force_y = clamp(force_y, -auto_float_power_max, auto_float_power_max)

		apply_force(Vector3.UP * force_y)

	var rot_input: float = 0.0
	if Input.is_action_pressed("p1_rotate_ccw"):
		rot_input = 1
	if Input.is_action_pressed("p1_rotate_cw"):
		rot_input = -1

	if rot_input != 0:
		rotation_degrees = Vector3(0, rotation_degrees.y + delta * rotation_speed * rot_input, 0)

	# clamp up speed and damp a bit
	linear_velocity = Vector3(
		clamp(linear_velocity.x * 0.95, -max_x_speed, max_x_speed),
		clamp(linear_velocity.y, -max_y_speed, max_y_speed),
		clamp(linear_velocity.z * 0.95, -max_z_speed, max_z_speed)
	)
	propellit.set_speeds(abs(linear_velocity.length() * 0.5) + 3)

	if Input.is_action_just_pressed("p1_show_info_toggle"):
		show_info = not show_info
	if show_info:
		infotext.text = (
			"Altitude: %.2f\nAltitude target: %.2f\nLinVelY: %.2f\nAutofloat F: %.2f "
			% [
				global_position.y,
				auto_float_target_altitude,
				linear_velocity.y,
				auto_float_debug_value
			]
		)
	else:
		infotext.text = ""


func _find_node_by_name(root: Node, name: StringName) -> Node3D:
	if root.name == name and root is Node3D:
		return root as Node3D
	for child in root.get_children():
		var found := _find_node_by_name(child, name)
		if found != null:
			return found
	return null


func get_camera_xz_basis(cam: Camera3D) -> Dictionary:
	# Godot forward is -Z in basis.
	var fwd: Vector3 = -cam.global_transform.basis.z
	fwd.y = 0.0
	fwd = fwd.normalized()

	var right: Vector3 = cam.global_transform.basis.x
	right.y = 0.0
	right = right.normalized()

	# Re-orthonormalize
	right = right - fwd * right.dot(fwd)
	right = right.normalized()

	return {"forward": fwd, "right": right}
