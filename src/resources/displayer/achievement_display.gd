extends CanvasLayer

const ACHIEVEMENT_UNLOCK = preload("res://audio/achievement unlock.mp3")

func _ready() -> void:
	AudioManager.play_sound(ACHIEVEMENT_UNLOCK)

func _on_displayer_animation_finished(_anim_name: StringName) -> void:
	queue_free()
