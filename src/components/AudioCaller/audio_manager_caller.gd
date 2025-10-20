extends Node

@export var sound_buttons: Array[BaseButton] = []
@export var sound_sliders: Array[Slider] = []

const UI_HOVER = preload("res://audio/pop.mp3")

func _ready() -> void:
	for b in sound_buttons:
		b.mouse_entered.connect(_play_sound)
	for s in sound_sliders:
		s.mouse_entered.connect(_play_sound)

func _play_sound() -> void:
	AudioManager.play_sound(UI_HOVER)
