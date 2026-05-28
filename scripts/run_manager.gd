extends Node

const RUN_MAP_GENERATOR := preload("res://scripts/RunMapGenerator.gd")
const ENEMY_DATABASE := preload("res://scripts/enemy_database.gd")

enum RunState {
	NOT_STARTED,
	IN_PROGRESS,
	CLEARED,
	FAILED,
}

const PLAYER_MAX_HEALTH := 50
const BATTLE_SCENE_PATH := "res://scenes/BattleScene.tscn"
const MAP_SCENE_PATH := "res://scenes/MapScene.tscn"
const MAP_PLACEHOLDER_SCENE_PATH := "res://scenes/MapPlaceholderScene.tscn"
const EVENT_SCENE_PATH := "res://scenes/EventScene.tscn"
const REST_SCENE_PATH := "res://scenes/RestScene.tscn"
const SHOP_SCENE_PATH := "res://scenes/ShopScene.tscn"
const REWARD_SCENE_PATH := "res://scenes/RewardScene.tscn"
const RELIC_REWARD_SCENE_PATH := "res://scenes/RelicRewardScene.tscn"
const CHAPTER_REWARD_SCENE_PATH := "res://scenes/ChapterRewardScene.tscn"
const CHAPTER4_INTRO_SCENE_PATH := "res://scenes/Chapter4IntroScene.tscn"
const VICTORY_SCENE_PATH := "res://scenes/VictoryScene.tscn"
const DEFEAT_SCENE_PATH := "res://scenes/DefeatScene.tscn"

const RUN_STATUS_NONE := "none"
const RUN_STATUS_ACTIVE := "active"
const RUN_STATUS_FAILED := "failed"
const RUN_STATUS_COMPLETED := "completed"
const ENDING_ROUTE_NONE := "none"
const ENDING_ROUTE_STAR := "star"
const ENDING_ROUTE_ABYSS := "abyss"
const MIN_DIFFICULTY := 1
const MAX_DIFFICULTY := 5

const NODE_NORMAL_BATTLE := "NormalBattle"
const NODE_ELITE_BATTLE := "EliteBattle"
const NODE_EVENT := "Event"
const NODE_SHOP := "Shop"
const NODE_REST := "Rest"
const NODE_RELIC_REWARD := "RelicReward"
const NODE_SPECIAL_CARD_REWARD := "SpecialCardReward"
const NODE_BOSS_BATTLE := "BossBattle"

const BOSS_ENEMY_PATH := "res://data/enemies/chapter_1/forest_guardian.tres"

# Kept for old saves and debug code that still expects a battle index.
const ENEMY_ROUTE: Array[String] = [
	"res://data/enemies/slime.tres",
	"res://data/enemies/goblin.tres",
	"res://data/enemies/skeleton.tres",
	BOSS_ENEMY_PATH,
]

var current_deck: Array[CardData] = []
var selected_deck_card_ids: Array[String] = []
var current_deck_upgrades: Array[bool] = []
var relic_ids: Array[String] = []
var current_battle_index := 0
var player_current_health := PLAYER_MAX_HEALTH
var player_max_health := PLAYER_MAX_HEALTH
var current_gold := 0
var battle_reward_gold := 0
var gold_reward_claimed := false
var battle_reward_card_id := ""
var battle_card_reward_claimed := false
var run_state := RunState.NOT_STARTED
var run_status := RUN_STATUS_NONE
var fate_score := 0
var ending_route := ENDING_ROUTE_NONE
var chapter4_route_unlocked := false
var chapter4_route := ENDING_ROUTE_NONE
var pending_chapter_intro := false
var current_difficulty := MIN_DIFFICULTY
var pending_chapter_reward := false
var chapter_reward_claimed := false
var last_completed_chapter := 0
var pending_next_chapter := 0
var deck_builder_mode := "new_run"
var deck_builder_return_scene_path := ""
var deck_builder_original_card_ids: Array[String] = []
var deck_builder_original_upgrades: Array[bool] = []
var shop_basic_products: Array[Dictionary] = []
var shop_relic_product: Dictionary = {}
var shop_remove_service_used := false
var shop_state_node_id := ""
var rest_state_node_id := ""
var rest_option_used := false

var current_map: Array[Dictionary] = []
var available_map_node_ids: Array[String] = []
var completed_map_node_ids: Array[String] = []
var current_map_node_id := ""
var current_map_node_type := ""
var current_enemy_path := ""
var current_enemy_id := ""
var last_normal_enemy_id := ""
var seen_event_ids: Array[String] = []

# Compatibility names that match the map-system design docs.
var current_chapter := 1
var current_floor := 1
var current_map_nodes: Array[Dictionary] = []
var completed_nodes: Array[String] = []
var available_nodes: Array[String] = []
var selected_node := ""
var current_node_type := ""


