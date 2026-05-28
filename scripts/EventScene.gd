extends Control

const EVENT_IMAGE_PATHS := {
	"fate_crossroads": "res://assets/events/fate_crossroads.png",
	"star_whisper": "res://assets/events/star_whisper.png",
	"abyss_contract": "res://assets/events/abyss_contract.png",
	"fate_scales": "res://assets/events/fate_scale.png",
	"shattered_mirror_hall": "res://assets/events/broken_mirror_hall.png",
	"corrupted_shrine": "res://assets/events/corrupted_altar.png",
	"unstable_portal": "res://assets/events/unstable_portal.png",
	"mystic_spring": "res://assets/events/mystic_spring.png",
	"wandering_merchant": "res://assets/events/wandering_merchant.png",
	"broken_altar": "res://assets/events/broken_altar.png",
	"forgotten_blacksmith": "res://assets/events/forgotten_blacksmith.png",
	"cursed_chest": "res://assets/events/cursed_chest.png",
	"star_divination": "res://assets/events/astrology_divination.png",
}

var title_label: Label
var status_label: Label
var event_art_texture: TextureRect
var description_label: Label
var result_label: Label
var choice_container: VBoxContainer
var continue_button: Button

var current_event: Dictionary = {}
var choice_made := false


func _ready() -> void:
	_build_ui()
	if not LanguageManager.language_changed.is_connected(_refresh_event_view):
		LanguageManager.language_changed.connect(_refresh_event_view)
	_pick_event()
	_refresh_event_view()


func _build_ui() -> void:
	var background := ColorRect.new()
	background.color = Color(0.045, 0.04, 0.06, 1.0)
	background.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(background)

	var panel := PanelContainer.new()
	panel.set_anchors_preset(Control.PRESET_CENTER)
	panel.offset_left = -500
	panel.offset_top = -360
	panel.offset_right = 500
	panel.offset_bottom = 360
	add_child(panel)

	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.11, 0.09, 0.13, 0.96)
	style.border_color = Color(0.62, 0.48, 0.25, 0.9)
	style.set_border_width_all(2)
	style.set_corner_radius_all(8)
	style.content_margin_left = 36
	style.content_margin_right = 36
	style.content_margin_top = 30
	style.content_margin_bottom = 30
	panel.add_theme_stylebox_override("panel", style)

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 18)
	panel.add_child(box)

	title_label = Label.new()
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_label.add_theme_font_size_override("font_size", 42)
	title_label.add_theme_color_override("font_color", Color(1.0, 0.86, 0.52))
	box.add_child(title_label)

	status_label = Label.new()
	status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	status_label.add_theme_font_size_override("font_size", 22)
	status_label.add_theme_color_override("font_color", Color(0.8, 0.92, 1.0))
	box.add_child(status_label)

	event_art_texture = TextureRect.new()
	event_art_texture.custom_minimum_size = Vector2(860, 210)
	event_art_texture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	event_art_texture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	event_art_texture.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_child(event_art_texture)

	description_label = Label.new()
	description_label.custom_minimum_size = Vector2(860, 80)
	description_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	description_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	description_label.add_theme_font_size_override("font_size", 24)
	description_label.add_theme_color_override("font_color", Color(0.94, 0.9, 0.78))
	box.add_child(description_label)

	choice_container = VBoxContainer.new()
	choice_container.add_theme_constant_override("separation", 12)
	box.add_child(choice_container)

	result_label = Label.new()
	result_label.custom_minimum_size = Vector2(760, 70)
	result_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	result_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	result_label.add_theme_font_size_override("font_size", 23)
	result_label.add_theme_color_override("font_color", Color(0.58, 1.0, 0.68))
	box.add_child(result_label)

	continue_button = Button.new()
	continue_button.disabled = true
	continue_button.custom_minimum_size = Vector2(240, 56)
	continue_button.add_theme_font_size_override("font_size", 26)
	continue_button.pressed.connect(_on_continue_pressed)
	box.add_child(continue_button)


func _pick_event() -> void:
	var events := _event_pool()
	var chapter_events: Array[Dictionary] = []
	for event in events:
		if not event.has("chapter") or int(event.get("chapter", 0)) == RunManager.current_chapter:
			chapter_events.append(event)
	if not chapter_events.is_empty():
		events = chapter_events

	var candidates: Array[Dictionary] = []
	for event in events:
		if not RunManager.seen_event_ids.has(str(event["event_id"])):
			candidates.append(event)
	if candidates.is_empty():
		candidates = events

	current_event = candidates.pick_random()
	var event_id := str(current_event["event_id"])
	if not RunManager.seen_event_ids.has(event_id):
		RunManager.seen_event_ids.append(event_id)
	SaveManager.save_run()


