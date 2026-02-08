###############################################################
# weapons/weapon_definition.gd
# Key Classes      • WeaponDefinition – data for a single weapon
# Key Functions    • n/a
# Critical Consts  • n/a
# Editor Exports   • weapon_name: String – display label
#                 • icon: Texture2D – HUD icon
#                 • area_radius: float – radius for area weapons
#                 • projectile_count: int – number of projectiles per shot
#                 • projectile_count_level_step: int – extra projectiles per step
#                 • projectile_count_level_interval: int – levels per step
#                 • knockback: float – base knockback force
#                 • knockback_per_level: float – knockback gained per level
# Dependencies     • n/a
# Last Major Rev   • 25-09-27 – add projectile count scaling fields
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
@export var knockback: float = 0.0
@export var knockback_per_level: float = 0.0
@export var range: float = 50.0
@export var area_radius: float = 6.0
@export var projectile_count: int = 1
@export var projectile_count_level_step: int = 0
@export var projectile_count_level_interval: int = 1
@export var projectile_scene: PackedScene
@export var beam_scene: PackedScene
@export var beam_color: Color = Color(1.0, 0.2, 0.2, 1.0)
@export var beam_width: float = 0.05