# Starts a map-based run after the player confirms a deck.
func start_run(selected_difficulty := 0) -> void:
	current_battle_index = 0
	current_chapter = 1
	if selected_difficulty > 0:
		current_difficulty = clamp(selected_difficulty, MIN_DIFFICULTY, MAX_DIFFICULTY)
	else:
		current_difficulty = clamp(current_difficulty, MIN_DIFFICULTY, MAX_DIFFICULTY)
	print("[Difficulty] start run difficulty: ", current_difficulty)
	player_max_health = max(1, PLAYER_MAX_HEALTH - get_player_max_hp_penalty())
	player_current_health = player_max_health
	current_gold = 0
	fate_score = 0
	ending_route = ENDING_ROUTE_NONE
	chapter4_route_unlocked = false
	chapter4_route = ENDING_ROUTE_NONE
	pending_chapter_intro = false
	pending_chapter_reward = false
	chapter_reward_claimed = false
	last_completed_chapter = 0
	pending_next_chapter = 0
	battle_reward_gold = 0
	gold_reward_claimed = false
	battle_reward_card_id = ""
	battle_card_reward_claimed = false
	relic_ids.clear()
	run_state = RunState.IN_PROGRESS
	run_status = RUN_STATUS_ACTIVE
	_generate_new_map()
	SaveManager.save_run()


# Stores the confirmed deck for this run.
func set_current_deck(cards: Array[CardData]) -> void:
	current_deck.clear()
	selected_deck_card_ids.clear()
	current_deck_upgrades.clear()
	for card in cards:
		if card != null:
			selected_deck_card_ids.append(card.card_id)
			current_deck_upgrades.append(false)
			current_deck.append(_make_run_card(card.card_id, false))


func set_current_deck_with_upgrades(card_ids: Array[String], upgrades: Array[bool]) -> void:
	current_deck.clear()
	selected_deck_card_ids.clear()
	current_deck_upgrades.clear()
	for index in range(card_ids.size()):
		var card_id := card_ids[index]
		var upgraded := index < upgrades.size() and upgrades[index]
		var card := _make_run_card(card_id, upgraded)
		if card != null:
			selected_deck_card_ids.append(card_id)
			current_deck_upgrades.append(upgraded)
			current_deck.append(card)
	_ensure_upgrade_array_size()


func prepare_deck_builder_edit(return_scene_path: String) -> void:
	deck_builder_mode = "edit_run_deck"
	deck_builder_return_scene_path = return_scene_path
	deck_builder_original_card_ids = selected_deck_card_ids.duplicate()
	deck_builder_original_upgrades = current_deck_upgrades.duplicate()


func clear_deck_builder_context() -> void:
	deck_builder_mode = "new_run"
	deck_builder_return_scene_path = ""
	deck_builder_original_card_ids.clear()
	deck_builder_original_upgrades.clear()


func restore_deck_builder_original_deck() -> void:
	if deck_builder_original_card_ids.is_empty():
		return
	set_current_deck_with_upgrades(deck_builder_original_card_ids, deck_builder_original_upgrades)


# Rebuilds the last confirmed deck from card ids.
func get_saved_deck_cards() -> Array[CardData]:
	var cards: Array[CardData] = []
	for index in range(selected_deck_card_ids.size()):
		var card_id := selected_deck_card_ids[index]
		var upgraded := index < current_deck_upgrades.size() and current_deck_upgrades[index]
		var card := _make_run_card(card_id, upgraded)
		if card != null:
			cards.append(card)
	return cards


# Returns whether a battle deck has been confirmed in this run.
func has_current_deck() -> bool:
	return current_deck.size() > 0


# Returns whether there is an unfinished run.
func has_active_run() -> bool:
	return run_status == RUN_STATUS_ACTIVE and run_state == RunState.IN_PROGRESS and has_current_deck() and not current_map.is_empty()


# Returns the enemy selected by the current map node, with old-route fallback.
func get_current_enemy_data() -> EnemyData:
	if current_enemy_id != "":
		var enemy_data := ENEMY_DATABASE.get_enemy(current_enemy_id)
		if enemy_data != null:
			return enemy_data

	var path := current_enemy_path
	if path == "":
		if current_battle_index < 0 or current_battle_index >= ENEMY_ROUTE.size():
			return null
		path = ENEMY_ROUTE[current_battle_index]

	return load(path) as EnemyData


# Returns true when the selected map node is the boss battle.
func is_boss_battle() -> bool:
	if current_map_node_type != "":
		return current_map_node_type == NODE_BOSS_BATTLE
	return current_battle_index == ENEMY_ROUTE.size() - 1


# Persists player health between battles.
func save_player_health(current_health: int) -> void:
	player_current_health = clamp(current_health, 0, player_max_health)


func add_gold(amount: int) -> void:
	if amount <= 0:
		push_warning("[Gold] ignored non-positive add_gold amount: %d" % amount)
		return

	current_gold += amount
	print("[Gold] reward: ", amount)
	print("[Gold] current total: ", current_gold)


func spend_gold(amount: int) -> bool:
	if amount <= 0:
		push_warning("[Gold] ignored non-positive spend_gold amount: %d" % amount)
		return false
	if not can_afford(amount):
		print("[Gold] not enough gold")
		return false

	current_gold -= amount
	print("[Gold] spend: ", amount)
	print("[Gold] remaining: ", current_gold)
	return true


