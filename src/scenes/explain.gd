extends CanvasLayer

func _ready() -> void:
	if OS.has_feature("web"):
		$browtip.visible = true

func _on_tree_exiting() -> void:
	if !SettingsManager.st_notified:
		SettingsManager.st_notified = true
		SettingsManager._save()
