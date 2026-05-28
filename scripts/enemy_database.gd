extends Node
class_name EnemyDatabase

const CHAPTER_1_NORMAL_ENEMY_IDS: Array[String] = [
	"forest_wolf",
	"poison_vine",
	"mushroom_mage",
]

const CHAPTER_1_ELITE_ENEMY_IDS: Array[String] = [
	"ancient_treant",
	"berserker_orc",
]

const CHAPTER_1_BOSS_ENEMY_ID := "forest_guardian"

const CHAPTER_2_NORMAL_ENEMY_IDS: Array[String] = [
	"fire_elemental",
	"lava_slime",
	"flame_archer",
	"lava_guard",
	"ash_mage",
]

const CHAPTER_2_ELITE_ENEMY_IDS: Array[String] = [
	"molten_knight",
	"blazing_golem",
]

const CHAPTER_2_BOSS_ENEMY_ID := "molten_lord"

const CHAPTER_3_NORMAL_ENEMY_IDS: Array[String] = [
	"astral_wraith",
	"void_walker",
	"mirror_golem",
	"shadow_priest",
	"time_guardian",
]

const CHAPTER_3_ELITE_ENEMY_IDS: Array[String] = [
	"fate_judge",
	"astral_drake",
]

const CHAPTER_3_BOSS_ENEMY_ID := "world_devourer"
const CHAPTER_4_STAR_BOSS_ENEMY_ID := "astral_judicator"
const CHAPTER_4_ABYSS_BOSS_ENEMY_ID := "abyss_avatar"

const CHAPTER_4_NORMAL_ENEMY_IDS: Array[String] = [
	"fate_echo",
	"rift_spirit",
	"eclipse_acolyte",
]

const CHAPTER_4_ELITE_ENEMY_IDS: Array[String] = [
	"fate_stitcher",
	"rift_enforcer",
]

const ENEMY_PATHS := {
	"slime": "res://data/enemies/chapter_1/slime.tres",
	"goblin": "res://data/enemies/chapter_1/goblin.tres",
	"forest_wolf": "res://data/enemies/chapter_1/forest_wolf.tres",
	"poison_vine": "res://data/enemies/chapter_1/poison_vine.tres",
	"mushroom_mage": "res://data/enemies/chapter_1/mushroom_mage.tres",
	"ancient_treant": "res://data/enemies/chapter_1/ancient_treant.tres",
	"berserker_orc": "res://data/enemies/chapter_1/berserker_orc.tres",
	"forest_guardian": "res://data/enemies/chapter_1/forest_guardian.tres",
	"fire_elemental": "res://data/enemies/chapter_2/fire_elemental.tres",
	"lava_slime": "res://data/enemies/chapter_2/lava_slime.tres",
	"flame_archer": "res://data/enemies/chapter_2/flame_archer.tres",
	"lava_guard": "res://data/enemies/chapter_2/lava_guard.tres",
	"ash_mage": "res://data/enemies/chapter_2/ash_mage.tres",
	"molten_knight": "res://data/enemies/chapter_2/molten_knight.tres",
	"blazing_golem": "res://data/enemies/chapter_2/blazing_golem.tres",
	"molten_lord": "res://data/enemies/chapter_2/molten_lord.tres",
	"astral_wraith": "res://data/enemies/chapter_3/astral_wraith.tres",
	"void_walker": "res://data/enemies/chapter_3/void_walker.tres",
	"mirror_golem": "res://data/enemies/chapter_3/mirror_golem.tres",
	"shadow_priest": "res://data/enemies/chapter_3/shadow_priest.tres",
	"time_guardian": "res://data/enemies/chapter_3/time_guardian.tres",
	"fate_judge": "res://data/enemies/chapter_3/fate_judge.tres",
	"astral_drake": "res://data/enemies/chapter_3/astral_drake.tres",
	"world_devourer": "res://data/enemies/chapter_3/world_devourer.tres",
	"fate_echo": "res://data/enemies/chapter_4/fate_echo.tres",
	"rift_spirit": "res://data/enemies/chapter_4/rift_spirit.tres",
	"eclipse_acolyte": "res://data/enemies/chapter_4/eclipse_acolyte.tres",
	"fate_stitcher": "res://data/enemies/chapter_4/fate_stitcher.tres",
	"rift_enforcer": "res://data/enemies/chapter_4/rift_enforcer.tres",
	"astral_judicator": "res://data/enemies/chapter_4/astral_judicator.tres",
	"abyss_avatar": "res://data/enemies/chapter_4/abyss_avatar.tres",
}


static func get_enemy(enemy_id: String) -> EnemyData:
	var path: String = ENEMY_PATHS.get(enemy_id, "")
	if path == "":
		push_warning("Unknown enemy_id: " + enemy_id)
		return null

	return load(path) as EnemyData


static func get_random_enemy_id_for_node_type(chapter: int, node_type: String, previous_enemy_id := "", ending_route := "none") -> String:
	var pool := get_enemy_pool(chapter, node_type, ending_route)
	if pool.is_empty():
		return ""

	var candidates := pool.duplicate()
	if candidates.size() > 1 and previous_enemy_id != "":
		candidates.erase(previous_enemy_id)
	candidates.shuffle()
	return candidates[0]


static func get_enemy_pool(chapter: int, node_type: String, ending_route := "none") -> Array[String]:
	var normal_pool := CHAPTER_1_NORMAL_ENEMY_IDS
	var elite_pool := CHAPTER_1_ELITE_ENEMY_IDS
	var boss_id := CHAPTER_1_BOSS_ENEMY_ID

	if chapter == 2:
		normal_pool = CHAPTER_2_NORMAL_ENEMY_IDS
		elite_pool = CHAPTER_2_ELITE_ENEMY_IDS
		boss_id = CHAPTER_2_BOSS_ENEMY_ID
	elif chapter == 3:
		normal_pool = CHAPTER_3_NORMAL_ENEMY_IDS
		elite_pool = CHAPTER_3_ELITE_ENEMY_IDS
		boss_id = CHAPTER_3_BOSS_ENEMY_ID
	elif chapter == 4:
		normal_pool = CHAPTER_4_NORMAL_ENEMY_IDS
		elite_pool = CHAPTER_4_ELITE_ENEMY_IDS
		if ending_route == "abyss":
			boss_id = CHAPTER_4_ABYSS_BOSS_ENEMY_ID
		else:
			if ending_route != "star":
				push_warning("Unknown ending_route for chapter 4: %s. Falling back to astral_judicator." % ending_route)
			boss_id = CHAPTER_4_STAR_BOSS_ENEMY_ID
	elif chapter != 1:
		push_warning("Unknown chapter %d enemy pools. Falling back to chapter 1." % chapter)

	match node_type:
		"EliteBattle":
			return elite_pool.duplicate()
		"BossBattle":
			return [boss_id]
		_:
			return normal_pool.duplicate()