func _refresh_event_view() -> void:
	if not is_node_ready() or current_event.is_empty():
		return

	var event_id := str(current_event.get("event_id", ""))
	title_label.text = _event_text(event_id, "title", "Event")
	description_label.text = _event_text(event_id, "desc", "")
	if not choice_made:
		result_label.text = ""
	continue_button.text = LanguageManager.tr_key("ui_continue")
	_refresh_status()

	for child in choice_container.get_children():
		child.queue_free()

	var index := 0
	for choice in current_event.get("choices", []):
		index += 1
		var button := Button.new()
		button.text = _event_text(event_id, "choice_%d" % index, LanguageManager.tr_key("ui_choose"))
		button.custom_minimum_size = Vector2(760, 56)
		button.add_theme_font_size_override("font_size", 22)
		var unavailable_reason := _choice_unavailable_reason(choice)
		if unavailable_reason != "":
			button.text += " (%s)" % unavailable_reason
			button.disabled = true
		button.pressed.connect(_on_choice_pressed.bind(choice, index))
		choice_container.add_child(button)

	_set_event_art(event_id)


func _event_text(event_id: String, suffix: String, fallback: String) -> String:
	var key := "event.%s.%s" % [event_id, suffix]
	if LanguageManager.has_key(key):
		return LanguageManager.tr_key(key)
	return fallback


func _set_event_art(event_id: String) -> void:
	var image_path: String = str(EVENT_IMAGE_PATHS.get(event_id, ""))
	if image_path == "":
		event_art_texture.texture = null
		return
	if not ResourceLoader.exists(image_path):
		event_art_texture.texture = null
		push_warning("[EventScene] missing event image: " + image_path)
		return
	event_art_texture.texture = load(image_path) as Texture2D


func _refresh_status() -> void:
	status_label.text = "%s: %d / %d   %s: %d" % [
		LanguageManager.tr_key("ui_hp"),
		RunManager.player_current_health,
		RunManager.player_max_health,
		LanguageManager.tr_key("ui_gold"),
		RunManager.get_gold(),
	]


func _on_choice_pressed(choice: Dictionary, choice_index: int) -> void:
	if choice_made:
		return

	var unavailable_reason := _choice_unavailable_reason(choice)
	if unavailable_reason != "":
		result_label.text = unavailable_reason
		return

	AudioManager.play_sfx("ui_click")
	choice_made = true
	var effect_result := _apply_choice_effect(choice)
	var event_id := str(current_event.get("event_id", ""))
	var result_text := _event_text(event_id, "result_%d" % choice_index, "")
	if effect_result != "":
		result_text += "\n%s" % effect_result
	result_label.text = result_text.strip_edges()

	for child in choice_container.get_children():
		if child is Button:
			child.disabled = true
	continue_button.disabled = false
	_refresh_status()
	SaveManager.save_run()


func _choice_unavailable_reason(choice: Dictionary) -> String:
	for effect in _choice_effects(choice):
		var effect_type := str(effect.get("effect_type", "none"))
		var value := int(effect.get("effect_value", 0))
		match effect_type:
			"spend_gold_relic", "buy_basic_card", "buy_special_card", "paid_upgrade", "fortune_special", "SpendGold":
				if not RunManager.can_afford(value):
					return LanguageManager.tr_key("ui_not_enough_gold")
			"sacrifice_relic":
				if RunManager.player_current_health <= value:
					return LanguageManager.tr_key("ui_not_enough_hp")
			"LoseHP":
				if RunManager.player_current_health <= 1:
					return LanguageManager.tr_key("ui_not_enough_hp")
			"buy_special_card", "fortune_special", "GrantSpecialCard":
				if _get_unowned_special_cards().is_empty():
					return LanguageManager.tr_key("event.effect_no_special")
			"spend_gold_relic", "sacrifice_relic", "GrantRelic":
				if RelicManager.get_unowned_relics().is_empty():
					return LanguageManager.tr_key("event.effect_no_relic")
			"random_upgrade", "paid_upgrade", "UpgradeRandomBasic":
				if RunManager.get_upgradeable_deck_entries().is_empty():
					return LanguageManager.tr_key("event.effect_no_upgrade")
			"remove_basic", "RemoveRandomBasicCard":
				if not _has_removable_basic_card():
					return LanguageManager.tr_key("event.effect_no_remove")
	return ""


