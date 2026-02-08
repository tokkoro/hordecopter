###############################################################
# hordecopter.gd
# Key Classes      • Hordecopter – player controller
# Key Functions    • _configure_weapon_systems() – random starter weapon
# Critical Consts  • n/a
# Editor Exports   • auto_float: bool – hover assist toggle
# Dependencies     • weapons/weapon_system.gd
# Last Major Rev   • 25-09-20 – weapon activation toggle remove
###############################################################

class_name Hordecopter
extends RigidBody3D

const HC_WEAPON_DAMAGE_STEP: float = 0.25
const HC_WEAPON_COOLDOWN_MULTIPLIER: float = 0.92
const HC_MAX_UNLOCKED_WEAPONS: int = 6

@export var auto_float: bool = true
@export var my_camera_name: StringName = &"Camera3D"
@export var auto_float_power_max: float = 2000.0
@export var rotor_swosh_sound: AudioStream = preload("res://sfx/rotor_blade_swosh.sfxr")
@export var rotor_swosh_interval: float = 0.6
@export var rotor_swosh_speed_threshold: float = 2.0
@export var player_hit_sound: AudioStream = preload("res://sfx/player_hit.sfxr")
# PID multipliers
@export var kp: float = 25.0
@export var ki: float = 2.0
@export var kd: float = 12.0
@export var d_filter_hz: float = -1.0
@export var rotation_speed: float = 50.0

var my_camera: Camera3D
var auto_float_target_altitude: float = 0.5
var show_info: bool = false
var upward_power: float = 100_000.0
var sideward_power: float = 100_000.0
var forward_power: float = 100_000.0
var max_y_speed: float = 10.0
var max_x_speed: float = 10.0
var max_z_speed: float = 10.0

var hc_weapon_systems_is_initialized = false
var hc_weapon_systems: Array[WeaponSystem] = []
var hc_weapon_system_names: Array[StringName] = [
	&"WeaponSystem",
	&"MissileWeaponSystem",
	&"GrenadeWeaponSystem",
	&"PlasmaWeaponSystem",
	&"AreaWeaponSystem",
	&"OrbitingWeaponSystem"
]

var hc_weapon_levels: Array[int] = []
var hc_weapon_base_damage: Array[float] = []
var hc_weapon_base_cooldown: Array[float] = []
var hc_weapon_base_knockback: Array[float] = []
var hc_weapon_base_projectile_count: Array[int] = []
var hc_rotor_swosh_timer: float = 0.0
var _i: float = 0.0
var _prev_error: float = 0.0
var _d_state: float = 0.0
@onready var propellit: Node = get_node("rollaus_pivot_piste")
@onready var infotext: Label3D = get_node("infotext")


func _ready() -> void:
	add_to_group("player")
	my_camera = _find_node_by_name(get_tree().current_scene, my_camera_name)
	if my_camera == null:
		push_error("Missä on mun kamera? %s" % [my_camera_name])
		return
	_ensure_orbiting_weapon_system()
	# _configure_weapon_systems()


func _physics_process(delta: float) -> void:
	if not hc_weapon_systems_is_initialized:
		_configure_weapon_systems()
		hc_weapon_systems_is_initialized = true
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
	_update_rotor_swosh(delta)

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


func apply_damage(amount: float) -> void:
	if amount <= 0.0:
		return
	_play_sfx_at(player_hit_sound, global_position)


func _update_rotor_swosh(delta: float) -> void:
	hc_rotor_swosh_timer = max(0.0, hc_rotor_swosh_timer - delta)
	if rotor_swosh_sound == null:
		return
	if linear_velocity.length() < rotor_swosh_speed_threshold:
		return
	if hc_rotor_swosh_timer > 0.0:
		return
	hc_rotor_swosh_timer = max(0.1, rotor_swosh_interval)
	_play_sfx_at(rotor_swosh_sound, global_position)


func _play_sfx_at(stream: AudioStream, position: Vector3) -> void:
	if stream == null:
		return
	var current_scene := get_tree().current_scene
	if current_scene == null:
		return
	var player := AudioStreamPlayer3D.new()
	current_scene.add_child(player)
	player.stream = stream
	player.global_position = position
	player.finished.connect(player.queue_free)
	player.play()


func _find_node_by_name(root: Node, name: StringName) -> Node3D:
	if root.name == name and root is Node3D:
		return root as Node3D
	for child in root.get_children():
		var found := _find_node_by_name(child, name)
		if found != null:
			return found
	return null


func _collect_weapon_systems() -> Array[WeaponSystem]:
	var systems: Array[WeaponSystem] = []
	for system_name in hc_weapon_system_names:
		var system := get_node_or_null(NodePath(system_name)) as WeaponSystem
		if system != null:
			systems.append(system)
	return systems


func _ensure_orbiting_weapon_system() -> void:
	var existing := get_node_or_null(NodePath("OrbitingWeaponSystem")) as WeaponSystem
	if existing != null:
		return
	var orbiting_system := OrbitingHelicopterWeaponSystem.new()
	orbiting_system.name = "OrbitingWeaponSystem"
	add_child(orbiting_system)


