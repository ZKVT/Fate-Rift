extends Node
class_name Enemy

signal health_changed(current_health: int, max_health: int)
signal status_changed(status_text: String)
signal intent_changed(intent_text: String)
signal boss_mechanic_changed(mechanic_text: String, banner_text: String, floating_text: String)
signal action_performed(action_text: String)
signal died

const FOREST_GUARDIAN_ID := "forest_guardian"
const MOLTEN_LORD_ID := "molten_lord"
const WORLD_DEVOURER_ID := "world_devourer"
const ASTRAL_JUDICATOR_ID := "astral_judicator"
const ABYSS_AVATAR_ID := "abyss_avatar"

@export var enemy_name := "Slime"
@export var max_health := 30
@export var actions: Array[EnemyAction] = []
@export var enemy_data: EnemyData

var current_health := 0
var block := 0
var strength := 0
var burn_stacks := 0
var weak_stacks := 0
var action_index := 0
var is_boss := false
var lost_health_step_size := 20
var damage_bonus_per_step := 0
var low_health_threshold := 0.5
var low_health_damage_bonus := 0
var boss_mechanic_stacks := 0
var boss_mechanic_active := false
var boss_turns_taken := 0


func _ready() -> void:
	_apply_enemy_data()
	if actions.is_empty():
		setup_slime()

	current_health = max_health
	health_changed.emit(current_health, max_health)
	_emit_status_changed()
	_emit_intent_changed()


# Replaces this enemy with new data and resets combat state.
func setup_from_data(data: EnemyData) -> void:
	enemy_data = data
	block = 0
	strength = 0
	burn_stacks = 0
	weak_stacks = 0
	is_boss = false
	lost_health_step_size = 20
	damage_bonus_per_step = 0
	low_health_threshold = 0.5
	low_health_damage_bonus = 0
	boss_mechanic_stacks = 0
	boss_mechanic_active = false
	boss_turns_taken = 0
	_apply_enemy_data()
	if actions.is_empty():
		setup_slime()

	current_health = max_health
	action_index = 0
	health_changed.emit(current_health, max_health)
	_emit_status_changed()
	_emit_intent_changed()


# Applies optional EnemyData so different enemies can share this script.
func _apply_enemy_data() -> void:
	if enemy_data == null:
		return

	enemy_name = enemy_data.enemy_name
	var original_hp := enemy_data.max_health
	max_health = int(ceil(float(original_hp) * RunManager.get_enemy_hp_multiplier()))
	print("[Difficulty] enemy hp multiplier: ", RunManager.get_enemy_hp_multiplier())
	print("[Difficulty] original hp: ", original_hp)
	print("[Difficulty] scaled hp: ", max_health)
	actions = enemy_data.actions.duplicate()
	is_boss = enemy_data.is_boss
	lost_health_step_size = enemy_data.lost_health_step_size
	damage_bonus_per_step = enemy_data.damage_bonus_per_step
	low_health_threshold = enemy_data.low_health_threshold
	low_health_damage_bonus = enemy_data.low_health_damage_bonus


# Test enemy: Slime cycles Attack 6 / Defend 5.
func setup_slime() -> void:
	enemy_name = "Slime"
	max_health = 30
	actions = [
		EnemyAction.create(EnemyAction.ActionType.ATTACK, 6, "Attack 6"),
		EnemyAction.create(EnemyAction.ActionType.DEFEND, 5, "Defend 5"),
	]
	is_boss = false
	action_index = 0


# Test enemy: Goblin cycles Attack 5 / Attack 7 / Apply Weak.
func setup_goblin() -> void:
	enemy_name = "Goblin"
	max_health = 26
	actions = [
		EnemyAction.create(EnemyAction.ActionType.ATTACK, 5, "Attack 5"),
		EnemyAction.create(EnemyAction.ActionType.ATTACK, 7, "Attack 7"),
		EnemyAction.create(EnemyAction.ActionType.DEBUFF, 2, "Apply Weak"),
	]
	is_boss = false
	action_index = 0


