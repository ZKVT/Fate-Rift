extends Control

const MAIN_MENU_SCENE_PATH := "res://scenes/MainMenu.tscn"
const TURN_BANNER_TIME := 0.8
const ENEMY_TURN_START_DELAY := 0.5
const ENEMY_ATTACK_WINDUP := 0.3
const HIT_PAUSE_TIME := 0.12
const AFTER_HIT_DELAY := 0.4
const ENEMY_TURN_END_DELAY := 0.5
const CARD_PLAY_ANIM_TIME := 0.25
const HEALTH_BAR_TWEEN_TIME := 0.18
const FLOATING_TEXT_LIFETIME := 1.15
const BATTLE_BACKGROUND_PATHS := {
	1: "res://assets/backgrounds/battle/chapter_1_forest_ruins.png",
	2: "res://assets/backgrounds/battle/chapter_2_molten_castle.png",
	3: "res://assets/backgrounds/battle/chapter_3_astral_temple.png",
}
const CHAPTER_4_STAR_BACKGROUND_PATH := "res://assets/backgrounds/battle/chapter_4_star_route.png"
const CHAPTER_4_ABYSS_BACKGROUND_PATH := "res://assets/backgrounds/battle/chapter_4_abyss_route.png"
const CHAPTER_4_ABYSS_ENEMY_ART_PATHS := {
	"fate_echo": "res://assets/enemies/chapter_4/fate_echo_abyss.png",
	"rift_spirit": "res://assets/enemies/chapter_4/rift_spirit_abyss.png",
	"eclipse_acolyte": "res://assets/enemies/chapter_4/eclipse_acolyte_abyss.png",
}

@onready var deck_manager: DeckManager = $DeckManager
@onready var hand_manager: HandManager = $HandManager
@onready var turn_manager: TurnManager = $TurnManager
@onready var player: Player = $Player
@onready var enemy: Enemy = $Enemy
@onready var player_label: Label = $PlayerLabel
@onready var energy_label: Label = $EnergyLabel
@onready var draw_pile_label: Label = $DrawPileLabel
@onready var discard_pile_label: Label = $DiscardPileLabel
@onready var enemy_label: Label = $EnemyLabel
@onready var player_status_label: Label = $PlayerStatusLabel
@onready var relics_label: Label = $RelicsLabel
@onready var enemy_status_label: Label = $EnemyStatusLabel
@onready var enemy_intent_label: Label = $EnemyIntentLabel
@onready var action_log_label: Label = $ActionLogLabel
@onready var battle_background_texture: TextureRect = $BattleBackgroundTexture
@onready var enemy_art_texture: TextureRect = $EnemyArtTexture
@onready var enemy_target_area: ColorRect = $EnemyTargetArea
@onready var enemy_hud_panel: Panel = $EnemyHudPanel
@onready var player_hud_panel: Panel = $PlayerHudPanel
@onready var enemy_health_bar: ProgressBar = $EnemyHealthBar
@onready var player_health_bar: ProgressBar = $PlayerHealthBar
@onready var player_energy_bar: ProgressBar = $PlayerEnergyBar
@onready var phase_banner: Label = $PhaseBanner
@onready var card_preview_panel: PanelContainer = $CardPreviewPanel
@onready var preview_art_texture: TextureRect = $CardPreviewPanel/MarginContainer/VBoxContainer/PreviewArtTexture
@onready var preview_name_label: Label = $CardPreviewPanel/MarginContainer/VBoxContainer/PreviewNameLabel
@onready var preview_cost_label: Label = $CardPreviewPanel/MarginContainer/VBoxContainer/PreviewCostLabel
@onready var preview_description_label: Label = $CardPreviewPanel/MarginContainer/VBoxContainer/PreviewDescriptionLabel
@onready var end_turn_button: Button = $EndTurnButton
@onready var view_deck_button: Button = $ViewDeckButton
@onready var main_menu_button: Button = $MainMenuButton
@onready var hand_area: Control = $HandArea
@onready var play_area: ColorRect = $PlayArea
@onready var deck_view: DeckView = $DeckView
@onready var game_over_overlay: Control = $GameOverOverlay
@onready var result_label: Label = $GameOverOverlay/ResultLabel
@onready var restart_button: Button = $GameOverOverlay/RestartButton
@onready var play_card_audio: AudioStreamPlayer = $PlayCardAudio
@onready var hit_audio: AudioStreamPlayer = $HitAudio
@onready var button_audio: AudioStreamPlayer = $ButtonAudio
@onready var debug_panel: DebugPanel = $DebugPanel

var is_game_over := false
var battle_ended := false
var cards_played_this_turn := 0
var played_attack_this_turn := false
var attack_played_before_current_card := false
var current_damage_multiplier := 1
var next_turn_damage_multiplier := 1
var delayed_heal_next_turn := 0
var emperor_block_per_turn := 0
var star_extra_draw_per_turn := 0
var devil_self_damage_per_turn := 0
var wheel_of_fortune_active := false
var world_skip_enemy_turn_pending := false
var next_card_double_cast := false
var fate_ember_reviving := false
var current_resolving_card: CardData
var last_player_health := -1
var last_enemy_health := -1
var last_player_block := -1
var last_enemy_block := -1
var last_player_energy := -1
var last_player_burn := -1
var last_player_weak := -1
var last_enemy_burn := -1
var last_enemy_weak := -1
var is_animating := false
var is_enemy_turn_running := false
var player_health_tween: Tween
var enemy_health_tween: Tween
var floating_text_sequence := 0
var boss_mechanic_label: Label
var relic_icon_bar: HBoxContainer
var battle_ui_layer: Control
var enemy_area: Control
var player_area: Control
var hand_ui_area: Control
var action_area: Control
var utility_area: Control
var floating_text_layer: Control
var card_preview_layer: Control
var popup_layer: Control
var player_block_label: Label
var enemy_block_label: Label
var enemy_hp_label: Label
var turn_info_label: Label
var deck_pile_panel: PanelContainer
var deck_pile_label: Label
var exhaust_pile_label: Label
var hand_count_label: Label
var enemy_stage_panel: PanelContainer
var enemy_dais_panel: PanelContainer
var hand_area_panel: PanelContainer
var main_menu_confirm_overlay: ColorRect
var main_menu_confirm_title: Label
var main_menu_confirm_message: Label
var main_menu_confirm_accept_button: Button
var main_menu_confirm_cancel_button: Button
var action_log_last_text := ""
var action_log_timer := 0.0
var action_log_fading := false


func _ready() -> void:
	_apply_dark_fantasy_ui()
	_apply_battle_background()
	deck_manager.piles_changed.connect(_on_piles_changed)
	deck_manager.draw_failed_empty.connect(_on_draw_failed_empty)
	hand_manager.card_play_requested.connect(_on_card_play_requested)
	hand_manager.card_target_hover_changed.connect(_on_card_target_hover_changed)
	hand_manager.card_preview_requested.connect(_on_card_preview_requested)
	hand_manager.card_preview_hidden.connect(_on_card_preview_hidden)
	hand_manager.cards_overflowed.connect(_on_hand_cards_overflowed)
	turn_manager.turn_started.connect(_on_turn_started)
	turn_manager.turn_ended.connect(_on_turn_ended)
	player.health_changed.connect(_on_player_health_changed)
	player.energy_changed.connect(_on_player_energy_changed)
	player.status_changed.connect(_on_player_status_changed)
	player.damage_taken.connect(_on_player_damage_taken)
	player.died.connect(_on_player_died)
	enemy.health_changed.connect(_on_enemy_health_changed)
	enemy.status_changed.connect(_on_enemy_status_changed)
	enemy.intent_changed.connect(_on_enemy_intent_changed)
	enemy.boss_mechanic_changed.connect(_on_enemy_boss_mechanic_changed)
	enemy.action_performed.connect(_on_enemy_action_performed)
	enemy.died.connect(_on_enemy_died)
	end_turn_button.pressed.connect(_on_end_turn_button_pressed)
	view_deck_button.pressed.connect(_on_view_deck_button_pressed)
	main_menu_button.pressed.connect(_on_main_menu_button_pressed)
	LanguageManager.language_changed.connect(refresh_language_texts)
	restart_button.pressed.connect(_on_restart_button_pressed)
	restart_button.text = LanguageManager.tr_key("battle_return_main_menu")
	_setup_debug_panel()

	game_over_overlay.visible = false
	enemy_target_area.visible = false
	card_preview_panel.visible = false
	phase_banner.modulate.a = 0.0
	phase_banner.add_theme_font_size_override("font_size", 36)
	action_log_label.text = LanguageManager.tr_key("battle_start")
	player.set_current_health(RunManager.player_current_health)
	var enemy_data := RunManager.get_current_enemy_data()
	if enemy_data != null:
		enemy.setup_from_data(enemy_data)
		_set_enemy_art_for_data(enemy_data)
	elif enemy.enemy_data != null:
		_set_enemy_art_for_data(enemy.enemy_data)
	_on_player_health_changed(player.current_health, player.max_health)
	_on_player_energy_changed(player.current_energy, player.max_energy)
	last_player_block = player.block
	last_player_burn = player.burn_stacks
	last_player_weak = player.weak_stacks
	_on_enemy_health_changed(enemy.current_health, enemy.max_health)
	_on_enemy_status_changed(enemy.get_status_text())
	_refresh_boss_mechanic_ui()
	_on_enemy_intent_changed(enemy.get_current_intent_text())

	deck_manager.create_starter_deck()
	update_all_ui()
	_refresh_relic_icon_bar()
	var battle_start_relic_log := RelicManager.trigger_battle_start(player, enemy, hand_manager, deck_manager)
	if battle_start_relic_log != "":
		action_log_label.text = battle_start_relic_log
	update_all_ui()
	turn_manager.start_next_turn()


func _process(delta: float) -> void:
	_update_action_log_visibility(delta)


func refresh_language_texts() -> void:
	if end_turn_button != null:
		end_turn_button.text = _tr_or("battle_end_turn", "End Turn")
	if view_deck_button != null:
		view_deck_button.text = _tr_or("battle_view_deck", "View Deck")
	if main_menu_button != null:
		main_menu_button.text = _tr_or("battle_return_main_menu", "Main Menu")
	if restart_button != null:
		restart_button.text = _tr_or("battle_return_main_menu", "Main Menu")
	if player != null:
		_on_player_health_changed(player.current_health, player.max_health)
		_on_player_energy_changed(player.current_energy, player.max_energy)
		_update_player_block_ui()
	if enemy != null:
		_on_enemy_health_changed(enemy.current_health, enemy.max_health)
		_update_enemy_block_ui()
		_on_enemy_status_changed(enemy.get_status_text())
		_on_enemy_intent_changed(enemy.get_current_intent_text())
	update_deck_ui()
	update_player_ui()
	if card_preview_panel != null and card_preview_panel.visible and current_resolving_card != null:
		_on_card_preview_requested(current_resolving_card)


func _apply_battle_background() -> void:
	# Battle backgrounds are selected from the current chapter without changing
	# the scene tree, so opening BattleScene directly still keeps its fallback art.
	var background_path := _get_battle_background_path()
	if background_path == "":
		return

	if not ResourceLoader.exists(background_path):
		push_warning("[Battle Background] missing background: " + background_path)
		return

	var texture := load(background_path) as Texture2D
	if texture == null:
		push_warning("[Battle Background] failed to load: " + background_path)
		return

	battle_background_texture.texture = texture
	battle_background_texture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	battle_background_texture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	print("[Battle Background] loaded: ", background_path)


func _get_battle_background_path() -> String:
	if RunManager.current_chapter == 4:
		if RunManager.ending_route == RunManager.ENDING_ROUTE_ABYSS:
			return CHAPTER_4_ABYSS_BACKGROUND_PATH
		return CHAPTER_4_STAR_BACKGROUND_PATH

	return str(BATTLE_BACKGROUND_PATHS.get(RunManager.current_chapter, ""))


func _apply_dark_fantasy_ui() -> void:
	# Build a clean HUD on top of the existing combat logic. The original scene
	# nodes remain for compatibility, but the visible battle UI is recreated here.
	z_index = 0
	_rebuild_battle_ui()

	_style_label(player_label, Color(1.0, 0.82, 0.72), 24)
	_style_label(energy_label, Color(0.5, 0.86, 1.0), 22)
	_style_label(player_block_label, Color(0.68, 0.9, 1.0), 22)
	_style_label(player_status_label, Color(0.82, 0.94, 1.0), 20)
	_style_label(relics_label, Color(0.88, 0.76, 1.0), 18)
	_style_label(draw_pile_label, Color(0.88, 0.76, 0.55), 18)
	_style_label(discard_pile_label, Color(0.88, 0.76, 0.55), 18)
	_style_label(exhaust_pile_label, Color(0.88, 0.76, 0.55), 18)
	_style_label(hand_count_label, Color(0.88, 0.76, 0.55), 18)
	_style_label(enemy_label, Color(1.0, 0.82, 0.56), 30)
	_style_label(enemy_hp_label, Color(1.0, 0.88, 0.72), 20)
	_style_label(enemy_block_label, Color(0.68, 0.9, 1.0), 21)
	_style_label(enemy_status_label, Color(0.88, 0.94, 1.0), 19)
	_style_label(enemy_intent_label, Color(1.0, 0.84, 0.34), 20)
	_style_label(boss_mechanic_label, Color(1.0, 0.52, 0.18), 20)
	_style_label(turn_info_label, Color(1.0, 0.86, 0.58), 18)
	_style_label(deck_pile_label, Color(0.94, 0.88, 0.7), 19)
	_style_progress_bar(player_health_bar, Color(0.72, 0.08, 0.08, 0.92), Color(0.12, 0.04, 0.05, 0.74))
	_style_progress_bar(player_energy_bar, Color(0.1, 0.55, 0.95, 0.9), Color(0.03, 0.07, 0.12, 0.72))
	_style_progress_bar(enemy_health_bar, Color(0.78, 0.05, 0.04, 0.94), Color(0.14, 0.035, 0.04, 0.76))

	_style_button(end_turn_button, 30)
	_style_button(view_deck_button, 18)
	_style_button(main_menu_button, 18)
	_style_preview_panel()
	_style_label(action_log_label, Color(0.9, 0.82, 0.62), 18)
	action_log_label.modulate.a = 0.78


func _rebuild_battle_ui() -> void:
	_hide_legacy_battle_ui()
	battle_ui_layer = _make_fullscreen_layer("BattleUILayer", 1)
	add_child(battle_ui_layer)

	enemy_area = _make_fullscreen_layer("EnemyArea", 10)
	player_area = _make_fullscreen_layer("PlayerArea", 18)
	hand_ui_area = _make_fullscreen_layer("HandArea", 14)
	action_area = _make_fullscreen_layer("ActionArea", 18)
	utility_area = _make_fullscreen_layer("UtilityArea", 20)
	floating_text_layer = _make_fullscreen_layer("FloatingTextLayer", 90)
	card_preview_layer = _make_fullscreen_layer("CardPreviewLayer", 100)
	popup_layer = _make_fullscreen_layer("PopupLayer", 120)
	battle_ui_layer.add_child(enemy_area)
	battle_ui_layer.add_child(player_area)
	battle_ui_layer.add_child(hand_ui_area)
	battle_ui_layer.add_child(action_area)
	battle_ui_layer.add_child(utility_area)
	battle_ui_layer.add_child(floating_text_layer)
	battle_ui_layer.add_child(card_preview_layer)
	battle_ui_layer.add_child(popup_layer)

	_build_enemy_area()
	_build_player_area()
	_build_hand_area()
	_build_action_area()
	_build_utility_area()
	_build_feedback_layers()
	_build_preview_layer()
	_raise_battle_info_text()
	_refresh_rebuilt_battle_layout()
	_debug_battle_ui_bindings()
	if deck_view != null:
		deck_view.z_index = 230
	if game_over_overlay != null:
		game_over_overlay.z_index = 240
	if main_menu_confirm_overlay == null:
		_build_main_menu_confirm_dialog()
	validate_battle_ui_bindings()


