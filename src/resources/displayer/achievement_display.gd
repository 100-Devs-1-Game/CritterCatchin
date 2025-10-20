extends CanvasLayer

func _on_displayer_animation_finished(anim_name: StringName) -> void:
	queue_free()
