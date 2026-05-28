extends Control

const BASIC_CARD_PRICE_MIN := 30
const BASIC_CARD_PRICE_MAX := 60
const RELIC_PRICE := 100
const TAROT_PACK_PRICE := 150
const RELIC_PACK_PRICE := 120
const SHOP_BACKGROUND_PATH := "res://assets/ui/shop/shop_background.png"
const SHOP_MERCHANT_PATH := "res://assets/ui/shop/shop_merchant.png"
const GOLD_ICON_PATH := "res://assets/ui/shop/gold_icon.png"
const TAROT_PACK_ICON_PATH := "res://assets/ui/shop/tarot_pack_icon.png"
const RELIC_CHEST_ICON_PATH := "res://assets/ui/shop/relic_chest_icon.png"

var gold_label: Label
var error_label: Label
var result_label: Label
var goods_container: HBoxContainer
var pack_container: HBoxContainer
var continue_button: Button
var edit_deck_button: Button

var basic_products: Array[Dictionary] = []
var relic_product: Dictionary = {}


func _ready() -> void:
	_generate_products()
	_build_ui()
	_refresh_gold()


func _generate_products() -> void:
	if RunManager.shop_state_node_id == RunManager.current_map_node_id and not RunManager.shop_basic_products.is_empty():
		basic_products = RunManager.shop_basic_products.duplicate(true)
		relic_product = RunManager.shop_relic_product.duplicate(true)
		return

	basic_products.clear()
	var basic_cards: Array[CardData] = CardDatabase.get_basic_cards()
	basic_cards.shuffle()
	var basic_count: int = min(3, basic_cards.size())
	for index in range(basic_count):
		var card: CardData = basic_cards[index]
		basic_products.append({
			"card_id": card.card_id,
			"price": randi_range(BASIC_CARD_PRICE_MIN, BASIC_CARD_PRICE_MAX),
			"purchased": false,
		})

	relic_product = {}
	var relic: RelicData = RelicManager.get_random_unowned_relic()
	if relic != null:
		relic_product = {
			"relic_id": relic.relic_id,
			"price": RELIC_PRICE,
			"purchased": false,
		}
	_cache_shop_state()


