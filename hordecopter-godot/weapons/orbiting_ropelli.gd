extends Node3D

@export var rotation_speed: float = 10.0 # radians per second

func _process(delta: float) -> void:
	rotate_y(rotation_speed * delta)
