extends Control

const CHAPTER_REWARD_ICON_DIR := "res://assets/ui/chapter_rewards/"
const REWARD_ICON_PATHS := {
	"gold_150": CHAPTER_REWARD_ICON_DIR + "rich_loot.png",
	"relic": CHAPTER_REWARD_ICON_DIR + "ancient_relic.png",
	"special_card": CHAPTER_REWARD_ICON_DIR + "tarot_box.png",
	"max_hp": CHAPTER_REWARD_ICON_DIR + "life_blessing.png",
	"upgrade_two": CHAPTER_REWARD_ICON_DIR + "forge_opportunity.png",
	"remove_basic": CHAPTER_REWARD_ICON_DIR + "purify_deck.png",
	"fate_ember": CHAPTER_REWARD_ICON_DIR + "fate_ember.png",
	"supply": CHAPTER_REWARD_ICON_DIR + "full_supply.png",
	"gold": CHAPTER_REWARD_ICON_DIR + "rich_loot.png",
}

var title_label: Label
var subtitle_label: Label
var status_label: Label
var result_label: Label
var rewards_container: HBoxContainer
var continue_button: Button
var reward_options: Array[Dictionary] = []


func _ready() -> void:
	if not LanguageManager.language_changed.is_connected(_refresh_language_texts):
		LanguageManager.language_changed.connect(_refresh_language_texts)
	_build_ui()
	_prepare_rewards()
	_refresh_view()


func _build_ui() -> void:
	var background := ColorRect.new()
	background.color = Color(0.035, 0.03, 0.055, 1.0)
	background.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(background)

	var panel := PanelContainer.new()
	panel.set_anchors_preset(Control.PRESET_CENTER)
	panel.offset_left = -620
	panel.offset_top = -365
	panel.offset_right = 620
	panel.offset_bottom = 365
	panel.add_theme_stylebox_override("panel", _panel_style())
	add_child(panel)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 36)
	margin.add_theme_constant_override("margin_top", 30)
	margin.add_theme_constant_override("margin_right", 36)
	margin.add_theme_constant_override("margin_bottom", 30)
	panel.add_child(margin)

	var box := VBoxContainer.new()
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_theme_constant_override("separation", 18)
	margin.add_child(box)

	title_label = Label.new()
	title_label.text = LanguageManager.tr_key("chapter_reward_title")
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_label.add_theme_font_size_override("font_size", 44)
	title_label.add_theme_color_override("font_color", Color(1.0, 0.86, 0.48))
	box.add_child(title_label)

	subtitle_label = Label.new()
	subtitle_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle_label.add_theme_font_size_override("font_size", 26)
	subtitle_label.add_theme_color_override("font_color", Color(0.9, 0.86, 0.76))
	box.add_child(subtitle_label)

	status_label = Label.new()
	status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	status_label.add_theme_font_size_override("font_size", 22)
	status_label.add_theme_color_override("font_color", Color(0.76, 0.9, 1.0))
	box.add_child(status_label)

	rewards_container = HBoxContainer.new()
	rewards_container.alignment = BoxContainer.ALIGNMENT_CENTER
	rewards_container.add_theme_constant_override("separation", 26)
	box.add_child(rewards_container)

	result_label = Label.new()
	result_label.custom_minimum_size = Vector2(900, 48)
	result_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	result_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	result_label.add_theme_font_size_override("font_size", 23)
	result_label.add_theme_color_override("font_color", Color(0.62, 1.0, 0.68))
	box.add_child(result_label)

	continue_button = Button.new()
	continue_button.text = LanguageManager.tr_key("ui_continue")
	continue_button.disabled = true
	continue_button.custom_minimum_size = Vector2(240, 58)
	continue_button.add_theme_font_size_override("font_size", 26)
	continue_button.pressed.connect(_on_continue_pressed)
	box.add_child(continue_button)


func _prepare_rewards() -> void:
	if not RunManager.pending_chapter_reward:
		result_label.text = LanguageManager.tr_key("chapter_reward_none_pending")
		continue_button.disabled = false
		return

	if RunManager.chapter_reward_claimed:
		result_label.text = LanguageManager.tr_key("chapter_reward_already_claimed")
		continue_button.disabled = false
		return

	var pool := _reward_pool()
	pool.shuffle()
	var used_ids: Array[String] = []
	for reward in pool:
		var resolved := _resolve_reward(reward)
		var reward_id := str(resolved.get("id", ""))
		if reward_id == "" or used_ids.has(reward_id):
			continue
		reward_options.append(resolved)
		used_ids.append(reward_id)
		if reward_options.size() >= 3:
			break

	while reward_options.size() < 3:
		var fallback := _gold_reward(100 + reward_options.size() * 25)
		fallback["id"] = "fallback_gold_%d" % reward_options.size()
		reward_options.append(fallback)


