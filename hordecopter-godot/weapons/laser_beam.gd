###############################################################
# weapons/laser_beam.gd
# Key Classes      • LaserBeam – short-lived beam visual
# Key Functions    • configure() – set segment, color, width
# Critical Consts  • n/a
# Editor Exports   • lifetime: float – beam lifetime
# Dependencies     • n/a
# Last Major Rev   • 25-09-27 – add sweep motion + multi-hit damage
###############################################################

class_name LaserBeam
extends Node3D

const SWEEP_ANGLE_DEGREES: float = 179.0

@export var lifetime: float = 0.05
@export var beam_mesh_path: NodePath = NodePath("BeamMesh")
@export var sweep_duration: float = 0.35
@export var sweep_ease_power: float = 2.0
var _beam_mesh: MeshInstance3D
var _beam_material: StandardMaterial3D
var _sweep_active := false
var _sweep_elapsed := 0.0
var _sweep_origin := Vector3.ZERO
var _sweep_base_direction := Vector3.FORWARD
var _sweep_right_axis := Vector3.RIGHT
var _sweep_range := 0.0
var _sweep_damage := 0.0
var _sweep_knockback := 0.0
var _sweep_color := Color.WHITE
var _sweep_width := 0.05
var _sweep_start_angle := 0.0
var _sweep_end_angle := 0.0
var _sweep_shape: BoxShape3D
var _sweep_exclude_rids: Array[RID] = []
var _hit_ids: Dictionary = {}


func _ready() -> void:
	_beam_mesh = get_node(beam_mesh_path) as MeshInstance3D
	if _beam_mesh != null:
		_beam_material = _beam_mesh.get_active_material(0) as StandardMaterial3D


func _physics_process(delta: float) -> void:
	if not _sweep_active:
		return
	_sweep_elapsed += delta
	var t := 1.0
	if sweep_duration > 0.0:
		t = clampf(_sweep_elapsed / sweep_duration, 0.0, 1.0)
	var eased_t := pow(t, sweep_ease_power)
	var angle := lerpf(_sweep_start_angle, _sweep_end_angle, eased_t)
	var direction := (
		_sweep_base_direction.rotated(_sweep_right_axis, deg_to_rad(angle)).normalized()
	)
	var end := _sweep_origin + direction * _sweep_range
	_update_beam(_sweep_origin, end, _sweep_color, _sweep_width)
	_apply_sweep_damage(_sweep_origin, direction)
	if t >= 1.0:
		queue_free()


func configure(start: Vector3, end: Vector3, color: Color, width: float) -> void:
	_sweep_active = false
	_update_beam(start, end, color, width)
	_start_lifetime_timer(lifetime)


func configure_sweep(
	start: Vector3,
	direction: Vector3,
	range: float,
	damage: float,
	knockback: float,
	color: Color,
	width: float,
	exclude_node: Node = null
) -> void:
	_sweep_active = true
	_sweep_elapsed = 0.0
	_sweep_origin = start
	_sweep_base_direction = direction.normalized()
	_sweep_range = range
	_sweep_damage = damage
	_sweep_knockback = knockback
	_sweep_color = color
	_sweep_width = width
	_hit_ids.clear()
	_sweep_shape = BoxShape3D.new()
	_sweep_shape.size = Vector3(width, width, range)
	_sweep_exclude_rids.clear()
	if exclude_node != null and exclude_node is CollisionObject3D:
		_sweep_exclude_rids.append(exclude_node.get_rid())
	var right_axis := _sweep_base_direction.cross(Vector3.UP)
	if right_axis.length() < 0.001:
		right_axis = Vector3.RIGHT
	_sweep_right_axis = right_axis.normalized()
	_sweep_start_angle = SWEEP_ANGLE_DEGREES * 0.5
	_sweep_end_angle = -SWEEP_ANGLE_DEGREES * 0.5
	_update_beam(
		_sweep_origin,
		_sweep_origin + _sweep_base_direction * _sweep_range,
		_sweep_color,
		_sweep_width
	)


func _apply_sweep_damage(start: Vector3, direction: Vector3) -> void:
	var space := get_world_3d().direct_space_state
	if space == null or _sweep_shape == null:
		return
	var end := start + direction * _sweep_range
	var midpoint := start.lerp(end, 0.5)
	var basis := Basis().looking_at(direction, Vector3.UP)
	var transform := Transform3D(basis, midpoint)
	var params := PhysicsShapeQueryParameters3D.new()
	params.shape = _sweep_shape
	params.transform = transform
	params.exclude = _sweep_exclude_rids
	params.collide_with_areas = true
	params.collide_with_bodies = true
	var results := space.intersect_shape(params)
	for entry in results:
		if not entry.has("collider"):
			continue
		var collider: Object = entry.collider
		if collider == null or not collider.has_method("apply_damage"):
			continue
		var id := collider.get_instance_id()
		if _hit_ids.has(id):
			continue
		_hit_ids[id] = true
		collider.apply_damage(_sweep_damage, _sweep_knockback, _sweep_origin)


func _update_beam(start: Vector3, end: Vector3, color: Color, width: float) -> void:
	if _beam_mesh == null:
		return
	var length := start.distance_to(end)
	var midpoint := start.lerp(end, 0.5)
	global_position = midpoint
	look_at(end, Vector3.UP)
	_beam_mesh.scale = Vector3(width, width, length)
	if _beam_material != null:
		_beam_material.albedo_color = color


func _start_lifetime_timer(duration: float) -> void:
	if duration <= 0.0:
		return
	var timer := get_tree().create_timer(duration)
	timer.timeout.connect(queue_free)
