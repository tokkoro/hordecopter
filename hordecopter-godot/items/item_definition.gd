###############################################################
# items/item_definition.gd
# Key Classes      • ItemDefinition – passive stat upgrade data
# Key Functions    • n/a
# Critical Consts  • n/a
# Editor Exports   • item_name: String – display label
#                 • icon: Texture2D – HUD icon
# Dependencies     • n/a
# Last Major Rev   • 25-09-29 – initial passive item data
###############################################################

class_name ItemDefinition
extends Resource

enum ItemType {
	DAMAGE,
	MOVE_SPEED,
	AREA_SIZE,
	ATTACK_SPEED,
	PROJECTILE_SPEED,
}

@export var item_name: String = "Item"
@export var icon: Texture2D
@export var item_type: ItemType = ItemType.DAMAGE
@export var bonus_per_level: float = 1.0
@export var max_level: int = 5
