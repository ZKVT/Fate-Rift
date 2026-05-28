extends Node

const RELIC_PATHS: Array[String] = [
	"res://data/relics/old_ring.tres",
	"res://data/relics/energy_core.tres",
	"res://data/relics/spiked_charm.tres",
	"res://data/relics/lucky_dice.tres",
	"res://data/relics/warrior_badge.tres",
	"res://data/relics/guardian_stone.tres",
	"res://data/relics/burning_ember.tres",
	"res://data/relics/swift_boots.tres",
	"res://data/relics/fate_ember.tres",
]

const FATE_EMBER_ID := "fate_ember"

var relics_by_id: Dictionary = {}
var fallback_relic_icon: Texture2D


func _ready() -> void:
	load_all_relics()


# Loads all known relic resources into a relic_id lookup table.
func load_all_relics() -> void:
	relics_by_id.clear()
	for path in RELIC_PATHS:
		var relic := load(path) as RelicData
		if relic != null:
			relics_by_id[relic.relic_id] = relic


# Returns a relic by id, or null if missing.
func get_relic(relic_id: String) -> RelicData:
	return relics_by_id.get(relic_id)


# Returns currently owned run relics.
func get_current_relics() -> Array[RelicData]:
	var relics: Array[RelicData] = []
	for relic_id in RunManager.relic_ids:
		var relic := get_relic(relic_id)
		if relic != null:
			relics.append(relic)
	return relics


# Adds a relic to the current run if it is not already owned.
func add_relic(relic_id: String) -> void:
	if relic_id == "" or RunManager.relic_ids.has(relic_id):
		return
	if get_relic(relic_id) == null:
		return
	RunManager.relic_ids.append(relic_id)


func has_relic(relic_id: String) -> bool:
	return RunManager.relic_ids.has(relic_id)


func remove_relic(relic_id: String) -> bool:
	if not RunManager.relic_ids.has(relic_id):
		return false
	RunManager.relic_ids.erase(relic_id)
	return true


func consume_fate_ember() -> bool:
	return remove_relic(FATE_EMBER_ID)


func get_relic_icon(relic: RelicData) -> Texture2D:
	if relic == null:
		return _get_fallback_relic_icon()
	if relic.icon != null:
		return relic.icon
	if relic.icon_path != "" and ResourceLoader.exists(relic.icon_path):
		var loaded_icon := load(relic.icon_path) as Texture2D
		if loaded_icon != null:
			return loaded_icon
	push_warning("[Relic Icon] missing icon: " + relic.relic_id)
	return _get_fallback_relic_icon()


# Returns a random unowned relic for reward screens.
func get_random_unowned_relic() -> RelicData:
	var candidates: Array[RelicData] = []
	for relic in relics_by_id.values():
		if not RunManager.relic_ids.has(relic.relic_id):
			var weight := _relic_reward_weight(relic)
			for index in range(weight):
				candidates.append(relic)
	if candidates.is_empty():
		return null
	return candidates.pick_random()


# Returns all relics that the current run does not already own.
func get_unowned_relics() -> Array[RelicData]:
	var candidates: Array[RelicData] = []
	for relic in relics_by_id.values():
		if not RunManager.relic_ids.has(relic.relic_id):
			candidates.append(relic)
	return candidates


# Rolls whether this battle should show a relic reward.
func roll_relic_drop(node_type: String) -> bool:
	if get_unowned_relics().is_empty():
		print("[Reward] relic roll: no available relics -> failed")
		return false

	var chance := 0.0
	match node_type:
		RunManager.NODE_NORMAL_BATTLE:
			chance = 0.05
		RunManager.NODE_ELITE_BATTLE:
			chance = 0.25
		RunManager.NODE_BOSS_BATTLE:
			chance = 0.50
		_:
			chance = 0.0

	var roll := randf()
	var success := roll < chance
	print("[Reward] relic roll: %.2f / chance %.2f -> %s" % [roll, chance, "success" if success else "failed"])
	print("[Reward] relic drop %s" % ("success" if success else "failed"))
	return success


# Kept for old callers. New battle flow should use roll_relic_drop(node_type).
func should_offer_relic_reward() -> bool:
	return roll_relic_drop(RunManager.get_current_map_node_type())


# Applies battle-start relic effects.
func trigger_battle_start(player: Player, enemy: Enemy, hand_manager: HandManager, deck_manager: DeckManager) -> String:
	var log_parts: Array[String] = []
	for relic in get_current_relics():
		match relic.effect:
			RelicData.RelicEffect.EXTRA_BATTLE_START_DRAW:
				var destroyed := hand_manager.add_cards(deck_manager.draw_cards(relic.value))
				log_parts.append("%s drew %d%s" % [relic.get_display_name(), relic.value, _overflow_text(destroyed)])
			RelicData.RelicEffect.BATTLE_START_BLOCK:
				player.add_block(relic.value)
				log_parts.append("%s gave %d Block" % [relic.get_display_name(), relic.value])
			RelicData.RelicEffect.BATTLE_START_BURN:
				enemy.add_burn(relic.value)
				log_parts.append("%s applied %d Burn" % [relic.get_display_name(), relic.value])
	return ", ".join(log_parts)


# Applies player turn start relic effects.
func trigger_player_turn_start(player: Player) -> String:
	var log_parts: Array[String] = []
	for relic in get_current_relics():
		if relic.effect == RelicData.RelicEffect.EXTRA_TURN_ENERGY:
			player.gain_energy(relic.value)
			log_parts.append("%s gave %d Energy" % [relic.get_display_name(), relic.value])
	return ", ".join(log_parts)


# Returns bonus first-turn draw from relics.
func get_first_turn_bonus_draw() -> int:
	var bonus := 0
	for relic in get_current_relics():
		if relic.effect == RelicData.RelicEffect.FIRST_TURN_DRAW:
			bonus += relic.value
	return bonus


# Modifies card damage when card-play relics apply.
func modify_card_damage(card: CardData, base_damage: int) -> int:
	var damage := base_damage
	for relic in get_current_relics():
		if relic.effect == RelicData.RelicEffect.ATTACK_DAMAGE_BONUS and card != null and card.card_type == CardData.CardType.ATTACK:
			damage += relic.value
	return damage


# Reflects damage when the player is damaged.
func trigger_player_damaged(enemy: Enemy) -> String:
	var log_parts: Array[String] = []
	for relic in get_current_relics():
		if relic.effect == RelicData.RelicEffect.THORNS:
			enemy.take_direct_damage(relic.value)
			log_parts.append("%s reflected %d damage" % [relic.get_display_name(), relic.value])
	return ", ".join(log_parts)


# Returns bonus card reward choices.
func get_reward_card_bonus() -> int:
	var bonus := 0
	for relic in get_current_relics():
		if relic.effect == RelicData.RelicEffect.EXTRA_REWARD_CARDS:
			bonus += relic.value
	return bonus


func _overflow_text(destroyed_count: int) -> String:
	if destroyed_count <= 0:
		return ""
	return ", destroyed %d overflow" % destroyed_count


func _get_fallback_relic_icon() -> Texture2D:
	if fallback_relic_icon != null:
		return fallback_relic_icon

	var image := Image.create(96, 96, false, Image.FORMAT_RGBA8)
	image.fill(Color(0.18, 0.15, 0.24, 1.0))
	fallback_relic_icon = ImageTexture.create_from_image(image)
	return fallback_relic_icon


func _relic_reward_weight(relic: RelicData) -> int:
	match relic.rarity:
		"Legendary":
			return 1
		"Rare":
			return 2
		_:
			return 4
