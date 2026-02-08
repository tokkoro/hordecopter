###############################################################
# weapons/plasma_ball.gd
# Key Classes      • PlasmaBall – straight projectile
# Key Functions    • configure() – seed damage and velocity
# Critical Consts  • n/a
# Editor Exports   • speed: float – travel speed
# Dependencies     • weapons/weapon_definition.gd
# Last Major Rev   • 25-09-20 – initial plasma projectile
###############################################################

class_name PlasmaBall
extends Area3D

@export var speed: float = 14.0
@export var lifetime: float = 3.5

var _weapon_damage: float = 0.0
var _weapon_knockback: float = 0.0
var _velocity: Vector3 = Vector3.ZERO


func _ready() -> void:
	monitoring = true
	monitorable = true
	body_entered.connect(_on_body_entered)
	var timer := get_tree().create_timer(lifetime)
	timer.timeout.connect(queue_free)


func configure(weapon: WeaponDefinition, direction: Vector3) -> void:
	_weapon_damage = weapon.damage
	_weapon_knockback = weapon.knockback
	if direction.length() > 0.0:
		_velocity = direction.normalized() * speed
	else:
		_velocity = -global_transform.basis.z * speed


func apply_projectile_speed_bonus(amount: float) -> void:
	if amount == 0.0:
		return
	speed = max(0.0, speed + amount)


func apply_projectile_size_bonus(amount: float) -> void:
	if amount == 0.0:
		return
	scale = scale + Vector3.ONE * amount


func _physics_process(delta: float) -> void:
	global_position += _velocity * delta


func _on_body_entered(body: Node) -> void:
	if body != null and body.has_method("apply_damage"):
		body.apply_damage(_weapon_damage, _weapon_knockback, global_position)
	queue_free()
