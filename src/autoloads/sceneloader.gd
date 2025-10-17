extends Node

var active_scene: Node = null

func _ready():
	self.process_mode = Node.PROCESS_MODE_ALWAYS

func to_title() -> void:
	load_scene("res://scenes/title.tscn")

func to_game() -> void:
	load_scene("res://scenes/game.tscn")

func load_scene(path: String) -> void:
	var err = get_tree().change_scene_to_file(path)
	if err != OK:
		push_error("Failed to change scene to: " + path)
