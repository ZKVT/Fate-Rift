extends Resource
class_name RelicData

enum TriggerTiming {
	BATTLE_START,
	PLAYER_TURN_START,
	CARD_PLAYED,
	PLAYER_DAMAGED,
	BATTLE_WON,
}

enum RelicEffect {
	EXTRA_BATTLE_START_DRAW,
	EXTRA_TURN_ENERGY,
	THORNS,
	EXTRA_REWARD_CARDS,
	ATTACK_DAMAGE_BONUS,
	BATTLE_START_BLOCK,
	BATTLE_START_BURN,
	FIRST_TURN_DRAW,
}

@export var relic_id: String = ""
@export var relic_name: String = "Relic"
@export var name_key: String = ""
@export_multiline var description: String = ""
@export var description_key: String = ""
@export var icon: Texture2D
@export var icon_path: String = ""
@export var rarity: String = "Common"
@export var trigger_timing: TriggerTiming = TriggerTiming.BATTLE_START
@export var effect: RelicEffect = RelicEffect.EXTRA_BATTLE_START_DRAW
@export var value := 0


func get_display_name() -> String:
	if Engine.has_singleton("LanguageManager") or LanguageManager != null:
		return LanguageManager.get_relic_name(relic_id, relic_name)
	return relic_name


func get_display_description() -> String:
	if Engine.has_singleton("LanguageManager") or LanguageManager != null:
		return LanguageManager.get_relic_description(relic_id, description)
	return description