func can_afford(amount: int) -> bool:
	return amount >= 0 and current_gold >= amount


func get_gold() -> int:
	return current_gold


func get_enemy_hp_multiplier() -> float:
	match current_difficulty:
		2:
			return 1.10
		3:
			return 1.20
		4:
			return 1.30
		5:
			return 1.40
		_:
			return 1.0


func get_enemy_damage_multiplier() -> float:
	match current_difficulty:
		3:
			return 1.10
		4:
			return 1.15
		5:
			return 1.20
		_:
			return 1.0


func get_player_max_hp_penalty() -> int:
	match current_difficulty:
		4:
			return 10
		5:
			return 15
		_:
			return 0


func get_gold_reward_multiplier() -> float:
	if current_difficulty >= 5:
		return 0.80
	return 1.0


func difficulty_name(difficulty: int = 0) -> String:
	var value := current_difficulty if difficulty <= 0 else difficulty
	match value:
		1:
			return "普通"
		2:
			return "进阶"
		3:
			return "困难"
		4:
			return "噩梦"
		5:
			return "终焉"
		_:
			return "未知"


# Adjusts the hidden route score used by late-game ending selection.
func add_fate_score(amount: int) -> void:
	if amount == 0:
		return
	fate_score += amount
	print("[Fate] change: %+d" % amount)
	print("[Fate] current score: ", fate_score)
	print("[Fate] alignment: ", get_fate_alignment())


# Unlocks the optional Chapter 4 route from key Chapter 3 event choices.
func unlock_chapter4_route(route: String) -> void:
	if route != ENDING_ROUTE_STAR and route != ENDING_ROUTE_ABYSS:
		push_warning("[Chapter4 Route] invalid route: " + route)
		return
	chapter4_route_unlocked = true
	chapter4_route = route
	ending_route = route
	print("[Chapter4 Route] unlocked: ", chapter4_route_unlocked)
	print("[Chapter4 Route] route: ", chapter4_route)


func get_fate_score() -> int:
	return fate_score


func get_fate_alignment() -> String:
	if fate_score >= 2:
		return "light"
	if fate_score <= -2:
		return "dark"
	return "neutral"


func claim_battle_gold_reward() -> int:
	var gold_before := current_gold
	if gold_reward_claimed:
		print("[Gold Test] node type: ", current_map_node_type)
		print("[Gold Test] reward gold: ", battle_reward_gold)
		print("[Gold Test] gold before: ", gold_before)
		print("[Gold Test] gold after: ", current_gold)
		print("[Gold Test] reward already claimed, skipped duplicate grant")
		return battle_reward_gold

	battle_reward_gold = _roll_battle_gold_reward()
	gold_reward_claimed = true
	print("[Gold Test] node type: ", current_map_node_type)
	print("[Gold Test] reward gold: ", battle_reward_gold)
	print("[Gold Test] gold before: ", gold_before)
	add_gold(battle_reward_gold)
	print("[Gold Test] gold after: ", current_gold)
	return battle_reward_gold


# Grants one basic card as the regular post-battle card reward.
func claim_battle_card_reward() -> CardData:
	if battle_card_reward_claimed:
		if battle_reward_card_id == "":
			return null
		return CardDatabase.get_card(battle_reward_card_id)

	var cards: Array[CardData] = CardDatabase.get_basic_cards()
	if cards.is_empty():
		battle_card_reward_claimed = true
		battle_reward_card_id = ""
		push_warning("[Reward] no basic cards available for battle reward.")
		return null

	var card: CardData = cards.pick_random()
	battle_card_reward_claimed = true
	battle_reward_card_id = card.card_id
	PlayerCardCollection.add_card(card.card_id, 1)
	print("[Reward] basic card reward: ", card.card_id)
	return card


# Returns basic, unupgraded cards in the current run deck for Rest upgrades.
func get_upgradeable_deck_entries() -> Array[Dictionary]:
	var entries: Array[Dictionary] = []
	for index in range(current_deck.size()):
		var card := current_deck[index]
		if card == null:
			continue
		if card.deck_category != CardData.DeckCategory.BASIC or card.is_special:
			continue
		if index < current_deck_upgrades.size() and current_deck_upgrades[index]:
			continue

		var upgraded_card := _make_run_card(card.card_id, true)
		if upgraded_card == null:
			continue

		entries.append({
			"deck_index": index,
			"card_name": card.card_name,
			"description": card.description,
			"upgraded_name": upgraded_card.card_name,
			"upgraded_description": upgraded_card.description,
		})
	return entries


# Upgrades one card by deck index. Special cards and already-upgraded cards are ignored.
func upgrade_deck_card(deck_index: int) -> CardData:
	if deck_index < 0 or deck_index >= selected_deck_card_ids.size():
		return null
	_ensure_upgrade_array_size()
	if current_deck_upgrades[deck_index]:
		return null

	var base_card := CardDatabase.get_card(selected_deck_card_ids[deck_index])
	if base_card == null or base_card.deck_category != CardData.DeckCategory.BASIC or base_card.is_special:
		return null

	current_deck_upgrades[deck_index] = true
	var upgraded_card := _make_run_card(base_card.card_id, true)
	current_deck[deck_index] = upgraded_card
	SaveManager.save_run()
	return upgraded_card


