extends Control
class_name DeckView

signal closed

@onready var title_label: Label = $Panel/MarginContainer/VBoxContainer/Header/TitleLabel
@onready var close_button: Button = $Panel/MarginContainer/VBoxContainer/Header/CloseButton
@onready var tab_container: TabContainer = $Panel/MarginContainer/VBoxContainer/TabContainer
@onready var full_deck_list: ItemList = $Panel/MarginContainer/VBoxContainer/TabContainer/FullDeck
@onready var draw_pile_list: ItemList = $Panel/MarginContainer/VBoxContainer/TabContainer/DrawPile
@onready var discard_pile_list: ItemList = $Panel/MarginContainer/VBoxContainer/TabContainer/DiscardPile
@onready var exhaust_pile_list: ItemList = $Panel/MarginContainer/VBoxContainer/TabContainer/ExhaustPile
@onready var card_detail_popup: CardDetailPopup = $CardDetailPopup

var deck_manager: DeckManager
var list_cards := {}


func _ready() -> void:
	visible = false
	close_button.pressed.connect(_on_close_pressed)
	full_deck_list.item_selected.connect(_on_card_selected.bind(full_deck_list))
	draw_pile_list.item_selected.connect(_on_card_selected.bind(draw_pile_list))
	discard_pile_list.item_selected.connect(_on_card_selected.bind(discard_pile_list))
	exhaust_pile_list.item_selected.connect(_on_card_selected.bind(exhaust_pile_list))
	if not LanguageManager.language_changed.is_connected(_refresh_language_texts):
		LanguageManager.language_changed.connect(_refresh_language_texts)
	_refresh_language_texts()


# Opens the deck viewer for the given DeckManager.
func open(manager: DeckManager) -> void:
	deck_manager = manager
	visible = true
	_refresh()


func _refresh() -> void:
	if deck_manager == null:
		return

	_fill_list(full_deck_list, deck_manager.get_full_deck())
	_fill_list(draw_pile_list, deck_manager.get_draw_pile())
	_fill_list(discard_pile_list, deck_manager.get_discard_pile())
	_fill_list(exhaust_pile_list, deck_manager.get_exhaust_pile())
	_refresh_language_texts()


func _refresh_language_texts() -> void:
	title_label.text = LanguageManager.tr_key("battle_view_deck")
	close_button.text = LanguageManager.tr_key("ui_close")
	tab_container.set_tab_title(0, LanguageManager.tr_format("deck_view.full", {"count": full_deck_list.item_count}))
	tab_container.set_tab_title(1, LanguageManager.tr_format("deck_view.draw", {"count": draw_pile_list.item_count}))
	tab_container.set_tab_title(2, LanguageManager.tr_format("deck_view.discard", {"count": discard_pile_list.item_count}))
	tab_container.set_tab_title(3, LanguageManager.tr_format("deck_view.exhaust", {"count": exhaust_pile_list.item_count}))


func _fill_list(list: ItemList, cards: Array[CardData]) -> void:
	list.clear()
	list_cards[list] = cards
	for card in cards:
		list.add_item("%s  %s %d" % [card.get_display_name(), LanguageManager.tr_key("ui_cost"), card.cost], card.get_art_texture())


func _on_card_selected(index: int, list: ItemList) -> void:
	AudioManager.play_sfx("ui_click")
	var cards: Array = list_cards.get(list, [])
	if index < 0 or index >= cards.size():
		return

	card_detail_popup.show_card(cards[index])


func _on_close_pressed() -> void:
	AudioManager.play_sfx("ui_click")
	visible = false
	closed.emit()