func _hide_legacy_battle_ui() -> void:
	var legacy_nodes: Array[CanvasItem] = [
		enemy_hud_panel,
		player_hud_panel,
		enemy_health_bar,
		player_health_bar,
		player_energy_bar,
		player_label,
		energy_label,
		draw_pile_label,
		discard_pile_label,
		enemy_label,
		player_status_label,
		relics_label,
		enemy_status_label,
		enemy_intent_label,
		action_log_label,
		end_turn_button,
		view_deck_button,
		main_menu_button,
		phase_banner,
		card_preview_panel
	]
	for node in legacy_nodes:
		if node != null:
			node.visible = false
	if play_area != null:
		play_area.visible = false


func _build_enemy_area() -> void:
	enemy_hud_panel = Panel.new()
	enemy_hud_panel.name = "EnemyInfoPanel"
	enemy_hud_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	enemy_hud_panel.clip_contents = false
	enemy_hud_panel.add_theme_stylebox_override("panel", _make_battle_panel_style(0.9, 12))
	enemy_area.add_child(enemy_hud_panel)
	_position_top_center(enemy_hud_panel, Vector2(-340, 24), Vector2(340, 214))

	enemy_label = _make_clean_label("EnemyNameLabel", HORIZONTAL_ALIGNMENT_CENTER)
	enemy_label.add_theme_font_size_override("font_size", 24)
	enemy_label.custom_minimum_size = Vector2(600, 26)
	enemy_hp_label = _make_clean_label("EnemyHPLabel", HORIZONTAL_ALIGNMENT_CENTER)
	enemy_hp_label.add_theme_font_size_override("font_size", 20)
	enemy_hp_label.custom_minimum_size = Vector2(600, 22)

	enemy_health_bar = _make_progress_bar("EnemyHealthBar")
	enemy_health_bar.custom_minimum_size = Vector2(540, 18)
	enemy_health_bar.size_flags_horizontal = Control.SIZE_SHRINK_CENTER

	enemy_block_label = _make_clean_label("EnemyBlockLabel", HORIZONTAL_ALIGNMENT_CENTER)
	enemy_status_label = _make_clean_label("EnemyStatusLabel", HORIZONTAL_ALIGNMENT_CENTER)
	enemy_intent_label = _make_clean_label("EnemyIntentLabel", HORIZONTAL_ALIGNMENT_CENTER)
	enemy_block_label.autowrap_mode = TextServer.AUTOWRAP_OFF
	enemy_status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	enemy_intent_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	enemy_status_label.text_overrun_behavior = TextServer.OVERRUN_NO_TRIMMING
	enemy_intent_label.text_overrun_behavior = TextServer.OVERRUN_NO_TRIMMING

	boss_mechanic_label = _make_clean_label("BossMechanicLabel", HORIZONTAL_ALIGNMENT_CENTER)
	boss_mechanic_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	boss_mechanic_label.visible = false

	var enemy_margin := MarginContainer.new()
	enemy_margin.name = "EnemyInfoMargin"
	enemy_hud_panel.add_child(enemy_margin)
	_position_full_rect(enemy_margin, 18, 8, 18, 8)

	var enemy_box := VBoxContainer.new()
	enemy_box.name = "EnemyInfoBox"
	enemy_box.alignment = BoxContainer.ALIGNMENT_CENTER
	enemy_box.add_theme_constant_override("separation", 4)
	enemy_margin.add_child(enemy_box)

	enemy_box.add_child(enemy_label)
	enemy_box.add_child(enemy_hp_label)
	var enemy_hp_center := CenterContainer.new()
	enemy_hp_center.name = "EnemyHPBarCenter"
	enemy_hp_center.custom_minimum_size = Vector2(600, 18)
	enemy_box.add_child(enemy_hp_center)
	enemy_hp_center.add_child(enemy_health_bar)

	var enemy_top_info_row := HBoxContainer.new()
	enemy_top_info_row.name = "EnemyTopInfoRow"
	enemy_top_info_row.alignment = BoxContainer.ALIGNMENT_CENTER
	enemy_top_info_row.add_theme_constant_override("separation", 28)
	enemy_box.add_child(enemy_top_info_row)
	enemy_block_label.custom_minimum_size = Vector2(210, 26)
	enemy_intent_label.custom_minimum_size = Vector2(330, 30)
	enemy_block_label.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	enemy_intent_label.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	enemy_top_info_row.add_child(enemy_block_label)
	enemy_top_info_row.add_child(enemy_intent_label)

	enemy_status_label.custom_minimum_size = Vector2(600, 30)
	enemy_status_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	enemy_box.add_child(enemy_status_label)

	boss_mechanic_label.custom_minimum_size = Vector2(600, 24)
	enemy_box.add_child(boss_mechanic_label)

	enemy_stage_panel = PanelContainer.new()
	enemy_stage_panel.name = "EnemyCardFrame"
	enemy_stage_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	enemy_stage_panel.add_theme_stylebox_override("panel", _make_enemy_stage_style())
	enemy_area.add_child(enemy_stage_panel)
	_position_top_center(enemy_stage_panel, Vector2(-188, 226), Vector2(188, 626))

	enemy_dais_panel = PanelContainer.new()
	enemy_dais_panel.name = "EnemyCardCaption"
	enemy_dais_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	enemy_dais_panel.add_theme_stylebox_override("panel", _make_enemy_dais_style())
	enemy_dais_panel.visible = false
	enemy_area.add_child(enemy_dais_panel)
	_position_top_center(enemy_dais_panel, Vector2(-148, 522), Vector2(148, 554))

	_reparent_to(enemy_art_texture, enemy_area)
	enemy_art_texture.visible = true
	enemy_art_texture.mouse_filter = Control.MOUSE_FILTER_IGNORE
	enemy_art_texture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	enemy_art_texture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	enemy_art_texture.custom_minimum_size = Vector2(330, 370)
	enemy_art_texture.z_index = 12
	_position_top_center(enemy_art_texture, Vector2(-165, 242), Vector2(165, 608))

	_reparent_to(enemy_target_area, enemy_area)
	enemy_target_area.visible = false
	enemy_target_area.z_index = 13
	_position_top_center(enemy_target_area, Vector2(-170, 242), Vector2(170, 608))


func _build_player_area() -> void:
	player_hud_panel = Panel.new()
	player_hud_panel.name = "PlayerInfoPanel"
	player_hud_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	player_hud_panel.clip_contents = false
	player_hud_panel.add_theme_stylebox_override("panel", _make_battle_panel_style(0.94, 12))
	player_area.add_child(player_hud_panel)
	_position_bottom_left(player_hud_panel, Vector2(32, -374), Vector2(430, -42))

	turn_info_label = _make_clean_label("TurnLabel", HORIZONTAL_ALIGNMENT_CENTER)
	player_label = _make_clean_label("PlayerHPLabel", HORIZONTAL_ALIGNMENT_LEFT)
	player_block_label = _make_clean_label("PlayerBlockLabel", HORIZONTAL_ALIGNMENT_LEFT)
	energy_label = _make_clean_label("PlayerEnergyLabel", HORIZONTAL_ALIGNMENT_LEFT)
	player_status_label = _make_clean_label("PlayerStatusLabel", HORIZONTAL_ALIGNMENT_LEFT)
	relics_label = _make_clean_label("RelicLabel", HORIZONTAL_ALIGNMENT_LEFT)

	player_health_bar = _make_progress_bar("PlayerHealthBar")
	player_energy_bar = _make_progress_bar("PlayerEnergyBar")
	player_health_bar.custom_minimum_size = Vector2(322, 18)
	player_energy_bar.custom_minimum_size = Vector2(322, 18)

	var player_margin := MarginContainer.new()
	player_margin.name = "PlayerInfoMargin"
	player_hud_panel.add_child(player_margin)
	_position_full_rect(player_margin, 18, 14, 18, 14)

	var player_box := VBoxContainer.new()
	player_box.name = "PlayerInfoBox"
	player_box.add_theme_constant_override("separation", 6)
	player_margin.add_child(player_box)

	player_box.add_child(turn_info_label)
	player_box.add_child(player_label)
	player_box.add_child(player_health_bar)
	player_box.add_child(player_block_label)
	player_box.add_child(energy_label)
	player_box.add_child(player_energy_bar)
	player_box.add_child(player_status_label)
	player_box.add_child(relics_label)

	_ensure_relic_icon_bar()
	_reparent_to(relic_icon_bar, player_box)
	relic_icon_bar.custom_minimum_size = Vector2(320, 24)


func _build_hand_area() -> void:
	hand_area_panel = PanelContainer.new()
	hand_area_panel.name = "HandBackground"
	hand_area_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hand_area_panel.add_theme_stylebox_override("panel", _make_hand_area_style())
	hand_ui_area.add_child(hand_area_panel)
	_position_bottom_center(hand_area_panel, Vector2(-410, -174), Vector2(410, -18))

	_reparent_to(hand_area, hand_ui_area)
	hand_area.visible = true
	hand_area.z_index = 30
	_position_bottom_center(hand_area, Vector2(-400, -246), Vector2(400, 0))


func _build_action_area() -> void:
	deck_pile_panel = PanelContainer.new()
	deck_pile_panel.name = "DeckInfoPanel"
	deck_pile_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	deck_pile_panel.add_theme_stylebox_override("panel", _make_battle_panel_style(0.9, 10))
	action_area.add_child(deck_pile_panel)
	_position_bottom_right(deck_pile_panel, Vector2(-304, -320), Vector2(-44, -170))

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 16)
	margin.add_theme_constant_override("margin_right", 16)
	margin.add_theme_constant_override("margin_top", 12)
	margin.add_theme_constant_override("margin_bottom", 12)
	deck_pile_panel.add_child(margin)

	var deck_box := VBoxContainer.new()
	deck_box.name = "DeckInfoBox"
	deck_box.add_theme_constant_override("separation", 4)
	margin.add_child(deck_box)

	draw_pile_label = _make_clean_label("DrawPileLabel", HORIZONTAL_ALIGNMENT_LEFT)
	discard_pile_label = _make_clean_label("DiscardPileLabel", HORIZONTAL_ALIGNMENT_LEFT)
	exhaust_pile_label = _make_clean_label("ExhaustPileLabel", HORIZONTAL_ALIGNMENT_LEFT)
	hand_count_label = _make_clean_label("HandCountLabel", HORIZONTAL_ALIGNMENT_LEFT)
	deck_pile_label = _make_clean_label("DeckPileLabel", HORIZONTAL_ALIGNMENT_LEFT)
	deck_pile_label.visible = false
	for label in [draw_pile_label, discard_pile_label, exhaust_pile_label, hand_count_label]:
		label.custom_minimum_size = Vector2(220, 20)
		deck_box.add_child(label)

	end_turn_button = Button.new()
	end_turn_button.name = "EndTurnButton"
	end_turn_button.text = _tr_or("battle_end_turn", "结束回合")
	end_turn_button.focus_mode = Control.FOCUS_NONE
	end_turn_button.text = _tr_or("battle_end_turn", "End Turn")
	end_turn_button.custom_minimum_size = Vector2(260, 82)
	action_area.add_child(end_turn_button)
	_position_bottom_right(end_turn_button, Vector2(-304, -144), Vector2(-44, -58))


func _build_utility_area() -> void:
	view_deck_button = Button.new()
	view_deck_button.name = "ViewDeckButton"
	view_deck_button.text = _tr_or("battle_view_deck", "View Deck")
	view_deck_button.focus_mode = Control.FOCUS_NONE
	view_deck_button.text = _tr_or("battle_view_deck", "View Deck")
	main_menu_button = Button.new()
	main_menu_button.name = "ReturnMainMenuButton"
	main_menu_button.text = _tr_or("battle_return_main_menu", "Main Menu")
	main_menu_button.focus_mode = Control.FOCUS_NONE
	main_menu_button.text = _tr_or("battle_return_main_menu", "Main Menu")
	utility_area.add_child(view_deck_button)
	utility_area.add_child(main_menu_button)
	_position_top_right(view_deck_button, Vector2(-214, 28), Vector2(-42, 70))
	_position_top_right(main_menu_button, Vector2(-214, 80), Vector2(-42, 122))


func _build_feedback_layers() -> void:
	action_log_label = _make_clean_label("ActionToastLabel", HORIZONTAL_ALIGNMENT_CENTER)
	floating_text_layer.add_child(action_log_label)
	_position_top_center(action_log_label, Vector2(-320, 502), Vector2(320, 536))
	action_log_label.modulate.a = 0.0

	phase_banner = _make_clean_label("PhaseBanner", HORIZONTAL_ALIGNMENT_CENTER)
	floating_text_layer.add_child(phase_banner)
	_position_center(phase_banner, Vector2(-230, -156), Vector2(230, -92))
	phase_banner.add_theme_font_size_override("font_size", 40)
	phase_banner.modulate.a = 0.0


func _build_preview_layer() -> void:
	_reparent_to(card_preview_panel, card_preview_layer)
	card_preview_panel.visible = false
	_position_center(card_preview_panel, Vector2(104, -104), Vector2(504, 330))
	card_preview_panel.z_index = 100
	card_preview_panel.custom_minimum_size = Vector2(410, 462)


func _raise_battle_info_text() -> void:
	var labels: Array[Label] = [
		enemy_label,
		enemy_hp_label,
		enemy_block_label,
		enemy_status_label,
		enemy_intent_label,
		boss_mechanic_label,
		turn_info_label,
		player_label,
		player_block_label,
		energy_label,
		player_status_label,
		relics_label,
		deck_pile_label,
		draw_pile_label,
		discard_pile_label,
		exhaust_pile_label,
		hand_count_label,
		action_log_label,
		phase_banner
	]
	for label in labels:
		if label == null:
			continue
		label.visible = true
		label.z_index = 40
	if enemy_health_bar != null:
		enemy_health_bar.z_index = 30
	if player_health_bar != null:
		player_health_bar.z_index = 30
	if player_energy_bar != null:
		player_energy_bar.z_index = 30


func _debug_battle_ui_bindings() -> void:
	print("[BattleUI] player_hp_label valid: ", player_label != null)
	print("[BattleUI] player_block_label valid: ", player_block_label != null)
	print("[BattleUI] player_energy_label valid: ", energy_label != null)
	print("[BattleUI] enemy_name_label valid: ", enemy_label != null)
	print("[BattleUI] enemy_hp_label valid: ", enemy_hp_label != null)
	print("[BattleUI] enemy_hp_bar valid: ", enemy_health_bar != null)
	print("[BattleUI] draw_pile_label valid: ", draw_pile_label != null)
	print("[BattleUI] discard_pile_label valid: ", discard_pile_label != null)
	print("[BattleUI] exhaust_pile_label valid: ", exhaust_pile_label != null)
	print("[BattleUI] hand_count_label valid: ", hand_count_label != null)
	print("[BattleUI] end_turn_button valid: ", end_turn_button != null)


