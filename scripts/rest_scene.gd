extends Control

const REST_BACKGROUND_PATH := "res://assets/ui/rest/rest_background.png"
const HEAL_ICON_PATH := "res://assets/ui/rest/heal_icon.png"
const UPGRADE_CARD_ICON_PATH := "res://assets/ui/rest/upgrade_card_icon.png"

@onready var panel: PanelContainer = $Panel
@onready var title_label: Label = $Panel/MarginContainer/VBoxContainer/TitleLabel
@onready var health_label: Label = $Panel/MarginContainer/VBoxContainer/HealthLabel
@onready var message_label: Label = $Panel/MarginContainer/VBoxContainer/MessageLabel
@onready var rest_button: Button = $Panel/MarginContainer/VBoxContainer/RestButton
@onready var continue_button: Button = $Panel/MarginContainer/VBoxContainer/ContinueButton

var upgrade_button: Button
var edit_deck_button: Button
var upgrade_list: VBoxContainer
var has_chosen := false


func _ready() -> void:
	rest_button.pressed.connect(_on_rest_button_pressed)
	continue_button.pressed.connect(_on_continue_button_pressed)
	if not LanguageManager.language_changed.is_connected(_refresh_language_texts):
		LanguageManager.language_changed.connect(_refresh_language_texts)
	_apply_style()
	_create_upgrade_controls()
	_apply_assets()
	_refresh_language_texts()
	_refresh_health()

	if RunManager.get_current_map_node_type() != RunManager.NODE_REST:
		message_label.text = LanguageManager.tr_key("rest_invalid_node")
		_disable_choices()
		return

	if RunManager.is_current_map_node_completed():
		has_chosen = true
		message_label.text = LanguageManager.tr_key("rest_used")
		_disable_choices()
		return

	if RunManager.rest_state_node_id == RunManager.current_map_node_id and RunManager.rest_option_used:
		has_chosen = true
		message_label.text = LanguageManager.tr_key("rest_resume_used")
		_disable_choices()
		return

	message_label.text = LanguageManager.tr_key("rest_choose_prompt")
	continue_button.disabled = false


func _create_upgrade_controls() -> void:
	var parent := rest_button.get_parent()
	upgrade_button = Button.new()
	upgrade_button.custom_minimum_size = Vector2(270, 64)
	upgrade_button.add_theme_font_size_override("font_size", 26)
	upgrade_button.pressed.connect(_on_upgrade_button_pressed)
	parent.add_child(upgrade_button)
	parent.move_child(upgrade_button, rest_button.get_index() + 1)

	edit_deck_button = Button.new()
	edit_deck_button.custom_minimum_size = Vector2(270, 64)
	edit_deck_button.add_theme_font_size_override("font_size", 26)
	edit_deck_button.pressed.connect(_on_edit_deck_button_pressed)
	parent.add_child(edit_deck_button)
	parent.move_child(edit_deck_button, upgrade_button.get_index() + 1)

	upgrade_list = VBoxContainer.new()
	upgrade_list.add_theme_constant_override("separation", 8)
	parent.add_child(upgrade_list)
	parent.move_child(upgrade_list, edit_deck_button.get_index() + 1)


func _on_rest_button_pressed() -> void:
	AudioManager.play_sfx("ui_click")
	if has_chosen:
		return

	has_chosen = true
	RunManager.rest_state_node_id = RunManager.current_map_node_id
	RunManager.rest_option_used = true
	var healed := RunManager.rest_at_current_node()
	_refresh_health()
	message_label.text = LanguageManager.tr_format("rest_healed", {"amount": healed})
	_disable_choices()
	SaveManager.save_run()


func _on_upgrade_button_pressed() -> void:
	AudioManager.play_sfx("ui_click")
	if has_chosen:
		return
	_show_upgrade_list()


func _show_upgrade_list() -> void:
	for child in upgrade_list.get_children():
		child.queue_free()

	var entries := RunManager.get_upgradeable_deck_entries()
	if entries.is_empty():
		message_label.text = LanguageManager.tr_key("rest_no_upgrade_cards")
		return

	message_label.text = LanguageManager.tr_key("rest_choose_upgrade")
	for entry in entries:
		var deck_index := int(entry["deck_index"])
		var button := Button.new()
		button.text = "%s -> %s\n%s -> %s" % [
			str(entry["card_name"]),
			str(entry["upgraded_name"]),
			str(entry["description"]),
			str(entry["upgraded_description"]),
		]
		button.custom_minimum_size = Vector2(520, 72)
		button.add_theme_font_size_override("font_size", 18)
		button.pressed.connect(_on_upgrade_card_selected.bind(deck_index))
		upgrade_list.add_child(button)


