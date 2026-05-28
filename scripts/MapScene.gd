extends Control

const CHAPTER_MAP_BACKGROUNDS := {
	1: "res://assets/backgrounds/map/ch1_forest_map.png",
	2: "res://assets/backgrounds/map/ch2_molten_map.png",
	3: "res://assets/backgrounds/map/ch3_astral_map.png",
}
const CHAPTER_4_STAR_BACKGROUND := "res://assets/backgrounds/map/ch4_star_map.png"
const CHAPTER_4_ABYSS_BACKGROUND := "res://assets/backgrounds/map/ch4_abyss_map.png"

@onready var fallback_background: ColorRect = $Background
@onready var title_label: Label = $TitleLabel
@onready var progress_label: Label = $ProgressLabel
@onready var map_area: Control = $MapArea
@onready var status_label: Label = $StatusLabel
@onready var main_menu_button: Button = $MainMenuButton

var node_positions: Dictionary = {}
var is_blocked_without_run := false
var map_background_rect: TextureRect
var map_background_shade: ColorRect
var floor_node_counts: Dictionary = {}


func _ready() -> void:
	_apply_style()
	_ensure_map_background_nodes()
	if not LanguageManager.language_changed.is_connected(refresh_language_texts):
		LanguageManager.language_changed.connect(refresh_language_texts)
	main_menu_button.pressed.connect(_on_main_menu_button_pressed)
	if not RunManager.has_active_run():
		_refresh_map_background()
		_show_no_active_run()
		return
	_build_map()


func refresh_language_texts() -> void:
	if not is_node_ready():
		return
	if is_blocked_without_run or not RunManager.has_active_run():
		_show_no_active_run()
		return
	_refresh_header_text()
	for child in map_area.get_children():
		if child is MapNode:
			var node_type := str(child.node_data.get("type", child.node_data.get("node_type", "")))
			child.setup(
				child.node_data,
				_localized_node_label(node_type),
				RunManager.get_available_map_node_ids().has(child.node_id),
				RunManager.get_completed_map_node_ids().has(child.node_id)
			)


func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED and is_node_ready() and not is_blocked_without_run:
		_build_map()


func _draw() -> void:
	if is_blocked_without_run:
		return

	var available_ids := RunManager.get_available_map_node_ids()
	var completed_ids := RunManager.get_completed_map_node_ids()
	for node in RunManager.get_map_nodes():
		var from_id := str(node.get("id", node.get("node_id", "")))
		if not node_positions.has(from_id):
			continue
		for next_id_value in node.get("next_ids", node.get("connected_to", [])):
			var next_id := str(next_id_value)
			if not node_positions.has(next_id):
				continue
			var color := Color(0.25, 0.3, 0.42, 0.5)
			var width := 3.0
			if completed_ids.has(from_id):
				color = Color(1.0, 0.76, 0.28, 0.92)
				width = 4.0
			elif available_ids.has(from_id) or available_ids.has(next_id):
				color = Color(0.52, 0.78, 1.0, 0.78)
				width = 3.5
			_draw_connection(node_positions[from_id], node_positions[next_id], color, width)


func _build_map() -> void:
	if not RunManager.has_active_run():
		_show_no_active_run()
		return

	for child in map_area.get_children():
		child.queue_free()
	node_positions.clear()
	_rebuild_floor_counts()
	map_area.visible = true
	is_blocked_without_run = false
	_refresh_map_background()

	title_label.text = _localized_chapter_title()
	progress_label.text = LanguageManager.tr_format("map_chapter_progress", {
		"floor": RunManager.get_current_floor(),
		"max": 7,
		"difficulty": _localized_difficulty_name(RunManager.current_difficulty),
		"hp": RunManager.player_current_health,
		"max_hp": RunManager.player_max_health,
		"gold": RunManager.get_gold(),
	})
	status_label.text = ""
	main_menu_button.visible = false
	_refresh_header_text()

	var area_size := map_area.size
	if area_size.x <= 0.0 or area_size.y <= 0.0:
		area_size = get_viewport_rect().size - Vector2(160, 220)

	var available_ids := RunManager.get_available_map_node_ids()
	var completed_ids := RunManager.get_completed_map_node_ids()

	for node in RunManager.get_map_nodes():
		var node_id := str(node.get("id", node.get("node_id", "")))
		var layer := int(node.get("layer", node.get("floor", 1)))
		var column := int(node.get("column", node.get("position", {}).get("x", 1)))
		var pos := _node_position(area_size, layer, column, int(floor_node_counts.get(layer, 1)))
		var global_center := map_area.position + pos
		node_positions[node_id] = global_center

		var button := MapNode.new()
		map_area.add_child(button)
		var node_type := str(node.get("type", node.get("node_type", "")))
		var node_size := _node_size(node_type)
		button.position = pos - node_size * 0.5
		button.z_index = 10
		button.setup(node, _localized_node_label(node_type), available_ids.has(node_id), completed_ids.has(node_id))
		button.map_node_pressed.connect(_on_map_node_pressed)

	queue_redraw()