func _build_ui() -> void:
	var fallback_background := ColorRect.new()
	fallback_background.color = Color(0.05, 0.04, 0.07, 1.0)
	fallback_background.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(fallback_background)

	var background_texture := _make_texture_rect(SHOP_BACKGROUND_PATH, Vector2.ZERO)
	if background_texture.texture != null:
		background_texture.set_anchors_preset(Control.PRESET_FULL_RECT)
		background_texture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		background_texture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		add_child(background_texture)

	var shade := ColorRect.new()
	shade.color = Color(0.02, 0.015, 0.015, 0.42)
	shade.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(shade)

	var root := VBoxContainer.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.offset_left = 42
	root.offset_top = 28
	root.offset_right = -42
	root.offset_bottom = -28
	root.add_theme_constant_override("separation", 16)
	add_child(root)

	var top_bar := HBoxContainer.new()
	top_bar.add_theme_constant_override("separation", 28)
	root.add_child(top_bar)

	var title_label := Label.new()
	title_label.text = LanguageManager.tr_key("shop_title")
	title_label.add_theme_font_size_override("font_size", 46)
	title_label.add_theme_color_override("font_color", Color(1.0, 0.86, 0.5))
	top_bar.add_child(title_label)

	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top_bar.add_child(spacer)

	var gold_box := HBoxContainer.new()
	gold_box.add_theme_constant_override("separation", 10)
	top_bar.add_child(gold_box)

	var gold_icon := _make_texture_rect(GOLD_ICON_PATH, Vector2(42, 42))
	gold_box.add_child(gold_icon)

	gold_label = Label.new()
	gold_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	gold_label.add_theme_font_size_override("font_size", 30)
	gold_label.add_theme_color_override("font_color", Color(1.0, 0.9, 0.25))
	gold_box.add_child(gold_label)

	edit_deck_button = Button.new()
	edit_deck_button.text = LanguageManager.tr_key("shop_edit_deck")
	edit_deck_button.custom_minimum_size = Vector2(150, 44)
	edit_deck_button.add_theme_font_size_override("font_size", 20)
	edit_deck_button.pressed.connect(_on_edit_deck_pressed)
	top_bar.add_child(edit_deck_button)

	var content := HBoxContainer.new()
	content.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content.add_theme_constant_override("separation", 16)
	root.add_child(content)

	var left_panel := _make_panel()
	left_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	left_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content.add_child(left_panel)

	var left_box := VBoxContainer.new()
	left_box.add_theme_constant_override("separation", 12)
	left_panel.add_child(left_box)

	var pack_title := _make_section_title(LanguageManager.tr_key("shop_pack_title"))
	left_box.add_child(pack_title)

	pack_container = HBoxContainer.new()
	pack_container.add_theme_constant_override("separation", 14)
	left_box.add_child(pack_container)

	var goods_title := _make_section_title(LanguageManager.tr_key("shop_goods_title"))
	left_box.add_child(goods_title)

	goods_container = HBoxContainer.new()
	goods_container.size_flags_vertical = Control.SIZE_EXPAND_FILL
	goods_container.add_theme_constant_override("separation", 12)
	left_box.add_child(goods_container)

	var right_panel := _make_panel()
	right_panel.custom_minimum_size = Vector2(380, 0)
	right_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content.add_child(right_panel)

	var right_box := VBoxContainer.new()
	right_box.add_theme_constant_override("separation", 12)
	right_panel.add_child(right_box)

	var merchant := _make_texture_rect(SHOP_MERCHANT_PATH, Vector2(0, 230))
	merchant.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right_box.add_child(merchant)

	result_label = Label.new()
	result_label.text = ""
	result_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	result_label.add_theme_font_size_override("font_size", 22)
	result_label.add_theme_color_override("font_color", Color(0.55, 1.0, 0.66))
	right_box.add_child(result_label)

	error_label = Label.new()
	error_label.text = ""
	error_label.add_theme_font_size_override("font_size", 24)
	error_label.add_theme_color_override("font_color", Color(1.0, 0.34, 0.28))
	root.add_child(error_label)

	continue_button = Button.new()
	continue_button.text = LanguageManager.tr_key("ui_continue")
	continue_button.custom_minimum_size = Vector2(220, 56)
	continue_button.add_theme_font_size_override("font_size", 28)
	continue_button.pressed.connect(_on_continue_pressed)
	root.add_child(continue_button)

	_rebuild_shop()


func _rebuild_shop() -> void:
	_rebuild_pack_area()
	_rebuild_goods()
	_refresh_gold()


func _rebuild_pack_area() -> void:
	for child in pack_container.get_children():
		child.queue_free()

	var special_count := _get_unowned_special_cards().size()
	var tarot_disabled := special_count == 0
	var tarot_message := LanguageManager.tr_key("shop_tarot_all_collected") if tarot_disabled else LanguageManager.tr_key("shop_tarot_desc")
	pack_container.add_child(_make_pack_panel(LanguageManager.tr_key("shop_tarot_pack"), tarot_message, TAROT_PACK_PRICE, LanguageManager.tr_key("shop_pack_draw"), tarot_disabled, _on_tarot_pack_pressed, TAROT_PACK_ICON_PATH))

	var relic_count := RelicManager.get_unowned_relics().size()
	var relic_disabled := relic_count == 0
	var relic_message := LanguageManager.tr_key("shop_relic_all_collected") if relic_disabled else LanguageManager.tr_key("shop_relic_desc")
	pack_container.add_child(_make_pack_panel(LanguageManager.tr_key("shop_relic_pack"), relic_message, RELIC_PACK_PRICE, LanguageManager.tr_key("shop_pack_open"), relic_disabled, _on_relic_pack_pressed, RELIC_CHEST_ICON_PATH))


func _rebuild_goods() -> void:
	for child in goods_container.get_children():
		child.queue_free()

	for product in basic_products:
		goods_container.add_child(_make_card_product_panel(product))

	if relic_product.is_empty():
		goods_container.add_child(_make_message_panel(LanguageManager.tr_key("shop_relic_title"), LanguageManager.tr_key("shop_no_relic_for_sale")))
	else:
		goods_container.add_child(_make_relic_product_panel(relic_product))