func validate_battle_ui_bindings() -> void:
	var missing: Array[String] = []
	_collect_missing_binding(missing, "player_turn_label", turn_info_label)
	_collect_missing_binding(missing, "player_hp_label", player_label)
	_collect_missing_binding(missing, "player_hp_bar", player_health_bar)
	_collect_missing_binding(missing, "player_block_label", player_block_label)
	_collect_missing_binding(missing, "player_energy_label", energy_label)
	_collect_missing_binding(missing, "player_energy_bar", player_energy_bar)
	_collect_missing_binding(missing, "player_status_label", player_status_label)
	_collect_missing_binding(missing, "player_relic_label", relics_label)
	_collect_missing_binding(missing, "enemy_name_label", enemy_label)
	_collect_missing_binding(missing, "enemy_hp_label", enemy_hp_label)
	_collect_missing_binding(missing, "enemy_hp_bar", enemy_health_bar)
	_collect_missing_binding(missing, "enemy_block_label", enemy_block_label)
	_collect_missing_binding(missing, "enemy_status_label", enemy_status_label)
	_collect_missing_binding(missing, "enemy_intent_label", enemy_intent_label)
	_collect_missing_binding(missing, "draw_pile_label", draw_pile_label)
	_collect_missing_binding(missing, "discard_pile_label", discard_pile_label)
	_collect_missing_binding(missing, "exhaust_pile_label", exhaust_pile_label)
	_collect_missing_binding(missing, "hand_count_label", hand_count_label)
	_collect_missing_binding(missing, "end_turn_button", end_turn_button)
	if not missing.is_empty():
		for key in missing:
			push_error("[BattleUI] Missing binding: " + key)
		return
	print("[BattleUI] All required UI bindings are valid.")


func _collect_missing_binding(missing: Array[String], binding_name: String, node: Node) -> void:
	if node == null:
		missing.append(binding_name)


func update_all_ui() -> void:
	update_player_ui()
	update_enemy_ui()
	update_deck_ui()
	update_turn_ui()
	_refresh_rebuilt_battle_layout()


func update_player_ui() -> void:
	if player == null:
		push_warning("[BattleUI] Cannot update player UI: player is null")
		return
	_set_required_label_text(turn_info_label, "player_turn_label", _current_turn_text())
	_set_required_label_text(player_label, "player_hp_label", "HP: %d / %d" % [player.current_health, player.max_health])
	if player_health_bar != null:
		player_health_bar.max_value = player.max_health
		player_health_bar.value = player.current_health
	_set_required_label_text(player_block_label, "player_block_label", "Block: %d" % player.block)
	_set_required_label_text(energy_label, "player_energy_label", "Energy: %d / %d" % [player.current_energy, player.max_energy])
	if player_energy_bar != null:
		player_energy_bar.max_value = player.max_energy
		player_energy_bar.value = player.current_energy
	_set_required_label_text(player_status_label, "player_status_label", _plain_status_summary(player.burn_stacks, player.weak_stacks, 0))
	_set_required_label_text(relics_label, "player_relic_label", _plain_relic_summary())


func update_enemy_ui() -> void:
	if enemy == null:
		push_warning("[BattleUI] Cannot update enemy UI: enemy is null")
		return
	_set_required_label_text(enemy_label, "enemy_name_label", _enemy_display_name())
	_set_required_label_text(enemy_hp_label, "enemy_hp_label", "HP: %d / %d" % [enemy.current_health, enemy.max_health])
	if enemy_health_bar != null:
		enemy_health_bar.max_value = enemy.max_health
		enemy_health_bar.value = enemy.current_health
	_set_required_label_text(enemy_block_label, "enemy_block_label", "Block: %d" % enemy.block)
	_set_required_label_text(enemy_status_label, "enemy_status_label", _plain_status_summary(enemy.burn_stacks, enemy.weak_stacks, enemy.strength))
	_set_required_label_text(enemy_intent_label, "enemy_intent_label", "Intent: %s" % _localized_enemy_intent())


func update_deck_ui() -> void:
	if deck_manager == null or hand_manager == null:
		push_warning("[BattleUI] Cannot update deck UI: deck or hand manager is null")
		return
	_set_required_label_text(draw_pile_label, "draw_pile_label", "Draw Pile: %d" % deck_manager.get_draw_pile().size())
	_set_required_label_text(discard_pile_label, "discard_pile_label", "Discard Pile: %d" % deck_manager.get_discard_pile().size())
	_set_required_label_text(exhaust_pile_label, "exhaust_pile_label", "Exhaust: %d" % deck_manager.get_exhaust_pile().size())
	_set_required_label_text(hand_count_label, "hand_count_label", "Hand: %d / %d" % [hand_manager.cards_count(), hand_manager.max_hand_size])


func update_turn_ui() -> void:
	if end_turn_button != null:
		end_turn_button.text = _tr_or("battle_end_turn", "End Turn")
	if view_deck_button != null:
		view_deck_button.text = _tr_or("battle_view_deck", "View Deck")
	if main_menu_button != null:
		main_menu_button.text = _tr_or("battle_return_main_menu", "Main Menu")


func _set_required_label_text(label: Label, binding_name: String, value: String) -> void:
	if label == null:
		push_error("[BattleUI] Missing binding: " + binding_name)
		return
	label.visible = true
	label.modulate = Color.WHITE
	label.clip_text = false
	label.text_overrun_behavior = TextServer.OVERRUN_NO_TRIMMING
	label.text = value
	if label.text.strip_edges() == "":
		push_warning("[BattleUI] Empty label text: " + binding_name)


func _current_turn_text() -> String:
	var turn_number := 1
	if turn_manager != null:
		turn_number = max(turn_manager.turn_number, 1)
	if is_enemy_turn_running:
		return LanguageManager.tr_format("battle_turn_count_enemy", {"turn": turn_number})
	return LanguageManager.tr_format("battle_turn_count_player", {"turn": turn_number})


func _plain_status_summary(burn: int, weak: int, strength: int) -> String:
	var parts: Array[String] = []
	if burn > 0:
		parts.append("%s %d" % [LanguageManager.get_status_name("burn"), burn])
	if weak > 0:
		parts.append("%s %d" % [LanguageManager.get_status_name("weak"), weak])
	if strength > 0:
		parts.append("%s %d" % [LanguageManager.get_status_name("strength"), strength])
	if parts.is_empty():
		return "%s: %s" % [LanguageManager.tr_key("ui_status"), LanguageManager.tr_key("status.none")]
	return "%s: %s" % [LanguageManager.tr_key("ui_status"), " / ".join(parts)]


func _plain_relic_summary() -> String:
	var relics := RelicManager.get_current_relics()
	if relics.is_empty():
		return "Relic: None"
	return "Relics: %d" % relics.size()


func _configure_battle_layout() -> void:
	_refresh_rebuilt_battle_layout()
	return

	# Fixed combat zones keep the important UI readable at the current target resolution.
	_ensure_boss_mechanic_label()
	_ensure_battle_extra_ui()
	_ensure_battle_ui_layers()
	_position_top_center(enemy_hud_panel, Vector2(-270, 22), Vector2(270, 140))
	_position_top_center(enemy_label, Vector2(-230, 32), Vector2(230, 60))
	_position_top_center(enemy_health_bar, Vector2(-214, 66), Vector2(214, 94))
	_position_top_center(enemy_block_label, Vector2(-230, 104), Vector2(-78, 130))
	_position_top_center(enemy_status_label, Vector2(-62, 104), Vector2(92, 130))
	_position_top_center(enemy_intent_label, Vector2(108, 101), Vector2(244, 132))
	_position_top_center(boss_mechanic_label, Vector2(-244, 142), Vector2(244, 168))
	enemy_hud_panel.z_index = 12
	enemy_label.z_index = 13
	enemy_health_bar.z_index = 13
	enemy_block_label.z_index = 13
	enemy_status_label.z_index = 13
	enemy_intent_label.z_index = 13
	boss_mechanic_label.z_index = 13

	_position_top_center(enemy_stage_panel, Vector2(-178, 158), Vector2(178, 520))
	_position_top_center(enemy_dais_panel, Vector2(-152, 468), Vector2(152, 538))
	_position_top_center(enemy_art_texture, Vector2(-150, 178), Vector2(150, 478))
	enemy_art_texture.custom_minimum_size = Vector2(300, 300)
	enemy_art_texture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	enemy_art_texture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	enemy_art_texture.z_index = 5

	_position_top_center(enemy_target_area, Vector2(-160, 178), Vector2(160, 478))
	enemy_target_area.z_index = 6

	_position_bottom_center(hand_area_panel, Vector2(-460, -178), Vector2(460, -14))
	_position_bottom_center(hand_area, Vector2(-430, -244), Vector2(430, 0))
	hand_area_panel.z_index = 14
	hand_area.z_index = 30

	_position_bottom_left(player_hud_panel, Vector2(38, -292), Vector2(406, -64))
	_position_bottom_left(turn_info_label, Vector2(62, -272), Vector2(376, -244))
	_position_bottom_left(player_label, Vector2(62, -232), Vector2(374, -202))
	_position_bottom_left(player_block_label, Vector2(62, -168), Vector2(374, -138))
	_position_bottom_left(energy_label, Vector2(62, -132), Vector2(374, -102))
	_position_bottom_left(player_status_label, Vector2(62, -84), Vector2(374, -58))
	_position_bottom_left(relics_label, Vector2(62, -54), Vector2(374, -30))
	_ensure_relic_icon_bar()
	_reparent_to(relic_icon_bar, player_area)
	_position_bottom_left(relic_icon_bar, Vector2(128, -47), Vector2(398, -23))
	_position_bottom_left(player_health_bar, Vector2(62, -198), Vector2(350, -170))
	_position_bottom_left(player_energy_bar, Vector2(62, -98), Vector2(274, -74))
	player_hud_panel.z_index = 18
	player_health_bar.z_index = 19
	player_energy_bar.z_index = 19

	draw_pile_label.visible = false
	discard_pile_label.visible = false
	_position_bottom_right(deck_pile_panel, Vector2(-296, -282), Vector2(-48, -170))

	_position_bottom_right(end_turn_button, Vector2(-296, -146), Vector2(-48, -60))
	_position_top_right(view_deck_button, Vector2(-198, 30), Vector2(-34, 68))
	_position_top_right(main_menu_button, Vector2(-198, 78), Vector2(-34, 116))

	_position_top_center(action_log_label, Vector2(-310, 500), Vector2(310, 532))
	action_log_label.z_index = 16
	_position_center(card_preview_panel, Vector2(98, -104), Vector2(500, 330))
	card_preview_panel.z_index = 60
	_position_center(phase_banner, Vector2(-210, -150), Vector2(210, -94))
	phase_banner.z_index = 80

	_position_top_center(play_area, Vector2(-340, 176), Vector2(340, 526))
	play_area.visible = false


func _ensure_boss_mechanic_label() -> void:
	if boss_mechanic_label != null:
		return

	boss_mechanic_label = Label.new()
	boss_mechanic_label.name = "BossMechanicLabel"
	boss_mechanic_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	boss_mechanic_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	boss_mechanic_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	boss_mechanic_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	boss_mechanic_label.z_index = 8
	boss_mechanic_label.visible = false
	add_child(boss_mechanic_label)


func _ensure_battle_extra_ui() -> void:
	if enemy_stage_panel == null:
		enemy_stage_panel = PanelContainer.new()
		enemy_stage_panel.name = "EnemyStagePanel"
		enemy_stage_panel.z_index = 2
		enemy_stage_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
		enemy_stage_panel.add_theme_stylebox_override("panel", _make_enemy_stage_style())
		add_child(enemy_stage_panel)
	if enemy_dais_panel == null:
		enemy_dais_panel = PanelContainer.new()
		enemy_dais_panel.name = "EnemyDaisPanel"
		enemy_dais_panel.z_index = 3
		enemy_dais_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
		enemy_dais_panel.add_theme_stylebox_override("panel", _make_enemy_dais_style())
		add_child(enemy_dais_panel)
	if hand_area_panel == null:
		hand_area_panel = PanelContainer.new()
		hand_area_panel.name = "HandAreaPanel"
		hand_area_panel.z_index = 14
		hand_area_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
		hand_area_panel.add_theme_stylebox_override("panel", _make_hand_area_style())
		add_child(hand_area_panel)
	if player_block_label == null:
		player_block_label = _make_hud_label("Block: 0", "PlayerBlockLabel", HORIZONTAL_ALIGNMENT_LEFT)
	if enemy_block_label == null:
		enemy_block_label = _make_hud_label("Block: 0", "EnemyBlockLabel", HORIZONTAL_ALIGNMENT_CENTER)
	if turn_info_label == null:
		turn_info_label = _make_hud_label(_tr_or("battle_player_turn", "Player Turn"), "TurnInfoLabel", HORIZONTAL_ALIGNMENT_CENTER)
	if deck_pile_panel == null:
		deck_pile_panel = PanelContainer.new()
		deck_pile_panel.name = "DeckPilePanel"
		deck_pile_panel.z_index = 18
		deck_pile_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
		deck_pile_panel.add_theme_stylebox_override("panel", _make_battle_panel_style(0.9, 10))
		add_child(deck_pile_panel)

		var margin := MarginContainer.new()
		margin.add_theme_constant_override("margin_left", 14)
		margin.add_theme_constant_override("margin_right", 14)
		margin.add_theme_constant_override("margin_top", 10)
		margin.add_theme_constant_override("margin_bottom", 10)
		deck_pile_panel.add_child(margin)

		deck_pile_label = Label.new()
		deck_pile_label.name = "DeckPileLabel"
		deck_pile_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		deck_pile_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		margin.add_child(deck_pile_label)
	if main_menu_confirm_overlay == null:
		_build_main_menu_confirm_dialog()


func _ensure_battle_ui_layers() -> void:
	if battle_ui_layer == null:
		battle_ui_layer = _make_fullscreen_layer("BattleUILayer", 1)
		add_child(battle_ui_layer)
	if enemy_area == null:
		enemy_area = _make_fullscreen_layer("EnemyArea", 10)
		battle_ui_layer.add_child(enemy_area)
	if player_area == null:
		player_area = _make_fullscreen_layer("PlayerArea", 18)
		battle_ui_layer.add_child(player_area)
	if hand_ui_area == null:
		hand_ui_area = _make_fullscreen_layer("HandArea", 14)
		battle_ui_layer.add_child(hand_ui_area)
	if action_area == null:
		action_area = _make_fullscreen_layer("ActionArea", 18)
		battle_ui_layer.add_child(action_area)
	if utility_area == null:
		utility_area = _make_fullscreen_layer("UtilityArea", 20)
		battle_ui_layer.add_child(utility_area)
	if floating_text_layer == null:
		floating_text_layer = _make_fullscreen_layer("FloatingTextLayer", 90)
		battle_ui_layer.add_child(floating_text_layer)
	if card_preview_layer == null:
		card_preview_layer = _make_fullscreen_layer("CardPreviewLayer", 100)
		battle_ui_layer.add_child(card_preview_layer)

	_reparent_to(enemy_stage_panel, enemy_area)
	_reparent_to(enemy_dais_panel, enemy_area)
	_reparent_to(enemy_art_texture, enemy_area)
	_reparent_to(enemy_target_area, enemy_area)
	_reparent_to(enemy_hud_panel, enemy_area)
	_reparent_to(enemy_label, enemy_area)
	_reparent_to(enemy_health_bar, enemy_area)
	_reparent_to(enemy_block_label, enemy_area)
	_reparent_to(enemy_status_label, enemy_area)
	_reparent_to(enemy_intent_label, enemy_area)
	_reparent_to(boss_mechanic_label, enemy_area)
	_reparent_to(player_hud_panel, player_area)
	_reparent_to(player_label, player_area)
	_reparent_to(player_health_bar, player_area)
	_reparent_to(player_block_label, player_area)
	_reparent_to(energy_label, player_area)
	_reparent_to(player_energy_bar, player_area)
	_reparent_to(player_status_label, player_area)
	_reparent_to(relics_label, player_area)
	_reparent_to(turn_info_label, player_area)
	_reparent_to(relic_icon_bar, player_area)
	_reparent_to(hand_area_panel, hand_ui_area)
	_reparent_to(hand_area, hand_ui_area)
	_reparent_to(deck_pile_panel, action_area)
	_reparent_to(end_turn_button, action_area)
	_reparent_to(view_deck_button, utility_area)
	_reparent_to(main_menu_button, utility_area)
	_reparent_to(action_log_label, floating_text_layer)
	_reparent_to(phase_banner, floating_text_layer)
	_reparent_to(card_preview_panel, card_preview_layer)