# Marks the run failed so menus or result screens can react later.
func mark_failed() -> void:
	run_state = RunState.FAILED
	run_status = RUN_STATUS_FAILED
	SaveManager.save_run()


# Advances the old fixed route. Map flow should use complete_current_map_node().
func advance_to_next_battle() -> void:
	current_battle_index += 1
	SaveManager.save_run()


# Marks the run cleared after the boss dies.
func mark_cleared() -> void:
	run_state = RunState.CLEARED
	run_status = RUN_STATUS_COMPLETED
	SaveManager.save_run()


# Clears in-memory run data after the player explicitly deletes the save.
func reset_run() -> void:
	current_deck.clear()
	selected_deck_card_ids.clear()
	current_deck_upgrades.clear()
	clear_deck_builder_context()
	shop_basic_products.clear()
	shop_relic_product.clear()
	shop_remove_service_used = false
	shop_state_node_id = ""
	rest_state_node_id = ""
	rest_option_used = false
	relic_ids.clear()
	current_battle_index = 0
	player_max_health = PLAYER_MAX_HEALTH
	player_current_health = PLAYER_MAX_HEALTH
	current_gold = 0
	current_difficulty = MIN_DIFFICULTY
	fate_score = 0
	ending_route = ENDING_ROUTE_NONE
	chapter4_route_unlocked = false
	chapter4_route = ENDING_ROUTE_NONE
	pending_chapter_intro = false
	pending_chapter_reward = false
	chapter_reward_claimed = false
	last_completed_chapter = 0
	pending_next_chapter = 0
	battle_reward_gold = 0
	gold_reward_claimed = false
	battle_reward_card_id = ""
	battle_card_reward_claimed = false
	run_state = RunState.NOT_STARTED
	run_status = RUN_STATUS_NONE
	current_map.clear()
	available_map_node_ids.clear()
	completed_map_node_ids.clear()
	current_map_node_id = ""
	current_map_node_type = ""
	current_enemy_path = ""
	current_enemy_id = ""
	last_normal_enemy_id = ""
	seen_event_ids.clear()
	current_chapter = 1
	current_floor = 1
	_sync_map_aliases()


# Advances to the next chapter after a non-final boss dies.
func advance_to_next_chapter_after_boss() -> bool:
	if not prepare_chapter_reward_after_boss():
		return false
	chapter_reward_claimed = true
	return complete_chapter_reward_and_advance()


# Prepares a chapter reward after a chapter boss. Returns false for final endings.
func prepare_chapter_reward_after_boss() -> bool:
	if current_chapter >= 4:
		return false

	var next_chapter := current_chapter + 1
	if current_chapter == 3:
		print("[Chapter4 Entry] chapter 3 boss defeated")
		print("[Chapter4 Entry] route unlocked: ", chapter4_route_unlocked)
		print("[Chapter4 Entry] route: ", chapter4_route)
		if not chapter4_route_unlocked or (chapter4_route != ENDING_ROUTE_STAR and chapter4_route != ENDING_ROUTE_ABYSS):
			ending_route = ENDING_ROUTE_NONE
			print("[Chapter4 Entry] going to normal victory")
			return false
		ending_route = chapter4_route
		pending_chapter_intro = true
		print("[Chapter4 Entry] going to intro scene")
		next_chapter = 4

	last_completed_chapter = current_chapter
	pending_next_chapter = next_chapter
	pending_chapter_reward = true
	chapter_reward_claimed = false
	_clear_current_map_node()
	SaveManager.save_run()
	return true


# Enters the pending next chapter after the player has selected a chapter reward.
func complete_chapter_reward_and_advance() -> bool:
	if not pending_chapter_reward or not chapter_reward_claimed or pending_next_chapter <= 0:
		push_warning("[ChapterReward] Cannot advance: no claimed pending chapter reward.")
		return false

	if pending_next_chapter == 4 and pending_chapter_intro:
		pending_chapter_reward = false
		chapter_reward_claimed = false
		SaveManager.save_run()
		return true

	current_chapter = pending_next_chapter
	current_floor = 1
	current_battle_index = 0
	battle_reward_gold = 0
	gold_reward_claimed = false
	battle_reward_card_id = ""
	battle_card_reward_claimed = false
	last_normal_enemy_id = ""
	current_enemy_path = ""
	current_enemy_id = ""
	completed_nodes.clear()
	available_nodes.clear()
	pending_chapter_reward = false
	chapter_reward_claimed = false
	pending_next_chapter = 0
	_generate_new_map()
	SaveManager.save_run()
	return true


