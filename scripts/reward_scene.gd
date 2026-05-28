extends Control

@onready var title_label: Label = $TitleLabel
@onready var card_art_texture: TextureRect = $RewardPanel/MarginContainer/VBoxContainer/CardArtTexture
@onready var card_name_label: Label = $RewardPanel/MarginContainer/VBoxContainer/CardNameLabel
@onready var cost_label: Label = $RewardPanel/MarginContainer/VBoxContainer/CostLabel
@onready var description_label: Label = $RewardPanel/MarginContainer/VBoxContainer/DescriptionLabel
@onready var message_label: Label = $RewardPanel/MarginContainer/VBoxContainer/MessageLabel
@onready var gold_label: Label = $RewardPanel/MarginContainer/VBoxContainer/GoldLabel
@onready var continue_button: Button = $BottomBar/ContinueButton

var rewarded_card: CardData


func _ready() -> void:
	AudioManager.play_sfx("reward")
	continue_button.pressed.connect(_on_continue_button_pressed)
	if not LanguageManager.language_changed.is_connected(_refresh_language_texts):
		LanguageManager.language_changed.connect(_refresh_language_texts)
	_apply_reward_style()
	_build_reward()
	_refresh_language_texts()


# Shows regular post-battle rewards: gold plus one basic card.
func _build_reward() -> void:
	title_label.text = LanguageManager.tr_key("reward_battle_title")
	cost_label.text = ""
	_refresh_gold_label()

	if not RunManager.has_active_run():
		card_art_texture.texture = null
		card_name_label.text = LanguageManager.tr_key("reward_no_active_title")
		description_label.text = LanguageManager.tr_key("reward_no_active_desc")
		message_label.text = ""
		gold_label.text = ""
		continue_button.disabled = true
		return

	rewarded_card = RunManager.claim_battle_card_reward()
	SaveManager.save_run()

	if rewarded_card == null:
		card_art_texture.texture = null
		card_name_label.text = LanguageManager.tr_key("reward_gold_title")
		description_label.text = LanguageManager.tr_key("reward_no_card_desc")
		message_label.text = ""
		return

	card_art_texture.texture = rewarded_card.get_art_texture()
	card_name_label.text = rewarded_card.get_display_name()
	cost_label.text = "%s: %d" % [LanguageManager.tr_key("ui_cost"), rewarded_card.cost]
	description_label.text = rewarded_card.get_display_description()
	message_label.text = LanguageManager.tr_key("reward_added_collection")


# Completes the current battle node and returns to the map.
func _on_continue_button_pressed() -> void:
	AudioManager.play_sfx("ui_click")
	RewardManager.clear_rewards()
	RunManager.complete_current_map_node()
	SaveManager.save_run()
	get_tree().change_scene_to_file(RunManager.MAP_SCENE_PATH)


func _refresh_language_texts() -> void:
	continue_button.text = LanguageManager.tr_key("ui_continue")
	title_label.text = LanguageManager.tr_key("reward_battle_title")
	_refresh_gold_label()
	if rewarded_card != null:
		card_name_label.text = rewarded_card.get_display_name()
		cost_label.text = "%s: %d" % [LanguageManager.tr_key("ui_cost"), rewarded_card.cost]
		description_label.text = rewarded_card.get_display_description()
		message_label.text = LanguageManager.tr_key("reward_added_collection")


func _apply_reward_style() -> void:
	title_label.add_theme_font_size_override("font_size", 44)
	title_label.add_theme_color_override("font_color", Color(1.0, 0.9, 0.68))
	title_label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.85))
	title_label.add_theme_constant_override("outline_size", 4)

	card_name_label.add_theme_font_size_override("font_size", 34)
	card_name_label.add_theme_color_override("font_color", Color(1.0, 0.84, 0.54))
	card_name_label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.9))
	card_name_label.add_theme_constant_override("outline_size", 3)

	cost_label.add_theme_font_size_override("font_size", 24)
	cost_label.add_theme_color_override("font_color", Color(0.45, 0.82, 1.0))
	description_label.add_theme_font_size_override("font_size", 24)
	description_label.add_theme_color_override("font_color", Color(0.94, 0.9, 0.78))
	message_label.add_theme_font_size_override("font_size", 22)
	message_label.add_theme_color_override("font_color", Color(0.55, 1.0, 0.66))
	gold_label.add_theme_font_size_override("font_size", 22)
	gold_label.add_theme_color_override("font_color", Color(1.0, 0.86, 0.36))
	continue_button.add_theme_font_size_override("font_size", 28)


func _refresh_gold_label() -> void:
	gold_label.text = LanguageManager.tr_format("reward_gold_line", {
		"reward": RunManager.battle_reward_gold,
		"current": RunManager.get_gold(),
	})
