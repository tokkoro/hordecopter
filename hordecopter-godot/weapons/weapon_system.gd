###############################################################
# weapons/weapon_system.gd
# Key Classes      • WeaponSystem – runtime firing logic
# Key Functions    • try_fire() – cooldown gate + dispatch
# Critical Consts  • n/a
# Editor Exports   • weapon: WeaponDefinition – data source
# Dependencies     • weapons/weapon_definition.gd
# Last Major Rev   • 25-09-20 – initial weapon system
###############################################################

class_name WeaponSystem
extends Node3D

const WEAPON_SYSTEM_LASER_SFX: AudioStream = preload("res://sfx/laser.sfxr")
const WEAPON_SYSTEM_MISSILE_SFX: AudioStream = preload("res://sfx/missile_shoot.sfxr")

@export var weapon: WeaponDefinition
@export var muzzle_path: NodePath = NodePath("../Muzzle")

var is_ready: bool = false
var is_active: bool = false

var _muzzle: Node3D
var _next_fire_time: float = 0.0


func _ready() -> void:
	if is_ready:
		return
	if weapon != null:
		_next_fire_time = weapon.cooldown
	if muzzle_path != NodePath():
		_muzzle = get_node(muzzle_path) as Node3D
	else:
		_muzzle = self
	is_ready = true


func activate() -> void:
	print("activate weapon")
	if is_active:
		push_warning("Reactivating active weapon 😱")
	is_active = true
	if not is_ready:
		push_warning("Activating weapon that is not ready! 😱😱")
	if weapon != null:
		_next_fire_time = weapon.cooldown


func _physics_process(_delta: float) -> void:
	if weapon == null or not is_active:
		return
	try_fire()


func try_fire() -> void:
	var now := Time.get_ticks_msec() / 1000.0
	if now < _next_fire_time:
		return
	_next_fire_time = now + weapon.cooldown
	match weapon.fire_mode:
		WeaponDefinition.FireMode.HITSCAN:
			_fire_hitscan()
		WeaponDefinition.FireMode.PROJECTILE:
			_fire_projectile()


func _fire_hitscan() -> void:
	if _muzzle == null:
		return
	_play_sfx_at(WEAPON_SYSTEM_LASER_SFX, _muzzle.global_position)
	var start := _muzzle.global_position
	var direction := -_muzzle.global_transform.basis.z
	var beam: Node = null
	if weapon.beam_scene != null:
		beam = weapon.beam_scene.instantiate()
		get_tree().current_scene.add_child(beam)
		if beam.has_method("configure_sweep"):
			beam.configure_sweep(
				start,
				direction,
				weapon.range,
				weapon.damage,
				weapon.knockback,
				weapon.beam_color,
				weapon.beam_width,
				get_parent()
			)
			return
	var end := start + direction * weapon.range
	var space := get_world_3d().direct_space_state
	var query := PhysicsRayQueryParameters3D.create(start, end)
	query.exclude = [get_parent()]
	var result := space.intersect_ray(query)
	var hit_point := end
	if result:
		hit_point = result.position
		var collider: Object = null
		if result.has("collider"):
			collider = result.collider
		if collider != null and collider.has_method("apply_damage"):
			collider.apply_damage(weapon.damage, weapon.knockback, start)
	if beam != null and beam.has_method("configure"):
		beam.configure(start, hit_point, weapon.beam_color, weapon.beam_width)


func _fire_projectile() -> void:
	if _muzzle == null:
		return
	if weapon.projectile_scene == null:
		push_warning("Projectile weapon should have projectile_scene!")
		return
	_play_projectile_sfx()

	var projectile_count: int = int(max(1, weapon.projectile_count))
	var base_direction := -_muzzle.global_transform.basis.z
	var base_up := _muzzle.global_transform.basis.y
	var spread_step_degrees := 15.0
	var spread_start := -0.5 * float(projectile_count - 1) * spread_step_degrees
	for index in range(projectile_count):
		var projectile := weapon.projectile_scene.instantiate()
		get_tree().current_scene.add_child(projectile)
		projectile.global_transform = _muzzle.global_transform
		_apply_projectile_item_bonuses(projectile)
		if projectile.has_method("configure"):
			var spread_angle := spread_start + float(index) * spread_step_degrees
			var direction := base_direction.rotated(base_up, deg_to_rad(spread_angle))
			projectile.configure(weapon, direction)


func _play_projectile_sfx() -> void:
	if weapon == null or weapon.projectile_scene == null:
		return
	var projectile_path := weapon.projectile_scene.resource_path
	if projectile_path == "":
		return
	if projectile_path.ends_with("homing_missile.tscn"):
		_play_sfx_at(WEAPON_SYSTEM_MISSILE_SFX, _muzzle.global_position)


func _apply_projectile_item_bonuses(projectile: Node) -> void:
	if projectile == null:
		return
	var speed_bonus := _get_player_item_bonus(ItemDefinition.ItemType.PROJECTILE_SPEED)
	var size_bonus := _get_player_item_bonus(ItemDefinition.ItemType.AREA_SIZE)
	if projectile.has_method("apply_projectile_speed_bonus"):
		projectile.apply_projectile_speed_bonus(speed_bonus)
	if projectile.has_method("apply_projectile_size_bonus"):
		projectile.apply_projectile_size_bonus(size_bonus)


func _get_player_item_bonus(item_type: ItemDefinition.ItemType) -> float:
	var player := get_tree().get_first_node_in_group("player")
	if player != null and player.has_method("get_item_bonus"):
		return player.get_item_bonus(item_type)
	return 0.0


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