func _make_fullscreen_layer(layer_name: String, layer_z_index: int) -> Control:
	var layer := Control.new()
	layer.name = layer_name
	layer.set_anchors_preset(Control.PRESET_FULL_RECT)
	layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.z_index = layer_z_index
	return layer


func _reparent_to(node: Node, new_parent: Node) -> void:
	if node == null or new_parent == null or node.get_parent() == new_parent:
		return
	node.reparent(new_parent, true)


func _make_hud_label(text: String, label_name: String, align := HORIZONTAL_ALIGNMENT_LEFT) -> Label:
	var label := Label.new()
	label.name = label_name
	label.text = text
	label.horizontal_alignment = align
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.z_index = 24
	add_child(label)
	return label


func _make_clean_label(label_name: String, align := HORIZONTAL_ALIGNMENT_LEFT) -> Label:
	var label := Label.new()
	label.name = label_name
	label.horizontal_alignment = align
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.clip_text = true
	label.z_index = 24
	label.add_theme_color_override("font_color", Color(0.94, 0.88, 0.74))
	label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.9))
	label.add_theme_constant_override("shadow_offset_x", 2)
	label.add_theme_constant_override("shadow_offset_y", 2)
	label.add_theme_font_size_override("font_size", 20)
	return label


func _tr_or(key: String, fallback: String) -> String:
	var text := LanguageManager.tr_key(key)
	if text == "" or text == key:
		return fallback
	return text


func _tr_format_or(key: String, params: Dictionary, fallback: String) -> String:
	var text := LanguageManager.tr_format(key, params)
	if text == "" or text == key:
		return fallback
	return text


func _make_progress_bar(bar_name: String) -> ProgressBar:
	var bar := ProgressBar.new()
	bar.name = bar_name
	bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bar.show_percentage = false
	bar.z_index = 24
	return bar


func _ensure_relic_icon_bar() -> void:
	if relic_icon_bar != null:
		return

	relic_icon_bar = HBoxContainer.new()
	relic_icon_bar.name = "RelicIconBar"
	relic_icon_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	relic_icon_bar.z_index = 24
	relic_icon_bar.add_theme_constant_override("separation", 6)
	add_child(relic_icon_bar)


func _style_preview_panel() -> void:
	card_preview_panel.custom_minimum_size = Vector2(410, 462)
	card_preview_panel.add_theme_stylebox_override("panel", _make_battle_panel_style(0.94, 12))
	preview_art_texture.custom_minimum_size = Vector2(360, 300)
	preview_art_texture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	preview_art_texture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	preview_name_label.add_theme_font_size_override("font_size", 30)
	preview_name_label.add_theme_color_override("font_color", Color(1.0, 0.86, 0.58))
	preview_cost_label.add_theme_font_size_override("font_size", 22)
	preview_cost_label.add_theme_color_override("font_color", Color(0.45, 0.8, 1.0))
	preview_description_label.custom_minimum_size = Vector2(360, 92)
	preview_description_label.add_theme_font_size_override("font_size", 20)
	preview_description_label.add_theme_color_override("font_color", Color(0.94, 0.88, 0.74))


func _build_main_menu_confirm_dialog() -> void:
	main_menu_confirm_overlay = ColorRect.new()
	main_menu_confirm_overlay.name = "MainMenuConfirmOverlay"
	main_menu_confirm_overlay.visible = false
	main_menu_confirm_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	main_menu_confirm_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	main_menu_confirm_overlay.color = Color(0, 0, 0, 0.58)
	main_menu_confirm_overlay.z_index = 250
	add_child(main_menu_confirm_overlay)

	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(560, 250)
	panel.set_anchors_preset(Control.PRESET_CENTER)
	panel.offset_left = -280
	panel.offset_top = -125
	panel.offset_right = 280
	panel.offset_bottom = 125
	panel.add_theme_stylebox_override("panel", _make_panel_style(Color(0.035, 0.03, 0.055, 0.82), Color(0.82, 0.66, 0.36, 0.82), 1, 12))
	main_menu_confirm_overlay.add_child(panel)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 36)
	margin.add_theme_constant_override("margin_right", 36)
	margin.add_theme_constant_override("margin_top", 28)
	margin.add_theme_constant_override("margin_bottom", 28)
	panel.add_child(margin)

	var box := VBoxContainer.new()
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_theme_constant_override("separation", 18)
	margin.add_child(box)

	main_menu_confirm_title = Label.new()
	main_menu_confirm_title.text = LanguageManager.tr_key("battle_return_confirm_title")
	main_menu_confirm_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_style_label(main_menu_confirm_title, Color(1.0, 0.84, 0.55), 32)
	box.add_child(main_menu_confirm_title)

	main_menu_confirm_message = Label.new()
	main_menu_confirm_message.text = LanguageManager.tr_key("battle_return_confirm_message")
	main_menu_confirm_message.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	main_menu_confirm_message.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_style_label(main_menu_confirm_message, Color(0.94, 0.9, 0.78), 21)
	box.add_child(main_menu_confirm_message)

	var buttons := HBoxContainer.new()
	buttons.alignment = BoxContainer.ALIGNMENT_CENTER
	buttons.add_theme_constant_override("separation", 22)
	box.add_child(buttons)

	main_menu_confirm_accept_button = Button.new()
	main_menu_confirm_accept_button.text = LanguageManager.tr_key("ui_confirm")
	main_menu_confirm_accept_button.custom_minimum_size = Vector2(170, 50)
	main_menu_confirm_accept_button.pressed.connect(_confirm_return_to_main_menu)
	_style_button(main_menu_confirm_accept_button, 22)
	buttons.add_child(main_menu_confirm_accept_button)

	main_menu_confirm_cancel_button = Button.new()
	main_menu_confirm_cancel_button.text = LanguageManager.tr_key("ui_cancel")
	main_menu_confirm_cancel_button.custom_minimum_size = Vector2(170, 50)
	main_menu_confirm_cancel_button.pressed.connect(func() -> void:
		AudioManager.play_sfx("ui_click")
		main_menu_confirm_overlay.visible = false
	)
	_style_button(main_menu_confirm_cancel_button, 22)
	buttons.add_child(main_menu_confirm_cancel_button)


func _position_bottom_left(control: Control, top_left: Vector2, bottom_right: Vector2) -> void:
	control.anchor_left = 0.0
	control.anchor_right = 0.0
	control.anchor_top = 1.0
	control.anchor_bottom = 1.0
	control.offset_left = top_left.x
	control.offset_top = top_left.y
	control.offset_right = bottom_right.x
	control.offset_bottom = bottom_right.y


func _position_bottom_right(control: Control, top_left: Vector2, bottom_right: Vector2) -> void:
	control.anchor_left = 1.0
	control.anchor_right = 1.0
	control.anchor_top = 1.0
	control.anchor_bottom = 1.0
	control.offset_left = top_left.x
	control.offset_top = top_left.y
	control.offset_right = bottom_right.x
	control.offset_bottom = bottom_right.y


func _position_top_center(control: Control, top_left: Vector2, bottom_right: Vector2) -> void:
	control.anchor_left = 0.5
	control.anchor_right = 0.5
	control.anchor_top = 0.0
	control.anchor_bottom = 0.0
	control.offset_left = top_left.x
	control.offset_top = top_left.y
	control.offset_right = bottom_right.x
	control.offset_bottom = bottom_right.y


func _position_bottom_center(control: Control, top_left: Vector2, bottom_right: Vector2) -> void:
	control.anchor_left = 0.5
	control.anchor_right = 0.5
	control.anchor_top = 1.0
	control.anchor_bottom = 1.0
	control.offset_left = top_left.x
	control.offset_top = top_left.y
	control.offset_right = bottom_right.x
	control.offset_bottom = bottom_right.y


func _position_center(control: Control, top_left: Vector2, bottom_right: Vector2) -> void:
	control.anchor_left = 0.5
	control.anchor_right = 0.5
	control.anchor_top = 0.5
	control.anchor_bottom = 0.5
	control.offset_left = top_left.x
	control.offset_top = top_left.y
	control.offset_right = bottom_right.x
	control.offset_bottom = bottom_right.y


func _position_top_right(control: Control, top_left: Vector2, bottom_right: Vector2) -> void:
	control.anchor_left = 1.0
	control.anchor_right = 1.0
	control.anchor_top = 0.0
	control.anchor_bottom = 0.0
	control.offset_left = top_left.x
	control.offset_top = top_left.y
	control.offset_right = bottom_right.x
	control.offset_bottom = bottom_right.y


func _position_fill(control: Control, top_left: Vector2, bottom_right: Vector2) -> void:
	control.anchor_left = 0.0
	control.anchor_top = 0.0
	control.anchor_right = 1.0
	control.anchor_bottom = 0.0
	control.offset_left = top_left.x
	control.offset_top = top_left.y
	control.offset_right = bottom_right.x
	control.offset_bottom = bottom_right.y


func _position_full_rect(control: Control, left: float, top: float, right: float, bottom: float) -> void:
	control.anchor_left = 0.0
	control.anchor_top = 0.0
	control.anchor_right = 1.0
	control.anchor_bottom = 1.0
	control.offset_left = left
	control.offset_top = top
	control.offset_right = -right
	control.offset_bottom = -bottom


func _style_label(label: Label, color: Color, font_size: int) -> void:
	label.add_theme_color_override("font_color", color)
	label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.9))
	label.add_theme_constant_override("shadow_offset_x", 2)
	label.add_theme_constant_override("shadow_offset_y", 2)
	label.add_theme_font_size_override("font_size", font_size)


func _style_button(button: Button, font_size: int) -> void:
	_apply_battle_button_style(button)
	button.add_theme_color_override("font_color", Color(0.95, 0.86, 0.68))
	button.add_theme_color_override("font_hover_color", Color(1.0, 0.92, 0.68))
	button.add_theme_color_override("font_pressed_color", Color(0.76, 0.68, 0.52))
	button.add_theme_color_override("font_disabled_color", Color(0.5, 0.5, 0.56))
	button.add_theme_font_size_override("font_size", font_size)


func _apply_battle_button_style(button: Button) -> void:
	button.add_theme_stylebox_override("normal", create_button_style_normal())
	button.add_theme_stylebox_override("hover", create_button_style_hover())
	button.add_theme_stylebox_override("pressed", create_button_style_pressed())
	button.add_theme_stylebox_override("disabled", create_button_style_disabled())


func apply_battle_panel_style(panel: Control, alpha := 0.86, corner_radius := 12) -> void:
	if panel == null:
		return
	panel.add_theme_stylebox_override("panel", create_panel_style(alpha, corner_radius))


func _style_progress_bar(progress_bar: ProgressBar, fill_color: Color, background_color: Color) -> void:
	var background := StyleBoxFlat.new()
	background.bg_color = background_color
	background.border_color = Color(0.78, 0.58, 0.28, 0.6)
	background.set_border_width_all(1)
	background.set_corner_radius_all(7)
	background.shadow_color = Color(0, 0, 0, 0.45)
	background.shadow_size = 6

	var fill := StyleBoxFlat.new()
	fill.bg_color = fill_color
	fill.border_color = Color(1.0, 0.82, 0.46, 0.16)
	fill.set_border_width_all(1)
	fill.set_corner_radius_all(7)

	progress_bar.add_theme_stylebox_override("background", background)
	progress_bar.add_theme_stylebox_override("fill", fill)
	progress_bar.add_theme_color_override("font_color", Color(1.0, 0.92, 0.78))
	progress_bar.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.92))
	progress_bar.add_theme_constant_override("shadow_offset_x", 1)
	progress_bar.add_theme_constant_override("shadow_offset_y", 1)
	progress_bar.add_theme_font_size_override("font_size", 16)


func create_button_style_normal() -> StyleBoxFlat:
	return _make_button_style(Color(0.035, 0.055, 0.085, 0.94), Color(0.65, 0.48, 0.22, 0.96), 2)


func create_button_style_hover() -> StyleBoxFlat:
	var style := _make_button_style(Color(0.055, 0.085, 0.13, 0.98), Color(0.95, 0.76, 0.38, 1.0), 2)
	style.shadow_color = Color(0.9, 0.64, 0.26, 0.22)
	style.shadow_size = 12
	return style


func create_button_style_pressed() -> StyleBoxFlat:
	return _make_button_style(Color(0.018, 0.028, 0.05, 0.98), Color(0.58, 0.42, 0.2, 0.95), 2)


func create_button_style_disabled() -> StyleBoxFlat:
	return _make_button_style(Color(0.045, 0.05, 0.06, 0.46), Color(0.28, 0.28, 0.3, 0.68), 1)


func _make_button_style(bg_color: Color, border_color: Color, border_width := 1) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = bg_color
	style.border_color = border_color
	style.set_border_width_all(border_width)
	style.set_corner_radius_all(10)
	style.shadow_color = Color(0, 0, 0, 0.42)
	style.shadow_size = 8
	style.content_margin_left = 14
	style.content_margin_right = 14
	style.content_margin_top = 7
	style.content_margin_bottom = 7
	return style


func _make_battle_panel_style(alpha: float, corner_radius: int) -> StyleBox:
	return create_panel_style(alpha, corner_radius)


func create_panel_style(alpha := 0.86, corner_radius := 12, border_width := 2) -> StyleBoxFlat:
	var style := _make_panel_style(Color(0.03, 0.05, 0.08, alpha), Color(0.65, 0.48, 0.22, 0.95), border_width, corner_radius)
	style.content_margin_left = 14
	style.content_margin_right = 14
	style.content_margin_top = 12
	style.content_margin_bottom = 12
	style.shadow_color = Color(0, 0, 0, 0.52)
	style.shadow_size = 14
	return style


