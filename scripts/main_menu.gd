extends Control

const DECK_BUILDER_SCENE_PATH := "res://scenes/DeckBuilderScene.tscn"
const MENU_BACKGROUND_PATH := "res://assets/ui/menu/main_menu_background.png"
const FALLBACK_BACKGROUND_PATH := "res://assets/ui/main_menu_background.png"
const TITLE_FONT_PATH := "res://assets/fonts/title_font.ttf"
const UI_FONT_PATH := "res://assets/fonts/ui_font.ttf"

@onready var old_start_button: Button = $StartButton
@onready var old_continue_button: Button = $ContinueButton
@onready var old_delete_save_button: Button = $DeleteSaveButton
@onready var old_status_label: Label = $StatusLabel
@onready var old_background: TextureRect = $Background

var start_button: Button
var continue_button: Button
var delete_save_button: Button
var settings_button: Button
var exit_button: Button
var language_button: Button
var status_label: Label
var info_label: Label
var title_label: Label
var subtitle_label: Label
var difficulty_label: Label
var difficulty_title_label: Label
var confirm_overlay: Control
var confirm_title_label: Label
var confirm_message_label: Label
var confirm_accept_button: Button
var confirm_cancel_button: Button
var settings_overlay: Control
var settings_title_label: Label
var settings_text_label: Label
var settings_back_button: Button
var difficulty_buttons: Array[Button] = []
var selected_difficulty := 1
var pending_confirm_action := ""
var title_font: Font
var ui_font: Font


func _ready() -> void:
	_load_fonts()
	_hide_legacy_nodes()
	_build_ui()
	LanguageManager.language_changed.connect(refresh_language_texts)
	refresh_language_texts()
	_refresh_save_buttons()
	push_warning("[MainMenu] 如果仍看到白灰棋盘格，说明对应 PNG 本身带有棋盘格背景；当前主菜单已改用深色半透明 fallback 以保证可用。")


func _hide_legacy_nodes() -> void:
	var old_title := get_node_or_null("TitleLabel")
	for node in [old_start_button, old_continue_button, old_delete_save_button, old_status_label, old_title]:
		if node != null:
			node.visible = false


func _build_ui() -> void:
	_setup_background()

	var shade := ColorRect.new()
	shade.name = "DarkOverlay"
	shade.color = Color(0.01, 0.012, 0.02, 0.18)
	shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	shade.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(shade)

	language_button = _make_small_button("")
	language_button.name = "LanguageButton"
	language_button.anchor_left = 1.0
	language_button.anchor_top = 0.0
	language_button.anchor_right = 1.0
	language_button.anchor_bottom = 0.0
	language_button.offset_left = -454
	language_button.offset_top = 24
	language_button.offset_right = -150
	language_button.offset_bottom = 58
	language_button.pressed.connect(_on_language_button_pressed)
	add_child(language_button)

	var title_panel := _make_title_panel()
	title_panel.set_anchors_preset(Control.PRESET_TOP_LEFT)
	title_panel.offset_left = 72
	title_panel.offset_top = 58
	title_panel.offset_right = 552
	title_panel.offset_bottom = 188
	add_child(title_panel)

	var info_panel := _make_info_panel()
	info_panel.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	info_panel.offset_left = 72
	info_panel.offset_top = -260
	info_panel.offset_right = 540
	info_panel.offset_bottom = -64
	add_child(info_panel)

	var right_column := VBoxContainer.new()
	right_column.name = "MenuButtonArea"
	right_column.anchor_left = 1.0
	right_column.anchor_top = 0.0
	right_column.anchor_right = 1.0
	right_column.anchor_bottom = 1.0
	right_column.offset_left = -500
	right_column.offset_top = 108
	right_column.offset_right = -104
	right_column.offset_bottom = -74
	right_column.add_theme_constant_override("separation", 13)
	add_child(right_column)

	right_column.add_child(_make_difficulty_panel())

	continue_button = _make_menu_button("")
	continue_button.pressed.connect(_on_continue_button_pressed)
	right_column.add_child(continue_button)

	start_button = _make_menu_button("")
	start_button.pressed.connect(_on_start_button_pressed)
	right_column.add_child(start_button)

	settings_button = _make_menu_button("")
	settings_button.pressed.connect(_on_settings_button_pressed)
	right_column.add_child(settings_button)

	delete_save_button = _make_menu_button("", true)
	delete_save_button.pressed.connect(_on_delete_save_button_pressed)
	right_column.add_child(delete_save_button)

	exit_button = _make_menu_button("")
	exit_button.pressed.connect(_on_exit_button_pressed)
	right_column.add_child(exit_button)

	status_label = Label.new()
	status_label.custom_minimum_size = Vector2(0, 58)
	status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_apply_text_style(status_label, 20, Color(0.95, 0.86, 0.62))
	right_column.add_child(status_label)

	_build_confirm_dialog()
	_build_settings_dialog()