# Called by Chapter4IntroScene after the player reads the route story.
func continue_from_chapter4_intro() -> bool:
	if not pending_chapter_intro:
		push_warning("[Chapter4 Intro] no pending chapter intro.")
		return false
	if chapter4_route != ENDING_ROUTE_STAR and chapter4_route != ENDING_ROUTE_ABYSS:
		push_warning("[Chapter4 Intro] invalid route: " + chapter4_route)
		return false

	print("[Chapter4 Intro] continue")
	print("[Chapter4 Intro] route: ", chapter4_route)
	print("[Chapter4 Intro] generating chapter 4 map")
	current_chapter = 4
	current_floor = 1
	current_battle_index = 0
	ending_route = chapter4_route
	pending_chapter_intro = false
	pending_next_chapter = 0
	pending_chapter_reward = false
	chapter_reward_claimed = false
	battle_reward_gold = 0
	gold_reward_claimed = false
	battle_reward_card_id = ""
	battle_card_reward_claimed = false
	last_normal_enemy_id = ""
	current_enemy_path = ""
	current_enemy_id = ""
	completed_nodes.clear()
	available_nodes.clear()
	_generate_new_map()
	SaveManager.save_run()
	return true


# Returns the current map, creating one for old saves if needed.
func get_map_nodes() -> Array[Dictionary]:
	if current_map.is_empty():
		_generate_new_map()
	_sync_map_aliases()
	return current_map


func get_available_map_node_ids() -> Array[String]:
	return available_map_node_ids.duplicate()


func get_completed_map_node_ids() -> Array[String]:
	return completed_map_node_ids.duplicate()


func get_current_map_node_type() -> String:
	return current_map_node_type


func get_current_floor() -> int:
	var floor := 1
	for node in current_map:
		if completed_map_node_ids.has(str(node.get("id", ""))):
			floor = max(floor, int(node.get("layer", 1)) + 1)
	current_floor = clamp(floor, 1, 7)
	return current_floor


func get_map_node(node_id: String) -> Dictionary:
	for node in current_map:
		if str(node.get("id", "")) == node_id:
			return node
	return {}


# Selects a reachable map node and returns the scene path that should open.
func select_map_node(node_id: String) -> String:
	if not available_map_node_ids.has(node_id):
		return ""
	if completed_map_node_ids.has(node_id):
		return ""

	var node := get_map_node(node_id)
	if node.is_empty():
		return ""
	if bool(node.get("completed", false)):
		return ""

	current_map_node_id = node_id
	current_map_node_type = str(node.get("type", NODE_NORMAL_BATTLE))
	current_enemy_path = ""
	current_enemy_id = ""
	battle_reward_gold = 0
	gold_reward_claimed = false
	battle_reward_card_id = ""
	battle_card_reward_claimed = false
	_set_map_node_state(current_map_node_id, false, false)
	_sync_map_aliases()

	match current_map_node_type:
		NODE_NORMAL_BATTLE, NODE_ELITE_BATTLE, NODE_BOSS_BATTLE:
			current_enemy_id = _enemy_id_for_node(current_map_node_type)
			return BATTLE_SCENE_PATH
		NODE_RELIC_REWARD:
			return RELIC_REWARD_SCENE_PATH
		NODE_SPECIAL_CARD_REWARD:
			return SHOP_SCENE_PATH
		NODE_REST:
			return REST_SCENE_PATH
		NODE_SHOP:
			return SHOP_SCENE_PATH
		NODE_EVENT:
			return EVENT_SCENE_PATH

	return MAP_PLACEHOLDER_SCENE_PATH


# Completes the selected node and unlocks its outgoing route choices.
func complete_current_map_node() -> void:
	if current_map_node_id == "":
		return

	var node := get_map_node(current_map_node_id)
	if node.is_empty():
		_clear_current_map_node()
		return

	if not completed_map_node_ids.has(current_map_node_id):
		completed_map_node_ids.append(current_map_node_id)
	available_map_node_ids.erase(current_map_node_id)
	_set_map_node_state(current_map_node_id, false, true)

	for next_id in node.get("next_ids", []):
		var next_node_id := str(next_id)
		if not completed_map_node_ids.has(next_node_id) and not available_map_node_ids.has(next_node_id):
			available_map_node_ids.append(next_node_id)
			_set_map_node_state(next_node_id, true, false)

	if current_map_node_type == NODE_NORMAL_BATTLE or current_map_node_type == NODE_ELITE_BATTLE:
		current_battle_index += 1
	if current_map_node_type == NODE_NORMAL_BATTLE:
		last_normal_enemy_id = current_enemy_id

	_clear_current_map_node()
	SaveManager.save_run()
	_sync_map_aliases()


func rest_at_current_node() -> int:
	var heal_amount := int(ceil(float(player_max_health) * 0.3))
	player_current_health = min(player_current_health + heal_amount, player_max_health)
	return heal_amount


func heal_percent_of_max(percent: float) -> int:
	var heal_amount := int(ceil(float(player_max_health) * percent))
	player_current_health = min(player_current_health + heal_amount, player_max_health)
	return heal_amount


