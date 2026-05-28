extends Control

const STAR_BACKGROUND_PATH := "res://assets/backgrounds/map/ch4_star_map.png"
const ABYSS_BACKGROUND_PATH := "res://assets/backgrounds/map/ch4_abyss_map.png"

var title_label: Label
var body_label: Label
var continue_button: Button


func _ready() -> void:
	_build_ui()
	if not LanguageManager.language_changed.is_connected(_refresh_story):
		LanguageManager.language_changed.connect(_refresh_story)
	_refresh_story()


func _build_ui() -> void:
	var background := TextureRect.new()
	background.name = "Background"
	background.set_anchors_preset(Control.PRESET_FULL_RECT)
	background.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	background.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	background.texture = _load_background()
	add_child(background)

	var fallback := ColorRect.new()
	fallback.color = Color(0.02, 0.018, 0.03, 0.62)
	fallback.set_anchors_preset(Control.PRESET_FULL_RECT)
	fallback.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(fallback)

	var panel := PanelContainer.new()
	panel.set_anchors_preset(Control.PRESET_CENTER)
	panel.offset_left = -520
	panel.offset_top = -300
	panel.offset_right = 520
	panel.offset_bottom = 300
	panel.add_theme_stylebox_override("panel", _panel_style())
	add_child(panel)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 44)
	margin.add_theme_constant_override("margin_right", 44)
	margin.add_theme_constant_override("margin_top", 38)
	margin.add_theme_constant_override("margin_bottom", 36)
	panel.add_child(margin)

	var box := VBoxContainer.new()
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_theme_constant_override("separation", 24)
	margin.add_child(box)

	title_label = Label.new()
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_label.add_theme_font_size_override("font_size", 46)
	title_label.add_theme_color_override("font_color", Color(1.0, 0.86, 0.52))
	title_label.add_theme_color_override("font_outline_color", Color(0.04, 0.025, 0.02, 0.95))
	title_label.add_theme_constant_override("outline_size", 2)
	box.add_child(title_label)

	body_label = Label.new()
	body_label.custom_minimum_size = Vector2(900, 340)
	body_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body_label.add_theme_font_size_override("font_size", 24)
	body_label.add_theme_color_override("font_color", Color(0.94, 0.9, 0.8))
	body_label.add_theme_color_override("font_outline_color", Color(0.03, 0.025, 0.02, 0.9))
	body_label.add_theme_constant_override("outline_size", 1)
	box.add_child(body_label)

	continue_button = Button.new()
	continue_button.custom_minimum_size = Vector2(320, 58)
	continue_button.add_theme_font_size_override("font_size", 25)
	continue_button.add_theme_color_override("font_color", Color(0.95, 0.86, 0.68))
	continue_button.add_theme_stylebox_override("normal", _button_style(Color(0.12, 0.1, 0.15, 0.78), Color(0.75, 0.58, 0.3)))
	continue_button.add_theme_stylebox_override("hover", _button_style(Color(0.16, 0.13, 0.2, 0.9), Color(0.96, 0.76, 0.42)))
	continue_button.add_theme_stylebox_override("pressed", _button_style(Color(0.08, 0.07, 0.11, 0.94), Color(0.9, 0.68, 0.34)))
	continue_button.pressed.connect(_on_continue_pressed)
	box.add_child(continue_button)


func _refresh_story() -> void:
	if RunManager.chapter4_route == RunManager.ENDING_ROUTE_ABYSS:
		title_label.text = LanguageManager.tr_key("chapter4_intro.abyss.title")
		body_label.text = LanguageManager.tr_key("chapter4_intro.abyss.body")
		continue_button.text = LanguageManager.tr_key("chapter4_intro.abyss.button")
		return
	title_label.text = LanguageManager.tr_key("chapter4_intro.star.title")
	body_label.text = LanguageManager.tr_key("chapter4_intro.star.body")
	continue_button.text = LanguageManager.tr_key("chapter4_intro.star.button")
	return
	if RunManager.chapter4_route == RunManager.ENDING_ROUTE_ABYSS:
		title_label.text = "深渊回应"
		body_label.text = "世界吞噬者倒下后，星界神殿陷入死寂。\n\n可就在星光即将熄灭的瞬间，你灵魂深处的契约开始燃烧。黑色灰烬从掌心升起，像无数断裂的命运丝线重新缠上你的身体。\n\n你曾签下深渊契约，试图夺取命运的权柄。\n\n如今，深渊回应了你的欲望。\n\n一道不应存在的裂隙在神殿尽头张开，里面传来低沉的呼唤。那不是救赎，而是一场交换。\n\n你将夺取命运，但也必须承受深渊的代价。"
		continue_button.text = "回应深渊"
		return

	title_label.text = "星辰之路"
	body_label.text = "世界吞噬者倒下后，星界神殿并未崩塌。\n\n天空中破碎的星图开始缓慢重组，银白色的命运丝线从虚空中垂落，连接起那些早已断裂的道路。\n\n你曾在星辰低语中接受了命运的指引。\n\n如今，星辰回应了你的选择。\n\n一条通往命运裂隙深处的道路在光中显现。那里没有逃避，也没有反抗，只有最终的审判与归位。\n\n你将接纳命运，让世界回归星辰秩序。"
	continue_button.text = "继续前往命运裂隙"


func _on_continue_pressed() -> void:
	AudioManager.play_sfx("ui_click")
	if RunManager.continue_from_chapter4_intro():
		get_tree().change_scene_to_file(RunManager.MAP_SCENE_PATH)
		return
	get_tree().change_scene_to_file(RunManager.VICTORY_SCENE_PATH)


func _load_background() -> Texture2D:
	var path := STAR_BACKGROUND_PATH
	if RunManager.chapter4_route == RunManager.ENDING_ROUTE_ABYSS:
		path = ABYSS_BACKGROUND_PATH
	if not ResourceLoader.exists(path):
		push_warning("[Chapter4 Intro] missing background: " + path)
		return null
	return load(path) as Texture2D


func _panel_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.035, 0.03, 0.055, 0.76)
	style.border_color = Color(0.82, 0.66, 0.36, 0.74)
	style.set_border_width_all(1)
	style.set_corner_radius_all(12)
	style.shadow_color = Color(0, 0, 0, 0.55)
	style.shadow_size = 16
	return style


func _button_style(bg_color: Color, border_color: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = bg_color
	style.border_color = border_color
	style.set_border_width_all(1)
	style.set_corner_radius_all(8)
	style.shadow_color = Color(0, 0, 0, 0.45)
	style.shadow_size = 8
	style.content_margin_left = 18
	style.content_margin_right = 18
	style.content_margin_top = 8
	style.content_margin_bottom = 8
	return style