func _setup_background() -> void:
	if old_background == null:
		return
	old_background.texture = _load_texture(_background_path())
	old_background.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	old_background.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	old_background.mouse_filter = Control.MOUSE_FILTER_IGNORE


func _make_title_panel() -> Control:
	var panel := _make_frame_panel(Vector2(480, 130))
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 26)
	margin.add_theme_constant_override("margin_right", 26)
	margin.add_theme_constant_override("margin_top", 18)
	margin.add_theme_constant_override("margin_bottom", 18)
	panel.add_child(margin)

	var box := VBoxContainer.new()
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	margin.add_child(box)

	title_label = Label.new()
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_apply_text_style(title_label, 50, Color(1.0, 0.87, 0.56), true)
	box.add_child(title_label)

	subtitle_label = Label.new()
	subtitle_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_apply_text_style(subtitle_label, 21, Color(0.84, 0.9, 1.0))
	box.add_child(subtitle_label)
	return panel


func _make_info_panel() -> Control:
	var panel := _make_frame_panel(Vector2(468, 196))
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 26)
	margin.add_theme_constant_override("margin_right", 26)
	margin.add_theme_constant_override("margin_top", 20)
	margin.add_theme_constant_override("margin_bottom", 20)
	panel.add_child(margin)

	info_label = Label.new()
	info_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	info_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_apply_text_style(info_label, 20, Color(0.9, 0.87, 0.76))
	margin.add_child(info_label)
	return panel


func _make_difficulty_panel() -> Control:
	var panel := _make_frame_panel(Vector2(360, 238))
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 18)
	margin.add_theme_constant_override("margin_right", 18)
	margin.add_theme_constant_override("margin_top", 14)
	margin.add_theme_constant_override("margin_bottom", 14)
	panel.add_child(margin)

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 8)
	margin.add_child(box)

	difficulty_title_label = Label.new()
	difficulty_title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_apply_text_style(difficulty_title_label, 23, Color(1.0, 0.86, 0.58))
	box.add_child(difficulty_title_label)

	difficulty_label = Label.new()
	difficulty_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_apply_text_style(difficulty_label, 16, Color(0.76, 0.9, 1.0))
	box.add_child(difficulty_label)

	difficulty_buttons.clear()
	for difficulty in range(RunManager.MIN_DIFFICULTY, RunManager.MAX_DIFFICULTY + 1):
		var button := _make_small_button("")
		button.pressed.connect(_on_difficulty_pressed.bind(difficulty))
		difficulty_buttons.append(button)
		box.add_child(button)
	return panel


func _make_menu_button(text: String, danger := false) -> Button:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size = Vector2(360, 54)
	button.focus_mode = Control.FOCUS_NONE
	button.alignment = HORIZONTAL_ALIGNMENT_CENTER
	_apply_text_style(button, 24, Color(1.0, 0.9, 0.68), false, danger)
	_apply_button_style(button, danger)
	return button


func _make_small_button(text: String) -> Button:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size = Vector2(304, 31)
	button.focus_mode = Control.FOCUS_NONE
	button.alignment = HORIZONTAL_ALIGNMENT_CENTER
	_apply_text_style(button, 16, Color(0.92, 0.88, 0.76))
	_apply_small_button_style(button)
	return button


