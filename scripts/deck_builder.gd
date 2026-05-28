extends Control

const MAP_SCENE_PATH := "res://scenes/MapScene.tscn"
const MAIN_MENU_PATH := "res://scenes/MainMenu.tscn"
const CARD_TILE_SCENE := preload("res://scenes/DeckBuilderCardView.tscn")

const REQUIRED_TOTAL := 20
const REQUIRED_BASIC := 16
const REQUIRED_SPECIAL := 4
const MAX_BASIC_COPIES := 3

@onready var card_grid: GridContainer = $MainContainer/ContentContainer/CollectionPanel/MarginContainer/VBoxContainer/CollectionScroll/CardGrid
@onready var deck_list: ItemList = $MainContainer/ContentContainer/DeckPanel/MarginContainer/VBoxContainer/DeckList
@onready var deck_stats_label: Label = $MainContainer/TopBar/DeckStatsLabel
@onready var error_label: Label = $MainContainer/TopBar/ErrorLabel
@onready var confirm_button: Button = $MainContainer/ContentContainer/DeckPanel/MarginContainer/VBoxContainer/ConfirmButton
@onready var back_button: Button = $MainContainer/ContentContainer/DeckPanel/MarginContainer/VBoxContainer/BackButton
@onready var large_card_image: TextureRect = $MainContainer/ContentContainer/DetailPanel/MarginContainer/VBoxContainer/ArtFrame/LargeCardImage
@onready var card_name_label: Label = $MainContainer/ContentContainer/DetailPanel/MarginContainer/VBoxContainer/NameRow/CardNameLabel
@onready var cost_label: Label = $MainContainer/ContentContainer/DetailPanel/MarginContainer/VBoxContainer/NameRow/CostLabel
@onready var type_label: Label = $MainContainer/ContentContainer/DetailPanel/MarginContainer/VBoxContainer/TypeLabel
@onready var rarity_label: Label = $MainContainer/ContentContainer/DetailPanel/MarginContainer/VBoxContainer/RarityLabel
@onready var description_label: Label = $MainContainer/ContentContainer/DetailPanel/MarginContainer/VBoxContainer/DescriptionLabel
@onready var owned_count_label: Label = $MainContainer/ContentContainer/DetailPanel/MarginContainer/VBoxContainer/OwnedCountLabel
@onready var selected_count_label: Label = $MainContainer/ContentContainer/DetailPanel/MarginContainer/VBoxContainer/SelectedCountLabel
@onready var reason_label: Label = $MainContainer/ContentContainer/DetailPanel/MarginContainer/VBoxContainer/ReasonLabel
@onready var add_button: Button = $MainContainer/ContentContainer/DetailPanel/MarginContainer/VBoxContainer/AddButton
@onready var remove_button: Button = $MainContainer/ContentContainer/DetailPanel/MarginContainer/VBoxContainer/RemoveButton
@onready var title_label: Label = $MainContainer/TopBar/TitleLabel
@onready var collection_title_label: Label = $MainContainer/ContentContainer/CollectionPanel/MarginContainer/VBoxContainer/CollectionTitle
@onready var detail_title_label: Label = $MainContainer/ContentContainer/DetailPanel/MarginContainer/VBoxContainer/DetailTitle
@onready var deck_title_label: Label = $MainContainer/ContentContainer/DeckPanel/MarginContainer/VBoxContainer/DeckTitle

var owned_cards: Array[CardData] = []
var selected_deck: Array[CardData] = []
var selected_deck_upgrades: Array[bool] = []
var selected_card: CardData
var deck_entry_card_ids: Array[String] = []


func _ready() -> void:
	if not LanguageManager.language_changed.is_connected(refresh_language_texts):
		LanguageManager.language_changed.connect(refresh_language_texts)
	deck_list.item_selected.connect(_on_deck_item_selected)
	deck_list.item_activated.connect(_on_deck_item_activated)
	confirm_button.pressed.connect(_on_confirm_button_pressed)
	back_button.pressed.connect(_on_back_button_pressed)
	add_button.pressed.connect(_on_add_button_pressed)
	remove_button.pressed.connect(_on_remove_button_pressed)

	owned_cards = CardDatabase.get_owned_cards(PlayerCardCollection.player_card_collection)
	_setup_mode_text()
	refresh_language_texts()
	_load_previous_or_default_deck()
	if not owned_cards.is_empty():
		selected_card = owned_cards[0]
	_refresh_ui()


