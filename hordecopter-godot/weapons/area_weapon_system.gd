###############################################################
# weapons/area_weapon_system.gd
# Key Classes      • AreaWeaponSystem – proximity damage logic
# Key Functions    • try_fire() – cooldown + area sweep
#                 • _update_indicator() – resize indicator mesh
# Critical Consts  • n/a
# Editor Exports   • indicator_path: NodePath – indicator node
# Dependencies     • weapons/weapon_system.gd
# Last Major Rev   • 25-09-27 – initial area weapon system
###############################################################

class_name AreaWeaponSystem
extends WeaponSystem

@export var indicator_path: NodePath = NodePath("AreaIndicator")
@onready var area_indicator = $"AreaIndicator"

var aws_indicator: Node3D
var aws_next_fire_time: float = 0.0


func _ready() -> void:
	if is_ready:
		return
	super._ready()
	if indicator_path != NodePath():
		aws_indicator = get_node_or_null(indicator_path) as Node3D
	_update_indicator()


func _physics_process(_delta: float) -> void:
	if weapon == null or not is_active:
		return
	try_fire()

func activate() -> void:
	super.activate()
	_update_indicator()

func try_fire() -> void:
	if weapon == null:
		return
	if weapon.fire_mode != WeaponDefinition.FireMode.AREA:
		return
	var now := Time.get_ticks_msec() / 1000.0
	if now < aws_next_fire_time:
		return
	aws_next_fire_time = now + weapon.cooldown
	_fire_area()


func _fire_area() -> void:
	var radius := _get_area_radius()
	if radius <= 0.0:
		return
	var origin := global_position
	for enemy in get_tree().get_nodes_in_group("enemies"):
		if enemy is Node3D:
			var enemy_node := enemy as Node3D
			if enemy_node.global_position.distance_to(origin) <= radius:
				if enemy_node.has_method("apply_damage"):
					enemy_node.apply_damage(weapon.damage)


func _get_area_radius() -> float:
	if weapon == null:
		return 0.0
	if weapon.area_radius > 0.0:
		return weapon.area_radius
	return weapon.range


func _update_indicator() -> void:
	if aws_indicator == null:
		return
	var radius := _get_area_radius()
	if radius <= 0.0 or not is_active:
		aws_indicator.visible = false
		return
	aws_indicator.visible = true
	aws_indicator.scale = Vector3(radius, 1.0, radius)