func _make_panel_style(bg_color: Color, border_color: Color, border_width: int, corner_radius: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = bg_color
	style.border_color = border_color
	style.set_border_width_all(border_width)
	style.set_corner_radius_all(corner_radius)
	style.shadow_color = Color(0, 0, 0, 0.58)
	style.shadow_size = 16
	return style


func _make_enemy_stage_style() -> StyleBoxFlat:
	var style := _make_panel_style(Color(0.028, 0.045, 0.072, 0.78), Color(0.78, 0.58, 0.28, 0.94), 2, 18)
	style.shadow_color = Color(0, 0, 0, 0.54)
	style.shadow_size = 22
	style.content_margin_left = 14
	style.content_margin_right = 14
	style.content_margin_top = 14
	style.content_margin_bottom = 14
	return style


func _make_enemy_dais_style() -> StyleBoxFlat:
	var style := _make_panel_style(Color(0.045, 0.035, 0.055, 0.58), Color(0.9, 0.68, 0.34, 0.58), 1, 18)
	style.shadow_color = Color(0, 0, 0, 0.56)
	style.shadow_size = 20
	return style


func _make_hand_area_style() -> StyleBoxFlat:
	var style := _make_panel_style(Color(0.022, 0.035, 0.055, 0.54), Color(0.72, 0.54, 0.26, 0.46), 1, 16)
	style.shadow_color = Color(0, 0, 0, 0.44)
	style.shadow_size = 18
	return style


func _update_action_log_visibility(delta: float) -> void:
	if action_log_label == null:
		return

	if action_log_label.text != action_log_last_text:
		action_log_last_text = action_log_label.text
		action_log_timer = 1.05
		action_log_fading = false
		action_log_label.modulate.a = 0.82
		return

	if action_log_timer > 0.0:
		action_log_timer = maxf(action_log_timer - delta, 0.0)
		return

	if not action_log_fading and action_log_label.modulate.a > 0.0:
		action_log_fading = true
		var tween := create_tween()
		tween.tween_property(action_log_label, "modulate:a", 0.0, 0.35)


func _input(event: InputEvent) -> void:
	if not OS.is_debug_build() or debug_panel == null:
		return

	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_F1:
		debug_panel.visible = not debug_panel.visible
		get_viewport().set_input_as_handled()


func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED and is_node_ready():
		_refresh_rebuilt_battle_layout()
		if hand_manager != null:
			hand_manager.relayout_hand()


func _refresh_rebuilt_battle_layout() -> void:
	if enemy_hud_panel != null:
		_position_top_center(enemy_hud_panel, Vector2(-340, 24), Vector2(340, 214))
	if enemy_health_bar != null:
		enemy_health_bar.custom_minimum_size = Vector2(540, 18)
		enemy_health_bar.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	if enemy_status_label != null:
		enemy_status_label.custom_minimum_size = Vector2(600, 30)
		enemy_status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		enemy_status_label.text_overrun_behavior = TextServer.OVERRUN_NO_TRIMMING
	if enemy_intent_label != null:
		enemy_intent_label.custom_minimum_size = Vector2(330, 30)
		enemy_intent_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		enemy_intent_label.clip_text = false
		enemy_intent_label.text_overrun_behavior = TextServer.OVERRUN_NO_TRIMMING
	if enemy_stage_panel != null:
		_position_top_center(enemy_stage_panel, Vector2(-188, 226), Vector2(188, 626))
	if enemy_art_texture != null:
		_position_top_center(enemy_art_texture, Vector2(-165, 242), Vector2(165, 608))
	if enemy_target_area != null:
		_position_top_center(enemy_target_area, Vector2(-170, 242), Vector2(170, 608))
	if player_hud_panel != null:
		_position_bottom_left(player_hud_panel, Vector2(32, -374), Vector2(430, -42))
	if player_health_bar != null:
		player_health_bar.custom_minimum_size = Vector2(316, 18)
	if player_energy_bar != null:
		player_energy_bar.custom_minimum_size = Vector2(316, 18)
	if deck_pile_panel != null:
		_position_bottom_right(deck_pile_panel, Vector2(-304, -320), Vector2(-44, -170))
	if end_turn_button != null:
		_position_bottom_right(end_turn_button, Vector2(-304, -144), Vector2(-44, -58))
		end_turn_button.text = _tr_or("battle_end_turn", "End Turn")
	if view_deck_button != null:
		_position_top_right(view_deck_button, Vector2(-214, 28), Vector2(-42, 70))
	if main_menu_button != null:
		_position_top_right(main_menu_button, Vector2(-214, 80), Vector2(-42, 122))
	if hand_area_panel != null:
		var card_count: int = 5
		if hand_manager != null:
			card_count = max(hand_manager.cards_count(), 5)
		var estimated_width: float = clampf(420.0 + float(card_count) * 105.0, 820.0, 1080.0)
		_position_bottom_center(hand_area_panel, Vector2(-estimated_width * 0.5, -214), Vector2(estimated_width * 0.5, -8))
	if hand_area != null:
		_position_bottom_center(hand_area, Vector2(-540, -264), Vector2(540, 0))
	_raise_battle_info_text()


func _on_turn_started(turn_number: int, cards_to_draw: int) -> void:
	if battle_ended:
		end_turn_button.disabled = true
		return

	is_enemy_turn_running = false
	is_animating = false
	end_turn_button.disabled = false
	AudioManager.play_sfx("turn_start")
	_show_phase_banner(LanguageManager.tr_key("battle_turn_start_player"))
	turn_info_label.text = LanguageManager.tr_format("battle_turn_count_player", {"turn": turn_number})
	cards_played_this_turn = 0
	played_attack_this_turn = false
	current_damage_multiplier = next_turn_damage_multiplier
	next_turn_damage_multiplier = 1

	player.resolve_turn_start_status()
	if battle_ended or is_game_over:
		return

	if devil_self_damage_per_turn > 0:
		player.take_direct_damage(devil_self_damage_per_turn)
		if battle_ended or is_game_over:
			return

	if delayed_heal_next_turn > 0:
		player.heal(delayed_heal_next_turn)
		delayed_heal_next_turn = 0

	if emperor_block_per_turn > 0:
		player.add_block(emperor_block_per_turn)

	player.refresh_energy()
	enemy.resolve_turn_start_status()
	if battle_ended or is_game_over:
		return

	var total_draw := cards_to_draw + star_extra_draw_per_turn
	if turn_number == 1:
		total_draw += RelicManager.get_first_turn_bonus_draw()
	var draw_count: int = min(total_draw, hand_manager.empty_slots())
	var destroyed_count := 0
	if draw_count > 0:
		destroyed_count = hand_manager.add_cards(deck_manager.draw_cards(draw_count))
	hand_manager.update_playable_cards(player.current_energy)
	_update_deck_pile_ui()
	_update_player_block_ui()
	_on_enemy_intent_changed(enemy.get_current_intent_text())
	action_log_label.text = LanguageManager.tr_format("battle_turn_draw_cards", {"value": draw_count})
	if draw_count < total_draw:
		action_log_label.text += " " + LanguageManager.tr_format("battle_hand_full_no_draw", {"count": total_draw - draw_count})
	var turn_start_relic_log := RelicManager.trigger_player_turn_start(player)
	if turn_start_relic_log != "":
		action_log_label.text += " " + turn_start_relic_log
	if destroyed_count > 0:
		action_log_label.text += " " + LanguageManager.tr_format("battle_overflow_destroy", {"count": destroyed_count})
	_update_deck_pile_ui()
	_refresh_rebuilt_battle_layout()


func _on_turn_ended(_turn_number: int) -> void:
	if battle_ended or is_game_over or is_enemy_turn_running or is_animating:
		return

	next_card_double_cast = false
	is_enemy_turn_running = true
	is_animating = true
	end_turn_button.disabled = true
	AudioManager.play_sfx("ui_click")
	_show_phase_banner(LanguageManager.tr_key("battle_turn_start_enemy"))
	turn_info_label.text = LanguageManager.tr_format("battle_turn_count_enemy", {"turn": max(turn_manager.turn_number, 1)})

	await get_tree().create_timer(ENEMY_TURN_START_DELAY).timeout
	if battle_ended or is_game_over:
		return

	if wheel_of_fortune_active:
		if deck_manager.is_deck_empty():
			_show_game_over("Victory")
			return
		var destroyed_count := hand_manager.add_cards(deck_manager.draw_cards(4))
		action_log_label.text = _effect_text("effect_wheel_turn_draw") + _overflow_text(destroyed_count)
		if deck_manager.is_deck_empty():
			_show_game_over("Victory")
			return

	if world_skip_enemy_turn_pending and cards_played_this_turn >= 5:
		world_skip_enemy_turn_pending = false
		await get_tree().create_timer(ENEMY_TURN_END_DELAY).timeout
		is_enemy_turn_running = false
		is_animating = false
		turn_manager.start_next_turn()
		var fill_count := hand_manager.empty_slots()
		var destroyed_count := hand_manager.add_cards(deck_manager.draw_cards(fill_count))
		action_log_label.text = _effect_text("effect_world_skip_enemy") + _overflow_text(destroyed_count)
		return

	world_skip_enemy_turn_pending = false

	# Enemy owns its action so intent/buff/debuff logic can grow in one place.
	var enemy_was_attacking := enemy.is_current_action_attack()
	if enemy_was_attacking:
		await _animate_enemy_attack_windup()
	else:
		await get_tree().create_timer(ENEMY_ATTACK_WINDUP).timeout
	if battle_ended or is_game_over:
		return
	enemy.perform_action(player)
	update_all_ui()
	if battle_ended or is_game_over:
		return
	if enemy_was_attacking:
		await _animate_player_hit_feedback()
		AudioManager.play_sfx("attack_hit")
		await get_tree().create_timer(HIT_PAUSE_TIME).timeout

	if not battle_ended and not is_game_over:
		await get_tree().create_timer(AFTER_HIT_DELAY).timeout
	if not battle_ended and not is_game_over:
		await get_tree().create_timer(ENEMY_TURN_END_DELAY).timeout
	if not battle_ended and not is_game_over:
		is_enemy_turn_running = false
		is_animating = false
		turn_manager.start_next_turn()


func _on_card_play_requested(card_view: CardView) -> void:
	if battle_ended or is_game_over or is_animating or is_enemy_turn_running or card_view.card_data == null:
		hand_manager.return_card_view_home(card_view)
		return

	is_animating = true
	end_turn_button.disabled = true
	var card := card_view.card_data
	var played_cost := card_view.current_cost
	if not player.can_spend_energy(played_cost):
		hand_manager.return_card_view_home(card_view)
		action_log_label.text = _effect_text("effect_not_enough_energy", {"card": _card_display_name(card)})
		is_animating = false
		end_turn_button.disabled = false
		return

	player.spend_energy(played_cost)
	card = hand_manager.remove_card_view(card_view, false)
	if card == null:
		card_view.queue_free()
		is_animating = false
		end_turn_button.disabled = false
		return
	AudioManager.play_sfx("card_play")
	await _animate_card_play(card_view)
	if battle_ended or is_game_over:
		is_animating = false
		end_turn_button.disabled = true
		return
	attack_played_before_current_card = played_attack_this_turn
	var enemy_health_before := enemy.current_health
	var should_double_cast := next_card_double_cast and card.card_id != "major_01_the_magician"
	_resolve_card(card)
	if should_double_cast and not battle_ended and not is_game_over:
		next_card_double_cast = false
		var double_text := _effect_text("effect_magician_double")
		show_floating_text(double_text, "energy")
		action_log_label.text = double_text
		_resolve_card(card)
	if not battle_ended and enemy.current_health < enemy_health_before:
		await get_tree().create_timer(HIT_PAUSE_TIME).timeout
	deck_manager.discard(card)
	cards_played_this_turn += 1
	if card.card_type == CardData.CardType.ATTACK:
		played_attack_this_turn = true
	hand_manager.update_playable_cards(player.current_energy)
	update_all_ui()
	is_animating = false
	end_turn_button.disabled = battle_ended or is_game_over


func _resolve_card(card: CardData) -> void:
	if card == null or battle_ended:
		return

	current_resolving_card = card
	var log_parts: Array[String] = []
	for effect in card.effects:
		if battle_ended:
			break
		log_parts.append(_apply_card_effect(effect))
	current_resolving_card = null
	if battle_ended:
		return

	action_log_label.text = _effect_text("effect_play_card_log", {
		"card": _card_display_name(card),
		"effects": _join_effect_parts(log_parts),
	})


func _apply_card_effect(effect: CardEffect) -> String:
	if effect == null:
		return _effect_text("effect_no_effect")
	if battle_ended:
		return _effect_text("effect_battle_ended")

	# The prototype has one enemy. ALL_ENEMIES can share this path until
	# BattleScene owns a collection of enemies.
	match effect.effect_type:
		CardEffect.EffectType.DAMAGE:
			var damage := _deal_damage(effect.value)
			return _effect_text("effect_damage", {"value": damage})
		CardEffect.EffectType.BLOCK:
			player.add_block(effect.value)
			return _effect_text("effect_block", {"value": effect.value})
		CardEffect.EffectType.DRAW:
			var destroyed_count := hand_manager.add_cards(deck_manager.draw_cards(effect.value))
			if destroyed_count > 0:
				return _effect_text("effect_draw_overflow", {"value": effect.value, "destroyed": destroyed_count})
			return _effect_text("effect_draw", {"value": effect.value})
		CardEffect.EffectType.GAIN_ENERGY:
			player.gain_energy(effect.value)
			return _effect_text("effect_energy", {"value": effect.value})
		CardEffect.EffectType.APPLY_BURN:
			enemy.add_burn(effect.value)
			return _effect_text("effect_apply_burn", {"value": effect.value})
		CardEffect.EffectType.APPLY_WEAK:
			enemy.add_weak(effect.value)
			return _effect_text("effect_apply_weak", {"value": effect.value})
		CardEffect.EffectType.HEALTH:
			player.heal(effect.value)
			return _effect_text("effect_heal", {"value": effect.value})
		CardEffect.EffectType.DISCARD_RANDOM:
			return _resolve_discard_random(effect.value)
		CardEffect.EffectType.CLEANSE_STATUS:
			return _resolve_cleanse_status(effect.value)
		CardEffect.EffectType.CONDITIONAL_WEAK:
			return _resolve_conditional_weak(effect.value)
		CardEffect.EffectType.CONDITIONAL_BURN:
			return _resolve_conditional_burn(effect.value)
		CardEffect.EffectType.CONDITIONAL_DAMAGE_IF_BURN:
			return _resolve_conditional_damage_if_burn(effect.value)
		CardEffect.EffectType.CONDITIONAL_WEAK_IF_BURN:
			return _resolve_conditional_weak_if_burn(effect.value)
		CardEffect.EffectType.CONDITIONAL_DAMAGE_IF_ENEMY_LOW_HP:
			return _resolve_conditional_damage_if_enemy_low_hp(effect.value)
		CardEffect.EffectType.CONDITIONAL_BLOCK_IF_PLAYER_LOW_HP:
			return _resolve_conditional_block_if_player_low_hp(effect.value)
		CardEffect.EffectType.CONDITIONAL_BLOCK_IF_NO_ATTACK_PLAYED:
			return _resolve_conditional_block_if_no_attack_played(effect.value)
		CardEffect.EffectType.FOOL:
			return _resolve_fool()
		CardEffect.EffectType.MAGICIAN:
			return _resolve_magician()
		CardEffect.EffectType.HIGH_PRIESTESS:
			return _resolve_high_priestess()
		CardEffect.EffectType.EMPRESS:
			player.heal(12)
			player.add_block(12)
			delayed_heal_next_turn += 6
			return _effect_text("effect_empress")
		CardEffect.EffectType.EMPEROR:
			player.add_block(15)
			emperor_block_per_turn += 2
			return _effect_text("effect_emperor")
		CardEffect.EffectType.HIEROPHANT:
			player.add_block(10)
			var destroyed_count := hand_manager.add_cards(deck_manager.draw_cards(2))
			hand_manager.reduce_next_playable_cards_cost(2, 1)
			return _effect_text("effect_hierophant", {"overflow": _overflow_text(destroyed_count)})
		CardEffect.EffectType.LOVERS:
			if player.current_health <= player.max_health - 12:
				player.heal(12)
				return _effect_text("effect_heal", {"value": 12})
			var damage := _deal_damage(12)
			return _effect_text("effect_damage", {"value": damage})
		CardEffect.EffectType.CHARIOT:
			var damage := _deal_damage(10)
			if attack_played_before_current_card:
				damage += _deal_damage(10)
				player.gain_energy(1)
				return _join_effect_parts([_effect_text("effect_damage", {"value": damage}), _effect_text("effect_energy", {"value": 1})])
			return _effect_text("effect_damage", {"value": damage})
		CardEffect.EffectType.STRENGTH:
			next_turn_damage_multiplier = max(next_turn_damage_multiplier, 2)
			return _effect_text("effect_next_turn_double_damage")
		CardEffect.EffectType.HERMIT:
			return _resolve_hermit()
		CardEffect.EffectType.WHEEL_OF_FORTUNE:
			wheel_of_fortune_active = true
			return _effect_text("effect_activate_wheel")
		CardEffect.EffectType.JUSTICE:
			return _resolve_justice()
		CardEffect.EffectType.HANGED_MAN:
			player.take_direct_damage(5)
			var destroyed_count := hand_manager.add_cards(deck_manager.draw_cards(4))
			player.gain_energy(2)
			return _effect_text("effect_hanged_man", {"overflow": _overflow_text(destroyed_count)})
		CardEffect.EffectType.TEMPERANCE:
			player.add_block(8)
			player.heal(3)
			var destroyed_count := hand_manager.add_cards(deck_manager.draw_cards(2))
			if not played_attack_this_turn:
				player.add_block(2)
				return _effect_text("effect_temperance_bonus", {"overflow": _overflow_text(destroyed_count)})
			return _effect_text("effect_temperance", {"overflow": _overflow_text(destroyed_count)})
		CardEffect.EffectType.DEVIL:
			var damage := _deal_damage(20)
			devil_self_damage_per_turn += 5
			return _effect_text("effect_devil", {"damage": damage})
		CardEffect.EffectType.TOWER:
			enemy.clear_block()
			var damage := _deal_damage(15)
			player.clear_block()
			return _effect_text("effect_remove_all_block_damage", {"damage": damage})
		CardEffect.EffectType.STAR:
			player.heal(8)
			var destroyed_count := hand_manager.add_cards(deck_manager.draw_cards(1))
			star_extra_draw_per_turn += 1
			return _effect_text("effect_star", {"overflow": _overflow_text(destroyed_count)})
		CardEffect.EffectType.SUN:
			enemy.add_burn(4)
			enemy.set_burn(enemy.burn_stacks * 2)
			return _effect_text("effect_sun")
		CardEffect.EffectType.JUDGEMENT:
			return _resolve_judgement()
		CardEffect.EffectType.WORLD:
			return _resolve_world()

	return _effect_text("effect_no_effect")


func _deal_damage(base_damage: int) -> int:
	if battle_ended or enemy == null or not is_instance_valid(enemy):
		return 0

	var modified_base_damage := RelicManager.modify_card_damage(current_resolving_card, base_damage)
	var damage := player.get_outgoing_damage(modified_base_damage)
	damage *= current_damage_multiplier
	enemy.take_damage(damage)
	return damage


func _effect_text(key: String, params: Dictionary = {}) -> String:
	return LanguageManager.tr_format(key, params)


func _join_effect_parts(parts: Array[String]) -> String:
	var separator := "，" if LanguageManager.get_language() == "zh" else ", "
	return separator.join(parts)


func _card_display_name(card: CardData) -> String:
	if card == null:
		return ""
	return card.get_display_name()


func _overflow_text(destroyed_count: int) -> String:
	if destroyed_count <= 0:
		return ""
	return _effect_text("effect_overflow_suffix", {"count": destroyed_count})


func _resolve_discard_random(amount: int) -> String:
	var discarded: Array[String] = []
	for index in range(max(amount, 0)):
		var discarded_card := hand_manager.discard_random_card()
		if discarded_card == null:
			break
		deck_manager.discard(discarded_card)
		discarded.append(discarded_card.get_display_name())
	update_all_ui()
	if discarded.is_empty():
		return _effect_text("effect_discard_none")
	return _effect_text("effect_discard_named", {"cards": ", ".join(discarded)})


func _resolve_cleanse_status(mode: int) -> String:
	var removed := player.cleanse_status(mode >= 2)
	var removed_weak := int(removed.get("weak", 0))
	var removed_burn := int(removed.get("burn", 0))
	if removed_weak == 0 and removed_burn == 0:
		return _effect_text("effect_cleanse_none")
	return _effect_text("effect_cleanse_result", {"weak": removed_weak, "burn": removed_burn})


func _resolve_conditional_weak(base_amount: int) -> String:
	var amount: int = max(base_amount, 0)
	if enemy != null and enemy.block > 0:
		amount += 1
	if enemy != null:
		enemy.add_weak(amount)
	return _effect_text("effect_apply_weak", {"value": amount})


func _resolve_conditional_burn(base_amount: int) -> String:
	var amount: int = max(base_amount, 0)
	if enemy != null and enemy.burn_stacks <= 0:
		amount += 2
	if enemy != null:
		enemy.add_burn(amount)
	return _effect_text("effect_apply_burn", {"value": amount})


func _resolve_conditional_damage_if_burn(amount: int) -> String:
	if enemy == null or enemy.burn_stacks <= 0:
		return _effect_text("effect_condition_not_met")
	var damage: int = _deal_damage(max(amount, 0))
	return _effect_text("effect_bonus_damage", {"value": damage})


func _resolve_conditional_weak_if_burn(amount: int) -> String:
	if enemy == null or enemy.burn_stacks <= 0:
		return _effect_text("effect_condition_not_met")
	var weak_amount: int = max(amount, 0)
	enemy.add_weak(weak_amount)
	return _effect_text("effect_apply_weak", {"value": weak_amount})


func _resolve_conditional_damage_if_enemy_low_hp(amount: int) -> String:
	if enemy == null or enemy.max_health <= 0:
		return _effect_text("effect_condition_not_met")
	if enemy.current_health > enemy.max_health * 0.5:
		return _effect_text("effect_condition_not_met")
	var damage: int = _deal_damage(max(amount, 0))
	return _effect_text("effect_bonus_damage", {"value": damage})


func _resolve_conditional_block_if_player_low_hp(amount: int) -> String:
	if player == null or player.max_health <= 0:
		return _effect_text("effect_condition_not_met")
	if player.current_health > player.max_health * 0.5:
		return _effect_text("effect_condition_not_met")
	var block_amount: int = max(amount, 0)
	player.add_block(block_amount)
	return _effect_text("effect_bonus_block", {"value": block_amount})


func _resolve_conditional_block_if_no_attack_played(amount: int) -> String:
	if played_attack_this_turn:
		return _effect_text("effect_condition_not_met")
	var block_amount: int = max(amount, 0)
	player.add_block(block_amount)
	return _effect_text("effect_bonus_block", {"value": block_amount})


func _resolve_fool() -> String:
	var destroyed_count := hand_manager.add_cards(deck_manager.draw_cards(3))
	player.gain_energy(2)
	var discarded_card := hand_manager.discard_random_card()
	if discarded_card != null:
		deck_manager.discard(discarded_card)
		if discarded_card.card_type == CardData.CardType.ATTACK:
			var damage := _deal_damage(8)
			return _effect_text("effect_fool_attack", {"card": _card_display_name(discarded_card), "damage": damage, "overflow": _overflow_text(destroyed_count)})
		if discarded_card.card_type == CardData.CardType.SKILL:
			player.add_block(8)
			return _effect_text("effect_fool_skill", {"card": _card_display_name(discarded_card), "overflow": _overflow_text(destroyed_count)})

	return _effect_text("effect_fool", {"overflow": _overflow_text(destroyed_count)})


func _resolve_magician() -> String:
	player.gain_energy(1)
	var destroyed_count := hand_manager.add_cards(deck_manager.draw_cards(2))
	next_card_double_cast = true
	return _effect_text("effect_magician", {"overflow": _overflow_text(destroyed_count)})

	var copied_card := deck_manager.get_random_available_card()
	if copied_card == null:
		return "没有可复制的卡牌"

	_resolve_card(copied_card)
	return "复制 %s" % copied_card.card_name


func _resolve_high_priestess() -> String:
	var drawn_cards := deck_manager.draw_cards(3)
	var destroyed_count := hand_manager.add_cards(drawn_cards)
	hand_manager.reduce_newest_cards_cost(drawn_cards.size() - destroyed_count, 1)
	return _effect_text("effect_high_priestess", {"overflow": _overflow_text(destroyed_count)})


func _resolve_hermit() -> String:
	var destroyed_count := hand_manager.add_cards(deck_manager.draw_cards(3))
	if hand_manager.cards_count() <= 3:
		destroyed_count += hand_manager.add_cards(deck_manager.draw_cards(3))
		player.gain_energy(1)
		return _effect_text("effect_hermit_big", {"overflow": _overflow_text(destroyed_count)})
	return _effect_text("effect_hermit", {"overflow": _overflow_text(destroyed_count)})


func _resolve_justice() -> String:
	if player.block > 0:
		var damage := _deal_damage(player.block * 2)
		player.set_block(int(floor(float(player.block) * 0.5)))
		return _effect_text("effect_retained_block_damage", {"damage": damage})

	var damage := _deal_damage(16)
	player.add_block(12)
	return _join_effect_parts([_effect_text("effect_damage", {"value": damage}), _effect_text("effect_block", {"value": 12})])


func _resolve_judgement() -> String:
	var recovered_count := 0
	for index in range(3):
		var card := deck_manager.take_random_from_discard()
		if card == null:
			break
		if hand_manager.add_card(card):
			recovered_count += 1

	hand_manager.set_newest_cards_cost(recovered_count, 0)
	return _effect_text("effect_recover_discard_zero", {"count": recovered_count})


func _resolve_world() -> String:
	var damage := _deal_damage(16)
	player.add_block(16)
	var destroyed_count := hand_manager.add_cards(deck_manager.draw_cards(3))
	player.gain_energy(2)
	player.heal(8)
	world_skip_enemy_turn_pending = true
	return _effect_text("effect_world", {"damage": damage, "overflow": _overflow_text(destroyed_count)})


func _on_piles_changed(draw_count: int, discard_count: int) -> void:
	draw_pile_label.text = "%s: %d" % [LanguageManager.tr_key("battle_draw_pile"), draw_count]
	discard_pile_label.text = "%s: %d" % [LanguageManager.tr_key("battle_discard_pile"), discard_count]
	_update_deck_pile_ui()


func _update_deck_pile_ui() -> void:
	if deck_manager == null or hand_manager == null:
		return
	if draw_pile_label == null:
		push_warning("[Battle UI] DrawPileLabel is missing")
	else:
		draw_pile_label.text = "%s: %d" % [_tr_or("battle_draw_pile", "Draw Pile"), deck_manager.get_draw_pile().size()]
	if discard_pile_label == null:
		push_warning("[Battle UI] DiscardPileLabel is missing")
	else:
		discard_pile_label.text = "%s: %d" % [_tr_or("battle_discard_pile", "Discard Pile"), deck_manager.get_discard_pile().size()]
	if exhaust_pile_label == null:
		push_warning("[Battle UI] ExhaustPileLabel is missing")
	else:
		exhaust_pile_label.text = "%s: %d" % [_tr_or("battle_exhaust_pile", "Exhaust"), deck_manager.get_exhaust_pile().size()]
	if hand_count_label == null:
		push_warning("[Battle UI] HandCountLabel is missing")
	else:
		hand_count_label.text = "%s: %d / %d" % [_tr_or("battle_hand_count", "Hand"), hand_manager.cards_count(), hand_manager.max_hand_size]
	if deck_pile_label != null:
		deck_pile_label.text = "%s: %d\n%s: %d\n%s: %d\n%s: %d / %d" % [
			_tr_or("battle_draw_pile", "Draw Pile"),
			deck_manager.get_draw_pile().size(),
			_tr_or("battle_discard_pile", "Discard Pile"),
			deck_manager.get_discard_pile().size(),
			_tr_or("battle_exhaust_pile", "Exhaust"),
			deck_manager.get_exhaust_pile().size(),
			_tr_or("battle_hand_count", "Hand"),
			hand_manager.cards_count(),
			hand_manager.max_hand_size,
		]
	_refresh_rebuilt_battle_layout()
	return

	deck_pile_label.text = "%s：%d\n%s：%d\n%s：%d\n%s：%d / %d" % [
		LanguageManager.tr_key("battle_draw_pile"),
		deck_manager.get_draw_pile().size(),
		LanguageManager.tr_key("battle_discard_pile"),
		deck_manager.get_discard_pile().size(),
		LanguageManager.tr_key("battle_exhaust_pile"),
		deck_manager.get_exhaust_pile().size(),
		LanguageManager.tr_key("battle_hand_count"),
		hand_manager.cards_count(),
		hand_manager.max_hand_size,
	]


func _on_player_health_changed(current_health: int, max_health: int) -> void:
	if player_health_bar != null:
		player_health_bar.max_value = max_health
		_tween_progress_bar(player_health_bar, current_health, true)
	player_label.text = _tr_format_or("battle_hp", {"current": current_health, "max": max_health}, "HP: %d / %d" % [current_health, max_health])
	_update_player_block_ui()
	if last_player_health != -1 and current_health < last_player_health:
		var amount := last_player_health - current_health
		show_damage(amount)
		_animate_player_hit_feedback()
		_shake_screen()
		AudioManager.play_sfx("attack_hit")
	elif last_player_health != -1 and current_health > last_player_health:
		show_heal(current_health - last_player_health)
		AudioManager.play_sfx("heal")
	last_player_health = current_health
	_refresh_rebuilt_battle_layout()


func _on_player_energy_changed(current_energy: int, max_energy: int) -> void:
	if player_energy_bar != null:
		player_energy_bar.max_value = max_energy
		player_energy_bar.value = current_energy
	energy_label.text = _tr_format_or("battle_energy", {"current": current_energy, "max": max_energy}, "Energy: %d / %d" % [current_energy, max_energy])
	if last_player_energy != -1 and current_energy > last_player_energy:
		AudioManager.play_sfx("energy_gain")
	last_player_energy = current_energy
	hand_manager.update_playable_cards(current_energy)
	_refresh_rebuilt_battle_layout()


func _on_player_status_changed(_status_text: String) -> void:
	player_status_label.text = _localized_status_summary(player.block, 0, player.burn_stacks, player.weak_stacks)
	_update_player_block_ui()
	if last_player_block != -1 and player.block > last_player_block:
		_spawn_floating_text(LanguageManager.tr_format("battle_float_block", {"amount": player.block - last_player_block}), _player_float_position() + Vector2(0, 28), Color(0.45, 0.75, 1.0))
		AudioManager.play_sfx("block_gain")
	if last_player_block != -1 and player.block < last_player_block:
		show_block_number(last_player_block - player.block, _player_float_position() + Vector2(0, 28), true)
	if last_player_burn != -1 and player.burn_stacks > last_player_burn:
		show_burn(player.burn_stacks - last_player_burn)
	if last_player_weak != -1 and player.weak_stacks > last_player_weak:
		show_weak(player.weak_stacks - last_player_weak)
	if last_player_burn != -1 and (player.burn_stacks > last_player_burn or player.weak_stacks > last_player_weak):
		AudioManager.play_sfx("debuff_apply")
	last_player_block = player.block
	last_player_burn = player.burn_stacks
	last_player_weak = player.weak_stacks


func _on_player_damage_taken(_amount: int) -> void:
	var relic_log := RelicManager.trigger_player_damaged(enemy)
	if relic_log != "":
		action_log_label.text = relic_log


func _update_player_block_ui() -> void:
	if player_block_label == null or player == null:
		return
	player_block_label.text = _tr_format_or("battle_block", {"value": player.block}, "Block: %d" % player.block)
	if player_status_label != null:
		player_status_label.text = _plain_status_summary(player.burn_stacks, player.weak_stacks, 0)


func _on_enemy_health_changed(current_health: int, max_health: int) -> void:
	if enemy_health_bar != null:
		enemy_health_bar.max_value = max_health
		_tween_progress_bar(enemy_health_bar, current_health, false)
	_refresh_boss_mechanic_ui()
	enemy_label.text = _enemy_display_name()
	if enemy_hp_label != null:
		enemy_hp_label.text = "HP: %d / %d" % [current_health, max_health]
	_update_enemy_block_ui()
	if last_enemy_health != -1 and current_health < last_enemy_health:
		var amount := last_enemy_health - current_health
		show_damage(amount)
		_animate_enemy_hit_feedback()
		AudioManager.play_sfx("attack_hit")
	last_enemy_health = current_health
	_refresh_rebuilt_battle_layout()


func _on_enemy_status_changed(_status_text: String) -> void:
	enemy_status_label.text = _plain_status_summary(enemy.burn_stacks, enemy.weak_stacks, enemy.strength)
	_refresh_boss_mechanic_ui()
	_update_enemy_block_ui()
	if last_enemy_block != -1 and enemy.block > last_enemy_block:
		_spawn_floating_text(LanguageManager.tr_format("battle_float_block", {"amount": enemy.block - last_enemy_block}), _enemy_float_position() + Vector2(0, 30), Color(0.45, 0.75, 1.0))
		AudioManager.play_sfx("block_gain")
	if last_enemy_block != -1 and enemy.block < last_enemy_block:
		show_block_number(last_enemy_block - enemy.block, _enemy_float_position() + Vector2(0, 30), true)
	if last_enemy_burn != -1 and enemy.burn_stacks > last_enemy_burn:
		show_burn(enemy.burn_stacks - last_enemy_burn)
	if last_enemy_weak != -1 and enemy.weak_stacks > last_enemy_weak:
		show_weak(enemy.weak_stacks - last_enemy_weak)
	if last_enemy_burn != -1 and (enemy.burn_stacks > last_enemy_burn or enemy.weak_stacks > last_enemy_weak):
		AudioManager.play_sfx("debuff_apply")
	last_enemy_block = enemy.block
	last_enemy_burn = enemy.burn_stacks
	last_enemy_weak = enemy.weak_stacks
	_refresh_rebuilt_battle_layout()


func _on_enemy_intent_changed(_intent_text: String) -> void:
	enemy_intent_label.text = _tr_format_or("battle_intent", {"intent": _localized_enemy_intent()}, "Intent: %s" % _localized_enemy_intent())
	_refresh_rebuilt_battle_layout()


func _update_enemy_block_ui() -> void:
	if enemy_block_label == null or enemy == null:
		return
	enemy_block_label.text = _tr_format_or("battle_block", {"value": enemy.block}, "Block: %d" % enemy.block)


func _localized_status_summary(block: int, strength: int, burn: int, weak: int) -> String:
	var parts: Array[String] = []
	if block > 0:
		parts.append("%s %d" % [LanguageManager.get_status_name("block"), block])
	if strength > 0:
		parts.append("%s %d" % [LanguageManager.get_status_name("strength"), strength])
	if burn > 0:
		parts.append("%s %d" % [LanguageManager.get_status_name("burn"), burn])
	if weak > 0:
		parts.append("%s %d" % [LanguageManager.get_status_name("weak"), weak])
	if parts.is_empty():
		return "%s: %s" % [LanguageManager.tr_key("ui_status"), LanguageManager.tr_key("ui_none")]
	return "  ".join(parts)


func _localized_enemy_intent() -> String:
	if enemy == null:
		return LanguageManager.tr_key("battle_intent_unknown")
	var action := enemy.get_current_action()
	if action == null:
		return LanguageManager.tr_key("battle_intent_unknown")
	match action.action_type:
		EnemyAction.ActionType.ATTACK:
			var attack_value := _preview_enemy_damage(action.value)
			if action.hit_count > 1:
				return LanguageManager.tr_format("intent.attack_times", {"value": attack_value, "times": action.hit_count})
			return LanguageManager.tr_format("intent.attack", {"value": attack_value})
		EnemyAction.ActionType.STRONG_ATTACK:
			return LanguageManager.tr_format("intent.strong_attack", {"value": _preview_enemy_damage(action.value)})
		EnemyAction.ActionType.DEFEND:
			return LanguageManager.tr_format("intent.block", {"value": action.value})
		EnemyAction.ActionType.BUFF:
			return LanguageManager.tr_format("intent.buff", {"value": action.value})
		EnemyAction.ActionType.DEBUFF:
			return LanguageManager.tr_format("intent.apply_weak", {"value": action.value})
		EnemyAction.ActionType.DEFEND_AND_DEBUFF:
			return LanguageManager.tr_format("intent.block_weak", {"value": action.value})
		EnemyAction.ActionType.CHARGE:
			return LanguageManager.tr_key("intent.charge")
		EnemyAction.ActionType.APPLY_BURN:
			return LanguageManager.tr_format("intent.apply_burn", {"value": action.value})
		EnemyAction.ActionType.HEAL_SELF:
			return LanguageManager.tr_format("intent.heal", {"value": action.value})
	return LanguageManager.tr_key("intent.unknown")


func _preview_enemy_damage(base_damage: int) -> int:
	if enemy == null:
		return base_damage
	var scaled := int(ceil(float(base_damage) * RunManager.get_enemy_damage_multiplier()))
	return max(scaled + enemy.strength - enemy.weak_stacks, 0)


func _on_enemy_boss_mechanic_changed(mechanic_text: String, banner_text: String, floating_text: String) -> void:
	if boss_mechanic_label != null:
		boss_mechanic_label.text = mechanic_text
		boss_mechanic_label.visible = mechanic_text != ""
	show_floating_text(floating_text, "burn")
	_animate_enemy_hit_feedback()
	_safe_play_sfx("debuff_apply")
	_show_boss_mechanic_banner(banner_text)


func _on_enemy_action_performed(action_text: String) -> void:
	if battle_ended:
		return

	action_log_label.text = _localize_combat_text(action_text)


func _on_end_turn_button_pressed() -> void:
	if battle_ended or is_game_over or is_animating or is_enemy_turn_running:
		return

	turn_manager.end_turn()


func _on_view_deck_button_pressed() -> void:
	AudioManager.play_sfx("ui_click")
	deck_view.open(deck_manager)


func _on_main_menu_button_pressed() -> void:
	AudioManager.play_sfx("ui_click")
	if main_menu_confirm_overlay != null:
		main_menu_confirm_overlay.visible = true
		return


func _confirm_return_to_main_menu() -> void:
	AudioManager.play_sfx("ui_click")
	if main_menu_confirm_overlay != null:
		main_menu_confirm_overlay.visible = false
	RunManager.save_player_health(player.current_health)
	SaveManager.save_run()
	get_tree().change_scene_to_file(MAIN_MENU_SCENE_PATH)


func _on_card_target_hover_changed(is_hovering: bool) -> void:
	if battle_ended or is_game_over:
		enemy_target_area.visible = false
		return

	enemy_target_area.visible = is_hovering


func _on_card_preview_requested(card: CardData) -> void:
	if card == null:
		return

	preview_art_texture.texture = card.get_art_texture()
	preview_name_label.text = card.get_display_name()
	preview_cost_label.text = "%s: %d" % [LanguageManager.tr_key("ui_cost"), card.cost]
	preview_description_label.text = card.get_display_description()
	card_preview_panel.visible = true


func _on_card_preview_hidden() -> void:
	card_preview_panel.visible = false


func _on_hand_cards_overflowed(cards: Array[CardData]) -> void:
	# Overflow cards are not kept in hand, but they remain visible in discard.
	deck_manager.discard_many(cards)
	_update_deck_pile_ui()


func _on_draw_failed_empty() -> void:
	if not battle_ended and not is_game_over:
		RunManager.mark_failed()
	if battle_ended or is_game_over:
		return

	action_log_label.text = LanguageManager.tr_key("battle_draw_failed_empty")
	_show_game_over("Defeat")


func _animate_card_play(card_view: CardView) -> void:
	var start_position := card_view.global_position
	if card_view.get_parent() != self:
		card_view.get_parent().remove_child(card_view)
		add_child(card_view)
	card_view.global_position = start_position
	card_view.z_index = 200
	card_view.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var target_position := enemy_target_area.global_position + enemy_target_area.size * 0.5 - card_view.size * 0.5
	var tween := create_tween()
	tween.set_parallel(true)
	tween.set_trans(Tween.TRANS_CUBIC)
	tween.set_ease(Tween.EASE_IN)
	tween.tween_property(card_view, "global_position", target_position, CARD_PLAY_ANIM_TIME)
	tween.tween_property(card_view, "scale", Vector2(0.25, 0.25), CARD_PLAY_ANIM_TIME)
	tween.tween_property(card_view, "modulate:a", 0.0, CARD_PLAY_ANIM_TIME)
	await tween.finished
	card_view.queue_free()
	enemy_target_area.visible = false


func show_damage_number(amount: int, global_pos: Vector2) -> void:
	show_damage(amount)


func show_block_number(amount: int, global_pos: Vector2, is_loss := false) -> void:
	var text := "%s -%d" % [LanguageManager.tr_key("ui_block"), amount] if is_loss else LanguageManager.tr_format("battle_float_block", {"amount": amount})
	_spawn_floating_text(text, global_pos, Color(0.45, 0.78, 1.0))


func show_heal_number(amount: int, global_pos: Vector2) -> void:
	show_heal(amount)


func show_damage(amount: int) -> void:
	show_floating_text("-%d" % amount, "damage")


func show_heal(amount: int) -> void:
	show_floating_text(LanguageManager.tr_format("battle_float_heal", {"amount": amount}), "heal")


func show_block(amount: int) -> void:
	show_floating_text(LanguageManager.tr_format("battle_float_block", {"amount": amount}), "block")


func show_guard(amount: int) -> void:
	show_floating_text(LanguageManager.tr_format("battle_float_guard", {"amount": amount}), "guard")


func show_burn(amount: int) -> void:
	show_floating_text(LanguageManager.tr_format("battle_float_burn", {"amount": amount}), "burn")


func show_weak(amount: int) -> void:
	show_floating_text(LanguageManager.tr_format("battle_float_weak", {"amount": amount}), "weak")


func show_floating_text(text: String, feedback_type: String = "generic") -> void:
	_spawn_floating_text(text, _next_floating_text_position(), _feedback_color(feedback_type))


func _feedback_color(feedback_type: String) -> Color:
	match feedback_type:
		"damage":
			return Color(1.0, 0.22, 0.12)
		"heal":
			return Color(0.28, 1.0, 0.42)
		"block":
			return Color(0.35, 0.78, 1.0)
		"armor_loss", "guard":
			return Color(0.72, 0.92, 1.0)
		"weak":
			return Color(0.78, 0.45, 1.0)
		"burn":
			return Color(1.0, 0.5, 0.08)
		"energy":
			return Color(0.4, 0.82, 1.0)
	return Color(1.0, 0.9, 0.58)


func _next_floating_text_position() -> Vector2:
	var viewport_size := get_viewport_rect().size
	var lane := floating_text_sequence % 7
	floating_text_sequence += 1
	var lane_offsets := [-90.0, -60.0, -30.0, 0.0, 30.0, 60.0, 90.0]
	var x_offset: float = lane_offsets[lane] + randf_range(-12.0, 12.0)
	var y_offset := randf_range(-44.0, 34.0) + float(lane % 3) * 12.0
	return viewport_size * 0.5 + Vector2(x_offset, y_offset - 58.0)


func _tween_progress_bar(progress_bar: ProgressBar, target_value: int, is_player_bar: bool) -> void:
	if is_player_bar:
		if player_health_tween != null:
			player_health_tween.kill()
		player_health_tween = create_tween()
		player_health_tween.tween_property(progress_bar, "value", target_value, HEALTH_BAR_TWEEN_TIME)
	else:
		if enemy_health_tween != null:
			enemy_health_tween.kill()
		enemy_health_tween = create_tween()
		enemy_health_tween.tween_property(progress_bar, "value", target_value, HEALTH_BAR_TWEEN_TIME)


func _spawn_floating_text(text: String, global_pos: Vector2, color: Color) -> void:
	global_pos = _next_floating_text_position()
	var label := Label.new()
	label.text = text
	label.modulate = color
	label.z_index = 300
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_color_override("font_color", color)
	label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 1))
	label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.95))
	label.add_theme_constant_override("outline_size", 7)
	label.add_theme_constant_override("shadow_offset_x", 2)
	label.add_theme_constant_override("shadow_offset_y", 2)
	label.add_theme_font_size_override("font_size", 46)
	add_child(label)
	label.global_position = global_pos
	label.scale = Vector2(0.7, 0.7)

	var tween := create_tween()
	tween.set_parallel(true)
	tween.set_trans(Tween.TRANS_QUAD)
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_property(label, "global_position", global_pos + Vector2(0, -86), FLOATING_TEXT_LIFETIME)
	tween.tween_property(label, "scale", Vector2(1.2, 1.2), 0.14)
	tween.chain().tween_property(label, "scale", Vector2.ONE, 0.12)
	tween.parallel().tween_property(label, "modulate:a", 0.0, FLOATING_TEXT_LIFETIME)
	tween.finished.connect(func() -> void:
		label.queue_free()
	)


