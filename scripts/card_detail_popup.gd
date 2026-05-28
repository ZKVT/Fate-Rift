extends PopupPanel
class_name CardDetailPopup

@onready var art_texture: TextureRect = $PanelContainer/MarginContainer/VBoxContainer/ArtTexture
@onready var name_label: Label = $PanelContainer/MarginContainer/VBoxContainer/NameLabel
@onready var cost_label: Label = $PanelContainer/MarginContainer/VBoxContainer/CostLabel
@onready var type_label: Label = $PanelContainer/MarginContainer/VBoxContainer/TypeLabel
@onready var description_label: Label = $PanelContainer/MarginContainer/VBoxContainer/DescriptionLabel
@onready var close_button: Button = $PanelContainer/MarginContainer/VBoxContainer/CloseButton

var current_card: CardData


func _ready() -> void:
	close_button.pressed.connect(_on_close_pressed)
	if not LanguageManager.language_changed.is_connected(_refresh_language_texts):
		LanguageManager.language_changed.connect(_refresh_language_texts)


# Shows a larger card preview.
func show_card(card: CardData) -> void:
	if card == null:
		return
	current_card = card
	art_texture.texture = card.get_art_texture()
	_refresh_language_texts()
	popup_centered(Vector2i(360, 560))


func _refresh_language_texts() -> void:
	if current_card == null:
		return
	name_label.text = current_card.get_display_name()
	cost_label.text = "%s: %d" % [LanguageManager.tr_key("ui_cost"), current_card.cost]
	type_label.text = "%s: %s" % [LanguageManager.tr_key("ui_type"), _card_type_text(current_card)]
	description_label.text = current_card.get_display_description()
	close_button.text = LanguageManager.tr_key("ui_close")


func _on_close_pressed() -> void:
	AudioManager.play_sfx("ui_click")
	hide()


func _card_type_text(card: CardData) -> String:
	match card.card_type:
		CardData.CardType.ATTACK:
			return LanguageManager.tr_key("card_type.attack")
		CardData.CardType.SKILL:
			return LanguageManager.tr_key("card_type.skill")
		CardData.CardType.POWER:
			return LanguageManager.tr_key("card_type.power")
	return LanguageManager.tr_key("ui_unknown")