func _make_pack_panel(title: String, description: String, price: int, button_text: String, disabled: bool, callback: Callable, icon_path: String) -> PanelContainer:
	var panel := _make_panel()
	panel.custom_minimum_size = Vector2(300, 276)

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 8)
	panel.add_child(box)

	var icon := _make_texture_rect(icon_path, Vector2(0, 106))
	icon.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	box.add_child(icon)

	var title_label := Label.new()
	title_label.text = title
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_label.add_theme_font_size_override("font_size", 28)
	title_label.add_theme_color_override("font_color", Color(1.0, 0.86, 0.52))
	box.add_child(title_label)

	var desc_label := Label.new()
	desc_label.text = description
	desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc_label.custom_minimum_size = Vector2(0, 46)
	desc_label.add_theme_font_size_override("font_size", 18)
	desc_label.add_theme_color_override("font_color", Color(0.88, 0.84, 0.74))
	box.add_child(desc_label)

	var price_label := Label.new()
	price_label.text = LanguageManager.tr_format("shop_price_format", {"price": price})
	price_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	price_label.add_theme_font_size_override("font_size", 20)
	price_label.add_theme_color_override("font_color", Color(1.0, 0.9, 0.25))
	box.add_child(price_label)

	var button := Button.new()
	button.text = button_text
	button.disabled = disabled
	button.custom_minimum_size = Vector2(0, 42)
	button.add_theme_font_size_override("font_size", 20)
	button.pressed.connect(callback)
	box.add_child(button)

	return panel


func _make_card_product_panel(product: Dictionary) -> PanelContainer:
	var card_id := str(product.get("card_id", ""))
	var card: CardData = CardDatabase.get_card(card_id)
	var price := int(product.get("price", 0))
	var purchased := bool(product.get("purchased", false))

	var panel := _make_panel()
	panel.custom_minimum_size = Vector2(190, 400)

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 7)
	panel.add_child(box)

	var art := TextureRect.new()
	art.custom_minimum_size = Vector2(155, 190)
	art.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
	art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	if card != null:
		art.texture = card.get_art_texture()
	box.add_child(art)

	var name_label := Label.new()
	name_label.text = card.get_display_name() if card != null else LanguageManager.tr_key("card.unknown.name")
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.add_theme_font_size_override("font_size", 20)
	name_label.add_theme_color_override("font_color", Color(1.0, 0.86, 0.52))
	box.add_child(name_label)

	var desc_label := Label.new()
	desc_label.text = card.get_display_description() if card != null else ""
	desc_label.custom_minimum_size = Vector2(0, 70)
	desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc_label.add_theme_font_size_override("font_size", 15)
	desc_label.add_theme_color_override("font_color", Color(0.88, 0.84, 0.74))
	box.add_child(desc_label)

	var price_label := Label.new()
	price_label.text = LanguageManager.tr_format("shop_price_format", {"price": price})
	price_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	price_label.add_theme_font_size_override("font_size", 18)
	price_label.add_theme_color_override("font_color", Color(1.0, 0.9, 0.25))
	box.add_child(price_label)

	var button := Button.new()
	button.text = LanguageManager.tr_key("shop_bought") if purchased else LanguageManager.tr_key("shop_buy")
	button.disabled = purchased
	button.custom_minimum_size = Vector2(0, 38)
	button.add_theme_font_size_override("font_size", 18)
	button.pressed.connect(_on_buy_card_pressed.bind(product))
	box.add_child(button)

	return panel


