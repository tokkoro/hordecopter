###############################################################
# enemies/test_enemy.gd
# Key Classes      • TestEnemy – wandering target dummy
# Key Functions    • apply_damage() – reduce health and despawn
#                 • _pick_wander_direction() – choose a new wander heading
# Critical Consts  • n/a
# Editor Exports   • health: float – hit points
# Dependencies     • n/a
# Last Major Rev   • 25-09-26 – add wandering movement
###############################################################

class_name TestEnemy
extends CharacterBody3D

@export var health: float = 12.0
@export var test_enemy_wander_speed: float = 2.5
@export var test_enemy_wander_interval: float = 1.5

var test_enemy_wander_direction: Vector3 = Vector3.ZERO
var test_enemy_wander_elapsed: float = 0.0
var test_enemy_rng: RandomNumberGenerator = RandomNumberGenerator.new()


func _ready() -> void:
	add_to_group("enemies")
	test_enemy_rng.randomize()
	_pick_wander_direction()


func _physics_process(delta: float) -> void:
	test_enemy_wander_elapsed += delta
	if test_enemy_wander_elapsed >= test_enemy_wander_interval:
		test_enemy_wander_elapsed = 0.0
		_pick_wander_direction()
	velocity = test_enemy_wander_direction * test_enemy_wander_speed
	move_and_slide()


func _pick_wander_direction() -> void:
	var test_enemy_angle: float = test_enemy_rng.randf_range(0.0, TAU)
	test_enemy_wander_direction = Vector3(cos(test_enemy_angle), 0.0, sin(test_enemy_angle))


func apply_damage(amount: float) -> void:
	health -= amount
	if health <= 0.0:
		queue_free()