func _on_map_node_pressed(node_id: String) -> void:
	if is_blocked_without_run or not RunManager.has_active_run():
		status_label.text = LanguageManager.tr_key("map_no_active_run")
		return

	AudioManager.play_sfx("ui_click")
	var scene_path := RunManager.select_map_node(node_id)
	if scene_path == "":
		status_label.text = LanguageManager.tr_key("map_node_unavailable")
		return

	SaveManager.save_run()
	get_tree().change_scene_to_file(scene_path)


func _node_position(area_size: Vector2, layer: int, column: int, floor_count: int) -> Vector2:
	var x_margin: float = 86.0
	var usable_width: float = max(area_size.x - x_margin * 2.0, 220.0)
	var x: float = x_margin + ((float(layer) - 1.0) / 6.0) * usable_width

	var y_margin: float = 72.0
	var usable_height: float = max(area_size.y - y_margin * 2.0, 160.0)
	var y_ratio := 0.5
	match floor_count:
		1:
			y_ratio = 0.5
		2:
			y_ratio = 0.34 if column <= 1 else 0.66
		_:
			y_ratio = [0.24, 0.5, 0.76][clamp(column, 0, 2)]
	var y: float = y_margin + usable_height * y_ratio
	return Vector2(x, y)


func _node_size(node_type: String) -> Vector2:
	if node_type == RunManager.NODE_BOSS_BATTLE:
		return Vector2(126, 126)
	return Vector2(106, 106)


func _refresh_header_text() -> void:
	title_label.text = _localized_chapter_title()
	progress_label.text = LanguageManager.tr_format("map_chapter_progress", {
		"floor": RunManager.get_current_floor(),
		"max": 7,
		"difficulty": _localized_difficulty_name(RunManager.current_difficulty),
		"hp": RunManager.player_current_health,
		"max_hp": RunManager.player_max_health,
		"gold": RunManager.get_gold(),
	})
	main_menu_button.text = LanguageManager.tr_key("map_return_main_menu")


func _localized_node_label(node_type: String) -> String:
	match node_type:
		RunManager.NODE_NORMAL_BATTLE:
			return LanguageManager.tr_key("map_node_normal_battle")
		RunManager.NODE_ELITE_BATTLE:
			return LanguageManager.tr_key("map_node_elite_battle")
		RunManager.NODE_EVENT:
			return LanguageManager.tr_key("map_node_event")
		RunManager.NODE_SHOP:
			return LanguageManager.tr_key("map_node_shop")
		RunManager.NODE_REST:
			return LanguageManager.tr_key("map_node_rest")
		RunManager.NODE_RELIC_REWARD:
			return LanguageManager.tr_key("map_node_relic_reward")
		RunManager.NODE_SPECIAL_CARD_REWARD:
			return LanguageManager.tr_key("map_node_special_reward")
		RunManager.NODE_BOSS_BATTLE:
			return LanguageManager.tr_key("map_node_boss_battle")
	return LanguageManager.tr_key("ui_unknown")


func _localized_chapter_title() -> String:
	if RunManager.current_chapter == 4 and RunManager.ending_route == RunManager.ENDING_ROUTE_STAR:
		return LanguageManager.tr_key("chapter.4.star.name")
	if RunManager.current_chapter == 4 and RunManager.ending_route == RunManager.ENDING_ROUTE_ABYSS:
		return LanguageManager.tr_key("chapter.4.abyss.name")
	var dotted_key := "chapter.%d.name" % RunManager.current_chapter
	if LanguageManager.has_key(dotted_key):
		return LanguageManager.tr_key(dotted_key)
	return LanguageManager.tr_key("chapter_unknown")


func _localized_difficulty_name(difficulty: int) -> String:
	match difficulty:
		1:
			return LanguageManager.tr_key("difficulty_normal")
		2:
			return LanguageManager.tr_key("difficulty_advanced")
		3:
			return LanguageManager.tr_key("difficulty_hard")
		4:
			return LanguageManager.tr_key("difficulty_nightmare")
		5:
			return LanguageManager.tr_key("difficulty_final")
	return LanguageManager.tr_key("difficulty_unknown")