# Test enemy: Skeleton cycles Defend 6 / Strong Attack 14.
func setup_skeleton() -> void:
	enemy_name = "Skeleton"
	max_health = 36
	actions = [
		EnemyAction.create(EnemyAction.ActionType.DEFEND, 6, "Defend 6"),
		EnemyAction.create(EnemyAction.ActionType.STRONG_ATTACK, 14, "Strong Attack 14"),
	]
	is_boss = false
	action_index = 0


# Executes the current intent, advances to the next action, then emits new intent.
func perform_action(player: Player) -> void:
	if current_health <= 0 or actions.is_empty():
		return

	var action := actions[action_index]
	var action_text := _execute_action(action, player)
	_update_boss_mechanic_after_action()
	_advance_action()
	action_performed.emit(action_text)
	_emit_intent_changed()


func get_current_intent_text() -> String:
	if actions.is_empty():
		return LanguageManager.tr_key("intent.unknown")

	var action := actions[action_index]
	match action.action_type:
		EnemyAction.ActionType.ATTACK:
			return _attack_intent_text(action)
		EnemyAction.ActionType.DEFEND:
			return LanguageManager.tr_format("intent.block", {"value": action.value})
		EnemyAction.ActionType.BUFF:
			return LanguageManager.tr_format("intent.buff", {"value": action.value})
		EnemyAction.ActionType.DEBUFF:
			return LanguageManager.tr_format("intent.apply_weak", {"value": action.value})
		EnemyAction.ActionType.STRONG_ATTACK:
			return LanguageManager.tr_format("intent.strong_attack", {"value": get_outgoing_damage(action.value)})
		EnemyAction.ActionType.DEFEND_AND_DEBUFF:
			if action.intent_text != "":
				return action.intent_text
			return LanguageManager.tr_format("intent.block_weak", {"value": action.value})
		EnemyAction.ActionType.CHARGE:
			if action.intent_text != "":
				return action.intent_text
			return LanguageManager.tr_key("intent.charge")
		EnemyAction.ActionType.APPLY_BURN:
			if action.intent_text != "":
				return action.intent_text
			return LanguageManager.tr_format("intent.apply_burn", {"value": action.value})
		EnemyAction.ActionType.HEAL_SELF:
			if action.intent_text != "":
				return action.intent_text
			return LanguageManager.tr_format("intent.heal", {"value": action.value})

	if action.intent_text != "":
		return action.intent_text
	return LanguageManager.tr_key("intent.unknown")


func get_current_action() -> EnemyAction:
	if actions.is_empty():
		return null
	return actions[action_index]


func is_current_action_attack() -> bool:
	var action := get_current_action()
	if action == null:
		return false
	return action.action_type == EnemyAction.ActionType.ATTACK or action.action_type == EnemyAction.ActionType.STRONG_ATTACK


# Returns the current status text so UI can initialize after signals are connected.
func get_status_text() -> String:
	var parts: Array[String] = []
	if block > 0:
		parts.append("%s %d" % [LanguageManager.get_status_name("block"), block])
	if strength > 0:
		parts.append("%s %d" % [LanguageManager.get_status_name("strength"), strength])
	if burn_stacks > 0:
		parts.append("%s %d" % [LanguageManager.get_status_name("burn"), burn_stacks])
	if weak_stacks > 0:
		parts.append("%s %d" % [LanguageManager.get_status_name("weak"), weak_stacks])

	if parts.is_empty():
		return "%s %s: %s" % [get_display_name(), LanguageManager.tr_key("ui_status"), LanguageManager.tr_key("ui_none")]
	return "%s %s: %s" % [get_display_name(), LanguageManager.tr_key("ui_status"), ", ".join(parts)]


func get_display_name() -> String:
	if enemy_data != null:
		return enemy_data.get_display_name()
	return enemy_name


