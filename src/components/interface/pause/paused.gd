extends Control

@export var pause: Panel

func _ready() -> void:
	_pause()

func _pause() -> void:
	SettingsManager.pause_game(true)
	SettingsManager.pause_streams(true)

func _unpause() -> void:
	SettingsManager.pause_game(false)
	SettingsManager.pause_streams(false)
	Eventbus.pauser_removed.emit()
	queue_free()

func _resume() -> void:
	_unpause()

func _settings() -> void:
	SettingsManager.display_settings_overlay(self)

func _exit() -> void:
	_unpause()
	Sceneloader.to_title()
