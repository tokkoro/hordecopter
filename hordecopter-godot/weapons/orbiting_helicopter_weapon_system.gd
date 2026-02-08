###############################################################
# weapons/orbiting_helicopter_weapon_system.gd
# Key Classes      • OrbitingHelicopterWeaponSystem – rotating swarm weapon
# Key Functions    • _update_orbit() – spin + pulse radius
#                 • _apply_swarm_damage() – damage enemies in range
# Critical Consts  • n/a
# Editor Exports   • orbit_count: int – number of mini copters
#                 • active_duration: float – on-time before cooldown
# Dependencies     • weapons/weapon_definition.gd
# Last Major Rev   • 25-09-27 – initial orbiting helicopter weapon
###############################################################

class_name OrbitingHelicopterWeaponSystem
extends WeaponSystem

@export var orbiting_object: PackedScene

@export var orbit_count: int = 4
@export var orbit_radius_min: float = 1.5
@export var orbit_radius_max: float = 4.0
@export var orbit_radius_speed: float = 1.2
@export var orbit_rotation_speed: float = 2.0
@export var active_duration: float = 3.0
@export var damage_tick_interval: float = 0.25
@export var damage_radius: float = 1.2

var ohs_helicopters: Array[Node3D] = []
var ohs_active_time: float = 0.0
var ohs_cooldown_time: float = 0.0
var ohs_rotation_phase: float = 0.0
var ohs_radius_phase: float = 0.0
var ohs_damage_time: float = 0.0
var ohs_is_active: bool = false


func _ready() -> void:
	if is_ready:
		return
	super._ready()
	if weapon == null:
		weapon = WeaponDefinition.new()
		weapon.weapon_name = "Orbiting Copters"
		weapon.fire_mode = WeaponDefinition.FireMode.AREA
		weapon.cooldown = 4.0
		weapon.damage = 2.0
		weapon.knockback = 1.2
		weapon.knockback_per_level = 0.3
		weapon.range = orbit_radius_max
	_spawn_copters()
	_set_copters_visible(false)
	ohs_cooldown_time = weapon.cooldown


func _physics_process(delta: float) -> void:
	if not is_active:
		return
	if weapon == null:
		return
	if ohs_is_active:
		ohs_active_time -= delta
		_update_orbit(delta)
		_apply_swarm_damage(delta)
		if ohs_active_time <= 0.0:
			_deactivate_swarm()
	else:
		ohs_cooldown_time -= delta
		if ohs_cooldown_time <= 0.0:
			_activate_swarm()


func _spawn_copters() -> void:
	for copter in ohs_helicopters:
		copter.queue_free()
	ohs_helicopters.clear()

	for index in range(orbit_count):
		var holder := orbiting_object.instantiate()
		holder.name = "OrbitCopter%d" % index
		add_child(holder)
		ohs_helicopters.append(holder)


func _activate_swarm() -> void:
	ohs_is_active = true
	ohs_active_time = maxf(0.1, active_duration)
	ohs_damage_time = 0.0
	_set_copters_visible(true)


func _deactivate_swarm() -> void:
	ohs_is_active = false
	ohs_cooldown_time = maxf(0.1, weapon.cooldown)
	_set_copters_visible(false)


func _set_copters_visible(visible: bool) -> void:
	for copter in ohs_helicopters:
		if copter != null:
			copter.visible = visible


func _update_orbit(delta: float) -> void:
	if ohs_helicopters.is_empty():
		return
	ohs_rotation_phase += orbit_rotation_speed * delta
	ohs_radius_phase += orbit_radius_speed * delta
	var radius := _get_current_radius()
	var step := TAU / float(ohs_helicopters.size())
	for index in range(ohs_helicopters.size()):
		var angle := ohs_rotation_phase + step * float(index)
		var offset := Vector3(cos(angle) * radius, 0.0, sin(angle) * radius)
		var copter := ohs_helicopters[index]
		if copter != null:
			copter.position = offset


func _get_current_radius() -> float:
	if orbit_radius_max <= orbit_radius_min:
		return orbit_radius_min
	var alpha := (sin(ohs_radius_phase) + 1.0) * 0.5
	return lerp(orbit_radius_min, orbit_radius_max, alpha)


func _apply_swarm_damage(delta: float) -> void:
	ohs_damage_time -= delta
	if ohs_damage_time > 0.0:
		return
	ohs_damage_time = maxf(0.05, damage_tick_interval)
	var enemies := get_tree().get_nodes_in_group("enemy_targets")
	if enemies.is_empty():
		return
	for enemy in enemies:
		if enemy is Node3D:
			var enemy_node := enemy as Node3D
			if _is_enemy_in_swarm_range(enemy_node):
				if enemy_node.has_method("apply_damage"):
					var origin := _get_swarm_hit_origin(enemy_node)
					enemy_node.apply_damage(weapon.damage, weapon.knockback, origin)


func _is_enemy_in_swarm_range(enemy_node: Node3D) -> bool:
	var radius: float = maxf(0.1, damage_radius)
	for copter in ohs_helicopters:
		if copter != null:
			if enemy_node.global_position.distance_to(copter.global_position) <= radius:
				return true
	return false


func _get_swarm_hit_origin(enemy_node: Node3D) -> Vector3:
	var closest_position := global_position
	var closest_distance := INF
	for copter in ohs_helicopters:
		if copter != null:
			var distance := enemy_node.global_position.distance_to(copter.global_position)
			if distance < closest_distance:
				closest_distance = distance
				closest_position = copter.global_position
	return closest_position
