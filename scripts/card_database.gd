extends Node

const BASIC_CARD_PATHS: Array[String] = [
	"res://data/cards/basic/strike.tres",
	"res://data/cards/basic/heavy_blow.tres",
	"res://data/cards/basic/combo_strike.tres",
	"res://data/cards/basic/flame_slash.tres",
	"res://data/cards/basic/armor_break.tres",
	"res://data/cards/basic/guard.tres",
	"res://data/cards/basic/hold_fast.tres",
	"res://data/cards/basic/nimble_defense.tres",
	"res://data/cards/basic/counter_stance.tres",
	"res://data/cards/basic/iron_wall.tres",
	"res://data/cards/basic/charge.tres",
	"res://data/cards/basic/insight.tres",
	"res://data/cards/basic/tactical_shift.tres",
	"res://data/cards/basic/burning_mark.tres",
	"res://data/cards/basic/weaken.tres",
	"res://data/cards/basic/grace.tres",
	"res://data/cards/basic/restore.tres",
	"res://data/cards/basic/quick_cut.tres",
	"res://data/cards/basic/dual_cut.tres",
	"res://data/cards/basic/guarded_strike.tres",
	"res://data/cards/basic/guard_up.tres",
	"res://data/cards/basic/battle_focus.tres",
	"res://data/cards/basic/prepare.tres",
	"res://data/cards/basic/cleanse.tres",
	"res://data/cards/basic/warm_blood.tres",
	"res://data/cards/basic/suppress.tres",
	"res://data/cards/basic/kindling.tres",
	"res://data/cards/basic/flame_guard.tres",
	"res://data/cards/basic/soul_spark.tres",
	"res://data/cards/basic/burning_edge.tres",
	"res://data/cards/basic/cinder_strike.tres",
	"res://data/cards/basic/execution.tres",
	"res://data/cards/basic/last_stand.tres",
	"res://data/cards/basic/steady_guard.tres",
]

const SPECIAL_CARD_PATHS: Array[String] = [
	"res://data/cards/special/00_the_fool.tres",
	"res://data/cards/special/01_the_magician.tres",
	"res://data/cards/special/02_the_high_priestess.tres",
	"res://data/cards/special/03_the_empress.tres",
	"res://data/cards/special/04_the_emperor.tres",
	"res://data/cards/special/05_the_hierophant.tres",
	"res://data/cards/special/06_the_lovers.tres",
	"res://data/cards/special/07_the_chariot.tres",
	"res://data/cards/special/08_strength.tres",
	"res://data/cards/special/09_the_hermit.tres",
	"res://data/cards/special/10_wheel_of_fortune.tres",
	"res://data/cards/special/11_justice.tres",
	"res://data/cards/special/12_the_hanged_man.tres",
	"res://data/cards/special/13_death.tres",
	"res://data/cards/special/14_temperance.tres",
	"res://data/cards/special/15_the_devil.tres",
	"res://data/cards/special/16_the_tower.tres",
	"res://data/cards/special/17_the_star.tres",
	"res://data/cards/special/18_the_moon.tres",
	"res://data/cards/special/19_the_sun.tres",
	"res://data/cards/special/20_judgement.tres",
	"res://data/cards/special/21_the_world.tres",
]

const CURSE_CARD_PATHS: Array[String] = [
	"res://data/cards/curse/fate_mark.tres",
]

var cards_by_id: Dictionary = {}


func _ready() -> void:
	load_all_cards()


# Loads all known card resources into a card_id lookup table.
func load_all_cards() -> void:
	cards_by_id.clear()
	for path in BASIC_CARD_PATHS:
		_register_card(path, CardData.DeckCategory.BASIC)
	for path in SPECIAL_CARD_PATHS:
		_register_card(path, CardData.DeckCategory.SPECIAL)
	for path in CURSE_CARD_PATHS:
		_register_card(path, CardData.DeckCategory.CURSE)


# Returns a CardData resource by card_id, or null if the id is unknown.
func get_card(card_id: String) -> CardData:
	return cards_by_id.get(card_id)


# Returns the cards owned by the player collection, in stable display order.
func get_owned_cards(collection: Dictionary) -> Array[CardData]:
	var cards: Array[CardData] = []
	for path in BASIC_CARD_PATHS + SPECIAL_CARD_PATHS + CURSE_CARD_PATHS:
		var card := load(path) as CardData
		if card != null and collection.get(card.card_id, 0) > 0:
			cards.append(card)
	return cards


# Returns every loaded card in stable database order.
func get_all_cards() -> Array[CardData]:
	var cards: Array[CardData] = []
	for path in BASIC_CARD_PATHS + SPECIAL_CARD_PATHS + CURSE_CARD_PATHS:
		var card := load(path) as CardData
		if card != null:
			cards.append(card)
	return cards


# Returns all basic cards that can appear in the shop.
func get_basic_cards() -> Array[CardData]:
	var cards: Array[CardData] = []
	for path in BASIC_CARD_PATHS:
		var card := load(path) as CardData
		if card != null:
			cards.append(card)
	return cards


# Returns all special cards that can appear in the shop.
func get_special_cards() -> Array[CardData]:
	var cards: Array[CardData] = []
	for path in SPECIAL_CARD_PATHS:
		var card := load(path) as CardData
		if card != null:
			cards.append(card)
	return cards


func _register_card(path: String, category: CardData.DeckCategory) -> void:
	var card := load(path) as CardData
	if card == null:
		return

	card.deck_category = category
	card.is_special = category == CardData.DeckCategory.SPECIAL
	cards_by_id[card.card_id] = card