func _on_language_button_pressed() -> void:
	_play_click()
	LanguageManager.toggle_language()


func refresh_language_texts() -> void:
	title_label.text = _tr("game_title")
	subtitle_label.text = _tr("game_subtitle")
	language_button.text = _tr("menu_language_switch")
	continue_button.text = _tr("menu_continue")
	start_button.text = _tr("menu_new_game")
	settings_button.text = _tr("menu_settings")
	delete_save_button.text = _tr("menu_delete_save")
	exit_button.text = _tr("menu_exit")
	difficulty_title_label.text = _tr("difficulty_title")
	confirm_accept_button.text = _tr("dialog_confirm")
	confirm_cancel_button.text = _tr("dialog_cancel")
	settings_title_label.text = _tr("settings_title")
	settings_text_label.text = _tr("settings_placeholder")
	settings_back_button.text = _tr("settings_back")
	_refresh_difficulty_buttons()
	_refresh_info_panel()


func _on_start_button_pressed() -> void:
	_play_click()
	if SaveManager.has_save():
		_show_confirm(_tr("dialog_overwrite_title"), _tr("dialog_overwrite_save"), "new_game")
		return
	_start_new_game()


func _on_continue_button_pressed() -> void:
	_play_click()
	if SaveManager.load_run():
		match RunManager.run_status:
			RunManager.RUN_STATUS_ACTIVE:
				if RunManager.pending_chapter_reward:
					get_tree().change_scene_to_file(RunManager.CHAPTER_REWARD_SCENE_PATH)
				elif RunManager.pending_chapter_intro:
					get_tree().change_scene_to_file(RunManager.CHAPTER4_INTRO_SCENE_PATH)
				else:
					get_tree().change_scene_to_file(RunManager.MAP_SCENE_PATH)
			RunManager.RUN_STATUS_FAILED:
				get_tree().change_scene_to_file(RunManager.DEFEAT_SCENE_PATH)
			RunManager.RUN_STATUS_COMPLETED:
				get_tree().change_scene_to_file(RunManager.VICTORY_SCENE_PATH)
			_:
				_set_status(_tr("status_no_save"))
	else:
		_set_status(_tr("status_no_save"))
	_refresh_save_buttons()


func _on_delete_save_button_pressed() -> void:
	_play_click()
	if not SaveManager.has_save():
		_set_status(_tr("status_no_delete_save"))
		_refresh_save_buttons()
		return
	_show_confirm(_tr("dialog_delete_title"), _tr("dialog_delete_save"), "delete_save")


func _on_difficulty_pressed(difficulty: int) -> void:
	if not SaveManager.is_difficulty_unlocked(difficulty):
		_set_status(_tr("status_difficulty_locked"))
		return
	selected_difficulty = difficulty
	RunManager.current_difficulty = selected_difficulty
	_play_click()
	_refresh_difficulty_buttons()


func _on_settings_button_pressed() -> void:
	_play_click()
	settings_overlay.visible = true


func _on_exit_button_pressed() -> void:
	_play_click()
	if OS.has_feature("web"):
		push_warning("[MainMenu] Web export cannot quit the browser tab.")
		_set_status(_tr("status_quit_unsupported"))
		return
	get_tree().quit()


func _start_new_game() -> void:
	RunManager.reset_run()
	RunManager.current_difficulty = selected_difficulty
	get_tree().change_scene_to_file(DECK_BUILDER_SCENE_PATH)


func _refresh_save_buttons() -> void:
	SaveManager.load_profile()
	var has_save := SaveManager.has_save()
	continue_button.disabled = not has_save
	delete_save_button.disabled = not has_save
	_refresh_difficulty_buttons()
	_refresh_info_panel()


