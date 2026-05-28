extends Node

const SAVE_PATH := "user://save.json"
const PROFILE_PATH := "user://profile.json"

var unlocked_difficulty := 1
var profile_language := "zh"


func _ready() -> void:
	load_profile()


# Saves the current run state to user://save.json.
func save_run() -> bool:
	print("[Gold Test] saving current_gold: ", RunManager.current_gold)
	print("[Fate] saving fate_score: ", RunManager.get_fate_score())
	print("[Ending] saving ending_route: ", RunManager.ending_route)
	var data := {
		"has_active_run": RunManager.has_active_run(),
		"run_status": RunManager.run_status,
		"current_difficulty": RunManager.current_difficulty,
		"current_battle_index": RunManager.current_battle_index,
		"player_current_health": RunManager.player_current_health,
		"player_max_health": RunManager.player_max_health,
		"current_gold": RunManager.current_gold,
		"fate_score": RunManager.get_fate_score(),
		"ending_route": RunManager.ending_route,
		"chapter4_route_unlocked": RunManager.chapter4_route_unlocked,
		"chapter4_route": RunManager.chapter4_route,
		"pending_chapter_intro": RunManager.pending_chapter_intro,
		"pending_chapter_reward": RunManager.pending_chapter_reward,
		"chapter_reward_claimed": RunManager.chapter_reward_claimed,
		"last_completed_chapter": RunManager.last_completed_chapter,
		"pending_next_chapter": RunManager.pending_next_chapter,
		"battle_reward_gold": RunManager.battle_reward_gold,
		"gold_reward_claimed": RunManager.gold_reward_claimed,
		"battle_reward_card_id": RunManager.battle_reward_card_id,
		"battle_card_reward_claimed": RunManager.battle_card_reward_claimed,
		"current_deck_card_ids": RunManager.selected_deck_card_ids,
		"current_deck_upgrades": RunManager.current_deck_upgrades,
		"relic_ids": RunManager.relic_ids,
		"player_card_collection": PlayerCardCollection.player_card_collection,
		"current_map": RunManager.current_map,
		"available_map_node_ids": RunManager.available_map_node_ids,
		"completed_map_node_ids": RunManager.completed_map_node_ids,
		"current_map_node_id": RunManager.current_map_node_id,
		"current_map_node_type": RunManager.current_map_node_type,
		"current_enemy_path": RunManager.current_enemy_path,
		"current_enemy_id": RunManager.current_enemy_id,
		"last_normal_enemy_id": RunManager.last_normal_enemy_id,
		"seen_event_ids": RunManager.seen_event_ids,
		"current_chapter": RunManager.current_chapter,
		"current_floor": RunManager.current_floor,
	}

	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file == null:
		push_warning("Failed to open save file for writing: %s" % SAVE_PATH)
		return false

	file.store_string(JSON.stringify(data, "\t"))
	return true


# Loads user://save.json and applies it to RunManager. Returns false on failure.
func load_run() -> bool:
	load_profile()
	if not FileAccess.file_exists(SAVE_PATH):
		return false

	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file == null:
		push_warning("Failed to open save file for reading: %s" % SAVE_PATH)
		return false

	var parsed = JSON.parse_string(file.get_as_text())
	if typeof(parsed) != TYPE_DICTIONARY:
		push_warning("Save file is not valid JSON dictionary.")
		return false

	print("[Gold Test] loading current_gold: ", int(parsed.get("current_gold", 0)))
	print("[Fate] loading fate_score: ", int(parsed.get("fate_score", 0)))
	print("[Ending] loading ending_route: ", str(parsed.get("ending_route", "none")))

	if parsed.has("player_card_collection") and typeof(parsed["player_card_collection"]) == TYPE_DICTIONARY:
		PlayerCardCollection.apply_collection_data(parsed["player_card_collection"])

	return RunManager.apply_save_data(parsed)


func load_game() -> bool:
	return load_run()


func save_game() -> bool:
	return save_run()


func get_save_path() -> String:
	return SAVE_PATH


