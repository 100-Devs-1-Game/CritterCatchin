extends CanvasLayer

var response: bool = false

func _on_warning_anim_animation_finished(_anim_name: StringName) -> void:
	await get_tree().create_timer(1.0).timeout
	$VBoxContainer2.visible = true

func _on_disable_pressed() -> void:
	response = true
	SettingsManager.flashing_enabled = false
	SettingsManager._save()
	queue_free()

func _on_ignore_pressed() -> void:
	response = true
	queue_free()

func _on_back_pressed() -> void:
	response = false
	queue_free()


func _on_child_exiting_tree(_node: Node) -> void:
	Eventbus.warning_closed.emit(response)
	SettingsManager.notified = true