func _refresh_difficulty_buttons() -> void:
	if difficulty_buttons.is_empty():
		return
	var unlocked := SaveManager.get_unlocked_difficulty()
	selected_difficulty = clamp(selected_difficulty, RunManager.MIN_DIFFICULTY, unlocked)
	RunManager.current_difficulty = selected_difficulty
	difficulty_label.text = "%s：%s" % [_tr("difficulty_unlocked_max"), _difficulty_name(unlocked)]
	for index in range(difficulty_buttons.size()):
		var difficulty := index + 1
		var button := difficulty_buttons[index]
		var is_unlocked := SaveManager.is_difficulty_unlocked(difficulty)
		var label := _difficulty_name(difficulty)
		if not is_unlocked:
			label += "（%s）" % _tr("difficulty_locked")
		elif difficulty == selected_difficulty:
			label = "◆ %s ◆" % label
		button.text = label
		button.disabled = not is_unlocked
		_apply_text_style(button, 16, Color(1.0, 0.88, 0.58) if difficulty == selected_difficulty else Color(0.92, 0.88, 0.76))


func _refresh_info_panel() -> void:
	var highest := _difficulty_name(SaveManager.get_unlocked_difficulty())
	if not SaveManager.has_save():
		info_label.text = "%s\n\n%s：%s" % [_tr("save_no_adventure"), _tr("difficulty_unlocked_max"), highest]
		return

	if not SaveManager.load_run():
		info_label.text = "%s\n\n%s：%s" % [_tr("save_read_failed"), _tr("difficulty_unlocked_max"), highest]
		return

	match RunManager.run_status:
		RunManager.RUN_STATUS_ACTIVE:
			info_label.text = "%s：%s\n%s：%s\n%s：%s\n%s：%d\n%s：%s\n\n%s：%s" % [
				_tr("save_current_adventure"),
				_tr("status_active"),
				_tr("save_chapter"),
				_chapter_name(RunManager.current_chapter),
				_tr("save_difficulty"),
				_difficulty_name(RunManager.current_difficulty),
				_tr("save_gold"),
				RunManager.get_gold(),
				_tr("save_status"),
				_tr("status_active"),
				_tr("difficulty_unlocked_max"),
				highest,
			]
		RunManager.RUN_STATUS_FAILED:
			info_label.text = "%s：%s\n%s\n\n%s：%s" % [_tr("save_current_adventure"), _tr("status_failed"), _tr("save_failed_hint"), _tr("difficulty_unlocked_max"), highest]
		RunManager.RUN_STATUS_COMPLETED:
			info_label.text = "%s：%s\n%s\n\n%s：%s" % [_tr("save_current_adventure"), _tr("status_completed"), _tr("save_completed_hint"), _tr("difficulty_unlocked_max"), highest]
		_:
			info_label.text = "%s\n\n%s：%s" % [_tr("save_no_adventure"), _tr("difficulty_unlocked_max"), highest]


func _chapter_name(chapter: int) -> String:
	match chapter:
		1:
			return _tr("chapter_1_name")
		2:
			return _tr("chapter_2_name")
		3:
			return _tr("chapter_3_name")
		4:
			return _tr("chapter_4_name")
	return _tr("chapter_unknown")


func _build_confirm_dialog() -> void:
	confirm_overlay = ColorRect.new()
	confirm_overlay.name = "ConfirmOverlay"
	confirm_overlay.visible = false
	confirm_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	confirm_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	(confirm_overlay as ColorRect).color = Color(0.0, 0.0, 0.0, 0.58)
	add_child(confirm_overlay)

	var panel := _make_frame_panel(Vector2(560, 260))
	panel.set_anchors_preset(Control.PRESET_CENTER)
	panel.offset_left = -280
	panel.offset_top = -130
	panel.offset_right = 280
	panel.offset_bottom = 130
	confirm_overlay.add_child(panel)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 36)
	margin.add_theme_constant_override("margin_right", 36)
	margin.add_theme_constant_override("margin_top", 28)
	margin.add_theme_constant_override("margin_bottom", 28)
	panel.add_child(margin)

	var box := VBoxContainer.new()
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_theme_constant_override("separation", 18)
	margin.add_child(box)

	confirm_title_label = Label.new()
	confirm_title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_apply_text_style(confirm_title_label, 34, Color(1.0, 0.82, 0.52), true)
	box.add_child(confirm_title_label)

	confirm_message_label = Label.new()
	confirm_message_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	confirm_message_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_apply_text_style(confirm_message_label, 22, Color(0.94, 0.9, 0.8))
	box.add_child(confirm_message_label)

	var buttons := HBoxContainer.new()
	buttons.alignment = BoxContainer.ALIGNMENT_CENTER
	buttons.add_theme_constant_override("separation", 22)
	box.add_child(buttons)

	confirm_accept_button = _make_menu_button("")
	confirm_accept_button.custom_minimum_size = Vector2(170, 50)
	confirm_accept_button.pressed.connect(_on_confirm_accept_pressed)
	buttons.add_child(confirm_accept_button)

	confirm_cancel_button = _make_menu_button("")
	confirm_cancel_button.custom_minimum_size = Vector2(170, 50)
	confirm_cancel_button.pressed.connect(_on_confirm_cancel_pressed)
	buttons.add_child(confirm_cancel_button)


