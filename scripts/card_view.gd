extends Control
class_name CardView

signal played(card_view: CardView)
signal target_hover_changed(is_hovering: bool)
signal preview_requested(card_data: CardData)
signal preview_hidden

@export var play_area_path: NodePath
@export var target_area_path: NodePath

const CARD_SIZE := Vector2(190, 253)
const HOVER_OFFSET := Vector2(0, -34)

var card_data: CardData
var is_dragging := false
var did_drag := false
var drag_offset := Vector2.ZERO
var home_position := Vector2.ZERO
var home_rotation := 0.0
var press_global_position := Vector2.ZERO
var drag_threshold := 8.0
var is_playable := true
var current_cost := 0
var is_target_hovering := false
var scale_tween: Tween

@onready var panel: Panel = $Panel
@onready var name_label: Label = $NameLabel
@onready var cost_label: Label = $CostLabel
@onready var art_texture: TextureRect = $ArtTexture
@onready var description_label: Label = $DescriptionLabel


func _ready() -> void:
	custom_minimum_size = CARD_SIZE
	size = CARD_SIZE
	pivot_offset = custom_minimum_size * 0.5
	mouse_filter = Control.MOUSE_FILTER_STOP
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	name_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	cost_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	art_texture.mouse_filter = Control.MOUSE_FILTER_IGNORE
	description_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)
	if not LanguageManager.language_changed.is_connected(_update_view):
		LanguageManager.language_changed.connect(_update_view)
	_update_view()


func setup(data: CardData, target_play_area: NodePath, target_area: NodePath = NodePath("")) -> void:
	card_data = data
	current_cost = card_data.cost
	play_area_path = target_play_area
	target_area_path = target_area
	_update_view()


func set_home_position(value: Vector2) -> void:
	home_position = value
	if not is_dragging:
		position = home_position


func set_home_transform(target_position: Vector2, target_rotation: float) -> void:
	home_position = target_position
	home_rotation = target_rotation
	if not is_dragging:
		position = home_position
		rotation = home_rotation


func set_playable(value: bool) -> void:
	is_playable = value
	modulate = Color.WHITE if is_playable else Color(0.45, 0.45, 0.45, 0.85)


func reduce_cost(amount: int) -> void:
	current_cost = max(current_cost - amount, 0)
	cost_label.text = str(current_cost)


func set_temporary_cost(value: int) -> void:
	current_cost = max(value, 0)
	cost_label.text = str(current_cost)


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			_start_drag(event.position)
		else:
			_stop_drag()
	elif event is InputEventMouseMotion and is_dragging:
		if get_global_mouse_position().distance_to(press_global_position) > drag_threshold:
			did_drag = true
		global_position = get_global_mouse_position() - drag_offset
		_update_target_hover()


func _start_drag(local_mouse_position: Vector2) -> void:
	if not is_playable:
		return

	preview_hidden.emit()
	is_dragging = true
	did_drag = false
	drag_offset = local_mouse_position
	press_global_position = get_global_mouse_position()
	z_index = 100
	if get_parent() != null:
		get_parent().move_child(self, get_parent().get_child_count() - 1)
	_tween_scale(Vector2(1.12, 1.12))
	_tween_rotation(0.0)


func _stop_drag() -> void:
	if not is_dragging:
		return

	is_dragging = false
	z_index = 0
	_set_target_hover(false)

	if not did_drag or _is_over_play_area():
		played.emit(self)
	else:
		return_home()


func _is_over_play_area() -> bool:
	var play_area := get_node_or_null(play_area_path) as Control
	if play_area == null:
		return false

	var mouse_position := get_global_mouse_position()
	var rect := Rect2(play_area.global_position, play_area.size)
	if rect.has_point(mouse_position):
		return true

	var target_area := get_node_or_null(target_area_path) as Control
	if target_area == null:
		return false

	return Rect2(target_area.global_position, target_area.size).has_point(mouse_position)


func _update_view() -> void:
	if not is_node_ready() or card_data == null:
		return

	name_label.text = card_data.get_display_name()
	cost_label.text = str(current_cost)
	description_label.text = card_data.get_display_description()
	art_texture.texture = card_data.get_art_texture()


func return_home() -> void:
	var tween := create_tween()
	tween.set_trans(Tween.TRANS_QUAD)
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "position", home_position, 0.16)
	tween.parallel().tween_property(self, "rotation", home_rotation, 0.16)
	_tween_scale(Vector2.ONE)


func _update_target_hover() -> void:
	var target_area := get_node_or_null(target_area_path) as Control
	if target_area == null:
		_set_target_hover(false)
		return

	var is_over := Rect2(target_area.global_position, target_area.size).has_point(get_global_mouse_position())
	_set_target_hover(is_over)


func _set_target_hover(value: bool) -> void:
	if is_target_hovering == value:
		return

	is_target_hovering = value
	target_hover_changed.emit(is_target_hovering)


func _on_mouse_entered() -> void:
	if not is_dragging:
		AudioManager.play_sfx("card_hover")
		z_index = 20
		preview_requested.emit(card_data)
		var tween := create_tween()
		tween.set_trans(Tween.TRANS_QUAD)
		tween.set_ease(Tween.EASE_OUT)
		tween.tween_property(self, "position", home_position + HOVER_OFFSET, 0.12)
		_tween_scale(Vector2(1.12, 1.12))
		_tween_rotation(0.0)


func _on_mouse_exited() -> void:
	if not is_dragging:
		z_index = 0
		preview_hidden.emit()
		var tween := create_tween()
		tween.set_trans(Tween.TRANS_QUAD)
		tween.set_ease(Tween.EASE_OUT)
		tween.tween_property(self, "position", home_position, 0.12)
		tween.parallel().tween_property(self, "rotation", home_rotation, 0.12)
		_tween_scale(Vector2.ONE)


func _tween_scale(target_scale: Vector2) -> void:
	if scale_tween != null:
		scale_tween.kill()
	scale_tween = create_tween()
	scale_tween.set_trans(Tween.TRANS_QUAD)
	scale_tween.set_ease(Tween.EASE_OUT)
	scale_tween.tween_property(self, "scale", target_scale, 0.12)


func _tween_rotation(target_rotation: float) -> void:
	var tween := create_tween()
	tween.set_trans(Tween.TRANS_QUAD)
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "rotation", target_rotation, 0.12)
