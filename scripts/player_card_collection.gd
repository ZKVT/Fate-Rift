extends Node

var player_card_collection: Dictionary = {}


func _ready() -> void:
	load_test_collection()


# Test collection used until a real account/save inventory exists.
func load_test_collection() -> void:
	player_card_collection = {
		"basic_strike": 3,
		"basic_heavy_blow": 3,
		"basic_combo_strike": 3,
		"basic_flame_slash": 3,
		"basic_armor_break": 3,
		"basic_guard": 3,
		"basic_hold_fast": 3,
		"basic_nimble_defense": 3,
		"basic_counter_stance": 3,
		"basic_iron_wall": 3,
		"basic_insight": 3,
		"basic_charge": 3,
		"basic_tactical_shift": 3,
		"basic_burning_mark": 3,
		"basic_weaken": 3,
		"basic_grace": 3,
		"basic_restore": 3,
		"basic_quick_cut": 3,
		"basic_dual_cut": 3,
		"basic_guarded_strike": 3,
		"basic_guard_up": 3,
		"basic_battle_focus": 3,
		"basic_prepare": 3,
		"basic_cleanse": 3,
		"basic_warm_blood": 3,
		"basic_suppress": 3,
		"basic_kindling": 3,
		"basic_flame_guard": 3,
		"basic_soul_spark": 3,
		"basic_burning_edge": 3,
		"basic_cinder_strike": 3,
		"basic_execution": 3,
		"basic_last_stand": 3,
		"basic_steady_guard": 3,
		"major_00_the_fool": 1,
		"major_01_the_magician": 1,
		"major_02_the_high_priestess": 1,
		"major_04_the_emperor": 1,
		"major_19_the_sun": 1,
		"major_18_the_moon": 1,
		"major_21_the_world": 1,
	}


# Returns how many copies of card_id the player owns.
func get_owned_count(card_id: String) -> int:
	return int(player_card_collection.get(card_id, 0))


# Returns true only if the player owns at least one copy of card_id.
func owns_card(card_id: String) -> bool:
	return get_owned_count(card_id) > 0


# Adds card copies to the player's collection for future deck building.
func add_card(card_id: String, amount: int = 1) -> void:
	if card_id == "" or amount <= 0:
		return

	var card := CardDatabase.get_card(card_id)
	if card != null and (card.deck_category == CardData.DeckCategory.SPECIAL or card.is_special):
		player_card_collection[card_id] = min(get_owned_count(card_id) + amount, 1)
		return

	player_card_collection[card_id] = get_owned_count(card_id) + amount


# Removes card copies from the player's collection. Returns true on success.
func remove_card(card_id: String, amount: int = 1) -> bool:
	if card_id == "" or amount <= 0:
		return false

	var current_count := get_owned_count(card_id)
	if current_count < amount:
		return false

	var new_count := current_count - amount
	if new_count <= 0:
		player_card_collection.erase(card_id)
	else:
		player_card_collection[card_id] = new_count
	return true


# Replaces the in-memory collection with JSON-safe saved card counts.
func apply_collection_data(collection_data: Dictionary) -> void:
	player_card_collection.clear()
	for card_id_value in collection_data.keys():
		var card_id := str(card_id_value)
		var count := int(collection_data[card_id_value])
		if card_id != "" and count > 0:
			player_card_collection[card_id] = count
