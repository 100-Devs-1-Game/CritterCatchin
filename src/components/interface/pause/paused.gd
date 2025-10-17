extends Control

@export var pause: Panel
@export var confirm: Panel

var parent: CanvasLayer

func _ready() -> void:
	if get_parent() is CanvasLayer:
		parent = get_parent()
	SettingsManager.pause_game(true)

func _resume() -> void:
	SettingsManager.pause_game(false)
	queue_free()

func _settings() -> void:
	SettingsManager.display_settings_overlay(self)

func _exit() -> void:
	SettingsManager.pause_game(false)
	Sceneloader.to_title()
	queue_free()
