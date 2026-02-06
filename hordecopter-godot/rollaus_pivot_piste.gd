extends Node3D

@export var rotation_speed: float = 1.0 # radians per second

func _process(delta: float) -> void:
	rotate_y(rotation_speed * delta)
	
func set_speeds(speed: float) -> void:
	rotation_speed = 2 * speed
