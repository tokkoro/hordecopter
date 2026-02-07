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
@export var grenade_gravity: float = 18.0
@export var lifetime: float = 2.2
@export var explosion_radius: float = 2.5
@export var explosion_scene: PackedScene

var _weapon_damage: float = 0.0
var _velocity: Vector3 = Vector3.ZERO
var _grenade_has_exploded: bool = false


func _ready() -> void:
	set_deferred("monitoring", true)
	set_deferred("monitorable", true)
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
	_velocity.y -= grenade_gravity * delta
	global_position += _velocity * delta


func _on_body_entered(_body: Node) -> void:
	_explode()


func _explode() -> void:
	if _grenade_has_exploded or not is_inside_tree():
		return
	_grenade_has_exploded = true
	if explosion_scene:
		var explosion := explosion_scene.instantiate()
		var target_parent := get_parent()
		if target_parent == null:
			target_parent = get_tree().current_scene
		if target_parent:
			target_parent.add_child(explosion)
		if explosion is Node3D:
			var explosion_node := explosion as Node3D
			explosion_node.global_position = global_position
		if explosion.has_method("configure"):
			explosion.configure(_weapon_damage, explosion_radius)
	queue_free()
