extends Node
class_name TurnManager

signal turn_started(turn_number: int, cards_to_draw: int)
signal turn_ended(turn_number: int)

@export var first_turn_draw_count := 5
@export var normal_turn_draw_count := 1

var turn_number := 0


func start_next_turn() -> void:
	turn_number += 1
	var draw_count := first_turn_draw_count if turn_number == 1 else normal_turn_draw_count
	turn_started.emit(turn_number, draw_count)


func end_turn() -> void:
	turn_ended.emit(turn_number)