# Deletes the current run save file if it exists.
func delete_save() -> void:
	if FileAccess.file_exists(SAVE_PATH):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE_PATH))


# Returns true when user://save.json exists.
func has_save() -> bool:
	return FileAccess.file_exists(SAVE_PATH)


func load_profile() -> void:
	unlocked_difficulty = 1
	profile_language = "zh"
	if not FileAccess.file_exists(PROFILE_PATH):
		print("[Difficulty] unlocked difficulty: ", unlocked_difficulty)
		return

	var file := FileAccess.open(PROFILE_PATH, FileAccess.READ)
	if file == null:
		push_warning("[Difficulty] Failed to open profile.json. Using default difficulty unlock.")
		print("[Difficulty] unlocked difficulty: ", unlocked_difficulty)
		return

	var parsed = JSON.parse_string(file.get_as_text())
	if typeof(parsed) != TYPE_DICTIONARY:
		push_warning("[Difficulty] profile.json is invalid. Using default difficulty unlock.")
		print("[Difficulty] unlocked difficulty: ", unlocked_difficulty)
		return

	unlocked_difficulty = clamp(int(parsed.get("unlocked_difficulty", 1)), RunManager.MIN_DIFFICULTY, RunManager.MAX_DIFFICULTY)
	profile_language = _normalize_profile_language(str(parsed.get("language", "zh")))
	print("[Difficulty] unlocked difficulty: ", unlocked_difficulty)


func save_profile() -> bool:
	var data := {
		"unlocked_difficulty": clamp(unlocked_difficulty, RunManager.MIN_DIFFICULTY, RunManager.MAX_DIFFICULTY),
		"language": _normalize_profile_language(profile_language),
	}
	var file := FileAccess.open(PROFILE_PATH, FileAccess.WRITE)
	if file == null:
		push_warning("[Difficulty] Failed to open profile.json for writing.")
		return false
	file.store_string(JSON.stringify(data, "\t"))
	return true


func get_unlocked_difficulty() -> int:
	return clamp(unlocked_difficulty, RunManager.MIN_DIFFICULTY, RunManager.MAX_DIFFICULTY)


func get_profile_language() -> String:
	load_profile()
	return _normalize_profile_language(profile_language)


func set_profile_language(language: String) -> bool:
	load_profile()
	profile_language = _normalize_profile_language(language)
	return save_profile()


func _normalize_profile_language(language: String) -> String:
	if language == "en":
		return "en"
	return "zh"


func is_difficulty_unlocked(difficulty: int) -> bool:
	return difficulty >= RunManager.MIN_DIFFICULTY and difficulty <= get_unlocked_difficulty()


func unlock_next_difficulty_after_clear(completed_difficulty: int) -> String:
	load_profile()
	print("[Difficulty] completed difficulty: ", completed_difficulty)
	if completed_difficulty >= RunManager.MAX_DIFFICULTY:
		return LanguageManager.tr_key("difficulty_highest_completed")
	if completed_difficulty == unlocked_difficulty:
		unlocked_difficulty = min(unlocked_difficulty + 1, RunManager.MAX_DIFFICULTY)
		save_profile()
		print("[Difficulty] unlocked new difficulty: ", unlocked_difficulty)
		return LanguageManager.tr_format("difficulty_unlocked_new", {"difficulty": _localized_difficulty_name(unlocked_difficulty)})
	if completed_difficulty < unlocked_difficulty:
		return LanguageManager.tr_key("difficulty_already_completed")
	return ""


func _localized_difficulty_name(difficulty: int) -> String:
	match difficulty:
		1:
			return LanguageManager.tr_key("difficulty_normal")
		2:
			return LanguageManager.tr_key("difficulty_advanced")
		3:
			return LanguageManager.tr_key("difficulty_hard")
		4:
			return LanguageManager.tr_key("difficulty_nightmare")
		5:
			return LanguageManager.tr_key("difficulty_final")
	return LanguageManager.tr_key("difficulty_unknown")