func _apply_choice_effect(choice: Dictionary) -> String:
	var results: Array[String] = []
	for effect in _choice_effects(choice):
		var result := _apply_single_choice_effect(effect)
		if result != "":
			results.append(result)
	return "\n".join(results)


func _choice_effects(choice: Dictionary) -> Array[Dictionary]:
	var effects: Array[Dictionary] = []
	if choice.has("effects") and typeof(choice["effects"]) == TYPE_ARRAY:
		for raw_effect in choice["effects"]:
			if typeof(raw_effect) == TYPE_DICTIONARY:
				effects.append(raw_effect)
	else:
		effects.append({
			"effect_type": str(choice.get("effect_type", "none")),
			"effect_value": int(choice.get("effect_value", 0)),
		})
	if choice.has("fate_score_delta"):
		effects.append({
			"effect_type": "FateChange",
			"effect_value": int(choice.get("fate_score_delta", 0)),
		})
	return effects


func _apply_single_choice_effect(effect: Dictionary) -> String:
	var effect_type := str(effect.get("effect_type", "none"))
	var value := int(effect.get("effect_value", 0))
	match effect_type:
		"none":
			return ""
		"heal_percent":
			return _effect_heal(RunManager.heal_percent_of_max(float(value) / 100.0))
		"HealFlat":
			return _effect_heal(_heal_flat(value))
		"spend_gold_relic":
			if not RunManager.spend_gold(value):
				return LanguageManager.tr_key("ui_not_enough_gold")
			return _grant_random_relic()
		"buy_basic_card":
			if not RunManager.spend_gold(value):
				return LanguageManager.tr_key("ui_not_enough_gold")
			return _grant_random_basic_card()
		"buy_special_card", "fortune_special":
			if not RunManager.spend_gold(value):
				return LanguageManager.tr_key("ui_not_enough_gold")
			return _grant_random_special_card()
		"sacrifice_relic":
			var sacrificed := _lose_hp_safely(value)
			if sacrificed <= 0:
				return LanguageManager.tr_key("ui_not_enough_hp")
			return _grant_random_relic()
		"gain_gold", "GainGold":
			RunManager.add_gold(value)
			return LanguageManager.tr_format("ui_gain_gold", {"amount": value})
		"SpendGold":
			if not RunManager.spend_gold(value):
				return LanguageManager.tr_key("ui_not_enough_gold")
			return LanguageManager.tr_format("ui_spend_gold", {"amount": value})
		"LoseHP":
			var lost_hp := _lose_hp_safely(value)
			if lost_hp <= 0:
				return LanguageManager.tr_key("ui_not_enough_hp")
			return LanguageManager.tr_format("event.effect_lose_hp", {"amount": lost_hp})
		"random_upgrade", "UpgradeRandomBasic":
			return _upgrade_random_basic_card()
		"paid_upgrade":
			if not RunManager.spend_gold(value):
				return LanguageManager.tr_key("ui_not_enough_gold")
			return _upgrade_random_basic_card()
		"cursed_chest":
			RunManager.add_gold(value)
			return "%s\n%s" % [LanguageManager.tr_format("ui_gain_gold", {"amount": value}), _add_curse_card()]
		"AddCurse":
			return _add_curse_card()
		"remove_basic", "RemoveRandomBasicCard":
			return _remove_random_basic_card()
		"GrantRelic":
			return _grant_random_relic()
		"GrantBasicCard":
			return _grant_random_basic_card()
		"GrantSpecialCard":
			return _grant_random_special_card()
		"RandomRisk":
			return _apply_random_risk(value)
		"FateLight":
			var light_amount: int = value if value != 0 else 1
			RunManager.add_fate_score(abs(light_amount))
			return LanguageManager.tr_key("event.effect_fate_light")
		"FateDark":
			var dark_amount: int = value if value != 0 else 1
			RunManager.add_fate_score(-abs(dark_amount))
			return LanguageManager.tr_key("event.effect_fate_dark")
		"FateChange":
			RunManager.add_fate_score(value)
			return LanguageManager.tr_key("event.effect_fate_change")
		"UnlockChapter4Route":
			var route := str(effect.get("route", RunManager.ENDING_ROUTE_NONE))
			RunManager.unlock_chapter4_route(route)
			if route == RunManager.ENDING_ROUTE_STAR:
				return LanguageManager.tr_key("event.effect_unlock_star")
			if route == RunManager.ENDING_ROUTE_ABYSS:
				return LanguageManager.tr_key("event.effect_unlock_abyss")
			return ""
	return ""


