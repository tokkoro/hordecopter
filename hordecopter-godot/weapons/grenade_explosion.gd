###############################################################
# weapons/grenade_explosion.gd
# Key Classes      • GrenadeExplosion – visual blast + damage pulse
# Key Functions    • configure() – seed damage and radius
# Critical Consts  • n/a
# Editor Exports   • explosion_radius: float – Area3D blast radius
# Dependencies     • n/a
# Last Major Rev   • 25-09-20 – initial explosion effect
###############################################################

class_name GrenadeExplosion
extends Area3D

@export var explosion_radius: float = 2.5
@export var explosion_damage: float = 10.0
@export var expansion_time: float = 0.18
@export var linger_time: float = 0.35
@export var explosion_color: Color = Color(1.0, 0.6, 0.2, 0.9)
@export var emission_color: Color = Color(1.0, 0.7, 0.25, 1.0)
@export var emission_energy: float = 2.8

var _explosion_has_damaged: bool = false
@onready var _explosion_mesh: MeshInstance3D = $ExplosionMesh
@onready var _explosion_collision: CollisionShape3D = $CollisionShape3D


func configure(damage: float, radius: float) -> void:
	explosion_damage = damage
	explosion_radius = radius


func _ready() -> void:
	monitoring = true
	monitorable = true
	_apply_radius()
	_prepare_material()
	_play_burst()
	call_deferred("_apply_damage")
	var timer := get_tree().create_timer(expansion_time + linger_time)
	timer.timeout.connect(queue_free)


func _apply_radius() -> void:
	if _explosion_collision.shape is SphereShape3D:
		var sphere := _explosion_collision.shape as SphereShape3D
		sphere.radius = explosion_radius
	_explosion_mesh.scale = Vector3.ONE * max(0.1, explosion_radius * 2.0)


func _prepare_material() -> void:
	if _explosion_mesh.material_override == null:
		return
	var material := _explosion_mesh.material_override.duplicate()
	_explosion_mesh.material_override = material
	if material is StandardMaterial3D:
		var standard := material as StandardMaterial3D
		standard.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		standard.albedo_color = explosion_color
		standard.emission = emission_color
		standard.emission_energy = emission_energy


func _play_burst() -> void:
	_explosion_mesh.scale = Vector3.ONE * 0.1
	var target_scale: Vector3 = Vector3.ONE * max(0.2, explosion_radius * 2.0)
	var tween := create_tween()
	var scale_tween := tween.tween_property(_explosion_mesh, "scale", target_scale, expansion_time)
	scale_tween.set_trans(Tween.TRANS_BACK)
	scale_tween.set_ease(Tween.EASE_OUT)
	if _explosion_mesh.material_override is StandardMaterial3D:
		var standard := _explosion_mesh.material_override as StandardMaterial3D
		var fade_color := standard.albedo_color
		fade_color.a = 0.0
		var fade_tween := tween.tween_property(standard, "albedo_color", fade_color, linger_time)
		fade_tween.set_trans(Tween.TRANS_SINE)
		fade_tween.set_ease(Tween.EASE_IN)


func _apply_damage() -> void:
	if _explosion_has_damaged:
		return
	_explosion_has_damaged = true
	var bodies := get_overlapping_bodies()
	for body in bodies:
		if body is Node3D:
			var node := body as Node3D
			var distance := global_position.distance_to(node.global_position)
			if distance <= explosion_radius and node.has_method("apply_damage"):
				node.apply_damage(explosion_damage)