func _refresh_view() -> void:
	subtitle_label.text = _chapter_subtitle()
	_refresh_status_label()

	for child in rewards_container.get_children():
		child.queue_free()

	if RunManager.chapter_reward_claimed:
		return

	for reward in reward_options:
		rewards_container.add_child(_make_reward_card(reward))


func _refresh_language_texts() -> void:
	if title_label != null:
		title_label.text = LanguageManager.tr_key("chapter_reward_title")
	if continue_button != null:
		continue_button.text = LanguageManager.tr_key("ui_continue")
	_refresh_view()


func _refresh_status_label() -> void:
	status_label.text = LanguageManager.tr_format("chapter_reward_status", {
		"hp": RunManager.player_current_health,
		"max_hp": RunManager.player_max_health,
		"gold": RunManager.get_gold(),
		"fate": RunManager.get_fate_score(),
	})


func _reward_name(reward: Dictionary) -> String:
	return LanguageManager.tr_key(str(reward.get("name_key", "chapter_reward.reward")))


func _reward_description(reward: Dictionary) -> String:
	var key := str(reward.get("description_key", ""))
	if key == "chapter_reward.gold_fallback.desc":
		return LanguageManager.tr_format(key, {"amount": int(reward.get("amount", 0))})
	return LanguageManager.tr_key(key)


func _make_reward_card(reward: Dictionary) -> Control:
	var card := PanelContainer.new()
	card.custom_minimum_size = Vector2(340, 360)
	card.add_theme_stylebox_override("panel", _reward_style(false))

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 18)
	margin.add_theme_constant_override("margin_top", 18)
	margin.add_theme_constant_override("margin_right", 18)
	margin.add_theme_constant_override("margin_bottom", 18)
	card.add_child(margin)

	var box := VBoxContainer.new()
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_theme_constant_override("separation", 12)
	margin.add_child(box)

	var icon := _make_reward_icon(reward)
	box.add_child(icon)

	var name_label := Label.new()
	name_label.text = _reward_name(reward)
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.add_theme_font_size_override("font_size", 26)
	name_label.add_theme_color_override("font_color", Color(1.0, 0.9, 0.62))
	box.add_child(name_label)

	var desc_label := Label.new()
	desc_label.text = _reward_description(reward)
	desc_label.custom_minimum_size = Vector2(280, 96)
	desc_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc_label.add_theme_font_size_override("font_size", 19)
	desc_label.add_theme_color_override("font_color", Color(0.9, 0.86, 0.78))
	box.add_child(desc_label)

	var button := Button.new()
	button.text = LanguageManager.tr_key("ui_choose")
	button.custom_minimum_size = Vector2(190, 50)
	button.add_theme_font_size_override("font_size", 22)
	button.pressed.connect(_on_reward_selected.bind(reward, card))
	box.add_child(button)

	return card


func _on_reward_selected(reward: Dictionary, selected_card: PanelContainer) -> void:
	if RunManager.chapter_reward_claimed:
		return

	var result := _apply_reward(reward)
	RunManager.chapter_reward_claimed = true
	result_label.text = LanguageManager.tr_format("chapter_reward_selected", {"reward": _reward_name(reward), "result": result})
	continue_button.disabled = false

	for child in rewards_container.get_children():
		if child is PanelContainer:
			child.add_theme_stylebox_override("panel", _reward_style(child == selected_card))
		for nested in child.find_children("*", "Button", true, false):
			if nested is Button:
				nested.disabled = true

	SaveManager.save_run()
	_refresh_status_label()


func _on_continue_pressed() -> void:
	AudioManager.play_sfx("ui_click")
	if RunManager.pending_chapter_reward:
		if RunManager.complete_chapter_reward_and_advance():
			if RunManager.pending_chapter_intro:
				get_tree().change_scene_to_file(RunManager.CHAPTER4_INTRO_SCENE_PATH)
				return
			get_tree().change_scene_to_file(RunManager.MAP_SCENE_PATH)
			return
		push_warning("[ChapterReward] Failed to advance after reward.")
	get_tree().change_scene_to_file(RunManager.VICTORY_SCENE_PATH)