func _effect_heal(amount: int) -> String:
	return LanguageManager.tr_format("event.effect_heal", {"amount": amount})


func _heal_flat(amount: int) -> int:
	var before := RunManager.player_current_health
	RunManager.player_current_health = min(RunManager.player_current_health + max(amount, 0), RunManager.player_max_health)
	return RunManager.player_current_health - before


func _lose_hp_safely(amount: int) -> int:
	if amount <= 0 or RunManager.player_current_health <= 1:
		return 0
	var before := RunManager.player_current_health
	RunManager.player_current_health = max(RunManager.player_current_health - amount, 1)
	return before - RunManager.player_current_health


func _add_curse_card() -> String:
	const CURSE_CARD_ID := "curse_fate_mark"
	var curse_card := CardDatabase.get_card(CURSE_CARD_ID)
	if curse_card == null:
		push_warning("[Event] missing curse card data: " + CURSE_CARD_ID)
		return LanguageManager.tr_key("event.effect_curse_missing")
	RunManager.selected_deck_card_ids.append(CURSE_CARD_ID)
	RunManager.current_deck_upgrades.append(false)
	RunManager.current_deck.append(curse_card)
	return LanguageManager.tr_format("event.effect_add_curse", {"card": curse_card.get_display_name()})


func _apply_random_risk(value: int) -> String:
	if randf() < 0.5:
		return _grant_random_relic()
	var damage := value if value > 0 else 20
	var lost_hp := _lose_hp_safely(damage)
	if lost_hp <= 0:
		return LanguageManager.tr_key("event.effect_random_risk_safe")
	return LanguageManager.tr_format("event.effect_lose_hp", {"amount": lost_hp})


func _grant_random_basic_card() -> String:
	var cards := CardDatabase.get_basic_cards()
	if cards.is_empty():
		return LanguageManager.tr_key("event.effect_no_basic")
	var card: CardData = cards.pick_random()
	PlayerCardCollection.add_card(card.card_id, 1)
	return LanguageManager.tr_format("event.effect_gain_basic", {"card": card.get_display_name()})


func _grant_random_special_card() -> String:
	var cards := _get_unowned_special_cards()
	if cards.is_empty():
		return LanguageManager.tr_key("event.effect_no_special")
	var card: CardData = cards.pick_random()
	PlayerCardCollection.add_card(card.card_id, 1)
	return LanguageManager.tr_format("event.effect_gain_special", {"card": card.get_display_name()})


func _grant_random_relic() -> String:
	var relics := RelicManager.get_unowned_relics()
	if relics.is_empty():
		return LanguageManager.tr_key("event.effect_no_relic")
	var relic: RelicData = relics.pick_random()
	RelicManager.add_relic(relic.relic_id)
	return LanguageManager.tr_format("event.effect_gain_relic", {"relic": relic.get_display_name()})


func _upgrade_random_basic_card() -> String:
	var card := RunManager.upgrade_random_basic_card()
	if card == null:
		return LanguageManager.tr_key("event.effect_no_upgrade")
	return LanguageManager.tr_format("event.effect_upgrade", {"card": card.get_display_name()})


func _remove_random_basic_card() -> String:
	var card := RunManager.remove_random_basic_card_from_run()
	if card == null:
		return LanguageManager.tr_key("event.effect_no_remove")
	return LanguageManager.tr_format("event.effect_remove", {"card": card.get_display_name()})


func _get_unowned_special_cards() -> Array[CardData]:
	var cards: Array[CardData] = []
	for card in CardDatabase.get_special_cards():
		if not PlayerCardCollection.owns_card(card.card_id):
			cards.append(card)
	return cards


func _has_removable_basic_card() -> bool:
	for card in RunManager.current_deck:
		if card != null and card.deck_category == CardData.DeckCategory.BASIC and not card.is_special:
			return true
	return false


func _on_continue_pressed() -> void:
	AudioManager.play_sfx("ui_click")
	RunManager.complete_current_map_node()
	SaveManager.save_run()
	get_tree().change_scene_to_file(RunManager.MAP_SCENE_PATH)


