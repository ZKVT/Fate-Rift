extends Control

const MAIN_MENU_SCENE_PATH := "res://scenes/MainMenu.tscn"
const NORMAL_VICTORY_BACKGROUND_PATH := "res://assets/ui/endings/normal_victory.png"
const STAR_ENDING_BACKGROUND_PATH := "res://assets/ui/endings/star_ending.png"
const ABYSS_ENDING_BACKGROUND_PATH := "res://assets/ui/endings/abyss_ending.png"

var difficulty_unlock_message := ""


func _ready() -> void:
	difficulty_unlock_message = SaveManager.unlock_next_difficulty_after_clear(RunManager.current_difficulty)
	if not LanguageManager.language_changed.is_connected(_rebuild_for_language):
		LanguageManager.language_changed.connect(_rebuild_for_language)
	_build_ui()


func _rebuild_for_language() -> void:
	for child in get_children():
		child.queue_free()
	_build_ui()


func _build_ui() -> void:
	var fallback_background := ColorRect.new()
	fallback_background.color = Color(0.04, 0.035, 0.07, 1.0)
	fallback_background.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(fallback_background)

	var background := _make_background(_ending_background_path())
	if background.texture != null:
		add_child(background)

	var shade := ColorRect.new()
	shade.color = Color(0.015, 0.012, 0.02, 0.35)
	shade.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(shade)

	var panel := PanelContainer.new()
	panel.set_anchors_preset(Control.PRESET_CENTER)
	panel.offset_left = -390.0
	panel.offset_top = -270.0
	panel.offset_right = 390.0
	panel.offset_bottom = 270.0
	panel.add_theme_stylebox_override("panel", _panel_style())
	add_child(panel)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 36)
	margin.add_theme_constant_override("margin_top", 34)
	margin.add_theme_constant_override("margin_right", 36)
	margin.add_theme_constant_override("margin_bottom", 34)
	panel.add_child(margin)

	var content := VBoxContainer.new()
	content.alignment = BoxContainer.ALIGNMENT_CENTER
	content.add_theme_constant_override("separation", 18)
	margin.add_child(content)

	var title := Label.new()
	title.text = _ending_title()
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 54)
	title.add_theme_color_override("font_color", Color(1.0, 0.86, 0.48))
	content.add_child(title)

	var description := Label.new()
	description.text = _ending_description()
	description.custom_minimum_size = Vector2(660, 110)
	description.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	description.add_theme_font_size_override("font_size", 26)
	description.add_theme_color_override("font_color", Color(0.9, 0.86, 0.76))
	content.add_child(description)

	var summary := Label.new()
	summary.text = _summary_text()
	summary.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	summary.add_theme_font_size_override("font_size", 24)
	summary.add_theme_color_override("font_color", Color(0.72, 0.9, 1.0))
	content.add_child(summary)

	var button := Button.new()
	button.text = "返回主菜单"
	button.custom_minimum_size = Vector2(220, 56)
	button.text = LanguageManager.tr_key("battle_return_main_menu")
	button.add_theme_font_size_override("font_size", 24)
	button.pressed.connect(_on_main_menu_pressed)
	content.add_child(button)


func _summary_text() -> String:
	return LanguageManager.tr_format("ending.summary", {
		"difficulty": _difficulty_name(RunManager.current_difficulty),
		"unlock": difficulty_unlock_message,
		"max_difficulty": _difficulty_name(SaveManager.get_unlocked_difficulty()),
		"gold": RunManager.get_gold(),
		"relics": RunManager.relic_ids.size(),
		"cards": RunManager.selected_deck_card_ids.size(),
		"fate": RunManager.get_fate_score(),
	})
	return "本次难度：%s\n%s\n当前最高解锁难度：%s\n最终金币：%d\n获得遗物：%d\n当前卡组：%d 张\n命运分数：%d" % [
		RunManager.difficulty_name(RunManager.current_difficulty),
		difficulty_unlock_message,
		RunManager.difficulty_name(SaveManager.get_unlocked_difficulty()),
		RunManager.get_gold(),
		RunManager.relic_ids.size(),
		RunManager.selected_deck_card_ids.size(),
		RunManager.get_fate_score(),
	]


func _difficulty_name(difficulty: int) -> String:
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


func _ending_title() -> String:
	match RunManager.ending_route:
		RunManager.ENDING_ROUTE_STAR:
			return LanguageManager.tr_key("ending.star.title")
		RunManager.ENDING_ROUTE_ABYSS:
			return LanguageManager.tr_key("ending.abyss.title")
		_:
			return LanguageManager.tr_key("ending.normal.title")
	match RunManager.ending_route:
		RunManager.ENDING_ROUTE_STAR:
			return "星辰结局"
		RunManager.ENDING_ROUTE_ABYSS:
			return "深渊结局"
		_:
			return "通关成功"


func _ending_description() -> String:
	match RunManager.ending_route:
		RunManager.ENDING_ROUTE_STAR:
			return LanguageManager.tr_key("ending.star.desc")
		RunManager.ENDING_ROUTE_ABYSS:
			return LanguageManager.tr_key("ending.abyss.desc")
		_:
			return LanguageManager.tr_key("ending.normal.desc")
	match RunManager.ending_route:
		RunManager.ENDING_ROUTE_STAR:
			return "你没有摧毁命运，而是选择接纳它。星辰重新排列，世界从崩塌边缘被拉回。"
		RunManager.ENDING_ROUTE_ABYSS:
			return "你夺取了命运的权柄，但深渊也回应了你的欲望。世界得救了，还是换了一个主人？"
		_:
			return "你击败了世界吞噬者，完成了这次冒险。"


func _ending_background_path() -> String:
	match RunManager.ending_route:
		RunManager.ENDING_ROUTE_STAR:
			return STAR_ENDING_BACKGROUND_PATH
		RunManager.ENDING_ROUTE_ABYSS:
			return ABYSS_ENDING_BACKGROUND_PATH
		_:
			return NORMAL_VICTORY_BACKGROUND_PATH


func _make_background(path: String) -> TextureRect:
	var rect := TextureRect.new()
	rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	var texture: Texture2D = _load_texture(path)
	if texture != null:
		rect.texture = texture
	return rect


func _load_texture(path: String) -> Texture2D:
	if path.is_empty() or not ResourceLoader.exists(path):
		push_warning("[VictoryScene] missing background: " + path)
		return null
	var resource: Resource = load(path)
	var texture: Texture2D = resource as Texture2D
	if texture == null:
		push_warning("[VictoryScene] background load failed: " + path)
	return texture


func _panel_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.055, 0.045, 0.075, 0.82)
	style.border_color = Color(0.86, 0.66, 0.32, 0.9)
	style.set_border_width_all(2)
	style.corner_radius_top_left = 10
	style.corner_radius_top_right = 10
	style.corner_radius_bottom_left = 10
	style.corner_radius_bottom_right = 10
	return style


func _on_main_menu_pressed() -> void:
	var audio_manager := get_node_or_null("/root/AudioManager")
	if audio_manager != null and audio_manager.has_method("play_sfx"):
		audio_manager.play_sfx("ui_click")
	get_tree().change_scene_to_file(MAIN_MENU_SCENE_PATH)