func _show_phase_banner(text: String) -> void:
	phase_banner.text = text
	phase_banner.scale = Vector2(0.9, 0.9)
	phase_banner.modulate.a = 0.0
	var tween := create_tween()
	tween.set_trans(Tween.TRANS_QUAD)
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_property(phase_banner, "modulate:a", 1.0, 0.12)
	tween.parallel().tween_property(phase_banner, "scale", Vector2.ONE, 0.12)
	tween.tween_interval(max(TURN_BANNER_TIME - 0.3, 0.1))
	tween.tween_property(phase_banner, "modulate:a", 0.0, 0.18)


func _show_boss_mechanic_banner(text: String) -> void:
	phase_banner.text = text
	phase_banner.scale = Vector2(0.82, 0.82)
	phase_banner.modulate.a = 0.0
	phase_banner.add_theme_font_size_override("font_size", 42)
	var tween := create_tween()
	tween.set_trans(Tween.TRANS_QUAD)
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_property(phase_banner, "modulate:a", 1.0, 0.15)
	tween.parallel().tween_property(phase_banner, "scale", Vector2(1.08, 1.08), 0.15)
	tween.tween_interval(1.0)
	tween.tween_property(phase_banner, "scale", Vector2.ONE, 0.12)
	tween.parallel().tween_property(phase_banner, "modulate:a", 0.0, 0.25)
	tween.finished.connect(func() -> void:
		phase_banner.add_theme_font_size_override("font_size", 36)
	)