func lose_health(amount: int) -> bool:
	if amount <= 0:
		return false
	if player_current_health <= amount:
		return false
	player_current_health = max(player_current_health - amount, 1)
	return true


func upgrade_random_basic_card() -> CardData:
	var entries := get_upgradeable_deck_entries()
	if entries.is_empty():
		return null
	var entry: Dictionary = entries.pick_random()
	return upgrade_deck_card(int(entry.get("deck_index", -1)))


func remove_random_basic_card_from_run() -> CardData:
	var candidates: Array[int] = []
	for index in range(current_deck.size()):
		var card := current_deck[index]
		if card != null and card.deck_category == CardData.DeckCategory.BASIC and not card.is_special:
			candidates.append(index)

	if candidates.is_empty():
		return null

	var deck_index: int = candidates.pick_random()
	var removed_card := current_deck[deck_index]
	selected_deck_card_ids.remove_at(deck_index)
	current_deck.remove_at(deck_index)
	if deck_index < current_deck_upgrades.size():
		current_deck_upgrades.remove_at(deck_index)
	PlayerCardCollection.remove_card(removed_card.card_id, 1)
	return removed_card


# Returns whether the currently selected map node has already been completed.
func is_current_map_node_completed() -> bool:
	return current_map_node_id != "" and completed_map_node_ids.has(current_map_node_id)


# Restores a saved run dictionary. Invalid card ids are skipped safely.
func apply_save_data(data: Dictionary) -> bool:
	var loaded_status: String = str(data.get("run_status", ""))
	if loaded_status == "":
		var saved_deck_value: Variant = data.get("current_deck_card_ids", [])
		var saved_map_value: Variant = data.get("current_map", [])
		var saved_deck_array: Array = []
		var saved_map_array: Array = []
		if typeof(saved_deck_value) == TYPE_ARRAY:
			saved_deck_array = saved_deck_value
		if typeof(saved_map_value) == TYPE_ARRAY:
			saved_map_array = saved_map_value
		var has_old_run_data: bool = not saved_deck_array.is_empty() and not saved_map_array.is_empty()
		var old_has_active_run: bool = bool(data.get("has_active_run", false))
		loaded_status = RUN_STATUS_ACTIVE if has_old_run_data or old_has_active_run else RUN_STATUS_NONE
	if loaded_status == RUN_STATUS_NONE:
		reset_run()
		return false

	current_chapter = int(data.get("current_chapter", 1))
	current_difficulty = clamp(int(data.get("current_difficulty", MIN_DIFFICULTY)), MIN_DIFFICULTY, MAX_DIFFICULTY)
	current_battle_index = int(data.get("current_battle_index", 0))
	player_max_health = int(data.get("player_max_health", PLAYER_MAX_HEALTH))
	player_current_health = clamp(int(data.get("player_current_health", player_max_health)), 0, player_max_health)
	current_gold = int(data.get("current_gold", 0))
	fate_score = int(data.get("fate_score", 0))
	ending_route = str(data.get("ending_route", ENDING_ROUTE_NONE))
	if ending_route != ENDING_ROUTE_STAR and ending_route != ENDING_ROUTE_ABYSS:
		ending_route = ENDING_ROUTE_NONE
	chapter4_route_unlocked = bool(data.get("chapter4_route_unlocked", false))
	chapter4_route = str(data.get("chapter4_route", ENDING_ROUTE_NONE))
	if chapter4_route != ENDING_ROUTE_STAR and chapter4_route != ENDING_ROUTE_ABYSS:
		chapter4_route = ENDING_ROUTE_NONE
		chapter4_route_unlocked = false
	pending_chapter_intro = bool(data.get("pending_chapter_intro", false))
	pending_chapter_reward = bool(data.get("pending_chapter_reward", false))
	chapter_reward_claimed = bool(data.get("chapter_reward_claimed", false))
	last_completed_chapter = int(data.get("last_completed_chapter", 0))
	pending_next_chapter = int(data.get("pending_next_chapter", 0))
	battle_reward_gold = int(data.get("battle_reward_gold", 0))
	gold_reward_claimed = bool(data.get("gold_reward_claimed", false))
	battle_reward_card_id = str(data.get("battle_reward_card_id", ""))
	battle_card_reward_claimed = bool(data.get("battle_card_reward_claimed", false))
	run_status = loaded_status
	relic_ids.clear()
	for relic_id in data.get("relic_ids", []):
		relic_ids.append(str(relic_id))

	selected_deck_card_ids.clear()
	current_deck.clear()
	current_deck_upgrades = _bool_array(data.get("current_deck_upgrades", []))
	for card_id_value in data.get("current_deck_card_ids", []):
		var card_id := str(card_id_value)
		var index := selected_deck_card_ids.size()
		var upgraded := index < current_deck_upgrades.size() and current_deck_upgrades[index]
		var card := _make_run_card(card_id, upgraded)
		if card != null:
			selected_deck_card_ids.append(card_id)
			current_deck.append(card)
	_ensure_upgrade_array_size()

	if current_deck.is_empty():
		return false

	current_map.clear()
	for raw_node in data.get("current_map", []):
		if typeof(raw_node) == TYPE_DICTIONARY:
			current_map.append(raw_node)
	if current_map.is_empty():
		_generate_new_map()

	available_map_node_ids = _string_array(data.get("available_map_node_ids", available_map_node_ids))
	completed_map_node_ids = _string_array(data.get("completed_map_node_ids", completed_map_node_ids))
	current_map_node_id = str(data.get("current_map_node_id", ""))
	current_map_node_type = str(data.get("current_map_node_type", ""))
	if run_status != RUN_STATUS_ACTIVE:
		current_map_node_id = ""
		current_map_node_type = ""
	current_enemy_path = str(data.get("current_enemy_path", ""))
	current_enemy_id = str(data.get("current_enemy_id", ""))
	last_normal_enemy_id = str(data.get("last_normal_enemy_id", ""))
	seen_event_ids = _string_array(data.get("seen_event_ids", []))

	current_battle_index = clamp(current_battle_index, 0, ENEMY_ROUTE.size() - 1)
	match run_status:
		RUN_STATUS_ACTIVE:
			run_state = RunState.IN_PROGRESS
		RUN_STATUS_FAILED:
			run_state = RunState.FAILED
		RUN_STATUS_COMPLETED:
			run_state = RunState.CLEARED
		_:
			run_state = RunState.NOT_STARTED
	_refresh_map_node_states()
	_sync_map_aliases()
	return true


