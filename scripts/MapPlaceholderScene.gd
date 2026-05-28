extends Control

@onready var title_label: Label = $Panel/MarginContainer/VBoxContainer/TitleLabel
@onready var description_label: Label = $Panel/MarginContainer/VBoxContainer/DescriptionLabel
@onready var continue_button: Button = $Panel/MarginContainer/VBoxContainer/ContinueButton


func _ready() -> void:
	continue_button.pressed.connect(_on_continue_button_pressed)
	_apply_style()
	_build_content()


func _build_content() -> void:
	var node_type := RunManager.get_current_map_node_type()
	match node_type:
		RunManager.NODE_EVENT:
			title_label.text = "随机事件"
			description_label.text = "随机事件开发中。"
		RunManager.NODE_SHOP:
			title_label.text = "商店"
			description_label.text = "商店开发中。"
		RunManager.NODE_REST:
			var healed := RunManager.rest_at_current_node()
			title_label.text = "休息点"
			description_label.text = "你休息片刻，恢复了 %d 点生命。" % healed
			SaveManager.save_run()
		_:
			title_label.text = "路线节点"
			description_label.text = "这个节点暂时还没有完整内容。"


func _on_continue_button_pressed() -> void:
	AudioManager.play_sfx("ui_click")
	RunManager.complete_current_map_node()
	SaveManager.save_run()
	get_tree().change_scene_to_file(RunManager.MAP_SCENE_PATH)


func _apply_style() -> void:
	title_label.add_theme_font_size_override("font_size", 40)
	title_label.add_theme_color_override("font_color", Color(1.0, 0.86, 0.58))
	description_label.add_theme_font_size_override("font_size", 26)
	description_label.add_theme_color_override("font_color", Color(0.92, 0.9, 0.8))
	continue_button.add_theme_font_size_override("font_size", 28)