func _build_settings_dialog() -> void:
	settings_overlay = ColorRect.new()
	settings_overlay.name = "SettingsOverlay"
	settings_overlay.visible = false
	settings_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	settings_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	(settings_overlay as ColorRect).color = Color(0.0, 0.0, 0.0, 0.55)
	add_child(settings_overlay)

	var panel := _make_frame_panel(Vector2(520, 260))
	panel.set_anchors_preset(Control.PRESET_CENTER)
	panel.offset_left = -260
	panel.offset_top = -130
	panel.offset_right = 260
	panel.offset_bottom = 130
	settings_overlay.add_child(panel)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 38)
	margin.add_theme_constant_override("margin_right", 38)
	margin.add_theme_constant_override("margin_top", 30)
	margin.add_theme_constant_override("margin_bottom", 30)
	panel.add_child(margin)

	var box := VBoxContainer.new()
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_theme_constant_override("separation", 18)
	margin.add_child(box)

	settings_title_label = Label.new()
	settings_title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_apply_text_style(settings_title_label, 36, Color(1.0, 0.84, 0.55), true)
	box.add_child(settings_title_label)

	settings_text_label = Label.new()
	settings_text_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	settings_text_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_apply_text_style(settings_text_label, 22, Color(0.92, 0.9, 0.82))
	box.add_child(settings_text_label)

	settings_back_button = _make_menu_button("")
	settings_back_button.custom_minimum_size = Vector2(200, 52)
	settings_back_button.pressed.connect(func() -> void:
		_play_click()
		settings_overlay.visible = false
	)
	box.add_child(settings_back_button)


func _show_confirm(title: String, message: String, action: String) -> void:
	pending_confirm_action = action
	confirm_title_label.text = title
	confirm_message_label.text = message
	confirm_overlay.visible = true


func _on_confirm_accept_pressed() -> void:
	_play_click()
	confirm_overlay.visible = false
	match pending_confirm_action:
		"new_game":
			_start_new_game()
		"delete_save":
			SaveManager.delete_save()
			RunManager.reset_run()
			_set_status(_tr("status_save_deleted"))
			_refresh_save_buttons()
	pending_confirm_action = ""


func _on_confirm_cancel_pressed() -> void:
	_play_click()
	confirm_overlay.visible = false
	pending_confirm_action = ""


func _set_status(text: String) -> void:
	if status_label != null:
		status_label.text = text


func _play_click() -> void:
	var audio_manager := get_node_or_null("/root/AudioManager")
	if audio_manager != null and audio_manager.has_method("play_sfx"):
		audio_manager.play_sfx("ui_click")


func _load_fonts() -> void:
	if ResourceLoader.exists(TITLE_FONT_PATH):
		title_font = load(TITLE_FONT_PATH) as Font
	else:
		push_warning("未找到自定义标题字体，使用默认字体 fallback。")
	if ResourceLoader.exists(UI_FONT_PATH):
		ui_font = load(UI_FONT_PATH) as Font
	else:
		push_warning("未找到自定义 UI 字体，使用默认字体 fallback。")