func _generate_new_map() -> void:
	current_map = RUN_MAP_GENERATOR.generate_chapter_map()
	completed_map_node_ids.clear()
	available_map_node_ids.clear()
	for node in current_map:
		if int(node.get("layer", 0)) == 1:
			var node_id := str(node.get("id", ""))
			available_map_node_ids.append(node_id)
			_set_map_node_state(node_id, true, false)
	_clear_current_map_node()
	_sync_map_aliases()


func _clear_current_map_node() -> void:
	current_map_node_id = ""
	current_map_node_type = ""
	current_enemy_path = ""
	current_enemy_id = ""
	_sync_map_aliases()


func _set_map_node_state(node_id: String, is_available: bool, is_completed: bool) -> void:
	for index in range(current_map.size()):
		if str(current_map[index].get("id", "")) != node_id:
			continue
		current_map[index]["available"] = is_available
		current_map[index]["completed"] = is_completed
		return


func _refresh_map_node_states() -> void:
	for index in range(current_map.size()):
		var node_id := str(current_map[index].get("id", current_map[index].get("node_id", "")))
		current_map[index]["available"] = available_map_node_ids.has(node_id)
		current_map[index]["completed"] = completed_map_node_ids.has(node_id)


func _enemy_id_for_node(node_type: String) -> String:
	var previous_id := last_normal_enemy_id if node_type == NODE_NORMAL_BATTLE else ""
	return ENEMY_DATABASE.get_random_enemy_id_for_node_type(current_chapter, node_type, previous_id, ending_route)


func _roll_battle_gold_reward() -> int:
	var base_reward := 10
	match current_map_node_type:
		NODE_NORMAL_BATTLE:
			base_reward = randi_range(10, 20)
		NODE_ELITE_BATTLE:
			return randi_range(30, 45)
		NODE_BOSS_BATTLE:
			return 80
		_:
			push_warning("[Gold] Unknown battle node type: %s. Defaulting to 10 gold." % current_map_node_type)
			base_reward = 10

	var scaled_reward := int(ceil(float(base_reward) * get_gold_reward_multiplier()))
	return max(scaled_reward, 0)


func _string_array(values: Variant) -> Array[String]:
	var result: Array[String] = []
	if typeof(values) != TYPE_ARRAY:
		return result
	for value in values:
		result.append(str(value))
	return result


func _bool_array(values: Variant) -> Array[bool]:
	var result: Array[bool] = []
	if typeof(values) != TYPE_ARRAY:
		return result
	for value in values:
		result.append(bool(value))
	return result


func _ensure_upgrade_array_size() -> void:
	while current_deck_upgrades.size() < selected_deck_card_ids.size():
		current_deck_upgrades.append(false)
	while current_deck_upgrades.size() > selected_deck_card_ids.size():
		current_deck_upgrades.pop_back()


func _make_run_card(card_id: String, upgraded: bool) -> CardData:
	var base_card := CardDatabase.get_card(card_id)
	if base_card == null:
		return null

	var card := base_card.duplicate(false) as CardData
	card.effects = []
	for effect in base_card.effects:
		if effect != null:
			card.effects.append(CardEffect.create(effect.effect_type, effect.value))
	card.upgraded = upgraded
	if upgraded:
		_apply_upgrade_to_card(card)
	return card