func _make_relic_product_panel(product: Dictionary) -> PanelContainer:
	var relic_id := str(product.get("relic_id", ""))
	var relic: RelicData = RelicManager.get_relic(relic_id)
	var price := int(product.get("price", 0))
	var purchased := bool(product.get("purchased", false))

	var panel := _make_panel()
	panel.custom_minimum_size = Vector2(190, 400)

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 9)
	panel.add_child(box)

	var icon := TextureRect.new()
	icon.custom_minimum_size = Vector2(130, 130)
	icon.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	if relic != null:
		icon.texture = RelicManager.get_relic_icon(relic)
	box.add_child(icon)

	var name_label := Label.new()
	name_label.text = relic.get_display_name() if relic != null else LanguageManager.tr_key("relic.unknown.name")
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.add_theme_font_size_override("font_size", 20)
	name_label.add_theme_color_override("font_color", Color(1.0, 0.86, 0.52))
	box.add_child(name_label)

	var desc_label := Label.new()
	desc_label.text = relic.get_display_description() if relic != null else ""
	desc_label.custom_minimum_size = Vector2(0, 112)
	desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc_label.add_theme_font_size_override("font_size", 15)
	desc_label.add_theme_color_override("font_color", Color(0.88, 0.84, 0.74))
	box.add_child(desc_label)

	var price_label := Label.new()
	price_label.text = LanguageManager.tr_format("shop_price_format", {"price": price})
	price_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	price_label.add_theme_font_size_override("font_size", 18)
	price_label.add_theme_color_override("font_color", Color(1.0, 0.9, 0.25))
	box.add_child(price_label)

	var button := Button.new()
	button.text = LanguageManager.tr_key("shop_bought") if purchased else LanguageManager.tr_key("shop_buy")
	button.disabled = purchased
	button.custom_minimum_size = Vector2(0, 38)
	button.add_theme_font_size_override("font_size", 18)
	button.pressed.connect(_on_buy_relic_pressed.bind(product))
	box.add_child(button)

	return panel


func _make_message_panel(title: String, message: String) -> PanelContainer:
	var panel := _make_panel()
	panel.custom_minimum_size = Vector2(190, 400)
	var box := VBoxContainer.new()
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_theme_constant_override("separation", 16)
	panel.add_child(box)

	var title_label := Label.new()
	title_label.text = title
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_label.add_theme_font_size_override("font_size", 24)
	title_label.add_theme_color_override("font_color", Color(1.0, 0.86, 0.52))
	box.add_child(title_label)

	var message_label := Label.new()
	message_label.text = message
	message_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	message_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	message_label.add_theme_font_size_override("font_size", 20)
	message_label.add_theme_color_override("font_color", Color(0.88, 0.84, 0.74))
	box.add_child(message_label)
	return panel


func _on_tarot_pack_pressed() -> void:
	var candidates := _get_unowned_special_cards()
	print("[Pack] tarot pack price: ", TAROT_PACK_PRICE)
	print("[Pack] available special cards: ", candidates.size())
	if candidates.is_empty():
		_set_error(LanguageManager.tr_key("shop_tarot_all_collected"))
		_rebuild_shop()
		return
	if not RunManager.can_afford(TAROT_PACK_PRICE) or not RunManager.spend_gold(TAROT_PACK_PRICE):
		_set_error(LanguageManager.tr_key("shop_not_enough_gold"))
		return

	var card: CardData = candidates.pick_random()
	PlayerCardCollection.add_card(card.card_id, 1)
	result_label.text = LanguageManager.tr_format("shop_obtained_special_card", {"card": card.get_display_name()})
	print("[Pack] obtained special card: ", card.card_id)
	print("[Pack] current gold: ", RunManager.get_gold())
	_set_error("")
	_after_purchase()


func _on_relic_pack_pressed() -> void:
	var candidates := RelicManager.get_unowned_relics()
	print("[Pack] relic pack price: ", RELIC_PACK_PRICE)
	print("[Pack] available relics: ", candidates.size())
	if candidates.is_empty():
		_set_error(LanguageManager.tr_key("shop_relic_all_collected"))
		_rebuild_shop()
		return
	if not RunManager.can_afford(RELIC_PACK_PRICE) or not RunManager.spend_gold(RELIC_PACK_PRICE):
		_set_error(LanguageManager.tr_key("shop_not_enough_gold"))
		return

	var relic: RelicData = RelicManager.get_random_unowned_relic()
	if relic == null:
		_set_error(LanguageManager.tr_key("shop_no_relic_available"))
		return
	RelicManager.add_relic(relic.relic_id)
	result_label.text = LanguageManager.tr_format("shop_obtained_relic", {"relic": relic.get_display_name()})
	print("[Pack] obtained relic: ", relic.relic_id)
	print("[Pack] current gold: ", RunManager.get_gold())
	_set_error("")
	_after_purchase()