func _event_pool() -> Array[Dictionary]:
	return [
		_event("fate_crossroads", [
			_choice("FateLight", 1),
			_choice("FateDark", 1),
			_choice("none", 0),
		]),
		_event("star_whisper", [
			{"effects": [
				{"effect_type": "FateLight", "effect_value": 1},
				{"effect_type": "HealFlat", "effect_value": 10},
				{"effect_type": "UnlockChapter4Route", "route": "star"},
			]},
			_choice("none", 0),
			{"effects": [
				{"effect_type": "FateDark", "effect_value": 1},
				{"effect_type": "GainGold", "effect_value": 40},
				{"effect_type": "LoseHP", "effect_value": 5},
			]},
		], 3),
		_event("abyss_contract", [
			{"effects": [
				{"effect_type": "FateDark", "effect_value": 1},
				{"effect_type": "GainGold", "effect_value": 100},
				{"effect_type": "AddCurse", "effect_value": 0},
				{"effect_type": "UnlockChapter4Route", "route": "abyss"},
			]},
			{"effects": [
				{"effect_type": "FateLight", "effect_value": 1},
				{"effect_type": "LoseHP", "effect_value": 10},
				{"effect_type": "GrantRelic", "effect_value": 0},
			]},
			_choice("none", 0),
		], 3),
		_event("fate_scales", [
			{"effects": [
				{"effect_type": "SpendGold", "effect_value": 80},
				{"effect_type": "FateLight", "effect_value": 1},
				{"effect_type": "UpgradeRandomBasic", "effect_value": 0},
			]},
			{"effects": [
				{"effect_type": "LoseHP", "effect_value": 15},
				{"effect_type": "FateDark", "effect_value": 1},
				{"effect_type": "GrantSpecialCard", "effect_value": 0},
			]},
			{"effects": [
				{"effect_type": "GainGold", "effect_value": 50},
				{"effect_type": "RemoveRandomBasicCard", "effect_value": 0},
			]},
		]),
		_event("shattered_mirror_hall", [
			{"effects": [
				{"effect_type": "UpgradeRandomBasic", "effect_value": 0},
				{"effect_type": "LoseHP", "effect_value": 8},
			]},
			{"effects": [
				{"effect_type": "GainGold", "effect_value": 60},
				{"effect_type": "AddCurse", "effect_value": 0},
			]},
			_choice("none", 0),
		]),
		_event("corrupted_shrine", [
			{"effects": [
				{"effect_type": "FateLight", "effect_value": 1},
				{"effect_type": "LoseHP", "effect_value": 12},
				{"effect_type": "GrantRelic", "effect_value": 0},
			]},
			{"effects": [
				{"effect_type": "FateDark", "effect_value": 1},
				{"effect_type": "GainGold", "effect_value": 120},
				{"effect_type": "AddCurse", "effect_value": 0},
			]},
			_choice("none", 0),
		]),
		_event("unstable_portal", [
			_choice("RandomRisk", 20),
			{"effects": [
				{"effect_type": "SpendGold", "effect_value": 50},
				{"effect_type": "HealFlat", "effect_value": 20},
			]},
			{"effects": [
				{"effect_type": "GainGold", "effect_value": 70},
				{"effect_type": "FateDark", "effect_value": 1},
			]},
		]),
		_event("mystic_spring", [
			_choice("heal_percent", 25),
			_choice("spend_gold_relic", 30),
			_choice("none", 0),
		]),
		_event("wandering_merchant", [
			_choice("buy_basic_card", 40),
			_choice("buy_special_card", 100),
			_choice("none", 0),
		]),
		_event("broken_altar", [
			_choice("sacrifice_relic", 10),
			_choice("gain_gold", 50),
			_choice("none", 0),
		]),
		_event("forgotten_blacksmith", [
			_choice("random_upgrade", 0),
			_choice("paid_upgrade", 50),
			_choice("none", 0),
		]),
		_event("cursed_chest", [
			_choice("cursed_chest", 80),
			_choice("gain_gold", 40),
			_choice("none", 0),
		]),
		_event("star_divination", [
			_choice("fortune_special", 50),
			_choice("remove_basic", 0),
			_choice("none", 0),
		]),
	]


func _event(event_id: String, choices: Array, chapter := 0) -> Dictionary:
	var data := {
		"event_id": event_id,
		"choices": choices,
	}
	if chapter > 0:
		data["chapter"] = chapter
	return data


func _choice(effect_type: String, effect_value: int) -> Dictionary:
	return {
		"effect_type": effect_type,
		"effect_value": effect_value,
	}
