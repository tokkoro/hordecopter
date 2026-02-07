###############################################################
# weapons/grenade_projectile.gd
# Key Classes      • GrenadeProjectile – arcing explosive
# Key Functions    • configure() – seed damage and velocity
# Critical Consts  • n/a
# Editor Exports   • speed: float – launch speed
# Dependencies     • weapons/weapon_definition.gd
# Last Major Rev   • 25-09-20 – initial grenade projectile
###############################################################

class_name GrenadeProjectile
extends Area3D

@export var speed: float = 10.0
#@export var gravity: float = 18.0
@export var lifetime: float = 2.2
@export var explosion_radius: float = 2.5

var _weapon_damage: float = 0.0
var _velocity: Vector3 = Vector3.ZERO


func _ready() -> void:
	monitoring = true
	monitorable = true
	body_entered.connect(_on_body_entered)
	var timer := get_tree().create_timer(lifetime)
	timer.timeout.connect(_explode)


func configure(weapon: WeaponDefinition, direction: Vector3) -> void:
	_weapon_damage = weapon.damage
	var launch_direction := direction
	launch_direction.y = 0.35
	if launch_direction.length() > 0.0:
		_velocity = launch_direction.normalized() * speed
	else:
		_velocity = -global_transform.basis.z * speed


func _physics_process(delta: float) -> void:
	_velocity.y -= gravity * delta
	global_position += _velocity * delta


func _on_body_entered(_body: Node) -> void:
	_explode()


func _explode() -> void:
	if not is_inside_tree():
		return
	var bodies := get_overlapping_bodies()
	for body in bodies:
		if body is Node3D:
			var node := body as Node3D
			var distance := global_position.distance_to(node.global_position)
			if distance <= explosion_radius and node.has_method("apply_damage"):
				node.apply_damage(_weapon_damage)
	queue_free()
