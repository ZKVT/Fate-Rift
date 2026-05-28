extends Node

const SFX_DIR := "res://assets/audio/sfx"
const SFX_EXTENSION := ".wav"
const SFX_NAMES: Array[String] = [
	"ui_click",
	"card_draw",
	"card_play",
	"card_hover",
	"attack_hit",
	"block_gain",
	"heal",
	"energy_gain",
	"debuff_apply",
	"victory",
	"defeat",
	"reward",
	"shuffle",
	"turn_start",
]

var master_sfx_volume := 1.0:
	set(value):
		master_sfx_volume = clamp(value, 0.0, 1.0)

var sfx_streams: Dictionary = {}


func _ready() -> void:
	print("[AudioManager] ready")
	reload_sfx()


func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_F2:
		print("[AudioManager] F2 test ui_click")
		play_sfx("ui_click")
		get_viewport().set_input_as_handled()


# Plays an SFX by filename stem, for example play_sfx("ui_click").
func play_sfx(sfx_name: String) -> void:
	print("[AudioManager] play_sfx:", sfx_name)
	if sfx_name == "":
		push_warning("[AudioManager] empty sfx name")
		return

	var stream: AudioStream = sfx_streams.get(sfx_name)
	if stream == null:
		var fallback_path := "%s/%s%s" % [SFX_DIR, sfx_name, SFX_EXTENSION]
		stream = load(fallback_path) as AudioStream
		if stream != null:
			sfx_streams[sfx_name] = stream
			print("[AudioManager] loaded on demand:", fallback_path)

	if stream == null:
		push_warning("[AudioManager] missing sfx: %s/%s%s" % [SFX_DIR, sfx_name, SFX_EXTENSION])
		return

	var player := AudioStreamPlayer.new()
	player.stream = stream
	player.bus = "Master"
	player.volume_db = 0.0 if master_sfx_volume >= 0.99 else linear_to_db(max(master_sfx_volume, 0.0001))
	player.finished.connect(player.queue_free)
	add_child(player)
	player.play()


# Plays a few known effects in sequence for quick troubleshooting.
func test_all_sfx() -> void:
	var names := ["ui_click", "card_draw", "card_play", "attack_hit", "victory"]
	for index in range(names.size()):
		await get_tree().create_timer(0.3 * float(index)).timeout
		play_sfx(names[index])


# Sets all future SFX playback volume. Value is linear, 0.0 to 1.0.
func set_master_sfx_volume(value: float) -> void:
	master_sfx_volume = value
	print("[AudioManager] master_sfx_volume:", master_sfx_volume)


# Reloads every known wav file from assets/audio/sfx.
func reload_sfx() -> void:
	sfx_streams.clear()
	for sfx_name in SFX_NAMES:
		_load_sfx(sfx_name)
	print("[AudioManager] loaded count:", sfx_streams.size())


func _load_sfx(sfx_name: String) -> void:
	var path := "%s/%s%s" % [SFX_DIR, sfx_name, SFX_EXTENSION]
	var stream := load(path) as AudioStream
	if stream == null:
		push_warning("[AudioManager] missing sfx: " + path)
		return

	sfx_streams[sfx_name] = stream
	print("[AudioManager] loaded:", path)