func _configure_weapon_systems() -> void:
	hc_weapon_systems = _collect_weapon_systems()
	if hc_weapon_systems.is_empty():
		push_warning("Didn't find any weapon systems")
		return
	hc_weapon_levels.clear()
	hc_weapon_base_damage.clear()
	hc_weapon_base_cooldown.clear()
	hc_weapon_base_knockback.clear()
	hc_weapon_base_projectile_count.clear()
	for system in hc_weapon_systems:
		if not system.is_ready:
			push_warning("Weapon was not ready to be configured!")
		hc_weapon_levels.append(0)
		if system.weapon != null:
			hc_weapon_base_damage.append(system.weapon.damage)
			hc_weapon_base_cooldown.append(system.weapon.cooldown)
			hc_weapon_base_knockback.append(system.weapon.knockback)
			hc_weapon_base_projectile_count.append(system.weapon.projectile_count)
		else:
			hc_weapon_base_damage.append(0.0)
			hc_weapon_base_cooldown.append(0.0)
			hc_weapon_base_knockback.append(0.0)
			hc_weapon_base_projectile_count.append(1)
	# TODO: level up at a start of give certain weapon?
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	var index := rng.randi_range(0, hc_weapon_systems.size() - 1)
	_unlock_weapon_system(index, true)
	_update_weapon_hud()


func get_level_up_options(count: int) -> Array[Dictionary]:
	var options: Array[Dictionary] = []
	if hc_weapon_systems.is_empty():
		return options
	var indices: Array[int] = []
	for index in range(hc_weapon_systems.size()):
		indices.append(index)
	indices.shuffle()
	var unlocked_count := _get_unlocked_weapon_count()
	var option_count: int = int(min(count, indices.size()))
	for option_index in range(option_count):
		var system_index := indices[option_index]
		var system := hc_weapon_systems[system_index]
		var weapon_name := "Weapon"
		var icon: Texture2D = null
		if system != null and system.weapon != null and system.weapon.weapon_name != "":
			weapon_name = system.weapon.weapon_name
		elif system != null:
			weapon_name = system.name
		if system != null and system.weapon != null:
			icon = system.weapon.icon
		var current_level := hc_weapon_levels[system_index]
		var label: String
		if current_level <= 0:
			if unlocked_count >= HC_MAX_UNLOCKED_WEAPONS:
				continue
			label = "Unlock %s" % weapon_name
		else:
			label = "Upgrade %s (Lv %d → %d)" % [weapon_name, current_level, current_level + 1]
		options.append({"index": system_index, "label": label, "icon": icon})
	return options


func apply_level_up_choice(choice: Dictionary) -> void:
	print("apply_level_up_choice")
	if not choice.has("index"):
		push_warning("Invalid level up choice: %s" % JSON.stringify(choice))
		return
	var system_index := int(choice["index"])
	if system_index < 0 or system_index >= hc_weapon_systems.size():
		return
	if (
		hc_weapon_levels[system_index] <= 0
		and _get_unlocked_weapon_count() >= HC_MAX_UNLOCKED_WEAPONS
	):
		push_warning("Weapon slots full; cannot unlock more weapons.")
		return
	hc_weapon_levels[system_index] += 1
	var level := _apply_weapon_level(system_index)
	if level == 1:
		_unlock_weapon_system(system_index, true)
	_update_weapon_hud()


func _unlock_weapon_system(index: int, make_active: bool) -> void:
	print("_unlock_weapon_system")
	if index < 0 or index >= hc_weapon_systems.size():
		push_warning("Trying to activate out of range weapon!")
		return
	if hc_weapon_levels[index] <= 0:
		hc_weapon_levels[index] = 1
		_apply_weapon_level(index)
	if make_active:
		hc_weapon_systems[index].activate()
	_update_weapon_hud()


func _apply_weapon_level(index: int) -> int:
	if index < 0 or index >= hc_weapon_systems.size():
		push_warning("Trying to _apply_weapon_level out of range weapon!")
		return 0
	var system := hc_weapon_systems[index]
	if system == null or system.weapon == null:
		push_warning("Trying to _apply_weapon_level for missing weapon!")
		return 0
	var base_damage := hc_weapon_base_damage[index]
	var base_cooldown := hc_weapon_base_cooldown[index]
	var base_knockback := hc_weapon_base_knockback[index]
	var base_projectile_count := hc_weapon_base_projectile_count[index]
	var level: int = int(max(1, hc_weapon_levels[index]))
	system.weapon.damage = base_damage * (1.0 + HC_WEAPON_DAMAGE_STEP * float(level - 1))
	system.weapon.knockback = base_knockback + system.weapon.knockback_per_level * float(level - 1)
	var cooldown_multiplier := pow(HC_WEAPON_COOLDOWN_MULTIPLIER, float(level - 1))
	system.weapon.cooldown = max(0.05, base_cooldown * cooldown_multiplier)
	var interval: int = int(max(1, system.weapon.projectile_count_level_interval))
	var steps := int(floor(float(level - 1) / float(interval)))
	system.weapon.projectile_count = max(
		1, base_projectile_count + steps * system.weapon.projectile_count_level_step
	)
	return level


func _get_unlocked_weapon_count() -> int:
	var unlocked_count := 0
	for level in hc_weapon_levels:
		if level > 0:
			unlocked_count += 1
	return unlocked_count


func _update_weapon_hud() -> void:
	var hud := get_tree().get_first_node_in_group("hud")
	if hud == null or not hud.has_method("update_weapon_slots"):
		return
	var weapon_data: Array[Dictionary] = []
	var slot_count := int(min(hc_weapon_systems.size(), HC_MAX_UNLOCKED_WEAPONS))
	for index in range(slot_count):
		var system := hc_weapon_systems[index]
		var icon: Texture2D = null
		var level := 0
		if system != null and system.weapon != null:
			icon = system.weapon.icon
			level = hc_weapon_levels[index]
		weapon_data.append({"icon": icon, "level": level})
	hud.update_weapon_slots(weapon_data)


func _is_weapon_locked(index: int) -> bool:
	if index < 0 or index >= hc_weapon_levels.size():
		return true
	return hc_weapon_levels[index] <= 0


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