func _reward_pool() -> Array[Dictionary]:
	return [
		{"id": "gold_150", "name_key": "chapter_reward.gold.name", "description_key": "chapter_reward.gold.desc", "type": "gold", "amount": 150},
		{"id": "relic", "name_key": "chapter_reward.relic.name", "description_key": "chapter_reward.relic.desc", "type": "relic", "fallback_gold": 100},
		{"id": "special_card", "name_key": "chapter_reward.special_card.name", "description_key": "chapter_reward.special_card.desc", "type": "special_card", "fallback_gold": 100},
		{"id": "max_hp", "name_key": "chapter_reward.max_hp.name", "description_key": "chapter_reward.max_hp.desc", "type": "max_hp", "amount": 15},
		{"id": "upgrade_two", "name_key": "chapter_reward.upgrade_two.name", "description_key": "chapter_reward.upgrade_two.desc", "type": "upgrade_two", "fallback_gold": 80},
		{"id": "remove_basic", "name_key": "chapter_reward.remove_basic.name", "description_key": "chapter_reward.remove_basic.desc", "type": "remove_basic", "fallback_gold": 80},
		{"id": "fate_ember", "name_key": "chapter_reward.fate_ember.name", "description_key": "chapter_reward.fate_ember.desc", "type": "fate_ember", "fallback_gold": 120},
		{"id": "supply", "name_key": "chapter_reward.supply.name", "description_key": "chapter_reward.supply.desc", "type": "supply", "amount": 80},
	]


func _resolve_reward(reward: Dictionary) -> Dictionary:
	var reward_type := str(reward.get("type", ""))
	match reward_type:
		"relic":
			if RelicManager.get_unowned_relics().is_empty():
				return _gold_reward(int(reward.get("fallback_gold", 100)))
		"special_card":
			if _get_unowned_special_cards().is_empty():
				return _gold_reward(int(reward.get("fallback_gold", 100)))
		"upgrade_two":
			if RunManager.get_upgradeable_deck_entries().is_empty():
				return _gold_reward(int(reward.get("fallback_gold", 80)))
		"remove_basic":
			if not _has_removable_basic_card():
				return _gold_reward(int(reward.get("fallback_gold", 80)))
		"fate_ember":
			if RelicManager.has_relic(RelicManager.FATE_EMBER_ID):
				return _gold_reward(int(reward.get("fallback_gold", 120)))
	return reward


func _gold_reward(amount: int) -> Dictionary:
	return {"id": "gold_%d" % amount, "name_key": "chapter_reward.gold_fallback.name", "description_key": "chapter_reward.gold_fallback.desc", "type": "gold", "amount": amount}


func _apply_reward(reward: Dictionary) -> String:
	var reward_type := str(reward.get("type", ""))
	match reward_type:
		"gold":
			var amount := int(reward.get("amount", 0))
			RunManager.add_gold(amount)
			return LanguageManager.tr_format("chapter_reward.result_gold", {"amount": amount})
		"relic":
			return _grant_random_relic()
		"special_card":
			return _grant_random_special_card()
		"max_hp":
			var amount := int(reward.get("amount", 15))
			RunManager.player_max_health += amount
			RunManager.player_current_health = min(RunManager.player_current_health + amount, RunManager.player_max_health)
			return LanguageManager.tr_format("chapter_reward.result_max_hp", {"amount": amount})
		"upgrade_two":
			var upgraded: Array[String] = []
			for index in range(2):
				var card := RunManager.upgrade_random_basic_card()
				if card != null:
					upgraded.append(card.get_display_name())
			if upgraded.is_empty():
				RunManager.add_gold(80)
				return LanguageManager.tr_format("chapter_reward.result_fallback_gold", {"amount": 80})
			return LanguageManager.tr_format("chapter_reward.result_upgrade", {"cards": ", ".join(upgraded)})
		"remove_basic":
			var removed := RunManager.remove_random_basic_card_from_run()
			if removed == null:
				RunManager.add_gold(80)
				return LanguageManager.tr_format("chapter_reward.result_fallback_gold", {"amount": 80})
			return LanguageManager.tr_format("chapter_reward.result_remove", {"card": removed.get_display_name()})
		"fate_ember":
			if RelicManager.has_relic(RelicManager.FATE_EMBER_ID):
				RunManager.add_gold(120)
				return LanguageManager.tr_format("chapter_reward.result_fallback_gold", {"amount": 120})
			RelicManager.add_relic(RelicManager.FATE_EMBER_ID)
			var fate_ember := RelicManager.get_relic(RelicManager.FATE_EMBER_ID)
			return LanguageManager.tr_format("chapter_reward.result_relic", {"relic": fate_ember.get_display_name() if fate_ember != null else LanguageManager.tr_key("relic.fate_ember.name")})
		"supply":
			var amount := int(reward.get("amount", 80))
			RunManager.player_current_health = RunManager.player_max_health
			RunManager.add_gold(amount)
			return LanguageManager.tr_format("chapter_reward.result_supply", {"amount": amount})
	return LanguageManager.tr_key("chapter_reward.result_no_effect")