func _apply_upgrade_to_card(card: CardData) -> void:
	var before_values: Array[int] = []
	for effect in card.effects:
		if effect != null:
			before_values.append(effect.value)

	match card.card_id:
		"basic_strike":
			_set_upgraded_values(card, [9], "造成 9 点伤害。")
		"basic_heavy_blow":
			_set_upgraded_values(card, [16], "造成 16 点伤害。")
		"basic_combo_strike":
			_set_upgraded_values(card, [4, 4], "造成 4 点伤害两次。")
		"basic_flame_slash":
			_set_upgraded_values(card, [8, 3], "造成 8 点伤害并施加 3 层燃烧。")
		"basic_armor_break":
			_set_upgraded_values(card, [7, 2], "造成 7 点伤害并施加 2 层虚弱。")
		"basic_guard":
			_set_upgraded_values(card, [8], "获得 8 点护甲。")
		"basic_hold_fast":
			_set_upgraded_values(card, [16], "获得 16 点护甲。")
		"basic_nimble_defense":
			_set_upgraded_values(card, [7, 1], "获得 7 点护甲并抽 1 张牌。")
		"basic_counter_stance":
			_set_upgraded_values(card, [9, 5], "获得 9 点护甲并对敌人造成 5 点伤害。")
		"basic_iron_wall":
			_set_upgraded_values(card, [28], "获得 28 点护甲。")
		"basic_charge":
			_set_upgraded_values(card, [2], "获得 2 点能量。")
		"basic_insight":
			_set_upgraded_values(card, [3], "抽 3 张牌。")
		"basic_tactical_shift":
			_set_upgraded_values(card, [2], "抽 2 张牌。")
		"basic_burning_mark":
			_set_upgraded_values(card, [6], "施加 6 层燃烧。")
		"basic_weaken":
			_set_upgraded_values(card, [3], "施加 3 层虚弱。")
		"basic_quick_cut":
			_set_upgraded_values(card, [5], "造成 5 点伤害。")
		"basic_dual_cut":
			_set_upgraded_values(card, [5, 5], "造成 5 点伤害两次。")
		"basic_guarded_strike":
			_set_upgraded_values(card, [7, 5], "造成 7 点伤害，获得 5 点护甲。")
		"basic_guard_up":
			_set_upgraded_values(card, [5], "获得 5 点护甲。")
		"basic_battle_focus":
			_set_upgraded_values(card, [2, 1], "抽 2 张牌，获得 1 点能量。")
		"basic_prepare":
			_set_upgraded_values(card, [2, 1], "抽 2 张牌，然后弃 1 张牌。")
		"basic_cleanse":
			_set_upgraded_values(card, [2, 6], "移除自身 1 层虚弱和 1 层燃烧，获得 6 点护甲。")
		"basic_warm_blood":
			_set_upgraded_values(card, [5, 1], "回复 5 点生命，获得 1 点能量。")
		"basic_suppress":
			_set_upgraded_values(card, [2], "施加 2 层虚弱。如果敌人有护甲，额外施加 1 层虚弱。")
		"basic_kindling":
			_set_upgraded_values(card, [3], "施加 3 层燃烧。若目标没有燃烧，改为施加 5 层燃烧。")
		"basic_flame_guard":
			_set_upgraded_values(card, [11, 3], "获得 11 点护甲，并施加 3 层燃烧。")
		"basic_soul_spark":
			_set_upgraded_values(card, [3, 1, 1], "造成 3 点伤害，抽 1 张牌，获得 1 点护甲。")
		"basic_burning_edge":
			_set_upgraded_values(card, [7, 5], "造成 7 点伤害。如果目标已有燃烧，额外造成 5 点伤害。")
		"basic_cinder_strike":
			_set_upgraded_values(card, [12, 3], "造成 12 点伤害。若目标有燃烧，施加 3 层虚弱。")
		"basic_execution":
			_set_upgraded_values(card, [13, 8], "造成 13 点伤害。若敌人生命低于 50%，额外造成 8 点伤害。")
		"basic_last_stand":
			_set_upgraded_values(card, [10, 10], "获得 10 点护甲。若你的生命低于 50%，额外获得 10 点护甲。")
		"basic_steady_guard":
			_set_upgraded_values(card, [9, 4], "获得 9 点护甲。若本回合没有打出攻击牌，额外获得 4 点护甲。")
		_:
			push_warning("[Rest] Missing upgrade data for card_id: " + card.card_id)
			return

	if not card.card_name.ends_with("+"):
		card.card_name += "+"
	var after_values: Array[int] = []
	for effect in card.effects:
		if effect != null:
			after_values.append(effect.value)
	print("[Upgrade Test] card_id: ", card.card_id)
	print("[Upgrade Test] upgraded: ", card.upgraded)
	print("[Upgrade Test] effect before: ", before_values)
	print("[Upgrade Test] effect after: ", after_values)


func _set_upgraded_values(card: CardData, values: Array[int], upgraded_description: String) -> void:
	for index in range(min(values.size(), card.effects.size())):
		card.effects[index].value = values[index]
	card.description = upgraded_description


func _sync_map_aliases() -> void:
	current_map_nodes = current_map.duplicate(true)
	completed_nodes = completed_map_node_ids.duplicate()
	available_nodes = available_map_node_ids.duplicate()
	selected_node = current_map_node_id
	current_node_type = current_map_node_type