func _apply_text_style(control: Control, font_size: int, color: Color, title := false, danger := false) -> void:
	var font := title_font if title else ui_font
	if font != null:
		control.add_theme_font_override("font", font)
	control.add_theme_font_size_override("font_size", font_size)
	control.add_theme_color_override("font_color", Color(1.0, 0.68, 0.62) if danger else color)
	control.add_theme_color_override("font_disabled_color", Color(0.5, 0.5, 0.56))
	control.add_theme_color_override("font_outline_color", Color(0.04, 0.03, 0.02, 0.95))
	control.add_theme_constant_override("outline_size", 2)


func _apply_button_style(button: Button, danger := false) -> void:
	button.add_theme_stylebox_override("normal", _button_flat_style("normal", danger))
	button.add_theme_stylebox_override("hover", _button_flat_style("hover", danger))
	button.add_theme_stylebox_override("pressed", _button_flat_style("pressed", danger))
	button.add_theme_stylebox_override("disabled", _button_flat_style("disabled", danger))


func _apply_small_button_style(button: Button) -> void:
	button.add_theme_stylebox_override("normal", _button_flat_style("normal"))
	button.add_theme_stylebox_override("hover", _button_flat_style("hover"))
	button.add_theme_stylebox_override("pressed", _button_flat_style("pressed"))
	button.add_theme_stylebox_override("disabled", _button_flat_style("disabled"))


func _button_flat_style(state: String, danger := false) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	var base := Color(0.12, 0.1, 0.15, 0.72)
	var border := Color(0.75, 0.58, 0.3, 0.86)
	if danger:
		base = Color(0.22, 0.07, 0.075, 0.74)
		border = Color(0.9, 0.34, 0.28, 0.86)
	match state:
		"hover":
			base = base.lightened(0.12)
			border = border.lightened(0.12)
		"pressed":
			base = base.darkened(0.12)
			border = border.lightened(0.2)
		"disabled":
			base = Color(0.08, 0.08, 0.1, 0.42)
			border = Color(0.32, 0.32, 0.36, 0.48)
	style.bg_color = base
	style.border_color = border
	style.set_border_width_all(1)
	style.set_corner_radius_all(8)
	style.shadow_color = Color(0, 0, 0, 0.45)
	style.shadow_size = 8
	style.content_margin_left = 18
	style.content_margin_right = 18
	style.content_margin_top = 8
	style.content_margin_bottom = 8
	return style


func _make_frame_panel(minimum_size: Vector2) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.custom_minimum_size = minimum_size
	panel.add_theme_stylebox_override("panel", _frame_panel_style())
	return panel


func _frame_panel_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.035, 0.03, 0.055, 0.58)
	style.border_color = Color(0.82, 0.66, 0.36, 0.7)
	style.set_border_width_all(1)
	style.set_corner_radius_all(10)
	style.shadow_color = Color(0, 0, 0, 0.5)
	style.shadow_size = 14
	return style


func _background_path() -> String:
	if ResourceLoader.exists(MENU_BACKGROUND_PATH):
		return MENU_BACKGROUND_PATH
	push_warning("[MainMenu] missing menu/main_menu_background.png, using existing main_menu_background fallback.")
	return FALLBACK_BACKGROUND_PATH


func _load_texture(path: String) -> Texture2D:
	if path.is_empty() or not ResourceLoader.exists(path):
		push_warning("[MainMenu] missing texture: " + path)
		return null
	var resource: Resource = load(path)
	var texture: Texture2D = resource as Texture2D
	if texture == null:
		push_warning("[MainMenu] texture load failed: " + path)
	return texture


func _difficulty_name(difficulty: int) -> String:
	match difficulty:
		1:
			return _tr("difficulty_normal")
		2:
			return _tr("difficulty_advanced")
		3:
			return _tr("difficulty_hard")
		4:
			return _tr("difficulty_nightmare")
		5:
			return _tr("difficulty_final")
	return _tr("difficulty_unknown")


func _tr(key: String) -> String:
	return LanguageManager.tr_key(key)
