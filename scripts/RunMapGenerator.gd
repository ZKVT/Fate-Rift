extends RefCounted
class_name RunMapGenerator

const NORMAL_BATTLE := "NormalBattle"
const ELITE_BATTLE := "EliteBattle"
const EVENT := "Event"
const SHOP := "Shop"
const REST := "Rest"
const RELIC_REWARD := "RelicReward"
const SPECIAL_CARD_REWARD := "SpecialCardReward"
const BOSS_BATTLE := "BossBattle"


# Creates a stable 7-floor semi-random map. Nodes store JSON-safe data only.
static func generate_chapter_map() -> Array[Dictionary]:
	var rng := RandomNumberGenerator.new()
	rng.randomize()

	var floors: Array[Array] = [
		[NORMAL_BATTLE],
		[_pick(rng, [NORMAL_BATTLE, EVENT]), _pick(rng, [NORMAL_BATTLE, EVENT])],
		[
			_pick(rng, [NORMAL_BATTLE, SHOP, REST, EVENT]),
			_pick(rng, [NORMAL_BATTLE, SHOP, REST, EVENT]),
			_pick(rng, [NORMAL_BATTLE, SHOP, REST, EVENT]),
		],
		[ELITE_BATTLE, _pick(rng, [ELITE_BATTLE, NORMAL_BATTLE])],
		[
			_pick(rng, [SHOP, RELIC_REWARD, NORMAL_BATTLE, EVENT]),
			_pick(rng, [SHOP, RELIC_REWARD, NORMAL_BATTLE, EVENT]),
			_pick(rng, [SHOP, RELIC_REWARD, NORMAL_BATTLE, EVENT]),
		],
		_generate_rest_floor(rng),
		[BOSS_BATTLE],
	]

	var map: Array[Dictionary] = []
	for floor_index in range(floors.size()):
		var floor_number := floor_index + 1
		var floor_types: Array = floors[floor_index]
		for index in range(floor_types.size()):
			var column := _column_for_index(index, floor_types.size())
			map.append(_make_node(floor_number, index, column, str(floor_types[index])))

	_connect_floors(map, rng)
	return map


static func _generate_rest_floor(rng: RandomNumberGenerator) -> Array:
	if rng.randi_range(0, 1) == 0:
		return [REST]
	return [REST, REST]


static func _connect_floors(map: Array[Dictionary], rng: RandomNumberGenerator) -> void:
	for floor_number in range(1, 7):
		var current_floor := _nodes_on_floor(map, floor_number)
		var next_floor := _nodes_on_floor(map, floor_number + 1)
		if current_floor.is_empty() or next_floor.is_empty():
			continue

		for index in range(current_floor.size()):
			var from_node: Dictionary = current_floor[index]
			var connected := _connections_for_node(index, current_floor.size(), next_floor, rng)
			from_node["connected_to"] = connected
			from_node["next_ids"] = connected
			_update_node(map, str(from_node["node_id"]), from_node)

		# Ensure every node on the next floor has at least one incoming edge.
		for next_node in next_floor:
			var next_id := str(next_node["node_id"])
			if _has_incoming_connection(map, floor_number, next_id):
				continue
			var source := _nearest_source_node(current_floor, next_node)
			var source_connections: Array = source.get("connected_to", [])
			if not source_connections.has(next_id):
				source_connections.append(next_id)
			source["connected_to"] = source_connections
			source["next_ids"] = source_connections
			_update_node(map, str(source["node_id"]), source)


static func _connections_for_node(index: int, current_count: int, next_floor: Array[Dictionary], rng: RandomNumberGenerator) -> Array[String]:
	var result: Array[String] = []
	if next_floor.size() == 1:
		return [str(next_floor[0]["node_id"])]

	var target_index := int(round(float(index) * float(next_floor.size() - 1) / float(max(current_count - 1, 1))))
	_add_connection(result, next_floor, target_index)

	if rng.randf() < 0.55:
		var side := -1 if rng.randf() < 0.5 else 1
		_add_connection(result, next_floor, target_index + side)

	return result


static func _add_connection(result: Array[String], next_floor: Array[Dictionary], index: int) -> void:
	var clamped_index: int = clamp(index, 0, next_floor.size() - 1)
	var node_id := str(next_floor[clamped_index]["node_id"])
	if not result.has(node_id):
		result.append(node_id)


static func _has_incoming_connection(map: Array[Dictionary], source_floor: int, target_id: String) -> bool:
	for node in _nodes_on_floor(map, source_floor):
		var connections: Array = node.get("connected_to", [])
		if connections.has(target_id):
			return true
	return false


static func _nearest_source_node(current_floor: Array[Dictionary], target_node: Dictionary) -> Dictionary:
	var best_node: Dictionary = current_floor[0]
	var target_column := int(target_node.get("column", 1))
	var best_distance := 999
	for node in current_floor:
		var distance: int = abs(int(node.get("column", 1)) - target_column)
		if distance < best_distance:
			best_distance = distance
			best_node = node
	return best_node


static func _nodes_on_floor(map: Array[Dictionary], floor_number: int) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for node in map:
		if int(node["floor"]) == floor_number:
			result.append(node)
	return result


static func _update_node(map: Array[Dictionary], node_id: String, updated_node: Dictionary) -> void:
	for index in range(map.size()):
		if str(map[index]["node_id"]) == node_id:
			map[index] = updated_node
			return


static func _make_node(floor_number: int, index: int, column: int, node_type: String) -> Dictionary:
	var node_id := "%d_%d" % [floor_number, index]
	var position := {"x": column, "y": floor_number}
	var is_available := floor_number == 1
	return {
		"node_id": node_id,
		"node_type": node_type,
		"floor": floor_number,
		"position": position,
		"connected_to": [],
		"completed": false,
		"available": is_available,
		"id": node_id,
		"type": node_type,
		"layer": floor_number,
		"column": column,
		"next_ids": [],
	}


static func _column_for_index(index: int, count: int) -> int:
	match count:
		1:
			return 1
		2:
			return 0 if index == 0 else 2
		_:
			return index


static func _pick(rng: RandomNumberGenerator, options: Array[String]) -> String:
	return options[rng.randi_range(0, options.size() - 1)]
