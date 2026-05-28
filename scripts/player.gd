extends Node
class_name Player

signal health_changed(current_health: int, max_health: int)
signal energy_changed(current_energy: int, max_energy: int)
signal status_changed(status_text: String)
signal damage_taken(amount: int)
signal died

@export var max_health := 50
@export var max_energy := 5

var current_health := 0
var current_energy := 0
var block := 0
var burn_stacks := 0
var weak_stacks := 0
var debug_invincible := false


func _ready() -> void:
	current_health = max_health
	current_energy = max_energy
	health_changed.emit(current_health, max_health)
	energy_changed.emit(current_energy, max_energy)
	_emit_status_changed()


# Sets health when entering a later battle in the same run.
func set_current_health(value: int) -> void:
	current_health = clamp(value, 0, max_health)
	health_changed.emit(current_health, max_health)


func refresh_energy() -> void:
	current_energy = max_energy
	energy_changed.emit(current_energy, max_energy)


func gain_energy(amount: int) -> void:
	current_energy = min(current_energy + amount, max_energy)
	energy_changed.emit(current_energy, max_energy)


# Debug-only helper used by DebugPanel. It can exceed max energy on purpose.
func debug_add_energy(amount: int) -> void:
	current_energy = max(current_energy + amount, 0)
	energy_changed.emit(current_energy, max_energy)


# Toggles DebugPanel invincibility without exposing status internals.
func set_debug_invincible(enabled: bool) -> void:
	debug_invincible = enabled
	_emit_status_changed()


func can_spend_energy(amount: int) -> bool:
	return current_energy >= amount


func spend_energy(amount: int) -> void:
	current_energy = max(current_energy - amount, 0)
	energy_changed.emit(current_energy, max_energy)


func get_outgoing_damage(base_damage: int) -> int:
	# Weak lowers damage dealt by 1 per stack. Damage cannot go below 0.
	return max(base_damage - weak_stacks, 0)


func take_damage(amount: int) -> void:
	if current_health <= 0:
		return
	if debug_invincible:
		_emit_status_changed()
		return

	# Weak increases normal incoming damage by 1 per stack before Block absorbs it.
	var incoming_damage: int = max(amount + weak_stacks, 0)
	var blocked_damage: int = min(block, incoming_damage)
	block -= blocked_damage
	incoming_damage -= blocked_damage
	current_health = max(current_health - incoming_damage, 0)
	health_changed.emit(current_health, max_health)
	_emit_status_changed()
	if incoming_damage > 0:
		damage_taken.emit(incoming_damage)

	if current_health == 0:
		died.emit()


func take_direct_damage(amount: int) -> void:
	if current_health <= 0:
		return
	if debug_invincible:
		_emit_status_changed()
		return

	current_health = max(current_health - max(amount, 0), 0)
	health_changed.emit(current_health, max_health)
	_emit_status_changed()

	if current_health == 0:
		died.emit()


func add_block(amount: int) -> void:
	block += amount
	_emit_status_changed()


func clear_block() -> void:
	block = 0
	_emit_status_changed()


func set_block(amount: int) -> void:
	block = max(amount, 0)
	_emit_status_changed()


func heal(amount: int) -> void:
	if current_health <= 0:
		return

	current_health = min(current_health + amount, max_health)
	health_changed.emit(current_health, max_health)


func add_burn(amount: int) -> void:
	burn_stacks += amount
	_emit_status_changed()


func add_weak(amount: int) -> void:
	weak_stacks += amount
	_emit_status_changed()


func remove_burn(amount: int) -> int:
	var removed: int = min(max(amount, 0), burn_stacks)
	burn_stacks -= removed
	_emit_status_changed()
	return removed


func remove_weak(amount: int) -> int:
	var removed: int = min(max(amount, 0), weak_stacks)
	weak_stacks -= removed
	_emit_status_changed()
	return removed


# Cleanses player debuffs for card effects without exposing UI logic.
func cleanse_status(remove_both: bool) -> Dictionary:
	var removed := {"weak": 0, "burn": 0}
	if remove_both:
		removed["weak"] = remove_weak(1)
		removed["burn"] = remove_burn(1)
		return removed

	if weak_stacks > 0:
		removed["weak"] = remove_weak(1)
	elif burn_stacks > 0:
		removed["burn"] = remove_burn(1)
	return removed


func resolve_turn_start_status() -> void:
	if burn_stacks > 0:
		take_direct_damage(burn_stacks)
	_emit_status_changed()


func _emit_status_changed() -> void:
	var parts: Array[String] = []
	if debug_invincible:
		parts.append("Invincible")
	if block > 0:
		parts.append("%s %d" % [LanguageManager.get_status_name("block"), block])
	if burn_stacks > 0:
		parts.append("%s %d" % [LanguageManager.get_status_name("burn"), burn_stacks])
	if weak_stacks > 0:
		parts.append("%s %d" % [LanguageManager.get_status_name("weak"), weak_stacks])

	var status_text := "%s: %s" % [LanguageManager.tr_key("ui_status"), LanguageManager.tr_key("ui_none")]
	if not parts.is_empty():
		status_text = "%s: %s" % [LanguageManager.tr_key("ui_status"), ", ".join(parts)]
	status_changed.emit(status_text)