# Returns the boss-only mechanic text for the battle HUD. Non-boss enemies keep
# this empty so regular and elite enemies do not show a special mechanic panel.
func get_boss_mechanic_text() -> String:
	if not is_boss:
		return ""

	var enemy_id := _get_enemy_id()
	if enemy_id == FOREST_GUARDIAN_ID:
		var stacks := _get_forest_fury_stacks()
		var bonus := stacks * 2
		var mechanic := LanguageManager.tr_key("boss_mechanic.ancient_wrath")
		if stacks <= 0:
			return LanguageManager.tr_format("boss_mechanic.forest_inactive", {"mechanic": mechanic})
		return LanguageManager.tr_format("boss_mechanic.stacks_attack", {"mechanic": mechanic, "stacks": stacks, "bonus": bonus})

	if enemy_id == MOLTEN_LORD_ID:
		var mechanic := LanguageManager.tr_key("boss_mechanic.molten_fury")
		if _is_molten_fury_active():
			return LanguageManager.tr_format("boss_mechanic.molten_active", {"mechanic": mechanic})
		return LanguageManager.tr_format("boss_mechanic.molten_inactive", {"mechanic": mechanic})

	if enemy_id == WORLD_DEVOURER_ID:
		var mechanic := LanguageManager.tr_key("boss_mechanic.doom_countdown")
		if boss_mechanic_stacks >= 3:
			return LanguageManager.tr_format("boss_mechanic.doom_bonus", {"mechanic": mechanic, "stacks": boss_mechanic_stacks, "bonus": boss_mechanic_stacks * 3})
		return LanguageManager.tr_format("boss_mechanic.stacks_attack", {"mechanic": mechanic, "stacks": boss_mechanic_stacks, "bonus": boss_mechanic_stacks * 3})

	if enemy_id == ASTRAL_JUDICATOR_ID:
		return LanguageManager.tr_format("boss_mechanic.astral_note", {"mechanic": LanguageManager.tr_key("boss_mechanic.astral_judgment"), "stacks": boss_mechanic_stacks, "bonus": boss_mechanic_stacks * 4})

	if enemy_id == ABYSS_AVATAR_ID:
		return LanguageManager.tr_format("boss_mechanic.abyss_note", {"mechanic": LanguageManager.tr_key("boss_mechanic.abyssal_corruption"), "stacks": boss_mechanic_stacks, "bonus": boss_mechanic_stacks * 3})

	var bonus := _get_generic_boss_damage_bonus()
	if bonus > 0:
		return LanguageManager.tr_format("boss_mechanic.stacks_attack", {"mechanic": LanguageManager.tr_key("boss_mechanic.generic"), "stacks": boss_mechanic_stacks, "bonus": bonus})
	return ""


func get_outgoing_damage(base_damage: int) -> int:
	# Weak lowers damage dealt by 1 per stack. Damage cannot go below 0.
	var scaled_base := int(ceil(float(base_damage) * RunManager.get_enemy_damage_multiplier()))
	print("[Difficulty] damage multiplier: ", RunManager.get_enemy_damage_multiplier())
	print("[Difficulty] original damage: ", base_damage)
	print("[Difficulty] scaled damage: ", scaled_base)
	return max(scaled_base + strength + _get_boss_damage_bonus() - weak_stacks, 0)


func take_damage(amount: int) -> void:
	if current_health <= 0:
		return

	# Weak increases normal incoming damage by 1 per stack.
	var incoming_damage: int = max(amount + weak_stacks, 0)
	var blocked_damage: int = min(block, incoming_damage)
	block -= blocked_damage
	incoming_damage -= blocked_damage
	current_health = max(current_health - incoming_damage, 0)
	_check_boss_mechanic_trigger()
	health_changed.emit(current_health, max_health)
	_emit_status_changed()
	_emit_intent_changed()

	if current_health == 0:
		died.emit()


func take_direct_damage(amount: int) -> void:
	if current_health <= 0:
		return

	current_health = max(current_health - max(amount, 0), 0)
	_check_boss_mechanic_trigger()
	health_changed.emit(current_health, max_health)
	_emit_status_changed()
	_emit_intent_changed()

	if current_health == 0:
		died.emit()


func add_block(amount: int) -> void:
	block += amount
	_emit_status_changed()


func add_strength(amount: int) -> void:
	strength += amount
	_emit_status_changed()
	_emit_intent_changed()


func clear_block() -> void:
	block = 0
	_emit_status_changed()


func add_burn(amount: int) -> void:
	burn_stacks += amount
	_emit_status_changed()


func set_burn(amount: int) -> void:
	burn_stacks = max(amount, 0)
	_emit_status_changed()


func add_weak(amount: int) -> void:
	weak_stacks += amount
	_emit_status_changed()
	_emit_intent_changed()