# Validates and stores the selected deck before entering battle.
func _on_confirm_button_pressed() -> void:
	AudioManager.play_sfx("ui_click")
	var result: Variant = validate_deck()
	if not _is_validation_success(result):
		_show_error(str(result))
		return

	if RunManager.deck_builder_mode == "edit_run_deck":
		RunManager.set_current_deck_with_upgrades(_selected_deck_card_ids(), selected_deck_upgrades)
		SaveManager.save_run()
		var return_path := RunManager.deck_builder_return_scene_path
		RunManager.clear_deck_builder_context()
		if return_path == "":
			return_path = MAP_SCENE_PATH
		get_tree().change_scene_to_file(return_path)
		return

	RunManager.set_current_deck(selected_deck)
	RunManager.start_run()
	get_tree().change_scene_to_file(MAP_SCENE_PATH)


func _on_back_button_pressed() -> void:
	AudioManager.play_sfx("ui_click")
	if RunManager.deck_builder_mode == "edit_run_deck":
		RunManager.restore_deck_builder_original_deck()
		SaveManager.save_run()
		var return_path := RunManager.deck_builder_return_scene_path
		RunManager.clear_deck_builder_context()
		if return_path == "":
			return_path = MAP_SCENE_PATH
		get_tree().change_scene_to_file(return_path)
		return
	get_tree().change_scene_to_file(MAIN_MENU_PATH)


func _on_add_button_pressed() -> void:
	AudioManager.play_sfx("ui_click")
	if selected_card != null:
		_try_add_card(selected_card)


func _on_remove_button_pressed() -> void:
	AudioManager.play_sfx("ui_click")
	if selected_card != null:
		_remove_one_card(selected_card.card_id)


func _on_collection_card_selected(card: CardData) -> void:
	selected_card = card
	_refresh_detail_panel()


func _on_collection_card_double_clicked(card: CardData) -> void:
	selected_card = card
	_try_add_card(card)


# Selects a merged deck-list row and shows details without changing the deck.
func _on_deck_item_selected(index: int) -> void:
	AudioManager.play_sfx("ui_click")
	if index < 0 or index >= deck_entry_card_ids.size():
		return

	var card_id := deck_entry_card_ids[index]
	selected_card = CardDatabase.get_card(card_id)
	_refresh_detail_panel()


# Removes one copy from a merged deck-list row on double click or activation.
func _on_deck_item_activated(index: int) -> void:
	AudioManager.play_sfx("ui_click")
	if index < 0 or index >= deck_entry_card_ids.size():
		return

	var card_id := deck_entry_card_ids[index]
	selected_card = CardDatabase.get_card(card_id)
	_remove_one_card(card_id)


# Returns true for a valid deck, otherwise returns a clear error string.
func validate_deck() -> Variant:
	if selected_deck.size() < REQUIRED_TOTAL:
		return LanguageManager.tr_key("deckbuilder_error_total_low")
	if selected_deck.size() > REQUIRED_TOTAL:
		return LanguageManager.tr_key("deckbuilder_error_total_high")

	var basic_count := _count_category(CardData.DeckCategory.BASIC)
	var special_count := _count_category(CardData.DeckCategory.SPECIAL)
	if basic_count != REQUIRED_BASIC:
		return LanguageManager.tr_key("deckbuilder_error_basic_count")
	if special_count != REQUIRED_SPECIAL:
		return LanguageManager.tr_key("deckbuilder_error_special_count")

	var selected_counts := _get_selected_counts()
	for card_id in selected_counts.keys():
		var card := CardDatabase.get_card(card_id)
		if card == null or not PlayerCardCollection.owns_card(card_id):
			return LanguageManager.tr_key("deckbuilder_error_not_owned")

		var count := int(selected_counts[card_id])
		var owned_count := PlayerCardCollection.get_owned_count(card_id)
		if _is_special_card(card) and count > 1:
			return LanguageManager.tr_format("deckbuilder_error_special_duplicate", {"card": card.get_display_name()})
		if _is_basic_card(card) and count > MAX_BASIC_COPIES:
			return LanguageManager.tr_format("deckbuilder_error_basic_max", {"card": card.get_display_name()})
		if count > owned_count:
			return LanguageManager.tr_key("deckbuilder_error_owned_limit")

	return true


