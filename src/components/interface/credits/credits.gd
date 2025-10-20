extends Node2D


func _on_quit_pressed() -> void:
	queue_free()


func _on_tree_exiting() -> void:
	Eventbus.menu_closed.emit()
