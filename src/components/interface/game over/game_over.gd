extends Control

func _ready() -> void:
	$CanvasLayer/VBoxContainer/replay.pressed.connect(func(): Sceneloader.to_game())
	$CanvasLayer/VBoxContainer/exit.pressed.connect(func(): Sceneloader.to_title())
