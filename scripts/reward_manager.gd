extends Node

const BASE_REWARD_CARD_COUNT := 3

var current_reward_cards: Array[CardData] = []
var selected_reward_card: CardData


# Randomly grants one unowned special card. Returns null when the pool is empty.
func grant_random_unowned_special_card() -> CardData:
	var candidates := _get_unowned_special_cards()
	candidates.shuffle()
	if candidates.is_empty():
		selected_reward_card = null
		current_reward_cards.clear()
		return null

	var card := candidates[0]
	claim_reward(card)
	current_reward_cards = [card]
	return card


# Creates up to 3 special-card rewards the player does not already own.
func generate_special_card_rewards() -> Array[CardData]:
	var candidates := _get_unowned_special_cards()
	candidates.shuffle()
	var reward_count := BASE_REWARD_CARD_COUNT + RelicManager.get_reward_card_bonus()
	current_reward_cards = candidates.slice(0, min(reward_count, candidates.size()))
	selected_reward_card = null
	return current_reward_cards


# Adds the selected reward card to the player's collection.
func claim_reward(card: CardData) -> void:
	if card == null:
		return

	if PlayerCardCollection.owns_card(card.card_id):
		return

	PlayerCardCollection.add_card(card.card_id, 1)
	selected_reward_card = card


# Clears transient reward state before the next reward screen.
func clear_rewards() -> void:
	current_reward_cards.clear()
	selected_reward_card = null


func _get_unowned_special_cards() -> Array[CardData]:
	var candidates: Array[CardData] = []
	for path in CardDatabase.SPECIAL_CARD_PATHS:
		var card := load(path) as CardData
		if card == null:
			continue
		if card.deck_category != CardData.DeckCategory.SPECIAL and not card.is_special:
			continue
		if PlayerCardCollection.owns_card(card.card_id):
			continue
		candidates.append(card)
	return candidates