func _refresh_boss_mechanic_ui() -> void:
	if boss_mechanic_label == null or enemy == null:
		return

	var mechanic_text := enemy.get_boss_mechanic_text()
	boss_mechanic_label.text = mechanic_text
	boss_mechanic_label.visible = mechanic_text != ""
	if mechanic_text != "":
		enemy_label.add_theme_font_size_override("font_size", 30)
		enemy_health_bar.custom_minimum_size = Vector2(570, 30)
	else:
		enemy_label.add_theme_font_size_override("font_size", 26)
		enemy_health_bar.custom_minimum_size = Vector2(570, 26)


func _animate_enemy_attack_windup() -> void:
	var original_position := enemy_art_texture.position
	var original_scale := enemy_art_texture.scale
	var tween := create_tween()
	tween.set_trans(Tween.TRANS_QUAD)
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_property(enemy_art_texture, "position", original_position + Vector2(0, 18), ENEMY_ATTACK_WINDUP * 0.55)
	tween.parallel().tween_property(enemy_art_texture, "scale", original_scale * 1.035, ENEMY_ATTACK_WINDUP * 0.55)
	tween.tween_property(enemy_art_texture, "position", original_position, ENEMY_ATTACK_WINDUP * 0.45)
	tween.parallel().tween_property(enemy_art_texture, "scale", original_scale, ENEMY_ATTACK_WINDUP * 0.45)
	await tween.finished


