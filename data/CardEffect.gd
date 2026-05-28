extends Resource
class_name CardEffect

enum EffectType {
	DAMAGE,
	BLOCK,
	DRAW,
	GAIN_ENERGY,
	APPLY_BURN,
	APPLY_WEAK,
	HEALTH,
	FOOL,
	MAGICIAN,
	HIGH_PRIESTESS,
	EMPRESS,
	EMPEROR,
	HIEROPHANT,
	LOVERS,
	CHARIOT,
	STRENGTH,
	HERMIT,
	WHEEL_OF_FORTUNE,
	JUSTICE,
	HANGED_MAN,
	TEMPERANCE,
	DEVIL,
	TOWER,
	STAR,
	SUN,
	JUDGEMENT,
	WORLD,
	DISCARD_RANDOM,
	CLEANSE_STATUS,
	CONDITIONAL_WEAK,
	CONDITIONAL_BURN,
	CONDITIONAL_DAMAGE_IF_BURN,
	CONDITIONAL_WEAK_IF_BURN,
	CONDITIONAL_DAMAGE_IF_ENEMY_LOW_HP,
	CONDITIONAL_BLOCK_IF_PLAYER_LOW_HP,
	CONDITIONAL_BLOCK_IF_NO_ATTACK_PLAYED,
}

@export var effect_type: EffectType = EffectType.DAMAGE

# Amount, stack count, turn count, or card count depending on effect_type.
@export var value: int = 0


static func create(type: EffectType, amount: int) -> CardEffect:
	var effect := CardEffect.new()
	effect.effect_type = type
	effect.value = amount
	return effect
