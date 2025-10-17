extends Node

@warning_ignore("unused_signal")
signal bug_caught
@warning_ignore("unused_signal")
signal level_started(difficulty: int)
@warning_ignore("unused_signal")
signal level_ended
@warning_ignore("unused_signal")
signal capture_bug(pos: Vector2)
@warning_ignore("unused_signal")
signal add_bug(tex: Texture2D)

func _ready():
	self.process_mode = Node.PROCESS_MODE_ALWAYS
