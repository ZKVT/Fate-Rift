extends Control

const MAIN_MENU_SCENE_PATH := "res://scenes/MainMenu.tscn"
const DEFEAT_BACKGROUND_PATH := "res://assets/ui/endings/defeat.png"


func _ready() -> void:
	if not LanguageManager.language_changed.is_connected(_rebuild_for_language):
		LanguageManager.language_changed.connect(_rebuild_for_language)
	_build_ui()


func _rebuild_for_language() -> void:
	for child in get_children():
		child.queue_free()
	_build_ui()


func _build_ui() -> void:
	var fallback_background := ColorRect.new()
	fallback_background.color = Color(0.055, 0.035, 0.04, 1.0)
	fallback_background.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(fallback_background)

	var background := _make_background(DEFEAT_BACKGROUND_PATH)
	if background.texture != null:
		add_child(background)

	var shade := ColorRect.new()
	shade.color = Color(0.025, 0.012, 0.014, 0.42)
	shade.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(shade)

	var panel := PanelContainer.new()
	panel.set_anchors_preset(Control.PRESET_CENTER)
	panel.offset_left = -370.0
	panel.offset_top = -255.0
	panel.offset_right = 370.0
	panel.offset_bottom = 255.0
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
	title.text = LanguageManager.tr_key("ending.defeat.title")
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 54)
	title.add_theme_color_override("font_color", Color(1.0, 0.48, 0.38))
	content.add_child(title)

	var description := Label.new()
	description.text = LanguageManager.tr_key("ending.defeat.desc")
	description.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	description.add_theme_font_size_override("font_size", 26)
	description.add_theme_color_override("font_color", Color(0.92, 0.84, 0.78))
	content.add_child(description)

	var summary := Label.new()
	summary.text = _summary_text()
	summary.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	summary.add_theme_font_size_override("font_size", 24)
	summary.add_theme_color_override("font_color", Color(0.82, 0.88, 1.0))
	content.add_child(summary)

	var button := Button.new()
	button.text = LanguageManager.tr_key("battle_return_main_menu")
	button.custom_minimum_size = Vector2(220, 56)
	button.add_theme_font_size_override("font_size", 24)
	button.pressed.connect(_on_main_menu_pressed)
	content.add_child(button)


func _summary_text() -> String:
	return LanguageManager.tr_format("ending.defeat.summary", {
		"difficulty": _difficulty_name(RunManager.current_difficulty),
		"chapter": RunManager.current_chapter,
		"gold": RunManager.get_gold(),
		"relics": RunManager.relic_ids.size(),
		"cards": RunManager.selected_deck_card_ids.size(),
	})


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


func _panel_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.095, 0.055, 0.06, 0.84)
	style.border_color = Color(0.78, 0.24, 0.18, 0.92)
	style.set_border_width_all(2)
	style.set_corner_radius_all(10)
	return style


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
		push_warning("[DefeatScene] missing background: " + path)
		return null
	var resource: Resource = load(path)
	var texture: Texture2D = resource as Texture2D
	if texture == null:
		push_warning("[DefeatScene] background load failed: " + path)
	return texture


func _on_main_menu_pressed() -> void:
	var audio_manager := get_node_or_null("/root/AudioManager")
	if audio_manager != null and audio_manager.has_method("play_sfx"):
		audio_manager.play_sfx("ui_click")
	get_tree().change_scene_to_file(MAIN_MENU_SCENE_PATH)
