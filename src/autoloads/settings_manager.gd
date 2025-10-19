extends Node

enum WindowMode { WINDOWED = 0, BORDERLESS = 1, FULLSCREEN = 2 }

var window_mode: int = WindowMode.WINDOWED
var vsync: bool = true
var postfx: bool = true
var framecap: int = 0

var game_paused: bool = false

var volumes: Dictionary = {
	"Master": 1.0,
	"SFX": 1.0,
	"Music": 1.0,
}

const CFG: String = "user://settings.cfg"
const SEC_VIDEO: String = "Video"
const SEC_AUDIO: String = "Audio"

const SETTINGS = preload("res://components/interface/settings/settings.tscn")

func _ready() -> void:
	self.process_mode = Node.PROCESS_MODE_ALWAYS
	add_to_group("SManager")
	_load()

	set_window_mode(window_mode)

	for bus_name in volumes.keys():
		_apply_bus_volume(bus_name, volumes[bus_name])

## Creates and displays the settings, applies it to a given parent node
func display_settings_overlay(parent: Node) -> void:
	if parent:
		var s = SETTINGS.instantiate()
		parent.add_child(s)

func set_window_mode(id: int) -> void:
	window_mode = id
	if id == WindowMode.FULLSCREEN:
		DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_BORDERLESS, false)
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	elif id == WindowMode.BORDERLESS:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
		DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_BORDERLESS, true)
		DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_MAX, true)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
		DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_BORDERLESS, false)
	_save()

func set_bus_volume(bus: String, linear_value: float) -> void:
	volumes[bus] = clamp(linear_value, 0.0, 1.0)
	_apply_bus_volume(bus, volumes[bus])
	_save()

func get_bus_volume(bus: String) -> float:
	return volumes.get(bus, 1.0)

func get_all_volumes() -> Dictionary:
	return volumes.duplicate()

func _apply_bus_volume(bus: String, linear: float) -> void:
	var index = AudioServer.get_bus_index(bus)
	if index == -1:
		push_error("Audio bus '%s' not found." % bus)
		return

	if linear <= 0.0001:
		AudioServer.set_bus_volume_db(index, -80.0)
		AudioServer.set_bus_mute(index, true)
	else:
		AudioServer.set_bus_volume_db(index, linear_to_db(linear))
		AudioServer.set_bus_mute(index, false)

func get_settings() -> Dictionary:
	return {
		"window_mode": window_mode,
		"vsync": vsync,
		"postfx": postfx,
		"framecap": framecap,
		"volumes": get_all_volumes()
	}

func _save() -> void:
	var c = ConfigFile.new()
	c.set_value(SEC_VIDEO, "window_mode", window_mode)
	c.set_value(SEC_VIDEO, "vsync", vsync)
	c.set_value(SEC_VIDEO, "postfx", postfx)
	c.set_value(SEC_VIDEO, "framecap", framecap)
	for bus in volumes.keys():
		c.set_value(SEC_AUDIO, bus, volumes[bus])
	c.save(CFG)

func _load() -> void:
	var c = ConfigFile.new()
	if c.load(CFG) != OK:
		return

	window_mode = int(c.get_value(SEC_VIDEO, "window_mode", window_mode))
	vsync = bool(c.get_value(SEC_VIDEO, "vsync", vsync))
	postfx = bool(c.get_value(SEC_VIDEO, "postfx", postfx))
	framecap = int(c.get_value(SEC_VIDEO, "framecap", framecap))

	for bus in ["Master", "SFX", "Music"]:
		if c.has_section_key(SEC_AUDIO, bus):
			volumes[bus] = clamp(float(c.get_value(SEC_AUDIO, bus, 1.0)), 0.0, 1.0)

func close_game() -> void:
	_save()
	call_deferred("queue_free")

## Pauses all available AudioStreamPlayers within the audio group
func pause_streams(state: bool) -> void:
	for x in get_tree().get_nodes_in_group("audio"):
		if x is AudioStreamPlayer:
			x.stream_paused = state

func pause_game(pause: bool) -> void:
	get_tree().paused = pause
	game_paused = pause
	pause_streams(pause)

## Used for things to check if the game/tree is paused
func is_paused() -> bool:
	return game_paused