func resolve_turn_start_status() -> void:
	if burn_stacks > 0:
		take_direct_damage(burn_stacks)
	_emit_status_changed()


func _execute_action(action: EnemyAction, player: Player) -> String:
	var display_name := get_display_name()
	match action.action_type:
		EnemyAction.ActionType.ATTACK:
			var damage := _perform_attack(action, player)
			if action.hit_count > 1:
				return LanguageManager.tr_format("enemy_action.attack_times", {"enemy": display_name, "value": int(damage / action.hit_count), "times": action.hit_count})
			return LanguageManager.tr_format("enemy_action.attack", {"enemy": display_name, "value": damage})
		EnemyAction.ActionType.DEFEND:
			add_block(action.value)
			return LanguageManager.tr_format("enemy_action.block", {"enemy": display_name, "value": action.value})
		EnemyAction.ActionType.BUFF:
			add_strength(action.value)
			return LanguageManager.tr_format("enemy_action.strength", {"enemy": display_name, "value": action.value})
		EnemyAction.ActionType.DEBUFF:
			player.add_weak(action.value)
			return LanguageManager.tr_format("enemy_action.apply_weak", {"enemy": display_name, "value": action.value})
		EnemyAction.ActionType.STRONG_ATTACK:
			var damage := _perform_attack(action, player)
			if action.hit_count > 1:
				return LanguageManager.tr_format("enemy_action.strong_attack_times", {"enemy": display_name, "value": int(damage / action.hit_count), "times": action.hit_count})
			return LanguageManager.tr_format("enemy_action.strong_attack", {"enemy": display_name, "value": damage})
		EnemyAction.ActionType.DEFEND_AND_DEBUFF:
			add_block(action.value)
			player.add_weak(action.secondary_value)
			return LanguageManager.tr_format("enemy_action.block_weak", {"enemy": display_name, "block": action.value, "weak": action.secondary_value})
		EnemyAction.ActionType.CHARGE:
			return LanguageManager.tr_format("enemy_action.charge", {"enemy": display_name})
		EnemyAction.ActionType.APPLY_BURN:
			player.add_burn(action.value)
			return LanguageManager.tr_format("enemy_action.apply_burn", {"enemy": display_name, "value": action.value})
		EnemyAction.ActionType.HEAL_SELF:
			current_health = min(current_health + action.value, max_health)
			health_changed.emit(current_health, max_health)
			_emit_status_changed()
			return LanguageManager.tr_format("enemy_action.heal", {"enemy": display_name, "value": action.value})

	return LanguageManager.tr_format("enemy_action.none", {"enemy": display_name})


func _perform_attack(action: EnemyAction, player: Player) -> int:
	var damage := get_outgoing_damage(action.value)
	var hits: int = max(action.hit_count, 1)
	for index in range(hits):
		player.take_damage(damage)
	return damage * hits


func _attack_intent_text(action: EnemyAction) -> String:
	var damage := get_outgoing_damage(action.value)
	if action.hit_count > 1:
		return LanguageManager.tr_format("intent.attack_times", {"value": damage, "times": action.hit_count})
	return LanguageManager.tr_format("intent.attack", {"value": damage})


func _get_boss_damage_bonus() -> int:
	if not is_boss:
		return 0

	var enemy_id := _get_enemy_id()
	if enemy_id == FOREST_GUARDIAN_ID:
		return _get_forest_fury_stacks() * 2
	if enemy_id == MOLTEN_LORD_ID:
		return 5 if _is_molten_fury_active() else 0
	if enemy_id == WORLD_DEVOURER_ID:
		return boss_mechanic_stacks * 3
	if enemy_id == ASTRAL_JUDICATOR_ID:
		return boss_mechanic_stacks * 4
	if enemy_id == ABYSS_AVATAR_ID:
		return boss_mechanic_stacks * 3

	return _get_generic_boss_damage_bonus()


func _get_generic_boss_damage_bonus() -> int:
	var step_size: int = max(lost_health_step_size, 1)
	var lost_steps := int(floor(float(max_health - current_health) / float(step_size)))
	var bonus := lost_steps * damage_bonus_per_step
	if _is_below_low_health_threshold():
		bonus += low_health_damage_bonus
	return bonus


