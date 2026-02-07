###############################################################
# weapons/weapon_definition.gd
# Key Classes      • WeaponDefinition – data for a single weapon
# Key Functions    • n/a
# Critical Consts  • n/a
# Editor Exports   • weapon_name: String – display label
#                 • icon: Texture2D – HUD icon
#                 • area_radius: float – radius for area weapons
# Dependencies     • n/a
# Last Major Rev   • 25-09-27 – add area fire mode data
###############################################################

class_name WeaponDefinition
extends Resource

enum FireMode {
	HITSCAN,
	PROJECTILE,
	AREA,
}

@export var weapon_name: String = "Weapon"
@export var icon: Texture2D
@export var fire_mode: FireMode = FireMode.HITSCAN
@export var cooldown: float = 0.2
@export var damage: float = 5.0
@export var range: float = 50.0
@export var area_radius: float = 6.0
@export var projectile_scene: PackedScene
@export var beam_scene: PackedScene
@export var beam_color: Color = Color(1.0, 0.2, 0.2, 1.0)
@export var beam_width: float = 0.05
