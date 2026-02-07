###############################################################
# weapons/homing_missile.gd
# Key Classes      • HomingMissile – seeking projectile
# Key Functions    • configure() – seed damage and direction
# Critical Consts  • n/a
# Editor Exports   • speed: float – travel speed
# Dependencies     • weapons/weapon_definition.gd
# Last Major Rev   • 25-09-20 – initial homing missile logic
###############################################################

class_name HomingMissile
extends Area3D

@export var speed: float = 12.0
@export var turn_rate: float = 6.0
@export var lifetime: float = 6.0

var _weapon_damage: float = 0.0
var _velocity: Vector3 = Vector3.ZERO
var _target: Node3D


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	var timer := get_tree().create_timer(lifetime)
	timer.timeout.connect(queue_free)


func configure(weapon: WeaponDefinition, direction: Vector3) -> void:
	_weapon_damage = weapon.damage
	if direction.length() > 0.0:
		_velocity = direction.normalized() * speed
	else:
		_velocity = -global_transform.basis.z * speed


func _physics_process(delta: float) -> void:
	if _velocity == Vector3.ZERO:
		_velocity = -global_transform.basis.z * speed
	if _target == null or not is_instance_valid(_target):
		_target = _find_target()
	if _target != null:
		var desired := (_target.global_position - global_position).normalized()
		var current := _velocity.normalized()
		var lerp_amount: float = clamp(turn_rate * delta, 0.0, 1.0)
		var new_direction := current.slerp(desired, lerp_amount)
		_velocity = new_direction * speed
		look_at(global_position + new_direction, Vector3.UP)
	global_position += _velocity * delta


func _find_target() -> Node3D:
	var candidates := get_tree().get_nodes_in_group("enemy_targets")
	var closest: Node3D = null
	var closest_distance := INF
	for candidate in candidates:
		if candidate is Node3D:
			var node := candidate as Node3D
			var distance := global_position.distance_to(node.global_position)
			if distance < closest_distance:
				closest_distance = distance
				closest = node
	return closest


func _on_body_entered(body: Node) -> void:
	if body != null and body.has_method("apply_damage"):
		body.apply_damage(_weapon_damage)
	queue_free()
