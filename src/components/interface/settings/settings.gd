extends Control

@export var tab_buttons: Array[BaseButton] = []
@export var exit_button: BaseButton
@export var setting_tabs: Array[Control] = []

func _ready(): 
	for b in tab_buttons: b.pressed.connect(show_tab.bind(b.name))
	if exit_button:
		exit_button.pressed.connect(func(): SettingsManager.save_game() ; queue_free() ; SettingsManager.pause_game(false))

func show_tab(t): 
	for s in setting_tabs: s.visible = s.name == t

func _apply_setting_values() -> void:
	#TODO: Get settings from SettingsManager, apply them to their nodes.
	pass