func _on_buy_card_pressed(product: Dictionary) -> void:
	if bool(product.get("purchased", false)):
		return

	var card_id := str(product.get("card_id", ""))
	var card: CardData = CardDatabase.get_card(card_id)
	if card == null:
		_set_error(LanguageManager.tr_key("shop_product_missing"))
		return

	var price := int(product.get("price", 0))
	if not RunManager.spend_gold(price):
		_set_error(LanguageManager.tr_key("shop_not_enough_gold"))
		return

	PlayerCardCollection.add_card(card_id, 1)
	product["purchased"] = true
	result_label.text = LanguageManager.tr_format("shop_buy_card_result", {"card": card.get_display_name()})
	_set_error("")
	_after_purchase()


func _on_buy_relic_pressed(product: Dictionary) -> void:
	if bool(product.get("purchased", false)):
		return

	var relic_id := str(product.get("relic_id", ""))
	var relic: RelicData = RelicManager.get_relic(relic_id)
	if relic == null:
		_set_error(LanguageManager.tr_key("shop_relic_missing"))
		return
	if RunManager.relic_ids.has(relic_id):
		_set_error(LanguageManager.tr_key("shop_relic_already_owned"))
		return

	var price := int(product.get("price", 0))
	if not RunManager.spend_gold(price):
		_set_error(LanguageManager.tr_key("shop_not_enough_gold"))
		return

	RelicManager.add_relic(relic_id)
	product["purchased"] = true
	result_label.text = LanguageManager.tr_format("shop_buy_relic_result", {"relic": relic.get_display_name()})
	_set_error("")
	_after_purchase()


func _get_unowned_special_cards() -> Array[CardData]:
	var cards: Array[CardData] = []
	for card in CardDatabase.get_special_cards():
		if not PlayerCardCollection.owns_card(card.card_id):
			cards.append(card)
	return cards


func _after_purchase() -> void:
	_refresh_gold()
	_cache_shop_state()
	_rebuild_shop()
	SaveManager.save_run()


func _refresh_gold() -> void:
	if gold_label != null:
		gold_label.text = LanguageManager.tr_format("shop_gold_format", {"gold": RunManager.get_gold()})


func _set_error(message: String) -> void:
	if error_label != null:
		error_label.text = message


func _on_continue_pressed() -> void:
	AudioManager.play_sfx("ui_click")
	RunManager.complete_current_map_node()
	_clear_shop_state()
	SaveManager.save_run()
	get_tree().change_scene_to_file(RunManager.MAP_SCENE_PATH)


func _on_edit_deck_pressed() -> void:
	AudioManager.play_sfx("ui_click")
	_cache_shop_state()
	RunManager.prepare_deck_builder_edit(RunManager.SHOP_SCENE_PATH)
	SaveManager.save_run()
	get_tree().change_scene_to_file("res://scenes/DeckBuilderScene.tscn")


func _cache_shop_state() -> void:
	RunManager.shop_state_node_id = RunManager.current_map_node_id
	RunManager.shop_basic_products = basic_products.duplicate(true)
	RunManager.shop_relic_product = relic_product.duplicate(true)
	RunManager.shop_remove_service_used = false


func _clear_shop_state() -> void:
	RunManager.shop_state_node_id = ""
	RunManager.shop_basic_products.clear()
	RunManager.shop_relic_product.clear()
	RunManager.shop_remove_service_used = false


func _make_section_title(text: String) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", 28)
	label.add_theme_color_override("font_color", Color(0.95, 0.9, 0.78))
	return label


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
		push_warning("[Shop UI] missing texture: " + path)
		return null
	var resource: Resource = load(path)
	var texture: Texture2D = resource as Texture2D
	if texture == null:
		push_warning("[Shop UI] texture load failed: " + path)
	return texture


func _make_panel() -> PanelContainer:
	var panel := PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.08, 0.055, 0.07, 0.86)
	style.border_color = Color(0.86, 0.64, 0.32, 0.72)
	style.set_border_width_all(1)
	style.corner_radius_top_left = 8
	style.corner_radius_top_right = 8
	style.corner_radius_bottom_left = 8
	style.corner_radius_bottom_right = 8
	style.content_margin_left = 16
	style.content_margin_right = 16
	style.content_margin_top = 16
	style.content_margin_bottom = 16
	panel.add_theme_stylebox_override("panel", style)
	return panel
