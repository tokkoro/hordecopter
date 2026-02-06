class_name WeaponSystem
extends Node3D

@export var weapon: WeaponDefinition
@export var muzzle_path: NodePath = NodePath("../Muzzle")

var _muzzle: Node3D
var _next_fire_time: float = 0.0


func _ready() -> void:
	if muzzle_path != NodePath():
		_muzzle = get_node(muzzle_path) as Node3D
	else:
		_muzzle = self


func _physics_process(_delta: float) -> void:
	if weapon == null:
		return
	if Input.is_action_pressed("p1_shoot"):
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
	var start := _muzzle.global_position
	var direction := -_muzzle.global_transform.basis.z
	var end := start + direction * weapon.range
	var space := get_world_3d().direct_space_state
	var query := PhysicsRayQueryParameters3D.create(start, end)
	query.exclude = [get_parent()]
	var result := space.intersect_ray(query)
	var hit_point := end
	if result:
		hit_point = result.position
		var collider := result.collider
		if collider != null and collider.has_method("apply_damage"):
			collider.apply_damage(weapon.damage)
	if weapon.beam_scene != null:
		var beam := weapon.beam_scene.instantiate()
		get_tree().current_scene.add_child(beam)
		if beam.has_method("configure"):
			beam.configure(start, hit_point, weapon.beam_color, weapon.beam_width)


func _fire_projectile() -> void:
	if _muzzle == null:
		return
	if weapon.projectile_scene == null:
		return
	var projectile := weapon.projectile_scene.instantiate()
	get_tree().current_scene.add_child(projectile)
	projectile.global_transform = _muzzle.global_transform
	if projectile.has_method("configure"):
		var direction := -_muzzle.global_transform.basis.z
		projectile.configure(weapon, direction)
