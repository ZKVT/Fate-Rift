extends Node
class_name HandManager

signal card_play_requested(card_view: CardView)
signal card_target_hover_changed(is_hovering: bool)
signal card_preview_requested(card_data: CardData)
signal card_preview_hidden
signal cards_overflowed(cards: Array[CardData])

@export var hand_area_path: NodePath
@export var play_area_path: NodePath
@export var target_area_path: NodePath
@export var card_view_scene: PackedScene
@export var max_hand_size := 8

var cards_in_hand: Array[CardData] = []
var card_views: Array[CardView] = []

@onready var hand_area: Control = get_node(hand_area_path)


func add_cards(cards: Array[CardData]) -> int:
	var destroyed_count := 0
	var overflow_cards: Array[CardData] = []
	for card in cards:
		if not add_card(card):
			destroyed_count += 1
			if card != null:
				overflow_cards.append(card)
	if not overflow_cards.is_empty():
		cards_overflowed.emit(overflow_cards)
	return destroyed_count


func add_card(card: CardData) -> bool:
	if card == null:
		return false

	# Cards gained while the hand is full are rejected here; add_cards()
	# forwards them so the battle can put overflow cards into discard.
	if cards_in_hand.size() >= max_hand_size:
		return false

	var card_view := card_view_scene.instantiate() as CardView
	cards_in_hand.append(card)
	card_views.append(card_view)

	hand_area.add_child(card_view)
	card_view.setup(card, play_area_path, target_area_path)
	card_view.played.connect(_on_card_view_played)
	card_view.target_hover_changed.connect(_on_card_target_hover_changed)
	card_view.preview_requested.connect(_on_card_preview_requested)
	card_view.preview_hidden.connect(_on_card_preview_hidden)

	_layout_hand()
	return true


func update_playable_cards(current_energy: int) -> void:
	for card_view in card_views:
		if card_view.card_data != null:
			card_view.set_playable(card_view.current_cost <= current_energy)


func discard_all_from_hand() -> Array[CardData]:
	var discarded_cards := cards_in_hand.duplicate()
	cards_in_hand.clear()

	for card_view in card_views:
		card_view.queue_free()

	card_views.clear()
	return discarded_cards


func remove_card_view(card_view: CardView, free_view := true) -> CardData:
	var index := card_views.find(card_view)
	if index == -1:
		return null

	var card := cards_in_hand[index]
	cards_in_hand.remove_at(index)
	card_views.remove_at(index)
	if free_view:
		card_view.queue_free()
	_layout_hand()
	return card


func discard_random_card() -> CardData:
	if card_views.is_empty():
		return null

	var index := randi_range(0, card_views.size() - 1)
	var card_view := card_views[index]
	var card := cards_in_hand[index]
	cards_in_hand.remove_at(index)
	card_views.remove_at(index)
	card_view.queue_free()
	_layout_hand()
	return card


func reduce_newest_cards_cost(count: int, amount: int) -> void:
	var start_index: int = max(card_views.size() - count, 0)
	for index in range(start_index, card_views.size()):
		card_views[index].reduce_cost(amount)


func reduce_next_playable_cards_cost(count: int, amount: int) -> void:
	for index in range(min(count, card_views.size())):
		card_views[index].reduce_cost(amount)


func set_newest_cards_cost(count: int, cost: int) -> void:
	var start_index: int = max(card_views.size() - count, 0)
	for index in range(start_index, card_views.size()):
		card_views[index].set_temporary_cost(cost)


func cards_count() -> int:
	return cards_in_hand.size()


func empty_slots() -> int:
	return max(max_hand_size - cards_in_hand.size(), 0)


func relayout_hand() -> void:
	_layout_hand()


func return_card_view_home(card_view: CardView) -> void:
	card_view.return_home()


func _on_card_view_played(card_view: CardView) -> void:
	card_play_requested.emit(card_view)


func _on_card_target_hover_changed(is_hovering: bool) -> void:
	card_target_hover_changed.emit(is_hovering)


# Forwards hand-card hover details to BattleScene without coupling cards to UI paths.
func _on_card_preview_requested(card_data: CardData) -> void:
	card_preview_requested.emit(card_data)


func _on_card_preview_hidden() -> void:
	card_preview_hidden.emit()


func _layout_hand() -> void:
	if card_views.is_empty():
		return

	var card_size := Vector2(190, 253)
	var available_width := hand_area.size.x
	var spacing := 112.0
	if card_views.size() > 1:
		spacing = min(spacing, max((available_width - card_size.x) / float(card_views.size() - 1), 66.0))
	var total_width := spacing * float(card_views.size() - 1) + card_size.x
	var start_x := (hand_area.size.x - total_width) * 0.5
	var center := float(card_views.size() - 1) * 0.5
	var base_y: float = hand_area.size.y - card_size.y - 24.0

	for index in range(card_views.size()):
		var card_view := card_views[index]
		var offset_from_center: float = float(index) - center
		var distance_from_center: float = abs(offset_from_center)
		var fan_y: float = base_y + distance_from_center * 9.0
		var rotation_degrees: float = offset_from_center * 4.0
		var target_position := Vector2(start_x + spacing * float(index), fan_y)
		card_view.set_home_transform(target_position, deg_to_rad(rotation_degrees))
