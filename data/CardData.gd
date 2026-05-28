extends Resource
class_name CardData

enum CardType {
	ATTACK,
	SKILL,
	POWER,
}

enum Rarity {
	COMMON,
	UNCOMMON,
	RARE,
}

enum TargetType {
	ENEMY,
	SELF,
	ALL_ENEMIES,
	NONE,
}

enum DeckCategory {
	BASIC,
	SPECIAL,
	CURSE,
}

@export var card_id: String = ""
@export var card_name: String = "Card"
@export var name_key: String = ""
@export var cost: int = 1
@export_multiline var description: String = ""
@export var description_key: String = ""
@export var card_type: CardType = CardType.ATTACK
@export var rarity: Rarity = Rarity.COMMON
@export var target_type: TargetType = TargetType.ENEMY
@export var art: Texture2D
@export var is_special := false
@export var deck_category: DeckCategory = DeckCategory.BASIC
var upgraded := false

# Effects are resolved in order by BattleScene. Add new effect resources here
# instead of adding one-off logic to individual cards.
@export var effects: Array[CardEffect] = []

const FALLBACK_CARD_ART_PATH := "res://assets/cards/basic/basic_strike.png"
static var fallback_card_art: Texture2D


func get_display_name() -> String:
	if Engine.has_singleton("LanguageManager") or LanguageManager != null:
		return LanguageManager.get_card_name(card_id, upgraded, card_name)
	return card_name


func get_display_description() -> String:
	if Engine.has_singleton("LanguageManager") or LanguageManager != null:
		return LanguageManager.get_card_description(card_id, upgraded, description)
	return description


func get_art_texture() -> Texture2D:
	if art != null:
		return art

	push_warning("[CardArt] Missing art for %s" % card_id)
	if fallback_card_art == null and ResourceLoader.exists(FALLBACK_CARD_ART_PATH):
		fallback_card_art = load(FALLBACK_CARD_ART_PATH) as Texture2D
	return fallback_card_art