func _is_validation_success(result: Variant) -> bool:
	return typeof(result) == TYPE_BOOL and bool(result)


func _try_add_card(card: CardData) -> void:
	var error := _get_add_error(card)
	if error != "":
		_show_error(error)
		_refresh_detail_panel()
		return

	selected_deck.append(card)
	selected_deck_upgrades.append(false)
	_show_error("")
	_refresh_ui()


func _remove_one_card(card_id: String) -> void:
	for index in range(selected_deck.size()):
		if selected_deck[index].card_id == card_id:
			selected_deck.remove_at(index)
			if index < selected_deck_upgrades.size():
				selected_deck_upgrades.remove_at(index)
			_show_error("")
			_refresh_ui()
			return

	_show_error(LanguageManager.tr_key("deckbuilder_error_card_not_in_deck"))
	_refresh_detail_panel()


func _get_add_error(card: CardData) -> String:
	if card == null or not PlayerCardCollection.owns_card(card.card_id):
		return LanguageManager.tr_key("deckbuilder_error_not_owned")
	if selected_deck.size() >= REQUIRED_TOTAL:
		return LanguageManager.tr_key("deckbuilder_error_total_full")

	var selected_count := _count_card(card.card_id)
	var owned_count := PlayerCardCollection.get_owned_count(card.card_id)
	if selected_count >= owned_count:
		return LanguageManager.tr_key("deckbuilder_error_owned_limit")

	if _is_special_card(card):
		if _count_category(CardData.DeckCategory.SPECIAL) >= REQUIRED_SPECIAL:
			return LanguageManager.tr_key("deckbuilder_error_special_full")
		if selected_count > 0:
			return LanguageManager.tr_format("deckbuilder_error_special_duplicate", {"card": card.get_display_name()})
		return ""

	if _is_basic_card(card):
		if _count_category(CardData.DeckCategory.BASIC) >= REQUIRED_BASIC:
			return LanguageManager.tr_key("deckbuilder_error_basic_full")
		if selected_count >= MAX_BASIC_COPIES:
			return LanguageManager.tr_format("deckbuilder_error_basic_max", {"card": card.get_display_name()})
		return ""

	return LanguageManager.tr_key("deckbuilder_error_unknown_category")


func _refresh_ui() -> void:
	_refresh_collection_grid()
	_refresh_deck_list()
	_refresh_stats()
	_refresh_detail_panel()


func _refresh_collection_grid() -> void:
	for child in card_grid.get_children():
		child.queue_free()

	for card in owned_cards:
		var selected_count := _count_card(card.card_id)
		var owned_count := PlayerCardCollection.get_owned_count(card.card_id)
		var tile := CARD_TILE_SCENE.instantiate() as DeckBuilderCardView
		card_grid.add_child(tile)
		tile.setup(card, selected_count, owned_count, _get_add_error(card) == "")
		tile.card_selected.connect(_on_collection_card_selected)
		tile.card_double_clicked.connect(_on_collection_card_double_clicked)


func _refresh_deck_list() -> void:
	deck_list.clear()
	deck_entry_card_ids.clear()

	var counts := _get_selected_counts()
	var cards := counts.keys()
	cards.sort_custom(func(a: String, b: String) -> bool:
		var card_a := CardDatabase.get_card(a)
		var card_b := CardDatabase.get_card(b)
		if card_a == null or card_b == null:
			return a < b
		if card_a.cost == card_b.cost:
			return card_a.get_display_name() < card_b.get_display_name()
		return card_a.cost < card_b.cost
	)

	for card_id in cards:
		var card := CardDatabase.get_card(card_id)
		if card == null:
			continue
		var count := int(counts[card_id])
		var label := "%d  %s  x%d  %s" % [card.cost, card.get_display_name(), count, _category_text(card)]
		deck_entry_card_ids.append(card_id)
		deck_list.add_item(label)
		var item_index := deck_list.item_count - 1
		var color := Color(0.95, 0.9, 0.78) if _is_basic_card(card) else Color(0.72, 0.86, 1.0)
		deck_list.set_item_custom_fg_color(item_index, color)


