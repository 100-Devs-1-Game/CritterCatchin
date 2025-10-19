extends Control

@export var window_mode: CheckBox

@export var master_slider: Slider
@export var sfx_slider: Slider
@export var music_slider: Slider

@export var exit_button: BaseButton

var settings_manager: Node

func _ready() -> void:
	settings_manager = get_tree().get_first_node_in_group("SManager")
	if settings_manager == null:
		push_error("Settings Manager autoload not found in tree.")
	else:
		_load_fullscreen_setting()
		_load_audio_sliders()
		_connect_signals()

func _connect_signals() -> void:
	window_mode.toggled.connect(_on_fullscreen_selected)
	master_slider.value_changed.connect(_on_master_slider_changed)
	sfx_slider.value_changed.connect(_on_sfx_slider_changed)
	music_slider.value_changed.connect(_on_music_slider_changed)
	exit_button.pressed.connect(func(): queue_free())

func _load_audio_sliders() -> void:
	var audio_sliders = settings_manager.get_all_volumes()
	master_slider.value = audio_sliders["Master"] * 100.0
	sfx_slider.value = audio_sliders["SFX"] * 100.0
	music_slider.value = audio_sliders["Music"] * 100.0

func _load_fullscreen_setting() -> void:
	if settings_manager != null:
		var settings = settings_manager.get_settings()
		window_mode.button_pressed = settings.get("fullscreen_mode", false)

func _on_fullscreen_selected(fullscreen: bool) -> void:
	if settings_manager != null and settings_manager.has_method("set_fullscreen_mode"):
		var selected_state: bool = window_mode.button_pressed
		settings_manager.set_fullscreen_mode(selected_state)

func _on_master_slider_changed(value: float) -> void:
	var new_value = value / 100
	if settings_manager != null:
		if settings_manager.has_method("set_bus_volume"):
			settings_manager.set_bus_volume("Master", new_value)

func _on_sfx_slider_changed(value: float) -> void:
	var new_value = value / 100
	if settings_manager != null:
		if settings_manager.has_method("set_bus_volume"):
			settings_manager.set_bus_volume("SFX", new_value)

func _on_music_slider_changed(value: float) -> void:
	var new_value = value / 100
	if settings_manager != null:
		if settings_manager.has_method("set_bus_volume"):
			settings_manager.set_bus_volume("Music", new_value)


func _on_child_exiting_tree(node: Node) -> void:
	Eventbus.menu_closed.emit()
	await Eventbus.menu_closed
	queue_free()
