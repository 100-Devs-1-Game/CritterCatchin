extends Node

@export var save_on_exit: bool = true

const SETTINGS = preload("res://components/interface/settings/settings.tscn")

func _ready() -> void:
	self.process_mode = Node.PROCESS_MODE_ALWAYS
	load_game()

func _set_autoload_processing() -> void:
	pass

func display_settings_overlay(parent: Node) -> void:
	var s = SETTINGS.instantiate()
	if parent:
		parent.add_child(s)
	pause_game(true)

func save_game() -> void:
	pass

func load_game() -> void:
	pass

func pause_game(pause: bool) -> void:
	get_tree().paused = pause

func close_game() -> void:
	if save_on_exit:
		save_game()
	get_tree().quit()
