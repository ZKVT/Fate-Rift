extends PanelContainer
class_name DeckBuilderCardView

signal card_selected(card: CardData)
signal card_double_clicked(card: CardData)

var card_data: CardData
var is_available := true
var hover_tween: Tween

@onready var art_texture: TextureRect = $MarginContainer/VBoxContainer/ArtTexture
@onready var cost_label: Label = $MarginContainer/VBoxContainer/Header/CostLabel
@onready var name_label: Label = $MarginContainer/VBoxContainer/Header/NameLabel
@onready var count_label: Label = $MarginContainer/VBoxContainer/CountLabel


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)
	if not LanguageManager.language_changed.is_connected(_refresh_language_texts):
		LanguageManager.language_changed.connect(_refresh_language_texts)


# Populates a deck-builder tile without coupling it to deck validation rules.
func setup(card: CardData, selected_count: int, owned_count: int, can_add: bool) -> void:
	card_data = card
	is_available = can_add
	if not is_node_ready():
		await ready

	art_texture.texture = card.get_art_texture()
	cost_label.text = str(card.cost)
	name_label.text = card.get_display_name()
	count_label.text = "%d/%d" % [selected_count, owned_count]
	modulate = Color.WHITE if is_available else Color(0.48, 0.48, 0.48, 0.78)


func _refresh_language_texts() -> void:
	if card_data != null and name_label != null:
		name_label.text = card_data.get_display_name()


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		AudioManager.play_sfx("ui_click")
		if event.double_click:
			card_double_clicked.emit(card_data)
		else:
			card_selected.emit(card_data)


func _on_mouse_entered() -> void:
	z_index = 10
	card_selected.emit(card_data)
	_tween_scale(Vector2(1.045, 1.045))


func _on_mouse_exited() -> void:
	z_index = 0
	_tween_scale(Vector2.ONE)


func _tween_scale(target_scale: Vector2) -> void:
	if hover_tween != null:
		hover_tween.kill()
	hover_tween = create_tween()
	hover_tween.set_trans(Tween.TRANS_QUAD)
	hover_tween.set_ease(Tween.EASE_OUT)
	hover_tween.tween_property(self, "scale", target_scale, 0.1)
