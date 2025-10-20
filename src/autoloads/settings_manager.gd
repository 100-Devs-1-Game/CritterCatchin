extends Node

var fullscreen: bool = false
var game_paused: bool = false
var flashing_enabled: bool = true
var animated_ui: bool = true
var custom_cursor: bool = true
var notified: bool = false
var st_notified: bool = false
var player_username: String = ""

var volumes: Dictionary = {
	"Master": 1.0,
	"SFX": 1.0,
	"Music": 1.0,
}

const CFG: String = "user://settings.cfg"
const SEC_VIDEO: String = "Video"
const SEC_AUDIO: String = "Audio"
const SEC_USER: String = "Username"
const SEC_STATES: String = "States"
const SETTINGS = preload("res://components/interface/settings/settings.tscn")

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	add_to_group("SManager")
	_load()

	set_window_mode(fullscreen)

	for bus_name in volumes.keys():
		_apply_bus_volume(bus_name, volumes[bus_name])


## Creates and displays the settings overlay on a parent node
func display_settings_overlay(parent: Node) -> void:
	if parent:
		var s = SETTINGS.instantiate()
		parent.add_child(s)

func set_flashing_mode(state: bool) -> void:
	flashing_enabled = state
	print("Flashing state changed: ", state)
	_save()

## Sets window mode to either fullscreen or windowed
func set_window_mode(state: bool) -> void:
	fullscreen = state
	if fullscreen:
		DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_BORDERLESS, false)
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
		DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_BORDERLESS, false)

	_save()


func set_animated_ui(state: bool) -> void:
	animated_ui = state
	_save()

func set_custom_cursor(state: bool) -> void:
	custom_cursor = state
	_save()

## Sets a bus volume, applies it, and saves
func set_bus_volume(bus: String, linear_value: float) -> void:
	volumes[bus] = clamp(linear_value, 0.0, 1.0)
	_apply_bus_volume(bus, volumes[bus])
	_save()


## Returns the current bus volume
func get_bus_volume(bus: String) -> float:
	return volumes.get(bus, 1.0)


## Returns a copy of all bus volumes
func get_all_volumes() -> Dictionary:
	return volumes.duplicate()


## Applies the volume to a bus
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


## Returns all current settings
func get_settings() -> Dictionary:
	return {
		"fullscreen": fullscreen,
		"volumes": get_all_volumes(),
		"flashing": flashing_enabled,
		"animated": animated_ui,
		"cursor": custom_cursor
	}


func _save() -> void:
	var c = ConfigFile.new()
	c.set_value(SEC_VIDEO, "fullscreen", fullscreen)
	c.set_value(SEC_USER, "username", player_username)
	c.set_value(SEC_STATES, "notified", notified)
	c.set_value(SEC_STATES, "st_notified", st_notified)
	c.set_value(SEC_STATES, "flashing", flashing_enabled)
	c.set_value(SEC_STATES, "animated", animated_ui)
	c.set_value(SEC_STATES, "cursor", custom_cursor)

	for bus in volumes.keys():
		c.set_value(SEC_AUDIO, bus, volumes[bus])

	var err = c.save(CFG)
	if err != OK:
		push_error("Failed to save settings: %s" % str(err))


func _load() -> void:
	var c = ConfigFile.new()
	if c.load(CFG) != OK:
		return

	fullscreen = bool(c.get_value(SEC_VIDEO, "fullscreen", fullscreen))
	notified = bool(c.get_value(SEC_STATES, "notified", notified))
	st_notified = bool(c.get_value(SEC_STATES, "st_notified", st_notified))
	player_username = str(c.get_value(SEC_USER, "username", player_username))
	flashing_enabled = bool(c.get_value(SEC_STATES, "flashing", flashing_enabled))
	animated_ui = bool(c.get_value(SEC_STATES, "animated", animated_ui))
	custom_cursor = bool(c.get_value(SEC_STATES, "cursor", custom_cursor))

	for bus in ["Master", "SFX", "Music"]:
		if c.has_section_key(SEC_AUDIO, bus):
			volumes[bus] = clamp(float(c.get_value(SEC_AUDIO, bus, 1.0)), 0.0, 1.0)

## Save and quit the game
func close_game() -> void:
	_save()
	AchievementManager._save_progress()
	get_tree().quit()

## Sets the player's username
func set_username(username: String) -> void:
	username = username.strip_edges().to_upper()
	print_debug("Username submitted: ", username)
	player_username = username
	_save()

func clear_username() -> void:
	player_username = ""
	_save()

## Returns the player's username
func get_username() -> String:
	return player_username

func has_username() -> bool:
	if player_username.strip_edges() == "":
		return false
	else:
		return true

## Pauses all AudioStreamPlayers in the "audio" group
func pause_streams(state: bool) -> void:
	for x in get_tree().get_nodes_in_group("audio"):
		if x is AudioStreamPlayer:
			x.stream_paused = state

## Pause or unpause the game
func pause_game(pause: bool) -> void:
	get_tree().paused = pause
	game_paused = pause
	pause_streams(pause)

## Returns if the game/tree is paused
func is_paused() -> bool:
	return game_paused
