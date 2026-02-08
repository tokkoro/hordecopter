###############################################################
# weapons/area_weapon_system.gd
# Key Classes      • AreaWeaponSystem – proximity damage logic
# Key Functions    • _update_pulse_state() – toggle active/inactive pulses
#                 • _try_damage() – periodic damage gate
#                 • _flash_indicator() – damage feedback flash
# Critical Consts  • n/a
# Editor Exports   • indicator_path: NodePath – indicator node
# Dependencies     • weapons/weapon_system.gd
# Last Major Rev   • 25-10-05 – pulse timing + damage flash
###############################################################

class_name AreaWeaponSystem
extends WeaponSystem

@export var indicator_path: NodePath = NodePath("AreaIndicator")
@export var aws_active_duration: float = 2.0
@export var aws_inactive_duration: float = 2.0
@export var aws_damage_interval: float = 1.0
@export var aws_damage_flash_duration: float = 0.1
@export var aws_damage_flash_color: Color = Color(1.0, 0.6, 0.2, 0.9)

var aws_indicator: Node3D
var aws_indicator_material: StandardMaterial3D
var aws_indicator_base_albedo: Color = Color.WHITE
var aws_indicator_base_emission: Color = Color.WHITE
var aws_is_pulse_active: bool = false
var aws_next_state_time: float = 0.0
var aws_next_damage_time: float = 0.0
var aws_flash_id: int = 0


func _ready() -> void:
	if is_ready:
		return
	super._ready()
	if indicator_path != NodePath():
		aws_indicator = get_node_or_null(indicator_path) as Node3D
	_cache_indicator_material()
	_reset_pulse_state()
	_update_indicator()


func _physics_process(_delta: float) -> void:
	if weapon == null or not is_active:
		return
	var now := Time.get_ticks_msec() / 1000.0
	_update_pulse_state(now)
	_try_damage(now)


func activate() -> void:
	super.activate()
	_reset_pulse_state()
	_update_indicator()


func _reset_pulse_state() -> void:
	var now := Time.get_ticks_msec() / 1000.0
	aws_is_pulse_active = false
	aws_next_state_time = now + max(0.05, aws_inactive_duration)
	aws_next_damage_time = now


func _update_pulse_state(now: float) -> void:
	if now < aws_next_state_time:
		return
	if aws_is_pulse_active:
		aws_is_pulse_active = false
		aws_next_state_time = now + max(0.05, aws_inactive_duration)
	else:
		aws_is_pulse_active = true
		aws_next_state_time = now + max(0.05, aws_active_duration)
		aws_next_damage_time = now
	_update_indicator()


func _try_damage(now: float) -> void:
	if weapon == null:
		return
	if weapon.fire_mode != WeaponDefinition.FireMode.AREA:
		return
	if not aws_is_pulse_active:
		return
	var interval := aws_damage_interval
	if interval <= 0.0:
		if weapon.cooldown > 0.0:
			interval = weapon.cooldown
		else:
			interval = 1.0
	if now < aws_next_damage_time:
		return
	aws_next_damage_time = now + interval
	_fire_area()
	_flash_indicator()


func _fire_area() -> void:
	var radius := _get_area_radius()
	if radius <= 0.0:
		return
	var origin := global_position
	for enemy in get_tree().get_nodes_in_group("enemy_targets"):
		if enemy is Node3D:
			var enemy_node := enemy as Node3D
			if enemy_node.global_position.distance_to(origin) <= radius:
				if enemy_node.has_method("apply_damage"):
					enemy_node.apply_damage(weapon.damage, weapon.knockback, origin)


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
	if radius <= 0.0 or not is_active or not aws_is_pulse_active:
		aws_indicator.visible = false
		return
	aws_indicator.visible = true
	aws_indicator.scale = Vector3(radius, 1.0, radius)


func _cache_indicator_material() -> void:
	if aws_indicator == null:
		return
	if aws_indicator is MeshInstance3D:
		var mesh_instance := aws_indicator as MeshInstance3D
		var material := mesh_instance.material_override
		if material is StandardMaterial3D:
			aws_indicator_material = material
			aws_indicator_base_albedo = aws_indicator_material.albedo_color
			aws_indicator_base_emission = aws_indicator_material.emission


func _flash_indicator() -> void:
	if aws_indicator_material == null:
		return
	aws_flash_id += 1
	var local_flash_id := aws_flash_id
	aws_indicator_material.albedo_color = aws_damage_flash_color
	aws_indicator_material.emission = aws_damage_flash_color
	await get_tree().create_timer(max(0.1, aws_damage_flash_duration)).timeout
	if local_flash_id != aws_flash_id:
		return
	aws_indicator_material.albedo_color = aws_indicator_base_albedo
	aws_indicator_material.emission = aws_indicator_base_emission