func _refresh_stats() -> void:
	var basic_count := _count_category(CardData.DeckCategory.BASIC)
	var special_count := _count_category(CardData.DeckCategory.SPECIAL)
	deck_stats_label.text = LanguageManager.tr_format("deckbuilder_stats", {
		"total": selected_deck.size(),
		"required_total": REQUIRED_TOTAL,
		"basic": basic_count,
		"required_basic": REQUIRED_BASIC,
		"special": special_count,
		"required_special": REQUIRED_SPECIAL,
	})

	var result: Variant = validate_deck()
	confirm_button.disabled = not _is_validation_success(result)
	if _is_validation_success(result):
		_show_error("")
	elif error_label.text == "":
		_show_error(str(result))


func _refresh_detail_panel() -> void:
	if selected_card == null:
		large_card_image.texture = null
		card_name_label.text = LanguageManager.tr_key("deckbuilder_select_card")
		cost_label.text = "-"
		type_label.text = LanguageManager.tr_format("deckbuilder_type_line", {"type": "-", "category": "-"})
		rarity_label.text = LanguageManager.tr_format("deckbuilder_rarity_line", {"rarity": "-"})
		description_label.text = LanguageManager.tr_key("deckbuilder_detail_hint")
		owned_count_label.text = LanguageManager.tr_format("deckbuilder_owned_count", {"count": 0})
		selected_count_label.text = LanguageManager.tr_format("deckbuilder_selected_count", {"count": 0})
		reason_label.text = ""
		add_button.disabled = true
		remove_button.disabled = true
		return

	var selected_count := _count_card(selected_card.card_id)
	var owned_count := PlayerCardCollection.get_owned_count(selected_card.card_id)
	var add_error := _get_add_error(selected_card)
	large_card_image.texture = selected_card.get_art_texture()
	card_name_label.text = selected_card.get_display_name()
	cost_label.text = str(selected_card.cost)
	type_label.text = LanguageManager.tr_format("deckbuilder_type_line", {"type": _card_type_text(selected_card), "category": _category_text(selected_card)})
	rarity_label.text = LanguageManager.tr_format("deckbuilder_rarity_line", {"rarity": _rarity_text(selected_card)})
	description_label.text = selected_card.get_display_description()
	owned_count_label.text = LanguageManager.tr_format("deckbuilder_owned_count", {"count": owned_count})
	selected_count_label.text = LanguageManager.tr_format("deckbuilder_selected_count", {"count": selected_count})
	reason_label.text = add_error
	add_button.disabled = add_error != ""
	remove_button.disabled = selected_count <= 0


func _load_previous_or_default_deck() -> void:
	selected_deck = RunManager.get_saved_deck_cards()
	selected_deck_upgrades = RunManager.current_deck_upgrades.duplicate()
	if selected_deck.size() > 0:
		_ensure_selected_upgrade_size()
		return

	var default_ids: Array[String] = [
		"basic_strike", "basic_strike", "basic_strike",
		"basic_heavy_blow", "basic_heavy_blow", "basic_heavy_blow",
		"basic_combo_strike", "basic_combo_strike", "basic_combo_strike",
		"basic_flame_slash", "basic_flame_slash", "basic_flame_slash",
		"basic_guard", "basic_guard", "basic_guard",
		"basic_hold_fast",
		"major_00_the_fool",
		"major_01_the_magician",
		"major_02_the_high_priestess",
		"major_04_the_emperor",
	]

	for card_id in default_ids:
		var card := CardDatabase.get_card(card_id)
		if card != null:
			selected_deck.append(card)
			selected_deck_upgrades.append(false)