func _on_upgrade_card_selected(deck_index: int) -> void:
	if has_chosen:
		return

	var upgraded_card := RunManager.upgrade_deck_card(deck_index)
	if upgraded_card == null:
		message_label.text = LanguageManager.tr_key("rest_cannot_upgrade")
		return

	has_chosen = true
	RunManager.rest_state_node_id = RunManager.current_map_node_id
	RunManager.rest_option_used = true
	message_label.text = LanguageManager.tr_format("rest_upgraded", {"card": upgraded_card.get_display_name()})
	_disable_choices()
	for child in upgrade_list.get_children():
		child.queue_free()


func _disable_choices() -> void:
	rest_button.disabled = true
	if upgrade_button != null:
		upgrade_button.disabled = true
	continue_button.disabled = false


func _on_continue_button_pressed() -> void:
	AudioManager.play_sfx("ui_click")
	RunManager.complete_current_map_node()
	RunManager.rest_state_node_id = ""
	RunManager.rest_option_used = false
	SaveManager.save_run()
	get_tree().change_scene_to_file(RunManager.MAP_SCENE_PATH)


func _on_edit_deck_button_pressed() -> void:
	AudioManager.play_sfx("ui_click")
	RunManager.prepare_deck_builder_edit(RunManager.REST_SCENE_PATH)
	SaveManager.save_run()
	get_tree().change_scene_to_file("res://scenes/DeckBuilderScene.tscn")


func _refresh_health() -> void:
	health_label.text = LanguageManager.tr_format("rest_health", {
		"current": RunManager.player_current_health,
		"max": RunManager.player_max_health,
	})


func _refresh_language_texts() -> void:
	title_label.text = LanguageManager.tr_key("rest_title")
	rest_button.text = LanguageManager.tr_key("rest_heal")
	continue_button.text = LanguageManager.tr_key("ui_continue")
	if upgrade_button != null:
		upgrade_button.text = LanguageManager.tr_key("rest_upgrade")
	if edit_deck_button != null:
		edit_deck_button.text = LanguageManager.tr_key("rest_edit_deck")
	_refresh_health()


func _apply_style() -> void:
	panel.offset_left = -430
	panel.offset_top = -300
	panel.offset_right = 430
	panel.offset_bottom = 300

	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.075, 0.06, 0.085, 0.84)
	style.border_color = Color(0.78, 0.62, 0.38, 0.78)
	style.set_border_width_all(1)
	style.set_corner_radius_all(10)
	style.content_margin_left = 42
	style.content_margin_top = 34
	style.content_margin_right = 42
	style.content_margin_bottom = 34
	panel.add_theme_stylebox_override("panel", style)

	title_label.add_theme_font_size_override("font_size", 52)
	title_label.add_theme_color_override("font_color", Color(1.0, 0.86, 0.58))
	health_label.add_theme_font_size_override("font_size", 32)
	health_label.add_theme_color_override("font_color", Color(0.72, 1.0, 0.78))
	message_label.custom_minimum_size = Vector2(680, 72)
	message_label.add_theme_font_size_override("font_size", 25)
	message_label.add_theme_color_override("font_color", Color(0.92, 0.9, 0.8))
	rest_button.custom_minimum_size = Vector2(270, 64)
	rest_button.add_theme_font_size_override("font_size", 26)
	continue_button.add_theme_font_size_override("font_size", 26)


func _apply_assets() -> void:
	var background_texture := _make_texture_rect(REST_BACKGROUND_PATH, Vector2.ZERO)
	if background_texture.texture != null:
		background_texture.set_anchors_preset(Control.PRESET_FULL_RECT)
		background_texture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		background_texture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		add_child(background_texture)
		move_child(background_texture, 1)

	var shade := ColorRect.new()
	shade.color = Color(0.02, 0.025, 0.035, 0.36)
	shade.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(shade)
	move_child(shade, 2)

	var parent := rest_button.get_parent()
	var heal_icon := _make_texture_rect(HEAL_ICON_PATH, Vector2(120, 120))
	heal_icon.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	parent.add_child(heal_icon)
	parent.move_child(heal_icon, rest_button.get_index())

	if upgrade_button != null:
		var upgrade_icon := _make_texture_rect(UPGRADE_CARD_ICON_PATH, Vector2(120, 120))
		upgrade_icon.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		parent.add_child(upgrade_icon)
		parent.move_child(upgrade_icon, upgrade_button.get_index())


func _make_texture_rect(path: String, minimum_size: Vector2) -> TextureRect:
	var rect := TextureRect.new()
	rect.custom_minimum_size = minimum_size
	rect.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
	rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	var texture: Texture2D = _load_texture(path)
	if texture != null:
		rect.texture = texture
	return rect


func _load_texture(path: String) -> Texture2D:
	if path.is_empty() or not ResourceLoader.exists(path):
		push_warning("[Rest UI] missing texture: " + path)
		return null
	var resource: Resource = load(path)
	var texture: Texture2D = resource as Texture2D
	if texture == null:
		push_warning("[Rest UI] texture load failed: " + path)
	return texture