func _node_label(node_type: String) -> String:
	return _localized_node_label(node_type)


func _chapter_title() -> String:
	return _localized_chapter_title()


func _apply_style() -> void:
	fallback_background.z_index = -100
	title_label.add_theme_font_size_override("font_size", 40)
	title_label.add_theme_color_override("font_color", Color(1.0, 0.88, 0.62))
	progress_label.add_theme_font_size_override("font_size", 24)
	progress_label.add_theme_color_override("font_color", Color(0.82, 0.9, 1.0))
	status_label.add_theme_font_size_override("font_size", 22)
	status_label.add_theme_color_override("font_color", Color(0.9, 0.84, 0.66))
	main_menu_button.add_theme_font_size_override("font_size", 24)


func _show_no_active_run() -> void:
	is_blocked_without_run = true
	_refresh_map_background()
	for child in map_area.get_children():
		child.queue_free()
	node_positions.clear()
	map_area.visible = false
	title_label.text = LanguageManager.tr_key("map_title")
	progress_label.text = ""
	status_label.text = LanguageManager.tr_key("map_no_active_run")
	main_menu_button.visible = true
	main_menu_button.text = LanguageManager.tr_key("map_return_main_menu")
	queue_redraw()


func _on_main_menu_button_pressed() -> void:
	AudioManager.play_sfx("ui_click")
	get_tree().change_scene_to_file("res://scenes/MainMenu.tscn")


func _rebuild_floor_counts() -> void:
	floor_node_counts.clear()
	for node in RunManager.get_map_nodes():
		var layer := int(node.get("layer", node.get("floor", 1)))
		floor_node_counts[layer] = int(floor_node_counts.get(layer, 0)) + 1


func _draw_connection(from_pos: Vector2, to_pos: Vector2, color: Color, width: float) -> void:
	draw_line(from_pos, to_pos, color, width, true)
	var direction := (to_pos - from_pos).normalized()
	if direction == Vector2.ZERO:
		return
	var arrow_length := 15.0
	var arrow_width := 9.0
	var tip := to_pos - direction * 52.0
	var back := tip - direction * arrow_length
	var normal := Vector2(-direction.y, direction.x)
	var points := PackedVector2Array([
		tip,
		back + normal * arrow_width,
		back - normal * arrow_width,
	])
	draw_colored_polygon(points, color)


func _ensure_map_background_nodes() -> void:
	if map_background_rect == null:
		map_background_rect = TextureRect.new()
		map_background_rect.name = "ChapterMapBackground"
		map_background_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
		map_background_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
		map_background_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		map_background_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		map_background_rect.z_index = -99
		add_child(map_background_rect)

	if map_background_shade == null:
		map_background_shade = ColorRect.new()
		map_background_shade.name = "MapBackgroundShade"
		map_background_shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
		map_background_shade.color = Color(0.02, 0.025, 0.04, 0.34)
		map_background_shade.set_anchors_preset(Control.PRESET_FULL_RECT)
		map_background_shade.z_index = -98
		add_child(map_background_shade)


func _refresh_map_background() -> void:
	_ensure_map_background_nodes()
	var path := _map_background_path()
	if path.is_empty():
		map_background_rect.texture = null
		map_background_shade.visible = false
		return
	if not ResourceLoader.exists(path):
		push_warning("[MapScene] missing map background: " + path)
		map_background_rect.texture = null
		map_background_shade.visible = false
		return
	var resource: Resource = load(path)
	var texture: Texture2D = resource as Texture2D
	if texture == null:
		push_warning("[MapScene] failed to load map background: " + path)
		map_background_rect.texture = null
		map_background_shade.visible = false
		return
	map_background_rect.texture = texture
	map_background_shade.visible = true


func _map_background_path() -> String:
	if RunManager.current_chapter == 4:
		if RunManager.ending_route == RunManager.ENDING_ROUTE_STAR:
			return CHAPTER_4_STAR_BACKGROUND
		if RunManager.ending_route == RunManager.ENDING_ROUTE_ABYSS:
			return CHAPTER_4_ABYSS_BACKGROUND
		push_warning("[MapScene] chapter 4 has no valid ending_route: " + RunManager.ending_route)
		return ""
	if CHAPTER_MAP_BACKGROUNDS.has(RunManager.current_chapter):
		return str(CHAPTER_MAP_BACKGROUNDS[RunManager.current_chapter])
	push_warning("[MapScene] no map background configured for chapter: %d" % RunManager.current_chapter)
	return ""
