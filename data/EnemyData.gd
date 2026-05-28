extends Resource
class_name EnemyData

enum EnemyType {
	NORMAL,
	ELITE,
	BOSS,
}

@export var enemy_id := ""
@export var enemy_name := "Enemy"
@export var enemy_name_key := ""
@export var chapter := 1
@export var enemy_type: EnemyType = EnemyType.NORMAL
@export var max_health := 30
@export var portrait_path := ""
@export var enemy_art: Texture2D
@export var actions: Array[EnemyAction] = []
@export_multiline var description := ""
@export var description_key := ""
@export var is_boss := false
@export var lost_health_step_size := 20
@export var damage_bonus_per_step := 0
@export_range(0.0, 1.0, 0.05) var low_health_threshold := 0.5
@export var low_health_damage_bonus := 0


func get_display_name() -> String:
	if Engine.has_singleton("LanguageManager") or LanguageManager != null:
		return LanguageManager.get_enemy_name(enemy_id, enemy_name)
	return enemy_name
