extends Control
class_name DebugPanel

signal add_health_requested(amount: int)
signal add_energy_requested(amount: int)
signal draw_cards_requested(amount: int)
signal add_card_requested(card_id: String)
signal kill_enemy_requested
signal next_battle_requested
signal print_piles_requested
signal invincible_changed(enabled: bool)

@onready var health_amount_spin: SpinBox = $PanelContainer/VBox/HealthRow/HealthAmountSpin
@onready var add_health_button: Button = $PanelContainer/VBox/HealthRow/AddHealthButton
@onready var energy_amount_spin: SpinBox = $PanelContainer/VBox/EnergyRow/EnergyAmountSpin
@onready var add_energy_button: Button = $PanelContainer/VBox/EnergyRow/AddEnergyButton
@onready var draw_amount_spin: SpinBox = $PanelContainer/VBox/DrawRow/DrawAmountSpin
@onready var draw_button: Button = $PanelContainer/VBox/DrawRow/DrawButton
@onready var card_id_edit: LineEdit = $PanelContainer/VBox/CardRow/CardIdEdit
@onready var add_card_button: Button = $PanelContainer/VBox/CardRow/AddCardButton
@onready var kill_enemy_button: Button = $PanelContainer/VBox/KillEnemyButton
@onready var next_battle_button: Button = $PanelContainer/VBox/NextBattleButton
@onready var print_piles_button: Button = $PanelContainer/VBox/PrintPilesButton
@onready var invincible_check_box: CheckBox = $PanelContainer/VBox/InvincibleCheckBox
@onready var status_label: Label = $PanelContainer/VBox/StatusLabel


func _ready() -> void:
	visible = false
	add_health_button.pressed.connect(_on_add_health_pressed)
	add_energy_button.pressed.connect(_on_add_energy_pressed)
	draw_button.pressed.connect(_on_draw_pressed)
	add_card_button.pressed.connect(_on_add_card_pressed)
	kill_enemy_button.pressed.connect(func() -> void:
		AudioManager.play_sfx("ui_click")
		kill_enemy_requested.emit()
	)
	next_battle_button.pressed.connect(func() -> void:
		AudioManager.play_sfx("ui_click")
		next_battle_requested.emit()
	)
	print_piles_button.pressed.connect(func() -> void:
		AudioManager.play_sfx("ui_click")
		print_piles_requested.emit()
	)
	invincible_check_box.toggled.connect(func(enabled: bool) -> void:
		AudioManager.play_sfx("ui_click")
		invincible_changed.emit(enabled)
	)


# Shows a short result message for the last debug action.
func set_status(text: String) -> void:
	status_label.text = text


# Keeps the checkbox in sync if a scene resets the player.
func set_invincible_enabled(enabled: bool) -> void:
	invincible_check_box.button_pressed = enabled


func _on_add_health_pressed() -> void:
	AudioManager.play_sfx("ui_click")
	add_health_requested.emit(int(health_amount_spin.value))


func _on_add_energy_pressed() -> void:
	AudioManager.play_sfx("ui_click")
	add_energy_requested.emit(int(energy_amount_spin.value))


func _on_draw_pressed() -> void:
	AudioManager.play_sfx("ui_click")
	draw_cards_requested.emit(int(draw_amount_spin.value))


func _on_add_card_pressed() -> void:
	AudioManager.play_sfx("ui_click")
	add_card_requested.emit(card_id_edit.text.strip_edges())
