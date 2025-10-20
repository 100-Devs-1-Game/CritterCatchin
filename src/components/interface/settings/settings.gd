extends Control

@export var window_mode: CheckBox
@export var flashing_enabler: CheckBox
@export var custom_cursor: CheckBox
@export var animate_ui: CheckBox

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
		_load_toggle(window_mode, "fullscreen")
		_load_toggle(flashing_enabler, "flashing")
		_load_toggle(animate_ui, "animated")
		_load_toggle(custom_cursor, "cursor")
		_load_audio_sliders()
		_connect_signals()

	if OS.has_feature("web"):
		$CanvasLayer/MenuPanel6/MenuPanel5/Panel/SettingVBox/VBoxContainer/Fullscreen.visible = false

func _connect_signals() -> void:
	window_mode.toggled.connect(_on_fullscreen_selected)
	flashing_enabler.toggled.connect(_on_flashing_selected)
	animate_ui.toggled.connect(_on_animate_ui_selected)
	custom_cursor.toggled.connect(_on_custom_mouse_selected)
	master_slider.value_changed.connect(_on_master_slider_changed)
	sfx_slider.value_changed.connect(_on_sfx_slider_changed)
	music_slider.value_changed.connect(_on_music_slider_changed)
	exit_button.pressed.connect(func(): queue_free())

func _load_toggle(toggle: CheckBox, key: String) -> void:
	toggle.button_pressed = settings_manager.get_settings().get(key, false)

func _load_audio_sliders() -> void:
	var audio_sliders = settings_manager.get_all_volumes()
	master_slider.value = audio_sliders["Master"] * 100.0
	sfx_slider.value = audio_sliders["SFX"] * 100.0
	music_slider.value = audio_sliders["Music"] * 100.0

func _on_flashing_selected(is_flashing: bool) -> void:
	if settings_manager.has_method("set_flashing_mode"):
		settings_manager.set_flashing_mode(is_flashing)

func _on_fullscreen_selected(fullscreen: bool) -> void:
	if settings_manager.has_method("set_window_mode"):
		settings_manager.set_window_mode(fullscreen)

func _on_custom_mouse_selected(cursor: bool) -> void:
	if settings_manager.has_method("set_custom_cursor"):
		settings_manager.set_custom_cursor(cursor)

func _on_animate_ui_selected(animate: bool) -> void:
	if settings_manager.has_method("set_animated_ui"):
		settings_manager.set_animated_ui(animate)

func _on_master_slider_changed(value: float) -> void:
	var new_value = value / 100
	if settings_manager.has_method("set_bus_volume"):
		settings_manager.set_bus_volume("Master", new_value)

func _on_sfx_slider_changed(value: float) -> void:
	var new_value = value / 100
	if settings_manager.has_method("set_bus_volume"):
		settings_manager.set_bus_volume("SFX", new_value)

func _on_music_slider_changed(value: float) -> void:
	var new_value = value / 100
	if settings_manager.has_method("set_bus_volume"):
		settings_manager.set_bus_volume("Music", new_value)

func _on_tree_exiting() -> void:
	Eventbus.menu_closed.emit()
	await Eventbus.menu_closed
	queue_free()
