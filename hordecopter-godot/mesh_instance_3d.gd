extends MeshInstance3D

var start_c: Color

func _ready():
	start_c = material_override.albedo_color
	material_override = material_override.duplicate()


func _process(delta):
		var material := material_override
		var next_color := start_c
		next_color.a = abs(sin(Time.get_ticks_msec() / 1000))
		material.albedo_color = next_color
