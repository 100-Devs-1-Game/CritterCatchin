extends Node2D


func _on_close_pressed() -> void:
	queue_free()



func _on_child_exiting_tree(node: Node) -> void:
	Eventbus.menu_closed.emit()
	await Eventbus.menu_closed
	queue_free()
