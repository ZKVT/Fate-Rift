extends Node
class_name DeckManager

signal piles_changed(draw_count: int, discard_count: int)
signal draw_failed_empty

var full_deck: Array[CardData] = []
var draw_pile: Array[CardData] = []
var discard_pile: Array[CardData] = []
var exhaust_pile: Array[CardData] = []

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

const MAX_SPECIAL_CARDS_IN_DECK := 4
const MAX_BASIC_CARDS_IN_DECK := 16


func create_starter_deck() -> void:
	full_deck.clear()
	draw_pile.clear()
	discard_pile.clear()
	exhaust_pile.clear()

	if RunManager.has_current_deck():
		full_deck.append_array(RunManager.current_deck)
		draw_pile.append_array(RunManager.current_deck)
		shuffle_draw_pile()
		_emit_piles_changed()
		return

	var basic_paths := BASIC_CARD_PATHS.duplicate()
	basic_paths.shuffle()
	for index in range(min(basic_paths.size(), MAX_BASIC_CARDS_IN_DECK)):
		var card := load(basic_paths[index]) as CardData
		if card != null:
			draw_pile.append(card)

	var special_paths := SPECIAL_CARD_PATHS.duplicate()
	special_paths.shuffle()
	for index in range(min(special_paths.size(), MAX_SPECIAL_CARDS_IN_DECK)):
		var card := load(special_paths[index]) as CardData
		if card != null:
			draw_pile.append(card)

	full_deck.append_array(draw_pile)
	shuffle_draw_pile()
	_emit_piles_changed()


# Allows callers to inject an explicit starting deck without changing draw logic.
func set_starting_deck(cards: Array[CardData]) -> void:
	full_deck.clear()
	draw_pile.clear()
	discard_pile.clear()
	exhaust_pile.clear()
	full_deck.append_array(cards)
	draw_pile.append_array(cards)
	shuffle_draw_pile()
	_emit_piles_changed()


func shuffle_draw_pile() -> void:
	draw_pile.shuffle()
	if not draw_pile.is_empty():
		AudioManager.play_sfx("shuffle")


func draw_cards(amount: int) -> Array[CardData]:
	var drawn_cards: Array[CardData] = []

	for index in range(amount):
		if draw_pile.is_empty():
			_refill_draw_pile_from_discard()

		if draw_pile.is_empty():
			draw_failed_empty.emit()
			break

		drawn_cards.append(draw_pile.pop_back())

	_emit_piles_changed()
	if not drawn_cards.is_empty():
		AudioManager.play_sfx("card_draw")
	return drawn_cards


func discard(card: CardData) -> void:
	if card == null:
		return

	discard_pile.append(card)
	_emit_piles_changed()


func discard_many(cards: Array[CardData]) -> void:
	for card in cards:
		discard(card)


func exhaust(card: CardData) -> void:
	if card == null:
		return

	exhaust_pile.append(card)
	_emit_piles_changed()


func take_random_from_discard() -> CardData:
	if discard_pile.is_empty():
		return null

	var index := randi_range(0, discard_pile.size() - 1)
	return discard_pile.pop_at(index)


func total_available_cards_count() -> int:
	return draw_pile.size() + discard_pile.size()


func is_deck_empty() -> bool:
	return draw_pile.is_empty() and discard_pile.is_empty()


func get_random_available_card() -> CardData:
	var candidates: Array[CardData] = []
	candidates.append_array(draw_pile)
	candidates.append_array(discard_pile)
	if candidates.is_empty():
		return null

	return candidates.pick_random()


# Returns a copy of every card that started this battle.
func get_full_deck() -> Array[CardData]:
	return full_deck.duplicate()


# Returns a copy of the current draw pile.
func get_draw_pile() -> Array[CardData]:
	return draw_pile.duplicate()


# Returns a copy of the current discard pile.
func get_discard_pile() -> Array[CardData]:
	return discard_pile.duplicate()


# Returns a copy of the current exhaust pile.
func get_exhaust_pile() -> Array[CardData]:
	return exhaust_pile.duplicate()


func _refill_draw_pile_from_discard() -> void:
	if discard_pile.is_empty():
		return

	draw_pile.clear()
	draw_pile.append_array(discard_pile)
	discard_pile.clear()
	shuffle_draw_pile()


func _emit_piles_changed() -> void:
	piles_changed.emit(draw_pile.size(), discard_pile.size())