func _setup_mode_text() -> void:
	if RunManager.deck_builder_mode == "edit_run_deck":
		title_label.text = LanguageManager.tr_key("deckbuilder_title_edit")
		confirm_button.text = LanguageManager.tr_key("deckbuilder_save_return")
		back_button.text = LanguageManager.tr_key("deckbuilder_cancel_edit")
		if RunManager.deck_builder_return_scene_path == RunManager.SHOP_SCENE_PATH:
			error_label.text = LanguageManager.tr_key("deckbuilder_editing_shop_hint")
		elif RunManager.deck_builder_return_scene_path == RunManager.REST_SCENE_PATH:
			error_label.text = LanguageManager.tr_key("deckbuilder_editing_rest_hint")
		else:
			error_label.text = LanguageManager.tr_key("deckbuilder_editing_return_hint")
	else:
		title_label.text = LanguageManager.tr_key("deckbuilder_title_new")
		confirm_button.text = LanguageManager.tr_key("deckbuilder_confirm")
		back_button.text = LanguageManager.tr_key("ui_back")


func refresh_language_texts() -> void:
	if collection_title_label != null:
		collection_title_label.text = LanguageManager.tr_key("deckbuilder_collection_title")
	if detail_title_label != null:
		detail_title_label.text = LanguageManager.tr_key("deckbuilder_detail_title")
	if deck_title_label != null:
		deck_title_label.text = LanguageManager.tr_key("deckbuilder_current_deck")
	if add_button != null:
		add_button.text = LanguageManager.tr_key("deckbuilder_add")
	if remove_button != null:
		remove_button.text = LanguageManager.tr_key("deckbuilder_remove_one")
	_setup_mode_text()
	_refresh_stats()
	_refresh_detail_panel()
	_refresh_deck_list()


func _selected_deck_card_ids() -> Array[String]:
	var ids: Array[String] = []
	for card in selected_deck:
		if card != null:
			ids.append(card.card_id)
	return ids


func _ensure_selected_upgrade_size() -> void:
	while selected_deck_upgrades.size() < selected_deck.size():
		selected_deck_upgrades.append(false)
	while selected_deck_upgrades.size() > selected_deck.size():
		selected_deck_upgrades.pop_back()


func _get_selected_counts() -> Dictionary:
	var counts := {}
	for card in selected_deck:
		counts[card.card_id] = int(counts.get(card.card_id, 0)) + 1
	return counts


func _count_card(card_id: String) -> int:
	return int(_get_selected_counts().get(card_id, 0))


func _count_category(category: int) -> int:
	var count := 0
	for card in selected_deck:
		if _get_category(card) == category:
			count += 1
	return count


func _get_category(card: CardData) -> int:
	if card.deck_category == CardData.DeckCategory.SPECIAL or card.is_special:
		return CardData.DeckCategory.SPECIAL
	return CardData.DeckCategory.BASIC


func _is_basic_card(card: CardData) -> bool:
	return _get_category(card) == CardData.DeckCategory.BASIC


func _is_special_card(card: CardData) -> bool:
	return _get_category(card) == CardData.DeckCategory.SPECIAL


func _category_text(card: CardData) -> String:
	return LanguageManager.tr_key("deckbuilder_category_special") if _is_special_card(card) else LanguageManager.tr_key("deckbuilder_category_basic")


func _card_type_text(card: CardData) -> String:
	match card.card_type:
		CardData.CardType.ATTACK:
			return LanguageManager.tr_key("card_type.attack")
		CardData.CardType.SKILL:
			return LanguageManager.tr_key("card_type.skill")
		CardData.CardType.POWER:
			return LanguageManager.tr_key("card_type.power")
	return LanguageManager.tr_key("ui_unknown")


func _rarity_text(card: CardData) -> String:
	match card.rarity:
		CardData.Rarity.COMMON:
			return LanguageManager.tr_key("rarity.common")
		CardData.Rarity.UNCOMMON:
			return LanguageManager.tr_key("rarity.uncommon")
		CardData.Rarity.RARE:
			return LanguageManager.tr_key("rarity.rare")
	return LanguageManager.tr_key("ui_unknown")


func _show_error(message: String) -> void:
	error_label.text = message