func _grant_random_relic() -> String:
	var relics := RelicManager.get_unowned_relics()
	if relics.is_empty():
		RunManager.add_gold(100)
		return LanguageManager.tr_format("chapter_reward.result_fallback_gold", {"amount": 100})
	var relic: RelicData = relics.pick_random()
	RelicManager.add_relic(relic.relic_id)
	return LanguageManager.tr_format("chapter_reward.result_relic", {"relic": relic.get_display_name()})


func _grant_random_special_card() -> String:
	var cards := _get_unowned_special_cards()
	if cards.is_empty():
		RunManager.add_gold(100)
		return LanguageManager.tr_format("chapter_reward.result_fallback_gold", {"amount": 100})
	var card: CardData = cards.pick_random()
	PlayerCardCollection.add_card(card.card_id, 1)
	return LanguageManager.tr_format("chapter_reward.result_special_card", {"card": card.get_display_name()})


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


func _chapter_subtitle() -> String:
	match RunManager.last_completed_chapter:
		1:
			return LanguageManager.tr_key("chapter_reward.subtitle_ch1")
		2:
			return LanguageManager.tr_key("chapter_reward.subtitle_ch2")
		3:
			return LanguageManager.tr_key("chapter_reward.subtitle_ch3")
		_:
			return LanguageManager.tr_key("chapter_reward.subtitle_default")


func _make_reward_icon(reward: Dictionary) -> Control:
	var icon_path := _reward_icon_path(reward)
	var texture := _load_texture(icon_path)
	if texture != null:
		var rect := TextureRect.new()
		rect.custom_minimum_size = Vector2(138, 118)
		rect.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		rect.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
		rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		rect.texture = texture
		return rect

	var fallback := Label.new()
	fallback.text = "*"
	fallback.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	fallback.add_theme_font_size_override("font_size", 52)
	fallback.add_theme_color_override("font_color", Color(1.0, 0.76, 0.34))
	return fallback


func _reward_icon_path(reward: Dictionary) -> String:
	var reward_id: String = str(reward.get("id", ""))
	var reward_type: String = str(reward.get("type", ""))
	if REWARD_ICON_PATHS.has(reward_id):
		return str(REWARD_ICON_PATHS[reward_id])
	if REWARD_ICON_PATHS.has(reward_type):
		return str(REWARD_ICON_PATHS[reward_type])
	if reward_type == "gold" or reward_id.begins_with("gold_") or reward_id.begins_with("fallback_gold_"):
		return str(REWARD_ICON_PATHS["gold"])
	return ""


func _load_texture(path: String) -> Texture2D:
	if path.is_empty() or not ResourceLoader.exists(path):
		push_warning("[ChapterReward] missing icon: " + path)
		return null
	var resource: Resource = load(path)
	var texture: Texture2D = resource as Texture2D
	if texture == null:
		push_warning("[ChapterReward] icon load failed: " + path)
	return texture


func _panel_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.075, 0.058, 0.095, 0.94)
	style.border_color = Color(0.82, 0.62, 0.3, 0.95)
	style.set_border_width_all(2)
	style.set_corner_radius_all(10)
	return style


func _reward_style(selected: bool) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.14, 0.11, 0.16, 0.98) if selected else Color(0.085, 0.075, 0.105, 0.96)
	style.border_color = Color(1.0, 0.82, 0.28, 1.0) if selected else Color(0.48, 0.38, 0.24, 0.9)
	style.set_border_width_all(3 if selected else 1)
	style.set_corner_radius_all(8)
	return style
