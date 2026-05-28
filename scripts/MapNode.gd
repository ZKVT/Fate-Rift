extends Button
class_name MapNode

signal map_node_pressed(node_id: String)

const NODE_ICON_PATHS := {
	"NormalBattle": "res://assets/ui/map/normal_battle_icon.png",
	"EliteBattle": "res://assets/ui/map/elite_battle_icon.png",
	"BossBattle": "res://assets/ui/map/boss_battle_icon.png",
	"Event": "res://assets/ui/map/event_icon.png",
	"Shop": "res://assets/ui/map/shop_icon.png",
	"Rest": "res://assets/ui/map/rest_icon.png",
	"RelicReward": "res://assets/ui/map/relic_reward_icon.png",
	"SpecialCardReward": "res://assets/ui/map/special_card_reward_icon.png",
}

var node_id := ""
var available := false
var completed := false
var node_data: Dictionary = {}


func setup(node_data: Dictionary, label_text: String, is_available: bool, is_completed: bool) -> void:
	self.node_data = node_data.duplicate(true)
	node_id = str(node_data.get("id", ""))
	available = is_available
	completed = is_completed
	text = label_text
	var node_type := str(node_data.get("type", node_data.get("node_type", "")))
	custom_minimum_size = Vector2(126, 126) if node_type == "BossBattle" else Vector2(106, 106)
	disabled = completed or not available
	focus_mode = Control.FOCUS_NONE
	clip_text = true
	expand_icon = true
	icon = _load_icon(node_type)
	tooltip_text = label_text
	add_theme_font_size_override("font_size", 16 if node_type != "BossBattle" else 18)
	add_theme_stylebox_override("normal", _node_style(node_type, available, completed, false))
	add_theme_stylebox_override("hover", _node_style(node_type, available, completed, true))
	add_theme_stylebox_override("pressed", _node_style(node_type, available, completed, true))
	add_theme_stylebox_override("disabled", _node_style(node_type, available, completed, false))

	if completed:
		disabled = true
		modulate = Color(0.5, 0.52, 0.54, 0.78)
	elif available:
		modulate = Color(1.0, 0.95, 0.62, 1.0)
	else:
		modulate = Color(0.48, 0.52, 0.62, 0.5)

	var callback := Callable(self, "_on_pressed")
	if not pressed.is_connected(callback):
		pressed.connect(callback)


func _load_icon(node_type: String) -> Texture2D:
	var icon_path: String = str(NODE_ICON_PATHS.get(node_type, ""))
	if icon_path == "":
		return null

	if not ResourceLoader.exists(icon_path):
		push_warning("[MapNode] missing icon: " + icon_path)
		return null

	return load(icon_path) as Texture2D


func _on_pressed() -> void:
	if completed or not available:
		return
	map_node_pressed.emit(node_id)


func _node_style(node_type: String, is_available: bool, is_completed: bool, is_hover: bool) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	var bg_color := Color(0.09, 0.09, 0.12, 0.84)
	var border_color := Color(0.34, 0.36, 0.44, 0.8)
	var border_width := 1
	if is_completed:
		bg_color = Color(0.08, 0.08, 0.085, 0.64)
		border_color = Color(0.72, 0.62, 0.42, 0.75)
	elif is_available:
		bg_color = Color(0.12, 0.105, 0.08, 0.92)
		border_color = Color(1.0, 0.78, 0.24, 1.0)
		border_width = 3
	else:
		bg_color = Color(0.055, 0.06, 0.075, 0.58)
		border_color = Color(0.24, 0.27, 0.34, 0.65)

	if node_type == "BossBattle":
		border_color = Color(1.0, 0.36, 0.24, 1.0) if is_available else border_color
		border_width += 1
	if is_hover and is_available and not is_completed:
		bg_color = bg_color.lightened(0.12)
		border_color = border_color.lightened(0.08)

	style.bg_color = bg_color
	style.border_color = border_color
	style.set_border_width_all(border_width)
	style.set_corner_radius_all(18 if node_type == "BossBattle" else 14)
	style.content_margin_left = 8
	style.content_margin_right = 8
	style.content_margin_top = 8
	style.content_margin_bottom = 8
	return style
