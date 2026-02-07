###############################################################
# enemies/enemy_experience_manager.gd
# Key Classes      • EnemyExperienceManager – shared XP scaling helper
# Key Functions    • calculate_experience_from_health() – scale XP by health
# Critical Consts  • n/a
# Editor Exports   • n/a
# Dependencies     • n/a
# Last Major Rev   • 25-09-27 – centralize enemy XP scaling
###############################################################

class_name EnemyExperienceManager
extends Node


static func calculate_experience_from_health(
	base_experience_reward: int, current_health: float, base_health: float
) -> int:
	var enemy_experience_manager_safe_base_health: float = max(1.0, base_health)
	var enemy_experience_manager_health_ratio: float = (
		current_health / enemy_experience_manager_safe_base_health
	)
	var enemy_experience_manager_scaled_experience: float = (
		float(base_experience_reward) * enemy_experience_manager_health_ratio
	)
	return max(1, int(round(enemy_experience_manager_scaled_experience)))
