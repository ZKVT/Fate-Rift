extends Control

@onready var title_label: Label = $TitleLabel
@onready var relic_icon_texture: TextureRect = $RelicPanel/MarginContainer/VBoxContainer/RelicIconTexture
@onready var relic_placeholder_label: Label = $RelicPanel/MarginContainer/VBoxContainer/RelicPlaceholderLabel
@onready var relic_name_label: Label = $RelicPanel/MarginContainer/VBoxContainer/RelicNameLabel
@onready var description_label: Label = $RelicPanel/MarginContainer/VBoxContainer/DescriptionLabel
@onready var gold_label: Label = $RelicPanel/MarginContainer/VBoxContainer/GoldLabel
@onready var take_button: Button = $BottomBar/TakeButton
@onready var skip_button: Button = $BottomBar/SkipButton

var offered_relic: RelicData
var has_chosen := false


func _ready() -> void:
	AudioManager.play_sfx("reward")
	if not LanguageManager.language_changed.is_connected(_refresh_language_texts):
		LanguageManager.language_changed.connect(_refresh_language_texts)
	take_button.pressed.connect(_on_take_button_pressed)
	skip_button.pressed.connect(_on_skip_button_pressed)
	_apply_reward_style()
	_refresh_language_texts()
	_refresh_gold_label()
	_build_reward()


func _refresh_language_texts() -> void:
	title_label.text = LanguageManager.tr_key("reward_relic_title")
	take_button.text = LanguageManager.tr_key("relic_reward_take")
	skip_button.text = LanguageManager.tr_key("ui_skip")
	_refresh_gold_label()
	if offered_relic != null:
		relic_name_label.text = offered_relic.get_display_name()
		description_label.text = offered_relic.get_display_description()


# Chooses one unowned relic to offer.
func _build_reward() -> void:
	offered_relic = RelicManager.get_random_unowned_relic()
	if offered_relic == null:
		relic_icon_texture.texture = null
		relic_placeholder_label.visible = true
		relic_name_label.text = LanguageManager.tr_key("relic_reward_all_collected")
		description_label.text = LanguageManager.tr_key("relic_reward_all_collected_desc")
		take_button.disabled = true
		return

	relic_icon_texture.texture = RelicManager.get_relic_icon(offered_relic)
	relic_placeholder_label.visible = offered_relic.icon == null and offered_relic.icon_path == ""
	relic_name_label.text = offered_relic.get_display_name()
	description_label.text = offered_relic.get_display_description()


# Adds the offered relic to this run, then continues the reward flow.
func _on_take_button_pressed() -> void:
	AudioManager.play_sfx("ui_click")
	if has_chosen or offered_relic == null:
		return

	has_chosen = true
	RelicManager.add_relic(offered_relic.relic_id)
	SaveManager.save_run()
	_go_after_relic_reward()


# Skips the relic reward and continues the reward flow.
func _on_skip_button_pressed() -> void:
	AudioManager.play_sfx("ui_click")
	if has_chosen:
		return

	has_chosen = true
	_go_after_relic_reward()


func _apply_reward_style() -> void:
	title_label.add_theme_font_size_override("font_size", 44)
	title_label.add_theme_color_override("font_color", Color(1.0, 0.9, 0.68))
	title_label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.85))
	title_label.add_theme_constant_override("outline_size", 4)

	relic_name_label.add_theme_font_size_override("font_size", 34)
	relic_name_label.add_theme_color_override("font_color", Color(1.0, 0.84, 0.54))
	relic_name_label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.9))
	relic_name_label.add_theme_constant_override("outline_size", 3)

	relic_placeholder_label.add_theme_font_size_override("font_size", 32)
	relic_placeholder_label.add_theme_color_override("font_color", Color(0.75, 0.82, 1.0))
	relic_placeholder_label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.9))
	relic_placeholder_label.add_theme_constant_override("outline_size", 3)

	description_label.add_theme_font_size_override("font_size", 25)
	description_label.add_theme_color_override("font_color", Color(0.94, 0.9, 0.78))
	gold_label.add_theme_font_size_override("font_size", 22)
	gold_label.add_theme_color_override("font_color", Color(1.0, 0.86, 0.36))

	take_button.add_theme_font_size_override("font_size", 28)
	skip_button.add_theme_font_size_override("font_size", 24)


func _go_after_relic_reward() -> void:
	if RunManager.get_current_map_node_type() == RunManager.NODE_RELIC_REWARD:
		RunManager.complete_current_map_node()
		SaveManager.save_run()
		get_tree().change_scene_to_file(RunManager.MAP_SCENE_PATH)
	else:
		get_tree().change_scene_to_file(RunManager.REWARD_SCENE_PATH)


func _refresh_gold_label() -> void:
	gold_label.text = LanguageManager.tr_format("reward_gold_line", {
		"reward": RunManager.battle_reward_gold,
		"current": RunManager.get_gold(),
	})