func _check_boss_mechanic_trigger() -> void:
	if not is_boss:
		return

	var enemy_id := _get_enemy_id()
	if enemy_id == FOREST_GUARDIAN_ID:
		var new_stacks := _get_forest_fury_stacks()
		if new_stacks > boss_mechanic_stacks:
			var gained := new_stacks - boss_mechanic_stacks
			boss_mechanic_stacks = new_stacks
			var mechanic := LanguageManager.tr_key("boss_mechanic.ancient_wrath")
			boss_mechanic_changed.emit(
				get_boss_mechanic_text(),
				LanguageManager.tr_format("boss_mechanic_trigger", {"mechanic": mechanic}),
				LanguageManager.tr_format("boss_mechanic_gain", {"mechanic": mechanic, "amount": gained})
			)
		return

	if enemy_id == MOLTEN_LORD_ID and not boss_mechanic_active and _is_molten_fury_active():
		boss_mechanic_active = true
		var mechanic := LanguageManager.tr_key("boss_mechanic.molten_fury")
		boss_mechanic_changed.emit(
			get_boss_mechanic_text(),
			LanguageManager.tr_format("boss_mechanic_trigger", {"mechanic": mechanic}),
			LanguageManager.tr_format("boss_mechanic_active", {"mechanic": mechanic})
		)


func _update_boss_mechanic_after_action() -> void:
	if not is_boss:
		return
	var enemy_id := _get_enemy_id()
	if enemy_id != WORLD_DEVOURER_ID and enemy_id != ASTRAL_JUDICATOR_ID and enemy_id != ABYSS_AVATAR_ID:
		return

	boss_turns_taken += 1
	var trigger_interval := 2 if enemy_id == ABYSS_AVATAR_ID else 3
	if boss_turns_taken % trigger_interval != 0:
		return

	boss_mechanic_stacks += 1
	if enemy_id == ASTRAL_JUDICATOR_ID:
		var mechanic := LanguageManager.tr_key("boss_mechanic.astral_judgment")
		boss_mechanic_changed.emit(get_boss_mechanic_text(), LanguageManager.tr_format("boss_mechanic_progress", {"mechanic": mechanic}), LanguageManager.tr_format("boss_mechanic_gain", {"mechanic": mechanic, "amount": 1}))
		_emit_status_changed()
		return
	if enemy_id == ABYSS_AVATAR_ID:
		var mechanic := LanguageManager.tr_key("boss_mechanic.abyssal_corruption")
		boss_mechanic_changed.emit(get_boss_mechanic_text(), LanguageManager.tr_format("boss_mechanic_progress", {"mechanic": mechanic}), LanguageManager.tr_format("boss_mechanic_gain", {"mechanic": mechanic, "amount": 1}))
		_emit_status_changed()
		return
	var mechanic := LanguageManager.tr_key("boss_mechanic.doom_countdown")
	boss_mechanic_changed.emit(get_boss_mechanic_text(), LanguageManager.tr_format("boss_mechanic_progress", {"mechanic": mechanic}), LanguageManager.tr_format("boss_mechanic_gain", {"mechanic": mechanic, "amount": 1}))
	_emit_status_changed()


func _get_forest_fury_stacks() -> int:
	if max_health <= 0:
		return 0

	var step_size: int = max(lost_health_step_size, 1)
	return max(int(floor(float(max_health - current_health) / float(step_size))), 0)


func _is_molten_fury_active() -> bool:
	if not is_boss or max_health <= 0:
		return false
	return float(current_health) < float(max_health) * 0.5


func _is_below_low_health_threshold() -> bool:
	if not is_boss or max_health <= 0:
		return false
	return float(current_health) < float(max_health) * low_health_threshold


func _get_enemy_id() -> String:
	if enemy_data == null:
		return ""
	return enemy_data.enemy_id


func _advance_action() -> void:
	action_index = (action_index + 1) % actions.size()


func _emit_intent_changed() -> void:
	intent_changed.emit(LanguageManager.tr_format("battle_intent", {"intent": get_current_intent_text()}))


func _emit_status_changed() -> void:
	status_changed.emit(get_status_text())
