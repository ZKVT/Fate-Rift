extends Resource
class_name EnemyAction

enum ActionType {
	ATTACK,
	DEFEND,
	BUFF,
	DEBUFF,
	STRONG_ATTACK,
	DEFEND_AND_DEBUFF,
	CHARGE,
	APPLY_BURN,
	HEAL_SELF,
}

@export var action_type: ActionType = ActionType.ATTACK
@export var value := 0
@export var secondary_value := 0
@export var hit_count := 1
@export var intent_text := ""


## Creates an action in code for quick test enemy setup.
static func create(type: ActionType, amount: int, text: String = "", hits := 1, secondary_amount := 0) -> EnemyAction:
	var action := EnemyAction.new()
	action.action_type = type
	action.value = amount
	action.hit_count = max(hits, 1)
	action.secondary_value = secondary_amount
	action.intent_text = text
	return action