func _animate_enemy_hit_feedback() -> void:
	_flash_enemy()
	_shake_enemy()
	var original_modulate := enemy_art_texture.modulate
	var tween := create_tween()
	tween.tween_property(enemy_art_texture, "modulate", Color(1.0, 0.45, 0.35, 1.0), 0.05)
	tween.tween_property(enemy_art_texture, "modulate", original_modulate, 0.12)


func _animate_player_hit_feedback() -> void:
	var original_modulate := player_hud_panel.modulate
	var original_player_label_position := player_label.position
	var original_energy_label_position := energy_label.position
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(player_hud_panel, "modulate", Color(1.0, 0.42, 0.38, 1.0), 0.08)
	tween.tween_property(player_label, "position", original_player_label_position + Vector2(-8, 0), 0.05)
	tween.tween_property(energy_label, "position", original_energy_label_position + Vector2(-8, 0), 0.05)
	await tween.finished
	var return_tween := create_tween()
	return_tween.set_parallel(true)
	return_tween.tween_property(player_hud_panel, "modulate", original_modulate, 0.14)
	return_tween.tween_property(player_label, "position", original_player_label_position, 0.08)
	return_tween.tween_property(energy_label, "position", original_energy_label_position, 0.08)
	await return_tween.finished


func _flash_enemy() -> void:
	enemy_target_area.visible = true
	enemy_target_area.modulate.a = 1.0
	enemy_target_area.color = Color(1.0, 0.2, 0.2, 0.35)
	var tween := create_tween()
	tween.tween_property(enemy_target_area, "modulate:a", 0.0, 0.18)
	tween.finished.connect(func() -> void:
		enemy_target_area.modulate.a = 1.0
		enemy_target_area.color = Color(1.0, 0.85, 0.2, 0.18)
		enemy_target_area.visible = false
	)


func _shake_enemy() -> void:
	var labels: Array[Label] = [enemy_label, enemy_status_label, enemy_intent_label]
	if boss_mechanic_label != null and boss_mechanic_label.visible:
		labels.append(boss_mechanic_label)
	var original_positions: Array[Vector2] = []
	for label in labels:
		original_positions.append(label.position)

	var tween := create_tween()
	for step in range(4):
		var offset := Vector2(6 if step % 2 == 0 else -6, 0)
		tween.tween_callback(_set_enemy_labels_offset.bind(labels, original_positions, offset))
		tween.tween_interval(0.035)
	tween.tween_callback(_set_enemy_labels_offset.bind(labels, original_positions, Vector2.ZERO))


func _set_enemy_labels_offset(labels: Array, original_positions: Array[Vector2], offset: Vector2) -> void:
	for index in range(labels.size()):
		labels[index].position = original_positions[index] + offset


func _shake_screen() -> void:
	var original_position := position
	var tween := create_tween()
	for step in range(5):
		var offset := Vector2(randf_range(-5.0, 5.0), randf_range(-3.0, 3.0))
		tween.tween_property(self, "position", original_position + offset, 0.025)
	tween.tween_property(self, "position", original_position, 0.04)


func _player_float_position() -> Vector2:
	return player_label.global_position + Vector2(player_label.size.x * 0.5 - 32, -10)


func _enemy_float_position() -> Vector2:
	return enemy_label.global_position + Vector2(enemy_label.size.x * 0.5 - 32, -10)


func _enemy_display_name() -> String:
	if enemy != null and enemy.enemy_data != null:
		return enemy.enemy_data.get_display_name()
	if enemy != null:
		return LanguageManager.get_enemy_name("", _localize_combat_text(enemy.enemy_name))
	return LanguageManager.tr_key("enemy.unknown.name")


func _set_enemy_art_for_data(enemy_data: EnemyData) -> void:
	var route_texture: Texture2D = _load_route_specific_enemy_art(enemy_data.enemy_id)
	if route_texture != null:
		_set_enemy_art(route_texture)
		return

	_set_enemy_art(enemy_data.enemy_art)


func _load_route_specific_enemy_art(enemy_id: String) -> Texture2D:
	if RunManager.current_chapter != 4 or RunManager.ending_route != RunManager.ENDING_ROUTE_ABYSS:
		return null

	var raw_path: Variant = CHAPTER_4_ABYSS_ENEMY_ART_PATHS.get(enemy_id, "")
	var art_path: String = str(raw_path)
	if art_path == "":
		return null

	if not ResourceLoader.exists(art_path):
		push_warning("[Enemy Art] missing route-specific art: " + art_path)
		return null

	return load(art_path) as Texture2D


func _set_enemy_art(texture: Texture2D) -> void:
	if texture == null:
		enemy_art_texture.texture = null
		push_warning("Enemy art is missing for %s." % enemy.enemy_name)
		return

	enemy_art_texture.texture = texture


func _localize_combat_text(text: String) -> String:
	if LanguageManager.get_language() == "en":
		return text
	var localized := text
	localized = localized.replace("Player Status", "玩家状态")
	localized = localized.replace("Enemy Status", "敌人状态")
	localized = localized.replace("Status", "状态")
	localized = localized.replace("Intent", "意图")
	localized = localized.replace("No Intent", "无意图")
	localized = localized.replace("Strong Attack", "强力攻击")
	localized = localized.replace("Attack", "攻击")
	localized = localized.replace("Defend", "防御")
	localized = localized.replace("Apply Weak", "施加虚弱")
	localized = localized.replace("Weak", "虚弱")
	localized = localized.replace("Burn", "燃烧")
	localized = localized.replace("Block", "护甲")
	localized = localized.replace("Strength", "力量")
	localized = localized.replace("Energy", "能量")
	localized = localized.replace("HP", "生命")
	localized = localized.replace("Health", "生命")
	localized = localized.replace("None", "无")
	localized = localized.replace("Victory", "胜利")
	localized = localized.replace("Defeat", "失败")
	localized = localized.replace("Run Cleared", "通关")
	localized = localized.replace("attacked for", "攻击造成")
	localized = localized.replace("used strong attack for", "强力攻击造成")
	localized = localized.replace("gained", "获得")
	localized = localized.replace("applied", "施加")
	localized = localized.replace("is charging", "正在蓄力")
	localized = localized.replace("did nothing", "没有行动")
	return localized


func _play_sound(audio_player: AudioStreamPlayer) -> void:
	if audio_player != null and audio_player.stream != null:
		audio_player.play()


func _refresh_relics_label() -> void:
	var names: Array[String] = []
	for relic in RelicManager.get_current_relics():
		names.append(relic.relic_name)

	relics_label.text = "%s: %s" % [LanguageManager.tr_key("ui_relic"), LanguageManager.tr_key("ui_none")] if names.is_empty() else "%s: %s" % [LanguageManager.tr_key("ui_relic"), ", ".join(names)]


func _refresh_relic_icon_bar() -> void:
	if relic_icon_bar == null:
		return

	for child in relic_icon_bar.get_children():
		child.queue_free()

	for relic in RelicManager.get_current_relics():
		var icon := TextureRect.new()
		icon.custom_minimum_size = Vector2(30, 30)
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.texture = RelicManager.get_relic_icon(relic)
		relic_icon_bar.add_child(icon)


func _enter_battle_end_state(context: String) -> bool:
	if battle_ended:
		print("[Victory] duplicate battle end ignored: ", context)
		return false

	battle_ended = true
	is_game_over = true
	is_enemy_turn_running = false
	is_animating = true
	end_turn_button.disabled = true
	enemy_target_area.visible = false
	card_preview_panel.visible = false
	print("[Victory] battle_ended set true")
	print("[Victory] disabling input")
	return true


func _safe_play_sfx(sfx_name: String) -> void:
	var audio_manager := get_node_or_null("/root/AudioManager")
	if audio_manager != null and audio_manager.has_method("play_sfx"):
		audio_manager.play_sfx(sfx_name)
	else:
		push_warning("[Victory] AudioManager not available, skipped sfx: " + sfx_name)


func _safe_change_scene(scene_path: String) -> void:
	print("[Victory] scene path:", scene_path)
	if not ResourceLoader.exists(scene_path):
		push_warning("[Victory] RewardScene not found: " + scene_path)
		_show_game_over("Victory")
		return

	print("[Victory] going to reward scene")
	var error := get_tree().change_scene_to_file(scene_path)
	if error != OK:
		push_warning("[Victory] change_scene_to_file failed (%d): %s" % [error, scene_path])
		_show_game_over("Victory")


func _on_enemy_died() -> void:
	print("[Victory] enemy hp <= 0")
	if not _enter_battle_end_state("enemy died"):
		return

	RunManager.save_player_health(player.current_health)
	RunManager.claim_battle_gold_reward()
	if RunManager.is_boss_battle():
		print("[Victory] boss battle cleared")
		if RunManager.prepare_chapter_reward_after_boss():
			_safe_play_sfx("victory")
			await get_tree().create_timer(0.5).timeout
			if not is_inside_tree():
				return
			_safe_change_scene(RunManager.CHAPTER_REWARD_SCENE_PATH)
		else:
			RunManager.mark_cleared()
			_safe_play_sfx("victory")
			await get_tree().create_timer(0.5).timeout
			if not is_inside_tree():
				return
			_safe_change_scene(RunManager.VICTORY_SCENE_PATH)
			return
			_show_game_over("通关")
	else:
		var save_ok := SaveManager.save_run()
		print("[Victory] save_run:", save_ok)
		print("[Victory] playing victory sfx")
		_safe_play_sfx("victory")

		var reward_scene_path := RunManager.REWARD_SCENE_PATH
		if RelicManager.roll_relic_drop(RunManager.get_current_map_node_type()):
			reward_scene_path = RunManager.RELIC_REWARD_SCENE_PATH

		await get_tree().create_timer(0.5).timeout
		if not is_inside_tree():
			return
		_safe_change_scene(reward_scene_path)


func _on_player_died() -> void:
	if player.debug_invincible:
		return
	if battle_ended:
		return

	if _try_fate_ember_revive():
		return

	RunManager.mark_failed()
	_show_game_over("失败")


func _try_fate_ember_revive() -> bool:
	if fate_ember_reviving or not RelicManager.has_relic(RelicManager.FATE_EMBER_ID):
		return false

	fate_ember_reviving = true
	RelicManager.consume_fate_ember()
	RunManager.player_current_health = RunManager.player_max_health
	SaveManager.save_run()
	_enter_battle_end_state("fate ember revive")
	action_log_label.text = _effect_text("effect_fate_ember_revive")
	_show_phase_banner(_effect_text("effect_fate_ember_banner"))
	show_floating_text(_effect_text("effect_fate_ember_float"), "heal")
	_safe_play_sfx("heal")
	_restart_after_fate_ember()
	return true


func _restart_after_fate_ember() -> void:
	await get_tree().create_timer(1.0).timeout
	if is_inside_tree():
		get_tree().reload_current_scene()


func _show_game_over(result_text: String) -> void:
	if not battle_ended:
		_enter_battle_end_state("game over: " + result_text)
	elif game_over_overlay.visible:
		print("[Victory] game over overlay already visible")
		return

	is_game_over = true
	is_animating = false
	is_enemy_turn_running = false
	end_turn_button.disabled = true
	game_over_overlay.visible = true
	restart_button.text = LanguageManager.tr_key("battle_return_main_menu")
	restart_button.visible = true
	if RunManager.run_state == RunManager.RunState.FAILED:
		_safe_play_sfx("defeat")
		_safe_change_scene(RunManager.DEFEAT_SCENE_PATH)
		return
	result_label.text = _localize_combat_text(result_text)
	if result_text == "失败" or result_text == "Defeat":
		_safe_play_sfx("defeat")
	else:
		print("[Victory] playing victory sfx")
		_safe_play_sfx("victory")


func _on_restart_button_pressed() -> void:
	AudioManager.play_sfx("ui_click")
	get_tree().change_scene_to_file(MAIN_MENU_SCENE_PATH)


func _setup_debug_panel() -> void:
	if debug_panel == null:
		return

	if not OS.is_debug_build():
		debug_panel.queue_free()
		return

	debug_panel.visible = false
	debug_panel.add_health_requested.connect(_debug_add_health)
	debug_panel.add_energy_requested.connect(_debug_add_energy)
	debug_panel.draw_cards_requested.connect(_debug_draw_cards)
	debug_panel.add_card_requested.connect(_debug_add_card_to_hand)
	debug_panel.kill_enemy_requested.connect(_debug_kill_enemy)
	debug_panel.next_battle_requested.connect(_debug_go_to_next_battle)
	debug_panel.print_piles_requested.connect(_debug_print_piles)
	debug_panel.invincible_changed.connect(_debug_set_invincible)


func _debug_add_health(amount: int) -> void:
	player.heal(amount)
	debug_panel.set_status("Added %d HP." % amount)


func _debug_add_energy(amount: int) -> void:
	player.debug_add_energy(amount)
	hand_manager.update_playable_cards(player.current_energy)
	debug_panel.set_status("Added %d Energy." % amount)


func _debug_draw_cards(amount: int) -> void:
	var destroyed_count := hand_manager.add_cards(deck_manager.draw_cards(amount))
	hand_manager.update_playable_cards(player.current_energy)
	debug_panel.set_status("Drew %d card(s). Overflow destroyed: %d." % [amount, destroyed_count])


func _debug_add_card_to_hand(card_id: String) -> void:
	if card_id == "":
		debug_panel.set_status("Enter a card_id first.")
		return

	var card := CardDatabase.get_card(card_id)
	if card == null:
		debug_panel.set_status("Unknown card_id: %s" % card_id)
		return

	if hand_manager.add_card(card):
		hand_manager.update_playable_cards(player.current_energy)
		debug_panel.set_status("Added %s to hand." % card.card_name)
	else:
		debug_panel.set_status("Hand is full. Card was destroyed.")


func _debug_kill_enemy() -> void:
	if enemy.current_health <= 0:
		debug_panel.set_status("Enemy is already dead.")
		return

	enemy.take_direct_damage(enemy.current_health)
	debug_panel.set_status("Enemy killed.")


func _debug_go_to_next_battle() -> void:
	if RunManager.is_boss_battle():
		if RunManager.prepare_chapter_reward_after_boss():
			debug_panel.set_status("Chapter reward prepared.")
			get_tree().change_scene_to_file(RunManager.CHAPTER_REWARD_SCENE_PATH)
		else:
			RunManager.mark_cleared()
			get_tree().change_scene_to_file(RunManager.VICTORY_SCENE_PATH)
		return

	RunManager.save_player_health(player.current_health)
	RunManager.complete_current_map_node()
	debug_panel.set_status("Going back to map.")
	get_tree().change_scene_to_file(RunManager.MAP_SCENE_PATH)


func _debug_print_piles() -> void:
	print("=== DEBUG DECK STATE ===")
	print("Full Deck: " + _debug_card_list(deck_manager.get_full_deck()))
	print("Draw Pile: " + _debug_card_list(deck_manager.get_draw_pile()))
	print("Discard Pile: " + _debug_card_list(deck_manager.get_discard_pile()))
	print("Exhaust Pile: " + _debug_card_list(deck_manager.get_exhaust_pile()))
	print("========================")
	debug_panel.set_status("Printed deck state to output.")


func _debug_card_list(cards: Array[CardData]) -> String:
	var ids: Array[String] = []
	for card in cards:
		if card != null:
			ids.append(card.card_id)
	return "[" + ", ".join(ids) + "]"


func _debug_set_invincible(enabled: bool) -> void:
	player.set_debug_invincible(enabled)
	debug_panel.set_status("Invincible: %s" % ("ON" if enabled else "OFF"))
